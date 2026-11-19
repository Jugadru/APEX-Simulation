extends Node
## APEX v0.6.6.8.11 — real driver portraits, sourced ONLY from a curated
## Wikimedia Commons collection when the player requests the download.
## No inferred identity from image pixels, no cars as fallback, no AI faces.
## CC BY-SA 3.0 credits: Gussisaurio, source links in driver_identity_2012.json.

signal status_changed(message: String)
signal portraits_finished()

const PortraitLocal = preload("res://scripts/apex_portrait_local_2012.gd")
const MANIFEST := "res://data/driver_identity_2012.json"
const CACHE_FOLDER := "user://apex_driver_portraits_2012"
const MAX_IMAGE_BYTES := 2500000
const MAX_THUMB_WIDTH := 480
const BETWEEN_PORTRAITS_SECONDS := 1.5
const MAX_TRANSIENT_RETRIES := 4

var status := "Retratos 2012: clique para baixar fotografias individuais (Wikimedia Commons)."
var download_state := "idle"
var _entries: Dictionary = {}
var _textures: Dictionary = {}
var _local_names: Dictionary = {}
var _requests: Array[String] = []
var _active_name := ""
var _image_url := ""
var _metadata_url := ""
var _transient_retries := 0
var _phase := ""
var _completed := 0
var _failed := 0
var _total := 0
var _http: HTTPRequest

func _ready() -> void:
	_load_catalogue()
	if PortraitLocal.available_count() > 0:
		status = "APEX Retratos 2012: %d arquivos locais de HUD disponíveis." % PortraitLocal.available_count()
	_http = HTTPRequest.new()
	_http.name = "LicensedPortraitRequest"
	_http.timeout = 20.0
	_http.max_redirects = 8
	add_child(_http)
	_http.request_completed.connect(_request_completed)
	var absolute: String = ProjectSettings.globalize_path(CACHE_FOLDER)
	DirAccess.make_dir_recursive_absolute(absolute)

func _load_catalogue() -> void:
	_entries.clear()
	if not FileAccess.file_exists(MANIFEST):
		status = "Catálogo 2012 indisponível; iniciais preservadas."
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if typeof(parsed) != TYPE_DICTIONARY:
		status = "Catálogo de pilotos inválido; iniciais preservadas."
		return
	for item in parsed.get("drivers", []):
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var name: String = str(item.get("name", ""))
		if not name.is_empty():
			_entries[name] = item.duplicate(true)

func get_info(driver_name: String) -> Dictionary:
	return _entries.get(driver_name, {}).duplicate(true)

func get_abbreviation(driver_name: String) -> String:
	# The curated 2012 code is authoritative; unknown drivers use a UI fallback.
	return str(_entries.get(driver_name, {}).get("abbr", ""))

func get_credit(driver_name: String) -> String:
	if _local_names.has(driver_name) or PortraitLocal.has_texture(driver_name):
		return "Retrato original fornecido pelo usuário; direitos de redistribuição não verificados."
	var info: Dictionary = _entries.get(driver_name, {})
	if info.is_empty():
		return ""
	return "Foto: %s · %s · Wikimedia Commons" % [
		str(info.get("photographer", "")), str(info.get("license", ""))]

func get_source_url(driver_name: String) -> String:
	if _local_names.has(driver_name) or PortraitLocal.has_texture(driver_name):
		return ""
	var info: Dictionary = _entries.get(driver_name, {})
	if info.is_empty():
		return ""
	return "https://commons.wikimedia.org/wiki/File:" + str(info.get("source_file", "")).replace(" ", "_").uri_encode()

func _cache_file(driver_name: String) -> String:
	var entry: Dictionary = _entries.get(driver_name, {})
	if entry.is_empty():
		return ""
	return CACHE_FOLDER + "/driver_%02d.jpg" % int(entry.get("number", 0))

func has_photo(driver_name: String) -> bool:
	return get_photo(driver_name) != null

func get_photo(driver_name: String) -> Texture2D:
	if _textures.has(driver_name):
		return _textures[driver_name]
	var bundled: Texture2D = PortraitLocal.get_texture(driver_name, "hud")
	if bundled != null:
		_textures[driver_name] = bundled
		_local_names[driver_name] = true
		return bundled
	var path: String = _cache_file(driver_name)
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load_jpg_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
		return null
	if image.get_width() < 128 or image.get_height() < 128:
		return null
	var texture := ImageTexture.create_from_image(image)
	_textures[driver_name] = texture
	return texture

func get_profile_photo(driver_name: String) -> Texture2D:
	var local_profile: Texture2D = PortraitLocal.get_texture(driver_name, "profile")
	if local_profile != null:
		return local_profile
	return get_photo(driver_name)

func download_for_team(driver_names: Array[String]) -> void:
	if download_state == "running":
		status_changed.emit("Download de retratos já está em andamento.")
		return
	if _http == null:
		status_changed.emit("Gerenciador de retratos ainda indisponível.")
		portraits_finished.emit()
		return
	_requests.clear()
	var added: Dictionary = {}
	for name in driver_names:
		if added.has(name) or not _entries.has(name):
			continue
		added[name] = true
		if not has_photo(name):
			_requests.append(name)
	_completed = 0
	_failed = 0
	_total = _requests.size()
	if _total == 0:
		status = "Retratos já disponíveis em cache ou sem novos pilotos reconhecidos."
		download_state = "idle"
		status_changed.emit(status)
		portraits_finished.emit()
		return
	download_state = "running"
	status = "Wikimedia Commons: verificando licença e baixando %d retrato(s)." % _total
	status_changed.emit(status)
	call_deferred("_next_portrait")

func _request_headers() -> PackedStringArray:
	return PackedStringArray([
		"User-Agent: APEXMotorsportManager/0.6.6.8.11 (2012 driver portrait viewer; Wikimedia Commons)",
		"Accept: application/json, image/jpeg"
	])

func _next_portrait() -> void:
	if _requests.is_empty():
		download_state = "idle"
		_phase = ""
		_active_name = ""
		status = "Retratos concluídos: %d novos, %d indisponível(is). Consulte créditos CC BY-SA 3.0." % [_completed, _failed]
		status_changed.emit(status)
		portraits_finished.emit()
		return
	_active_name = _requests.pop_front()
	_transient_retries = 0
	_image_url = ""
	var info: Dictionary = _entries.get(_active_name, {})
	var name: String = "File:" + str(info.get("source_file", ""))
	# The API supplies a thumb URL and a per-file copyright statement.
	var endpoint: String = "https://commons.wikimedia.org/w/api.php?action=query&format=json&formatversion=2&titles=" \
		+ name.uri_encode() \
		+ "&prop=imageinfo&iiprop=url%7Csize%7Cmime%7Cextmetadata&iiurlwidth=" + str(MAX_THUMB_WIDTH)
	_phase = "metadata"
	_metadata_url = endpoint
	var err: int = _http.request(_metadata_url, _request_headers(), HTTPClient.METHOD_GET)
	if err != OK:
		_skip("Falha de conexão ao consultar metadados")

func _metadata_text(data: Dictionary, field: String) -> String:
	var value: Variant = data.get(field, {})
	return str(value.get("value", "")) if typeof(value) == TYPE_DICTIONARY else ""

func _request_completed(result: int, status_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if download_state != "running" or _active_name.is_empty():
		return
	if result != HTTPRequest.RESULT_SUCCESS or status_code != 200:
		if result == HTTPRequest.RESULT_SUCCESS and _is_retryable_http_status(status_code) and _transient_retries < MAX_TRANSIENT_RETRIES:
			_transient_retries += 1
			var pause: float = _retry_delay_seconds(_transient_retries, headers)
			status = "%s: servidor temporariamente indisponível (HTTP %d). Nova tentativa %d/%d em %.0f s." % [
				_active_name, status_code, _transient_retries, MAX_TRANSIENT_RETRIES, pause]
			status_changed.emit(status)
			get_tree().create_timer(pause).timeout.connect(_retry_current_request)
			return
		_skip("HTTP %d / conexão %d" % [status_code, result])
		return
	if _phase == "metadata":
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if typeof(parsed) != TYPE_DICTIONARY:
			_skip("Metadados inválidos")
			return
		var query: Variant = parsed.get("query", {})
		var pages: Variant = query.get("pages", []) if typeof(query) == TYPE_DICTIONARY else []
		if typeof(pages) != TYPE_ARRAY or pages.is_empty():
			_skip("Fotografia não encontrada no Commons")
			return
		var images: Variant = pages[0].get("imageinfo", [])
		if typeof(images) != TYPE_ARRAY or images.is_empty():
			_skip("Sem metadados da fotografia")
			return
		var image_info: Dictionary = images[0]
		var meta: Dictionary = image_info.get("extmetadata", {})
		var license_name: String = _metadata_text(meta, "LicenseShortName")
		var artist: String = _metadata_text(meta, "Artist")
		# Reconfirm per file, not just category membership. Never cache uncertain licences.
		if license_name != "CC BY-SA 3.0" or not artist.contains("Gussisaurio"):
			_skip("Licença ou autor não confirmado")
			return
		if str(image_info.get("mime", "")) != "image/jpeg":
			_skip("Formato não suportado")
			return
		_image_url = str(image_info.get("thumburl", image_info.get("url", "")))
		if not (_image_url.begins_with("https://thumb.wikimedia.org/wikipedia/commons/thumb/") \
			or _image_url.begins_with("https://upload.wikimedia.org/wikipedia/commons/")):
			_skip("Origem de imagem inválida: " + _image_url.left(180))
			return
		_phase = "image_pending"
		call_deferred("_request_image")
	elif _phase == "image":
		if body.size() < 1000 or body.size() > MAX_IMAGE_BYTES:
			_skip("Tamanho inesperado da fotografia")
			return
		var decoded := Image.new()
		if decoded.load_jpg_from_buffer(body) != OK or decoded.get_width() < 128 or decoded.get_height() < 128:
			_skip("Fotografia não decodificada")
			return
		var save_path: String = _cache_file(_active_name)
		var fd: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
		if fd == null:
			_skip("Não foi possível gravar cache local")
			return
		fd.store_buffer(body)
		fd.close()
		_textures[_active_name] = ImageTexture.create_from_image(decoded)
		_completed += 1
		status = "Retrato real: %s (%d/%d), fotógrafo Gussisaurio." % [_active_name, _completed + _failed, _total]
		status_changed.emit(status)
		_schedule_next_portrait()

func _request_image() -> void:
	_phase = "image"
	var err: int = _http.request(_image_url, _request_headers(), HTTPClient.METHOD_GET)
	if err != OK:
		_skip("Falha ao baixar a imagem")

func _skip(reason: String) -> void:
	_failed += 1
	status = "%s: %s. Mantendo iniciais; nunca substituindo por foto de carro." % [_active_name, reason]
	status_changed.emit(status)
	_schedule_next_portrait()

func _is_retryable_http_status(status_code: int) -> bool:
	return status_code in [429, 500, 502, 503, 504]

func _retry_delay_seconds(attempt: int, headers: PackedStringArray = PackedStringArray()) -> float:
	# Respect retry-after seconds, with a strict bound to avoid indefinite UI stalls.
	var delay: float = minf(30.0, 2.0 * pow(2.0, float(maxi(0, attempt - 1))))
	for header in headers:
		if header.to_lower().begins_with("retry-after:"):
			var requested: String = header.substr(header.find(":") + 1).strip_edges()
			if requested.is_valid_int():
				delay = maxf(delay, minf(30.0, float(maxi(0, int(requested)))))
	return delay

func _retry_current_request() -> void:
	if download_state != "running" or _active_name.is_empty() or _http == null:
		return
	var url: String = _metadata_url if _phase == "metadata" else _image_url
	if url.is_empty() or _phase not in ["metadata", "image"]:
		_skip("Etapa de download inválida")
		return
	var err: int = _http.request(url, _request_headers(), HTTPClient.METHOD_GET)
	if err != OK:
		_skip("Falha ao retomar download")

func _schedule_next_portrait() -> void:
	# Spacing requests is kinder to Commons and avoids repeated HTTP 429.
	if download_state == "running":
		get_tree().create_timer(BETWEEN_PORTRAITS_SECONDS).timeout.connect(_next_portrait)

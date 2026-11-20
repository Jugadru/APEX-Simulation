extends SceneTree
## APEX 2012: teste ESTRITO para assets locais. Ao contrario do fallback, 0 arquivos falha.
## Godot 4.7.2: --headless --path . --script res://tests/apex_portraits_2012_strict_066841_smoke.gd
const Local = preload("res://scripts/apex_portrait_local_2012.gd")
const IDS := [
    "sebastian_vettel", "mark_webber", "jenson_button", "lewis_hamilton",
    "fernando_alonso", "felipe_massa", "michael_schumacher", "nico_rosberg",
    "kimi_raikkonen", "romain_grosjean", "paul_di_resta", "nico_hulkenberg",
    "kamui_kobayashi", "sergio_perez", "daniel_ricciardo", "jean_eric_vergne",
    "pastor_maldonado", "bruno_senna", "heikki_kovalainen", "vitaly_petrov",
    "pedro_de_la_rosa", "narain_karthikeyan", "timo_glock", "charles_pic"
]
func _initialize() -> void:
    call_deferred("_check")
func _check() -> void:
    var errors: Array[String] = []
    var total := 0
    for slug in IDS:
        for kind in ["hud", "profile"]:
            var name: String = slug.replace("_", " ")
            var path: String = Local.texture_path(name, kind)
            var texture: Texture2D = Local.get_texture(name, kind)
            if path.is_empty() or texture == null:
                errors.append("missing " + path)
                continue
            var wanted := Vector2i(384, 400) if kind == "hud" else Vector2i(640, 800)
            if Vector2i(texture.get_width(), texture.get_height()) != wanted:
                errors.append("wrong size " + path)
            else:
                total += 1
    if total != 48 or Local.available_count("hud") != 24 or Local.available_count("profile") != 24:
        errors.append("expected 48 textures, got %d" % total)
    if errors.is_empty(): print("APEX_PORTRAIT_PACK_2012_STRICT_PASS: 48 textures / 24 identities")
    else:
        for issue in errors: printerr("APEX_PORTRAIT_PACK_2012_STRICT_FAIL: ", issue)
    quit(0 if errors.is_empty() else 1)

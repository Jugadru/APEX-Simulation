extends SceneTree
## Project metadata contract; independent of sporting fixtures.
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		printerr("PROJECT_IDENTITY_FAIL " + description)

func _run() -> void:
	# Preserve the approved existing identity policy without tying it to weather.
	var app_name: String = str(ProjectSettings.get_setting("application/config/name", ""))
	var app_description: String = str(ProjectSettings.get_setting("application/config/description", ""))
	var version: String = str(ProjectSettings.get_setting("application/config/version",""))
	var parts: PackedStringArray = version.split(".")
	var numeric := true
	for part in parts:
		numeric = numeric and part.is_valid_int() and str(int(part)) == part and int(part) >= 0
	# Historical 9.8+ (optional patch) OR the approved short sequence 0.6.7+.
	var supported := false
	if numeric and parts.size() in [5,6]:
		supported = parts[0]=="0" and parts[1]=="6" and parts[2]=="6" and parts[3]=="9" and int(parts[4])>=8
	elif numeric and parts.size()==3:
		supported = parts[0]=="0" and (int(parts[1])>6 or (parts[1]=="6" and int(parts[2])>=7))
	var valid_name: bool = supported and app_name == "APEX Motorsport Manager v"+version+" — Core 2"
	check(valid_name, "supported Core 2 historical or short naming convention")
	check(valid_name and app_description.begins_with("v"+version+":"),
		"project description must match the Core 2 build identity")
	if failures.is_empty():
		print("PROJECT_IDENTITY_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)

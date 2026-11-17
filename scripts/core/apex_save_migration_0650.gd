extends RefCounted
## v0.6.5.0: one-time, read-only migration of 9.9 user:// saves.
## Godot with use_custom_user_dir=true stores at XDG_DATA_HOME/<custom-name>,
## while older builds used godot/app_userdata/<display-name>.
const PREFIXES := ["APEX_064", "apex motorsport manager", "APEX Motorsport Manager"]
const CURRENT_DIR := "APEX_0650_SOUL_STAFF"

static func previous_file(filename: String) -> String:
    if filename.is_empty() or filename.contains("/") or filename.contains("\\"):
        return ""
    var data_home: String = OS.get_environment("XDG_DATA_HOME")
    if data_home.is_empty():
        data_home = OS.get_environment("HOME").path_join(".local/share")
    var best_path: String = ""
    var best_time: int = -1
    for directory in [data_home, data_home.path_join("godot/app_userdata")]:
        if not DirAccess.dir_exists_absolute(directory):
            continue
        for folder in DirAccess.get_directories_at(directory):
            var folder_name: String = str(folder)
            if folder_name == CURRENT_DIR:
                continue
            var matching: bool = false
            for prefix in PREFIXES:
                if folder_name.to_lower().begins_with(str(prefix).to_lower()):
                    matching = true
                    break
            if not matching:
                continue
            var candidate: String = directory.path_join(folder_name).path_join(filename)
            if not FileAccess.file_exists(candidate):
                continue
            var modified: int = FileAccess.get_modified_time(candidate)
            if modified >= best_time:
                best_time = modified
                best_path = candidate
    return best_path

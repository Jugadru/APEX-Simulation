extends SceneTree
## Assets temporários de QA, NÃO representam fotos e NÃO podem ir para produção.
## Rodar somente em checkout temporário de CI.
const Portraits = preload("res://scripts/apex_portrait_local_2012.gd")
func _initialize() -> void:
    call_deferred("_build")
func _build() -> void:
    for kind in ["hud", "profile"]:
        var directory: String = "res://assets/portraits_2012/" + kind
        if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK:
            printerr("QA_FIXTURES_FAIL: cannot mkdir ", directory)
            quit(1)
            return
        var size := Vector2i(384,400) if kind == "hud" else Vector2i(640,800)
        for i in range(Portraits.DRIVER_IDS.size()):
            var slug: String = str(Portraits.DRIVER_IDS[i])
            var im := Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
            var marker: Color = Color.from_hsv(float(i)/24.0,0.65,0.55,1)
            im.fill(marker)
            var path: String = directory + "/" + slug + "_" + kind + "_2012.png"
            if im.save_png(path) != OK:
                printerr("QA_FIXTURES_FAIL: cannot write ", path)
                quit(2)
                return
    print("APEX_2012_CI_FIXTURES_READY 48 placeholders (NOT USER PHOTOS)")
    quit(0)

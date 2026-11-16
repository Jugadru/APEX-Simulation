extends SceneTree
func _initialize()->void:
	var before:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://qa/living_factory_2/save_v0655_fixture.json"))
	var file:=FileAccess.open("user://legacy_0656_test.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(before))
	file.close()
	var g=load("res://scripts/garage.gd").new("user://legacy_0656_test.json")
	g.get_team("Ferrari")
	var after:Dictionary=JSON.parse_string(JSON.stringify(g.team_data))
	after.Ferrari.erase("workshop")
	assert(JSON.stringify(before)==JSON.stringify(after),"all v0655 fields retained")
	assert(g.save())
	print("LEGACY_0655_PASS actual v0655 save; every prior field retained")
	quit()

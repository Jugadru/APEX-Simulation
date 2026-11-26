extends SceneTree
const Garage = preload("res://scripts/garage.gd")
const W = preload("res://scripts/core/workshop_0656.gd")
const I = preload("res://scripts/core/component_inventory_0651.gd")
var failures: Array[String] = []
var checks := 0
func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FACTORY_SLOT_0924_FAIL ",label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var path := "user://factory_slot_0924_%s.json" % Crypto.new().generate_random_bytes(8).hex_encode()
	var g = Garage.new(path)
	var s: Dictionary = g.get_team("Ferrari")
	g.staff_hire_candidate("Ferrari","Chefe de Mecânica","mec_a")
	g.staff_hire_candidate("Ferrari","Engenheiro","eng_b")
	var a := I.installed(s.component_inventory,1,"Motor")
	var b := I.installed(s.component_inventory,2,"Motor")
	verify(g.component_action("Ferrari",a,"remove",0).contains("salvo"),"remove A")
	verify(g.component_action("Ferrari",b,"remove",0).contains("salvo"),"remove B")
	var args := {"car":1,"part":a,"service":"Substituição","staff":"mec_a"}
	var other := {"car":1,"part":b,"service":"Substituição","staff":"eng_b"}
	verify(g.workshop_action("Ferrari","create",args).contains("salva"),"reserve empty slot")
	if s.workshop.tasks.is_empty():
		quit(1)
		return
	var id: String = s.workshop.tasks[0].id
	verify(W.slot_locked(s,1,"Motor"),"slot locked")
	verify(not W.slot_locked(s,2,"Motor") and not W.slot_locked(s,1,"Asa"),"other destinations unaffected")
	var before := JSON.stringify(s)
	verify(not W.create(s,other).is_empty(),"second replacement rejected")
	verify(JSON.stringify(s)==before,"rejection no cost, task or history")
	verify(g.component_action("Ferrari",b,"install",1).contains("reservado"),"direct install rejected")
	verify(JSON.stringify(s)==before,"direct rejection unchanged")
	# Reload persisted reservation, no new fields required.
	g = Garage.new(path)
	s = g.get_team("Ferrari")
	verify(W.slot_locked(s,1,"Motor"),"reservation survives reload")
	verify(g.component_action("Ferrari",b,"install",1).contains("reservado"),"reload guard")
	verify(g.workshop_action("Ferrari","cancel",{"id":id}).contains("salva"),"cancel")
	verify(not W.slot_locked(s,1,"Motor"),"cancel releases destination")
	verify(g.workshop_action("Ferrari","create",other).contains("salva"),"new reservation")
	verify(g.workshop_action("Ferrari","advance",{"hours":8}).contains("salva"),"advance")
	verify(I.installed(s.component_inventory,1,"Motor")==b,"reserved part installed")
	verify(not W.slot_locked(s,1,"Motor"),"completion releases destination")
	verify(s.component_inventory.parts.size()==6 and I.validate(s.component_inventory,Garage.PARTS).is_empty(),"no duplicate parts")
	# Simulate an old save with a stale recorded target; it must not displace B.
	var stale := {"car":1,"part":a,"service":"Substituição","staff":"mec_a"}
	verify(W.create(s,stale).is_empty(),"prepare legacy fixture")
	var t: Dictionary = s.workshop.tasks[-1]
	t.old_part = ""
	var stock_before := JSON.stringify(s.component_inventory)
	W.advance(s,8)
	verify(I.installed(s.component_inventory,1,"Motor")==b and JSON.stringify(s.component_inventory)==stock_before,"stale task cannot overwrite actual destination")
	verify(W.active(t) and t.status!="concluída","stale task not completed")
	verify(W.cancel(s,t.id).is_empty(),"stale task cancellable")
	verify(not W.slot_locked(s,1,"Motor"),"stale cancellation releases slot")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	if failures.is_empty(): print("FACTORY_SLOT_0924_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)

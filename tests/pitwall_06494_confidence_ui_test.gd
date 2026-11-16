extends SceneTree
## UI real Xvfb: confiança explicada sem abrir ordem de box.
var fails: Array[String] = []
func _initialize() -> void:
    call_deferred("_run")
func verify(ok: bool, text: String) -> void:
    if not ok:
        fails.append(text)
        printerr("CONF_UI_06494_FAIL ",text)
func _run() -> void:
    root.size = Vector2i(1600,900)
    var scene: PackedScene = load("res://scenes/main.tscn")
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game._start_race()
    await process_frame
    await process_frame
    var hud = game.race_hud_0620
    verify(hud != null and hud.visible,"HUD aberta")
    if hud == null:
        quit(3)
        return
    var before: Array = []
    for car in game.race.player_cars():
        before.append([int(car.get("pit_scheduled_lap",0)),bool(car.get("pit_request",false))])
    hud._open_window("pitwall3")
    await process_frame
    verify(hud.active_window == "pitwall3" and hud.pitwall3_cards.size() == 2, "dois pilotos e painel")
    for ui in hud.pitwall3_cards:
        var id: int = int(ui["id"])
        var car: Dictionary = game._car_by_id(id)
        var mate: Dictionary = {}
        for other in game.race.player_cars():
            if int(other.get("id",-1)) != id:
                mate = other
                break
        var analysis: Dictionary = hud._pitwall3_read(car,mate)
        verify(str(analysis.get("confidence","")) in ["ALTA","MODERADA","BAIXA"],"faixa de confiança real")
        verify(str((ui["notes"] as Label).text).contains("Confiança"),"confiança visível no painel")
        verify(str((ui["notes"] as Label).text).contains(str(analysis.get("confidence",""))),"nível exibido consistente")
        verify(str((ui["notes"] as Label).text).contains(str(analysis.get("confidence_reason",""))),"motivo exibido")
    for k in range(6):
        await process_frame
    var shot: Image = root.get_texture().get_image()
    verify(shot != null and shot.save_png("res://docs/APEX_06494_CONFIANCA_PITWALL_1600.png") == OK,"captura gráfica")
    root.size = Vector2i(1920,1080)
    await process_frame
    game._layout_ui()
    hud.layout_hud()
    hud._refresh_pitwall3_window()
    await process_frame
    verify(hud.overlay_window.size.x > 100 and hud.overlay_window.position.x >= 0,"layout em 1920")
    var after: Array = []
    for car in game.race.player_cars():
        after.append([int(car.get("pit_scheduled_lap",0)),bool(car.get("pit_request",false))])
    verify(before == after,"análise não emite comandos")
    if fails.is_empty():
        print("CONF_UI_06494_PASS real HUD 1600/1920, confidence + reason, no pit changes")
    quit(0 if fails.is_empty() else 1)

extends SceneTree
## Godot 4 native smoke test — director timing, plausible duels, camera cuts,
## and camera Livre regression. This is not a screenshot/UI test.
const Director = preload("res://scripts/tv_director.gd")
const Track3D = preload("res://scripts/track_3d.gd")

class FakeRace:
    extends RefCounted
    var team_name: String = "Red Bull Racing Renault"
    var events: Array = []
    var order: Array = [
        {"id": 4, "team": "Ferrari", "interval": 0.0, "progress": 2.500, "pit_left": 0.0},
        {"id": 9, "team": "Red Bull Racing Renault", "interval": 0.42, "progress": 2.497, "pit_left": 0.0},
        {"id": 10, "team": "Mercedes", "interval": 3.5, "progress": 2.470, "pit_left": 0.0},
    ]
    func get_sorted() -> Array:
        return order

func _initialize() -> void:
    call_deferred("run_smoke")

func _fail(message: String) -> void:
    printerr("APEX 0627: " + message)
    quit(1)

func run_smoke() -> void:
    var fake := FakeRace.new()
    var director := Director.new()
    var selected: int = director.select(fake, 9, 0.0)
    if selected != 9 or director.secondary_focus_id != 4 or director.camera_style != "battle":
        _fail("nao selecionou disputa P1/P2")
        return
    director.screen_clock = 5.0
    director.select(fake, 9, 100.0)
    if director.shot_counter != 1:
        _fail("tomada alterada antes do hold em tempo real")
        return
    director.screen_clock = 10.0
    director.select(fake, 9, 200.0)
    if director.shot_counter != 2 or director.camera_style != "trackside":
        _fail("sem alternancia de angulo depois do hold")
        return
    # Timing-tower gap of 0.2s but different sector: do not invent battle.
    fake.order[1]["progress"] = 2.100
    fake.order[1]["interval"] = 0.20
    director.screen_clock = 30.0
    director.select(fake, 9, 300.0)
    if director.secondary_focus_id >= 0:
        _fail("disputa falsa nao descartada")
        return
    var world := Track3D.new()
    root.add_child(world)
    world.set_broadcast_view(Vector2(540,450), Vector2.RIGHT, Vector2(555,450), "battle", 1.0, 9)
    if world.camera_mode_3d != "battle" or world.camera_3d == null or absf(world.camera_3d.fov - 51.0) > 0.1:
        _fail("camera de disputa nao ativada")
        return
    world.set_broadcast_view(Vector2(800,550), Vector2.RIGHT, Vector2(810,550), "trackside", 1.0, 4)
    if world.camera_mode_3d != "trackside" or world.camera_3d.position.distance_to(world.camera_look_target) < 1.0:
        _fail("camera trackside incorreta")
        return
    world.enter_free_view()
    var before: Vector3 = world.camera_3d.position
    world.pan_by(Vector2(100,-70))
    if world.camera_mode_3d != "overview" or world.camera_3d.position.distance_to(before) < 0.01 or absf(world.camera_3d.fov - 56.0) > 0.1:
        _fail("camera Livre nao preservada")
        return
    print("APEX 0.6.2.7 TV DIRECTOR SMOKE OK")
    quit(0)

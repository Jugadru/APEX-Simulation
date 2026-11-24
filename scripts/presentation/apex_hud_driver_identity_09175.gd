extends Control
## Optional real local portrait; original neutral helmet only when absent.
## Presentation only: no HTTP, sporting state or per-frame texture loading.
const HudSkin = preload("res://scripts/apex_race_hud_skin_ui01.gd")
const PortraitLocal = preload("res://scripts/apex_portrait_local_2012.gd")
var portrait: Texture2D
var driver_id: int = -1
var driver_name: String = ""
var team_name: String = ""
var team_tint: Color = HudSkin.ORANGE
var driver_slot: int = 0
var draw_count: int = 0

func _init() -> void:
	custom_minimum_size = Vector2(34.0, 25.0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE

func configure(car: Dictionary, slot: int) -> void:
	var next_id: int = int(car.get("id",-1))
	var next_name: String = str(car.get("name","Piloto"))
	var next_team: String = str(car.get("team",""))
	var next_tint: Color = Color.from_string(str(car.get("color","#FF8A21")),HudSkin.ORANGE)
	if driver_id==next_id and driver_name==next_name and team_name==next_team and team_tint==next_tint and driver_slot==slot:
		return
	driver_id=next_id
	driver_name=next_name
	team_name=next_team
	team_tint=next_tint
	driver_slot=slot
	portrait = PortraitLocal.get_texture(driver_name)
	custom_minimum_size = Vector2(34, 36) if portrait != null else Vector2(34, 25)
	# Name and team remain available from the existing card labels. Ignore
	# mouse input so this additional drawing cannot swallow command clicks.
	queue_redraw()

func _draw() -> void:
	draw_count+=1
	if portrait != null:
		var available := Vector2(maxf(1.0, size.x - 4.0), maxf(1.0, size.y - 2.0))
		var scale_factor := minf(available.x / portrait.get_width(), available.y / portrait.get_height())
		var photo_size := portrait.get_size() * scale_factor
		draw_rect(Rect2(Vector2.ZERO, size), HudSkin.SURFACE_SOLID)
		draw_texture_rect(portrait, Rect2((size - photo_size) * 0.5, photo_size), false)
		draw_rect(Rect2(Vector2.ZERO, Vector2(2, size.y)), team_tint)
		return
	var origin: Vector2 = (size-Vector2(34,25))*0.5
	# High-contrast background + original stylized helmet outline.
	draw_rect(Rect2(origin,Vector2(34,25)),HudSkin.SURFACE_SOLID,true)
	draw_rect(Rect2(origin,Vector2(34,25)),HudSkin.BORDER_SOFT,false,1.0)
	draw_rect(Rect2(origin+Vector2(1,1),Vector2(3,23)),team_tint,true)
	var helmet: PackedVector2Array=PackedVector2Array([
		Vector2(9,12),Vector2(10,7),Vector2(14,4),Vector2(21,4),
		Vector2(26,8),Vector2(28,13),Vector2(27,18),Vector2(23,21),
		Vector2(13,21),Vector2(9,17)])
	for i in range(helmet.size()): helmet[i]+=origin
	draw_colored_polygon(helmet,Color("#E8ECF2"))
	var visor: PackedVector2Array=PackedVector2Array([Vector2(12,9),Vector2(25,9),Vector2(27,13),Vector2(23,16),Vector2(14,15)])
	for i in range(visor.size()): visor[i]+=origin
	draw_colored_polygon(visor,Color("#283340"))
	draw_line(origin+Vector2(12,7),origin+Vector2(23,7),team_tint,2.0,true)
	# One or two small marks distinguish the team's two slots without
	# inventing historical car numbers or copying helmet liveries.
	for i in range(clampi(driver_slot+1,1,2)):
		draw_rect(Rect2(origin+Vector2(16+i*5,18),Vector2(3,2)),team_tint,true)

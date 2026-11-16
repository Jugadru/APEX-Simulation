extends Control
## Actual forecast visual: tyre-condition curve for each planned stint, not telemetric data.
var plan: Dictionary = {}
var total_laps: int = 52
const ORANGE := Color("#ff7900")
const WHITE := Color("#e9f3f8")
const MUTED := Color("#9caeba")

func set_plan(value: Dictionary, laps: int) -> void:
	plan = value.duplicate(true)
	total_laps = maxi(1,laps)
	queue_redraw()

func _tone(tire: String) -> Color:
	match tire:
		"Supermacio": return Color("#ed5e67")
		"Macio": return Color("#e6be4e")
		"Médio": return Color("#e4e9ec")
		"Duro": return Color("#aab9c2")
		"Intermediário": return Color("#65c999")
		"Chuva": return Color("#71a8ee")
	return ORANGE

func _draw() -> void:
	var rect: Rect2 = Rect2(10,10,maxf(60.0,size.x-20.0),maxf(60.0,size.y-24.0))
	draw_rect(rect,Color("#101821"),true)
	var left: float = rect.position.x+12.0
	var top: float = rect.position.y+15.0
	var width: float = rect.size.x-24.0
	var height: float = rect.size.y-36.0
	for y_value in [0.0,25.0,50.0,75.0,100.0]:
		var y: float = top+height*y_value/100.0
		draw_line(Vector2(left,y),Vector2(left+width,y),Color("#293844"),1.0)
	var font: Font = ThemeDB.fallback_font
	for tick in range(0,5):
		var lap_value: int = int(round(float(tick)*float(total_laps)/4.0))
		var x: float = left+width*float(lap_value)/float(total_laps)
		draw_string(font,Vector2(x-7.0,top+height+14.0),str(lap_value),HORIZONTAL_ALIGNMENT_LEFT,-1,10,MUTED)
	if not bool(plan.get("valid",false)):
		draw_string(font,Vector2(left+6,top+height/2),"PLANO SECO INDISPONÍVEL",HORIZONTAL_ALIGNMENT_LEFT,-1,12,MUTED)
		return
	for s in plan.get("stints",[]):
		var start: int = int(s["from"])-1
		var finish: int = int(s["to"])
		var sx: float = left+width*float(start)/float(total_laps)
		var ex: float = left+width*float(finish)/float(total_laps)
		var c: Color = _tone(str(s["compound"]))
		var wear: float = float(s["wear_end"])
		var yy: float = top+height*wear/100.0
		draw_line(Vector2(sx,top),Vector2(ex,yy),c,2.4,true)
		draw_circle(Vector2(ex,yy),3.2,c)
		if finish < total_laps:
			draw_dashed_line(Vector2(ex,top),Vector2(ex,top+height),ORANGE,1.0,4.0)
			draw_string(font,Vector2(ex+4.0,top+12.0),"V%d" % finish,HORIZONTAL_ALIGNMENT_LEFT,-1,11,ORANGE)
	draw_string(font,Vector2(left+2,top+12),"100%",HORIZONTAL_ALIGNMENT_LEFT,-1,10,MUTED)
	draw_string(font,Vector2(left+2,top+height-4),"0%",HORIZONTAL_ALIGNMENT_LEFT,-1,10,MUTED)

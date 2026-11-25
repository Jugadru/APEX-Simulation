extends RefCounted
## 032: bounded, deterministic wake from frozen on-track positions.
## Distances along track are estimated from normalized progress and lap_km;
## lateral offsets remain schematic RaceSpace units, not measured metres.
const MAX_RANGE_M := 150.0
const BODY := 6.4
const TOW_FRACTION := 0.014
const DIRTY_FRACTION := 0.020

static func clean() -> Dictionary:
	return {"source_id":-1,"gap_m":0.0,"exposure":0.0,"tow_fraction":0.0,"dirty_fraction":0.0,"wet_buffer_fraction":0.0}

static func sample(gap_units: float, gap_m: float, separation: float, load: float, ahead_load: float, wet: float) -> Dictionary:
	var out := clean()
	if gap_units<BODY or gap_m<=0.0 or gap_m>=MAX_RANGE_M: return out
	var longitudinal: float = smoothstep(BODY,BODY+1.0,gap_units)*(1.0-smoothstep(12.0,MAX_RANGE_M,gap_m))
	var tow_alignment: float = 1.0-smoothstep(0.10,1.15,absf(separation))
	var dirty_alignment: float = 1.0-smoothstep(0.20,2.30,absf(separation))
	var straight: float = 1.0-smoothstep(0.05,0.30,maxf(load,ahead_load*0.80))
	var corner: float = smoothstep(0.12,0.70,maxf(load,ahead_load*0.65))
	wet=clampf(wet,0.0,1.0)
	out.exposure=longitudinal*dirty_alignment
	out.tow_fraction=TOW_FRACTION*longitudinal*tow_alignment*straight*(1.0-0.80*wet)
	out.dirty_fraction=DIRTY_FRACTION*longitudinal*dirty_alignment*corner*(1.0-0.55*wet)
	out.wet_buffer_fraction=0.005*wet*longitudinal*tow_alignment*(1.0-smoothstep(15.0,55.0,gap_m))
	out.gap_m=gap_m
	return out

static func choose(car: Dictionary, candidates: Array, length: float, lap_km: float, load: float, ahead_load: float, wet: float, corrected: bool = true) -> Dictionary:
	var best := clean()
	var best_score := 0.0
	if lap_km<=0.0 or length<=0.0 or not is_finite(lap_km): return best
	for other in candidates:
		if other.id==car.id or bool(other.get("finished",false)) or float(other.get("pit_left",0.0))>0.0: continue
		var fraction: float=fposmod(float(other.progress)-float(car.progress),1.0)
		var distance: float=fraction*lap_km*1000.0
		if distance<=0.0 or distance>=MAX_RANGE_M: continue
		var separation: float=absf(float(car.get("race_lane",0.0))-float(other.get("race_lane",0.0)))
		if separation>=2.30: continue
		var effect: Dictionary=sample(fraction*length,distance,separation,load,ahead_load,wet)
		# 032 retains the original exposure ranking for archived replays.
		# 033 ranks actual effects, not broad dirty-air exposure on a straight.
		# A single source still supplies all modifiers; no stacking across cars.
		var score: float = float(effect.exposure)
		if corrected:
			score = maxf(float(effect.tow_fraction), float(effect.dirty_fraction)+float(effect.wet_buffer_fraction))
		if score>best_score or (score>0.0 and score==best_score and int(other.id)<int(best.source_id)):
			effect.source_id=int(other.id)
			best=effect
			best_score=score
	return best

static func apply(pace: float, effect: Dictionary) -> float:
	return pace*(1.0-float(effect.tow_fraction)+float(effect.dirty_fraction)+float(effect.wet_buffer_fraction))

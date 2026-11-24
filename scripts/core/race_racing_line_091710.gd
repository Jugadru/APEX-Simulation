extends RefCounted
## Schematic curvature profile; no RNG, no visual dependency, no new save fields.
const Space = preload("res://scripts/core/race_space_0655.gd")
const SAMPLES := 256
const START_SECONDS := 24.0

static func build(track: Dictionary) -> Dictionary:
	var route: Array[Vector2] = Space.route_points(track)
	if route.is_empty(): return {}
	var distances: Array[float]=[]
	var length:=0.0
	for i in range(route.size()):
		distances.append(length)
		length+=route[i].distance_to(route[(i+1)%route.size()])
	if length<100.0: return {}
	var points: Array[Vector2]=[]
	for i in range(SAMPLES):
		var distance:float=length*float(i)/SAMPLES
		var index:int=clampi(distances.bsearch(distance,true)-1,0,route.size()-1)
		var next:int=(index+1)%route.size()
		points.append(route[index].lerp(route[next],(distance-distances[index])/maxf(0.00001,route[index].distance_to(route[next]))))
	var angles: Array[float]=[]
	for i in range(SAMPLES):
		var before:Vector2=points[i]-points[posmod(i-6,SAMPLES)]
		var after:Vector2=points[posmod(i+6,SAMPLES)]-points[i]
		angles.append(before.angle_to(after))
	# Suppress the polygon subdivision's repeated micro-apices. Signed
	# smoothing retains turn direction rather than summing both sides.
	var smooth: Array[float]=[]
	for i in range(SAMPLES):
		var total:=0.0
		for offset in range(-3,4): total+=angles[posmod(i+offset,SAMPLES)]
		smooth.append(total/7.0)
	angles=smooth
	var candidates:Array=[]
	for i in range(SAMPLES):
		var strength:float=absf(angles[i])
		if strength>=0.18 and strength>=absf(angles[posmod(i-1,SAMPLES)]) and strength>absf(angles[posmod(i+1,SAMPLES)]):
			candidates.append({"index":i,"angle":angles[i],"strength":strength})
	candidates.sort_custom(func(a,b):return a.strength>b.strength if a.strength!=b.strength else a.index<b.index)
	var corners:Array=[]
	for c in candidates:
		var separated:=true
		for other in corners:
			if absf(fposmod(float(c.index-other.index)+SAMPLES*0.5,SAMPLES)-SAMPLES*0.5)<7.0:
				separated=false
				break
		if separated:
			var severity:float=clampf((float(c.strength)-0.12)/1.05,0.08,1.0)
			corners.append({"index":int(c.index),"apex":float(c.index)/SAMPLES,"brake":fposmod((float(c.index)-4.0-severity*4.0)/SAMPLES,1.0),"exit":fposmod((float(c.index)+4.0+severity*3.0)/SAMPLES,1.0),"direction":signf(float(c.angle)),"severity":severity,"brake_bins":4.0+severity*4.0,"exit_bins":4.0+severity*3.0})
	corners.sort_custom(func(a,b):return a.index<b.index)
	var lanes:=PackedFloat64Array()
	var loads:=PackedFloat64Array()
	var mean:=0.0
	for i in range(SAMPLES):
		var best:=0.0
		var lane:=0.0
		for c in corners:
			var delta:float=fposmod(float(i-c.index)+SAMPLES*0.5,SAMPLES)-SAMPLES*0.5
			var span:float=float(c.brake_bins) if delta<0.0 else float(c.exit_bins)
			var u:float=absf(delta)/span
			if u>=1.0: continue
			var weight:float=float(c.severity)*(1.0-u)
			if weight<=best: continue
			best=weight
			# Positive lane follows the left normal of the route in X/Z.
			# Outside -> apex -> outside, smoothly returning to zero.
			lane=float(c.direction)*sin(PI*2.0*(0.25+0.5*u))*(1.0-u)*float(c.severity)
		lanes.append(lane)
		loads.append(best)
		mean+=best
	return {"corners":corners,"lanes":lanes,"loads":loads,"mean":mean/SAMPLES}

static func sample(profile: Dictionary, progress: float, wetness: float, skill: float) -> Dictionary:
	if profile.is_empty(): return {"lane_ratio":0.0,"pace_factor":1.0,"load":0.0}
	var x:float=fposmod(progress,1.0)*SAMPLES
	var index:int=int(floor(x))%SAMPLES
	var next:int=(index+1)%SAMPLES
	var t:float=x-floor(x)
	var load:float=lerpf(profile.loads[index],profile.loads[next],t)
	var lane:float=lerpf(profile.lanes[index],profile.lanes[next],t)
	var wet:float=clampf(wetness,0.0,1.0)
	# Mean-centered local time redistribution, not a calibrated speed model.
	# Wet conditions favor earlier conservative positioning and more braking cost.
	var factor:float=1.0+0.10*(load-float(profile.mean))+0.025*wet*load
	return {"lane_ratio":lane*lerpf(0.42,0.62,clampf(skill/100.0,0.0,1.0))*(1.0-0.60*wet),"pace_factor":factor,"load":load}

extends RefCounted
## Exact global nearest-segment query. Blocks only reject provably farther segments.
## A previous segment is an upper-bound hint, never a restriction on the search.
const BLOCK_SIZE := 16
var points: Array[Vector3] = []
var vectors: Array[Vector3] = []
var lengths := PackedFloat64Array()
var squared := PackedFloat64Array()
var lows: Array[Vector3] = []
var highs: Array[Vector3] = []
var last_candidates := 0
var total_length := 0.0

func build(source: Array[Vector3]) -> void:
	points = source.duplicate()
	vectors.clear()
	lengths.clear()
	squared.clear()
	lows.clear()
	highs.clear()
	total_length = 0.0
	last_candidates = 0
	for i in range(points.size()):
		var vector := points[(i+1)%points.size()]-points[i]
		vectors.append(vector)
		lengths.append(vector.length())
		squared.append(maxf(.000001,vector.length_squared()))
		total_length += lengths[i]
	for start in range(0,points.size(),BLOCK_SIZE):
		var low := points[start]
		var high := low
		for i in range(start,mini(start+BLOCK_SIZE,points.size())):
			low = low.min(points[i]).min(points[(i+1)%points.size()])
			high = high.max(points[i]).max(points[(i+1)%points.size()])
		# Conservative padding accounts for Vector3 float arithmetic at the boundaries.
		lows.append(low-Vector3.ONE*.001)
		highs.append(high+Vector3.ONE*.001)

func project(origin: Vector3, hint: int = -1) -> Dictionary:
	last_candidates = 0
	if points.is_empty(): return {}
	var best := INF
	var nearest := 0
	var along := 0.0
	if hint >= 0 and hint < points.size():
		var t := clampf((origin-points[hint]).dot(vectors[hint])/squared[hint],0,1)
		best = origin.distance_squared_to(points[hint]+vectors[hint]*t)
		nearest = hint
		along = t*lengths[hint]
	for block in range(lows.size()):
		var closest := origin.clamp(lows[block],highs[block])
		if origin.distance_squared_to(closest)>best: continue
		for i in range(block*BLOCK_SIZE,mini((block+1)*BLOCK_SIZE,points.size())):
			last_candidates += 1
			var t := clampf((origin-points[i]).dot(vectors[i])/squared[i],0,1)
			var separation := origin.distance_squared_to(points[i]+vectors[i]*t)
			# Match legacy ascending traversal even when a hint supplies an equal minimum.
			if separation<best or (separation==best and i<nearest):
				best = separation
				nearest = i
				along = t*lengths[i]
	return {"nearest":nearest,"along":along}

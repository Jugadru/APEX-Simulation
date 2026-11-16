extends RefCounted
## Bounded, revision-local cache. Preserve legacy Float32 arc lengths and central difference.
const CACHE_LIMIT := 256
var points := PackedVector2Array()
var distances := PackedFloat32Array()
var length := 1.0
var revision := 0
var point_cache: Dictionary = {}
var direction_cache: Dictionary = {}

func build(route: PackedVector2Array, cumulative: PackedFloat32Array, total: float) -> void:
	points = route.duplicate()
	distances = cumulative.duplicate()
	length = total
	revision += 1
	point_cache.clear()
	direction_cache.clear()

func point(progress: float) -> Vector2:
	if points.size()<2: return Vector2.ZERO
	if point_cache.has(progress): return point_cache[progress]
	var distance := fposmod(progress,1.0)*length
	var lo := 0
	var hi := distances.size()-1
	# Keep double comparison against legacy Float32 distances; native bsearch converts
	# its query to Float32 and can select a different side of a very short segment.
	while hi-lo>1:
		var mid: int = (hi+lo)/2
		if distances[mid]<distance: lo=mid
		else: hi=mid
	var result := points[lo].lerp(points[hi],(distance-distances[lo])/maxf(.00001,distances[hi]-distances[lo]))
	if point_cache.size()>=CACHE_LIMIT: point_cache.clear()
	point_cache[progress] = result
	return result

func direction(progress: float) -> Vector2:
	if direction_cache.has(progress): return direction_cache[progress]
	var v := point(progress+.0015)-point(progress-.0015)
	var result := Vector2.RIGHT if v.length_squared()<.000001 else v.normalized()
	if direction_cache.size()>=CACHE_LIMIT: direction_cache.clear()
	direction_cache[progress] = result
	return result

func sample(progress: float) -> Dictionary:
	return {"point":point(progress),"direction":direction(progress),"revision":revision}

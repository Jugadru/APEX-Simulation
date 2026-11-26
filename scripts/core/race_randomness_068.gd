extends RefCounted
## 0.6.8: deterministic randomness contracts, no runtime state or global RNG.
## Historical draws remain byte-compatible. New domains are opt-in for future
## sporting revisions; never substitute them into an old replay.
const DRIVER_TRIGGER := 1
const DRIVER_KIND := 2
const DRIVER_SEVERITY := 3
# Registry for the NEW event sampler only. Never reuse a domain/channel pair
# for a different decision once a sporting revision has been published.
const DOMAIN_DRIVER_ERROR := 1
const DOMAIN_MECHANICAL := 2
const DOMAIN_SPORTING := 3

static func legacy_driver_sample(seed:int,id:int,tick:int,channel:int)->float:
	var x:int=posmod(seed,4294967296)
	x=(x ^ ((id*73856093)&0xffffffff) ^ ((tick*19349663)&0xffffffff) ^ ((channel*83492791)&0xffffffff))&0xffffffff
	# Two integer avalanche rounds: adjacent ticks/channels do not form
	# an affine sequence. Multiplication remains below signed 64-bit range.
	x=((x^(x>>16))*0x45d9f3b)&0xffffffff
	x=((x^(x>>16))*0x45d9f3b)&0xffffffff
	x=(x^(x>>16))&0xffffffff
	return float(x)/4294967296.0

static func legacy_weather_seed(initial_seed: int, code: String) -> int:
	# Fixed cross-platform mixing; independent of RNG used by cars and incidents.
	var value: int = posmod(initial_seed, 2147483647) + 1
	for i in range(code.length()):
		value = posmod(value * 131 + code.unicode_at(i) + 37, 2147483647)
	return maxi(1, value)

# New, stateless event key: five signed 64-bit little-endian words, SHA-256,
# first unsigned 32-bit word / 2^32. Full seed bits are retained. No claim
# of collision-free outputs or calibrated event probabilities. Do not call
# per car/tick speculatively; only at an eligible future decision.
static func event_sample(race_seed: int, actor_id: int, tick: int, domain: int, channel: int) -> float:
	var key := PackedByteArray()
	key.resize(40)
	key.encode_s64(0, race_seed)
	key.encode_s64(8, actor_id)
	key.encode_s64(16, tick)
	key.encode_s64(24, domain)
	key.encode_s64(32, channel)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(key)
	var result: PackedByteArray = context.finish()
	return float(result.decode_u32(0)) / 4294967296.0

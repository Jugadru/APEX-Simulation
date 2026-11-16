extends SceneTree
# 0666 contract: old archive schema, disposable cache, corruption detection,
# Racecraft observer and full sporting hashes across repeated navigation.
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var path: String = "res://qa/long_race_0663/replay_0662_650.apexreplay"
	var player = Replay.new()
	assert(player.load_file(path), player.error)
	assert(player.end_tick == 650)
	var historical: String = player.hashes[-1]
	var serialized: String = Codec.digest(player.export_data())
	for target in [175, 192, 185, 201, 175, 192, 195, 300, 299, 300, 650, 1, 175]:
		assert(player.seek(target), player.error)
		assert(Codec.sporting_hash(player.race, player.policy) == player.hashes[target-1])
		assert(player.racecraft_report().end_tick == target)
		assert(player.hot_seek_checkpoints.size() <= 4)
		var compressed_size: int = 0
		for cp in player.hot_seek_checkpoints:
			assert(cp.has("audit") and cp.has("packed_state"))
			compressed_size += cp.packed_state.size()
		assert(compressed_size <= player.MAX_HOT_SEEK_BYTES)
	assert(Codec.digest(player.export_data()) == serialized, "Hot anchors leaked into the public archive")
	# A manually corrupted in-memory race cannot be reused as a trusted anchor.
	assert(player.seek(175), player.error)
	player.race.cars[0].wear += 1.25
	assert(not player.seek(176))
	assert(player.first_divergence == 175)
	assert(player.seek(176), player.error)
	assert(Codec.sporting_hash(player.race, player.policy) == player.hashes[175])
	# Reload while paused at tick zero: a stale in-memory engine cannot be
	# accepted as the new source's starting position.
	assert(player.seek(0), player.error)
	player.race.cars[0].wear += 2.0
	assert(player.load_file(path), player.error)
	assert(player.hot_seek_checkpoints.is_empty(), "Cache must be cleared when loading a different source")
	assert(player.seek(1), player.error)
	assert(player.seek(650), player.error)
	assert(player.hashes[-1] == historical)
	print("REPLAY_FAST_SEEK_0666_CONTRACT_PASS legacy, corruption, caches, 13 seeks, Racecraft, archive")
	quit()

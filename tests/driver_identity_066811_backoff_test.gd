extends SceneTree
## Deterministic HTTP retry policy for Wikimedia Commons; no network or race state.
const Manager = preload("res://scripts/apex_portrait_manager.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("DRIVER_IDENTITY_066811_RETRY_FAIL: " + message)

func run() -> void:
	var manager = Manager.new()
	root.add_child(manager)
	await process_frame
	check(manager.download_state == "idle", "Downloads require explicit user action")
	check(manager._is_retryable_http_status(429), "429 retries")
	check(manager._is_retryable_http_status(503), "503 retries")
	check(not manager._is_retryable_http_status(404), "404 is permanent")
	check(not manager._is_retryable_http_status(403), "403 does not retry indefinitely")
	check(is_equal_approx(manager._retry_delay_seconds(1), 2.0), "First delay = 2s")
	check(is_equal_approx(manager._retry_delay_seconds(2), 4.0), "Second delay = 4s")
	check(is_equal_approx(manager._retry_delay_seconds(3), 8.0), "Third delay = 8s")
	check(is_equal_approx(manager._retry_delay_seconds(4), 16.0), "Fourth delay = 16s")
	check(is_equal_approx(manager._retry_delay_seconds(2, PackedStringArray(["Retry-After: 17"])), 17.0), "HTTP Retry-After respected")
	check(is_equal_approx(manager._retry_delay_seconds(1, PackedStringArray(["retry-after: 120"])), 30.0), "Retry delay upper bound")
	check(is_equal_approx(manager._retry_delay_seconds(1, PackedStringArray(["Retry-After: tomorrow"])), 2.0), "Invalid server header falls back")
	check(manager.BETWEEN_PORTRAITS_SECONDS >= 1.0, "Polite interval between downloads")
	check(manager.MAX_TRANSIENT_RETRIES <= 4, "Retry count bounded")
	if failures == 0:
		print("DRIVER_IDENTITY_066811_RETRY_PASS checks=%d bounded=true no_network=true" % checks)
	quit(0 if failures == 0 else 1)

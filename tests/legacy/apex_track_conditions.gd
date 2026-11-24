extends RefCounted
## Deterministic, UI-only environmental model (not historical telemetry).
## Explicitly NOT connected to tyre grip, AI, lap times or rain physics yet.

var base_temperature: float = 21.0
var sky_base: float = 0.18
var seed: int = 42
var track_code: String = "BEL"

func setup(track: Dictionary, race_seed: int) -> void:
	seed = race_seed
	track_code = str(track.get("code", "BEL"))
	var climate: Dictionary = {
		"BEL": [19.0, 0.52], "GBR": [18.0, 0.42], "MAL": [31.0, 0.67],
		"SIN": [29.0, 0.43], "UAE": [32.0, 0.04], "BHR": [31.0, 0.08],
		"BRA": [25.0, 0.40], "CAN": [22.0, 0.35], "USA": [24.0, 0.14],
		"JPN": [25.0, 0.36], "ITA": [27.0, 0.16], "ESP": [26.0, 0.17],
		"MON": [24.0, 0.12], "CHN": [22.0, 0.32], "GER": [21.0, 0.31],
		"HUN": [28.0, 0.22], "KOR": [24.0, 0.28], "IND": [30.0, 0.09],
		"EUR": [29.0, 0.08], "AUS": [22.0, 0.25]
	}
	var config: Array = climate.get(track_code, [24.0, 0.22])
	base_temperature = float(config[0]) + float(posmod(seed, 7) - 3) * 0.3
	sky_base = float(config[1])

func snapshot(seconds: float, completed_fraction: float) -> Dictionary:
	var t: float = seconds / 720.0
	var seeded_offset: float = sin(float(seed % 257) * 1.91 + t * 0.84)
	var cloud: float = clampf(sky_base + 0.18 * seeded_offset, 0.0, 0.98)
	var air: float = base_temperature + 1.7 * sin(t * 0.72 + 0.4)
	var track: float = air + 6.0 + (1.0 - cloud) * 7.5
	var damp: float = maxf(0.0, (cloud - 0.62) * 1.65)
	var rubber: float = clampf(0.08 + completed_fraction * 0.72, 0.0, 0.95)
	var grip: float = clampf(0.46 + rubber * 0.45 - damp * 0.3, 0.0, 1.0)
	var wind: float = 6.0 + 4.5 * absf(sin(t * 0.8 + 0.7))
	var sky_label: String = "Céu limpo" if cloud < 0.35 else ("Nublado" if cloud < 0.68 else "Chuva possível")
	return {
		"sky": sky_label, "air_c": air, "track_c": track,
		"rain_probability": int(round(cloud * 100.0)),
		"wetness": int(round(damp * 100.0)),
		"rubber": int(round(rubber * 100.0)),
		"grip": "Alto" if grip > 0.75 else ("Normal" if grip > 0.56 else "Baixo"),
		"wind": wind
	}

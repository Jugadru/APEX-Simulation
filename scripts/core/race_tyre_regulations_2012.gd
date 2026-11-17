extends RefCounted
## APEX 0.6.2.5: 2012 two-nominated-slick rule for dry races.
## Once a race was declared wet, or wet tyres were used, the dry obligation is waived.
static func compliant(used: Array, nominated: Array, race_wet_declared: bool) -> bool:
	if race_wet_declared or used.has("Intermediário") or used.has("Chuva"):
		return true
	for tyre in nominated:
		if not used.has(tyre):
			return false
	return true

class_name PathGenerator
extends RefCounted

# Explicit, versioned integer generator: independent of Godot RNG changes.
const VERSION: int = 1
const MODULUS: int = 2147483647

static func generate(path_seed: int, lanes: int, rows: int, version: int = VERSION) -> Array[int]:
	assert(version == VERSION, "Unsupported path generator version")
	assert(lanes > 0 and rows > 0)
	var state: int = posmod(path_seed, MODULUS - 1) + 1
	var path: Array[int] = []
	for _row in rows:
		state = (state * 48271) % MODULUS
		path.append(state % lanes)
	return path

static func lane_at(path_seed: int, lanes: int, row: int, version: int = VERSION) -> int:
	assert(version == VERSION and lanes > 0 and row >= 0)
	# Modular exponentiation gives random access in O(log row), with constant memory.
	var exponent: int = row + 1
	var factor: int = 48271
	var multiplier: int = 1
	while exponent > 0:
		if exponent & 1:
			multiplier = (multiplier * factor) % MODULUS
		factor = (factor * factor) % MODULUS
		exponent >>= 1
	return (((posmod(path_seed, MODULUS - 1) + 1) * multiplier) % MODULUS) % lanes

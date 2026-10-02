class_name DifficultyConfig
extends Resource

@export_range(3, 5) var lane_count: int = 3
@export_range(1, 30) var row_count: int = 10
@export_range(1.0, 15.0) var preview_seconds: float = 5.0
@export_range(0.15, 1.0) var jump_seconds: float = 0.38
@export var jump_height: float = 1.45
@export var row_spacing: float = 2.35
@export var lane_spacing: float = 2.25
@export var tile_size: Vector3 = Vector3(2.04, 0.38, 1.90)
@export var crack_seconds: float = 0.26
@export var fall_seconds: float = 0.7

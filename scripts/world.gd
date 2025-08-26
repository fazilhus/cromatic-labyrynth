class_name World
extends Node3D

@onready var spawn_point: SpawPoint = %SpawPoint

func spawn_position() -> Vector3:
	if spawn_point == null:
		return Vector3.ZERO
	return spawn_point.global_position
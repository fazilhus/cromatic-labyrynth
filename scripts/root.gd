class_name Root
extends Node3D

@export var player_pkd: PackedScene

@onready var world: World = %World

func _ready() -> void:
	var player_inst: Player = player_pkd.instantiate()
	self.add_child(player_inst)
	player_inst.global_position = world.spawn_position()
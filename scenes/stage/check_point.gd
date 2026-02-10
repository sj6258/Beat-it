class_name Checkpoint
extends Node2D

@onready var enemies : Node2D = $Enemies
@onready var player_detection_area : Area2D = $PlayerDetectionArea

var enemy_data : Array[EnemyData] =[]
var is_activated := false

func _ready() -> void:
	player_detection_area.body_entered.connect(on_player_enter.bind())
	for enemy : Character in enemies.get_children():
		enemy_data.append(EnemyData.new(enemy.type, enemy.global_position))
		enemy.queue_free()

func on_player_enter(player: Player) -> void:
	if not is_activated:
		is_activated = true

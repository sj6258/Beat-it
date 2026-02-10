extends Node

signal spawn_collectible(type: Collectible.Type, initial_state: Collectible.State, collectible_global_position: Vector2, collectible_direction: Vector2, collectible_height: float, autodestroy: bool)
signal spawn_shot(gun_root_position: Vector2, distance_traveled: float, height: float)
signal spawn_enemy(enemy_data : EnemyData)

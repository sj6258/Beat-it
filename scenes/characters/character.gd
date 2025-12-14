extends CharacterBody2D

@export var health : int
@export var damage : int
@export var speed : float

func _process(_delta: float) -> void:
		
	var direction := Input.get_vector("LEFT" , "RIGHT" , "UP" , "DOWN")
	velocity = direction * speed
	move_and_slide()

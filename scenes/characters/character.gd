extends CharacterBody2D

@export var health : int
@export var damage : int
@export var speed : float
@export var jump_intensity : float

@onready var character_sprite:= $characterSprite
@onready var damage_emitter := $DamageEmitter
@onready var animation_player:= $AnimationPlayer

const GRAVITY := 600.0

enum State {IDLE, WALK, ATTACK, TAKEOFF, JUMP, LANDING}

var anim_map := {
	State.IDLE : "idle",
	State.WALK : "walk",
	State.ATTACK : "punch",
	State.TAKEOFF : "takeoff",
	State.JUMP : "jump",
	State.LANDING : "landing",
	}

var height := 0.0
var height_speed := 0.0
var state = State.IDLE

func _ready() -> void:
	damage_emitter.area_entered.connect(_on_emit_damage.bind())

func _process(_delta: float) -> void:
	handle_animation()
	handle_input()
	handle_movement()
	handle_air_time(_delta)
	flip_sprites()
	character_sprite.position = Vector2.UP * height
	move_and_slide()
	
func handle_movement():
	if can_move():
		if velocity.length() == 0:
			state = State.IDLE
		else:
			state = State.WALK
	else:
		velocity = Vector2.ZERO
		
		
		
	
func handle_input(): 
	var direction := Input.get_vector("LEFT" , "RIGHT" , "UP" , "DOWN")
	velocity = direction * speed
	if can_attack() and Input.is_action_just_pressed("punch"):
		state = State.ATTACK
	if can_jump() and Input.is_action_just_pressed("jump"):
		state = State.TAKEOFF


func handle_animation():
	if animation_player.has_animation(anim_map[state]):
		animation_player.play(anim_map[state])
		
func handle_air_time(delta: float) -> void:
	if state == State.JUMP:
		height += height_speed * delta
		if height < 0:
			height = 0
			state = State.LANDING
		else:
			height_speed -= GRAVITY * delta
	
	

func flip_sprites():
	if velocity.x > 0:
		character_sprite.flip_h = false
		damage_emitter.scale.x = 1
	elif velocity.x < 0:
		character_sprite.flip_h = true
		damage_emitter.scale.x = -1


func can_move() -> bool:
	return state == State.IDLE or state == State.WALK
		
		
func can_attack() -> bool:
	return state == State.IDLE or state == State.WALK
	
func can_jump() -> bool:
	return state == State.IDLE or state == State.WALK

func on_action_complete():
	state = State.IDLE
	
func on_takeoff_complete() -> void:
	state = State.JUMP
	height_speed = jump_intensity
 
func on_landing_complete() -> void:
	state = State.IDLE


func _on_emit_damage(damage_reciever: DamageReciever) -> void:
	var direction:= Vector2.LEFT if damage_reciever.global_position.x < global_position.x else Vector2.RIGHT
	damage_reciever.damage_recieved.emit(damage, direction)
	print(damage_reciever)

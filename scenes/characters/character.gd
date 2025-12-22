class_name Character
extends CharacterBody2D


@export var max_health : int
@export var damage : int
@export var speed : float
@export var jump_intensity : float
@export var knockback_intensity : float

@onready var character_sprite:= $characterSprite
@onready var damage_emitter := $DamageEmitter
@onready var animation_player:= $AnimationPlayer
@onready var damage_reciever : DamageReciever = $DamageReciever

const GRAVITY := 600.0

enum State {IDLE, WALK, ATTACK, TAKEOFF, JUMP, LANDING, JUMPKICK, HURT}

var anim_map := {
	State.IDLE : "idle",
	State.WALK : "walk",
	State.ATTACK : "punch",
	State.TAKEOFF : "takeoff",
	State.JUMP : "jump",
	State.LANDING : "landing",
	State.JUMPKICK : "jumpkick",
	State.HURT : "hurt",
	}
var current_health := 0
var height := 0.0
var height_speed := 0.0
var state = State.IDLE

func _ready() -> void:
	damage_emitter.area_entered.connect(_on_emit_damage.bind())
	damage_reciever.damage_recieved.connect(on_recieve_damage.bind())
	current_health = max_health

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

		
		
		
	
func handle_input() -> void:
	pass


func handle_animation():
	if animation_player.has_animation(anim_map[state]):
		animation_player.play(anim_map[state])
		
func handle_air_time(delta: float) -> void:
	if state == State.JUMP or state == State.JUMPKICK:
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
	
func can_jumpkick() -> bool:
	return state == State.JUMP

func on_action_complete():
	state = State.IDLE
	
func on_takeoff_complete() -> void:
	state = State.JUMP
	height_speed = jump_intensity
 
func on_landing_complete() -> void:
	state = State.IDLE
	
func on_recieve_damage(damage, direction: Vector2) -> void:
	current_health = current_health - clamp(damage, 0, max_health)
	if current_health <= 0:
		queue_free()
	else:
		state = State.HURT
		velocity = direction * knockback_intensity


func _on_emit_damage(damage_reciever: DamageReciever) -> void:
	var direction:= Vector2.LEFT if damage_reciever.global_position.x < global_position.x else Vector2.RIGHT
	damage_reciever.damage_recieved.emit(damage, direction)
	print(damage_reciever)

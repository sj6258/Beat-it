class_name Character
extends CharacterBody2D

@export var can_respawn : bool
@export var max_health : int
@export var damage : int
@export var damage_power : int
@export var speed : float
@export var flight_speed :  float
@export var jump_intensity : float
@export var knockback_intensity : float
@export var knockdown_intensity : float
@export var duration_grounded: float

@onready var character_sprite:= $characterSprite
@onready var collateral_damage_emitter : Area2D = $CollateralDamageEmitter
@onready var collision_shape := $CollisionShape2D
@onready var damage_emitter := $DamageEmitter
@onready var animation_player:= $AnimationPlayer
@onready var damage_reciever : DamageReciever = $DamageReciever

const GRAVITY := 600.0

enum State {IDLE, WALK, ATTACK, TAKEOFF, JUMP, LANDING, JUMPKICK, HURT, FALL, GROUNDED, DEATH, FLY, PREP_ATTACK}


var anim_attacks :=[]
var anim_map : Dictionary = {
	State.IDLE : "idle",
	State.WALK : "walk",
	State.TAKEOFF : "takeoff",
	State.JUMP : "jump",
	State.LANDING : "landing",
	State.JUMPKICK : "jumpkick",
	State.HURT : "hurt",
	State.FALL : "fall",
	State.GROUNDED : "grounded",
	State.DEATH : "gorunded",
	State.FLY : "fly",
	State.PREP_ATTACK : "idle",
	}
	
var attack_combo_index := 0
var current_health := 0
var heading := Vector2.RIGHT
var height := 0.0
var height_speed := 0.0
var is_last_hit_successful := false
var state = State.IDLE
var time_since_grounded := Time.get_ticks_msec()

func _ready() -> void:
	damage_emitter.area_entered.connect(_on_emit_damage.bind())
	damage_reciever.damage_recieved.connect(on_recieve_damage.bind())
	collateral_damage_emitter.area_entered.connect(on_emit_collateral_damage.bind())
	collateral_damage_emitter.body_entered.connect(on_wall_hit.bind())
	current_health = max_health

func _process(_delta: float) -> void:
	handle_animation()
	handle_input()
	handle_movement()
	handle_air_time(_delta)
	handle_prep_attack()
	handle_grounded()
	handle_death(_delta)
	set_heading()
	flip_sprites()
	character_sprite.position = Vector2.UP * height
	collision_shape.disabled = is_collision_disabled()
	move_and_slide()
	
func handle_movement():
	if can_move():
		if velocity.length() == 0:
			state = State.IDLE
		else:
			state = State.WALK

	
func handle_input() -> void:
	pass

func handle_prep_attack() -> void:
	pass

func handle_grounded() -> void:
	if state == State.GROUNDED and (Time.get_ticks_msec() - time_since_grounded > duration_grounded):
		if current_health == 0:
			state = State.DEATH
		else:
			state = State.LANDING

func handle_death(delta: float) -> void:
	if state == State.DEATH and not can_respawn:
		modulate.a -= delta / 2.0
		if modulate.a <= 0:
			queue_free()

func handle_animation():
	if state == State.ATTACK:
		animation_player.play(anim_attacks[attack_combo_index])
	elif animation_player.has_animation(anim_map[state]):
		animation_player.play(anim_map[state])
		
func handle_air_time(delta: float) -> void:
	if [State.JUMP, State.JUMPKICK, State.FALL].has(state):
		height += height_speed * delta
		if height < 0:
			height = 0
			if state == State.FALL:
				state = State.GROUNDED
				time_since_grounded = Time.get_ticks_msec()

			else:
				state = State.LANDING
			velocity = Vector2.ZERO
			
		else:
			height_speed -= GRAVITY * delta
	
	
func set_heading() -> void:
	pass

func flip_sprites():
	if heading == Vector2.RIGHT:
		character_sprite.flip_h = false
		damage_emitter.scale.x = 1
	else:
		character_sprite.flip_h = true
		damage_emitter.scale.x = -1


func can_move() -> bool:
	return state == State.IDLE or state == State.WALK
		
		
func can_attack() -> bool:
	return state == State.IDLE or state == State.WALK
	
func can_jump() -> bool:
	return state == State.IDLE or state == State.WALK

func can_get_hurt() -> bool:
	return [State.IDLE, State.WALK, State.TAKEOFF, State.JUMP, State.LANDING].has(state)
	
func is_collision_disabled() -> bool:
	return [State.GROUNDED, State.DEATH, State.FLY].has(state)

func can_jumpkick() -> bool:
	return state == State.JUMP

func on_action_complete():
	state = State.IDLE
	
func on_takeoff_complete() -> void:
	state = State.JUMP
	height_speed = jump_intensity
 
func on_landing_complete() -> void:
	state = State.IDLE
	
func on_recieve_damage(amount: int, direction: Vector2, hit_type: DamageReciever.HitType) -> void:
	if can_get_hurt():
		print(str(amount))
		current_health = current_health - clamp(amount, 0, max_health)
		if current_health == 0 or hit_type == DamageReciever.HitType.KNOCKDOWN:
			state = State.FALL
			height_speed = knockdown_intensity
			velocity = direction * knockback_intensity
		elif hit_type ==  DamageReciever.HitType.POWER:
			state = State.FLY
			velocity =  direction * flight_speed
		else:
			state = State.HURT
			velocity = direction * knockback_intensity


func _on_emit_damage(reciever: DamageReciever) -> void:
	var hit_type := DamageReciever.HitType.NORMAL
	var direction:= Vector2.LEFT if reciever.global_position.x < global_position.x else Vector2.RIGHT
	var current_damage = damage
	if state == State.JUMPKICK:
		hit_type = DamageReciever.HitType.KNOCKDOWN
	if attack_combo_index == anim_attacks.size() - 1:
		hit_type = DamageReciever.HitType.POWER
		current_damage = damage_power
	reciever.damage_recieved.emit(current_damage, direction, hit_type)
	is_last_hit_successful = true

func on_emit_collateral_damage(reciever: DamageReciever) -> void:
	if reciever != damage_reciever:
		var direction := Vector2.LEFT if reciever.global_position.x < global_position.x else Vector2.RIGHT
		reciever.damage_recieved.emit(0, direction, DamageReciever.HitType.KNOCKDOWN)

func on_wall_hit(_wallL: AnimatableBody2D) -> void:
	state = State.FALL
	height_speed = knockdown_intensity
	velocity = -velocity / 2.0

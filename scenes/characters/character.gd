class_name Character
extends CharacterBody2D

@export var can_respawn : bool
@export var can_respawn_knifes : bool
@export var max_health : int
@export var damage : int
@export var damage_power : int
@export var duration_grounded: float
@export var duration_between_knife_respawn : int
@export var speed : float
@export var flight_speed :  float
@export var has_knife : bool
@export var jump_intensity : float
@export var knockback_intensity : float
@export var knockdown_intensity : float


@onready var character_sprite:= $characterSprite
@onready var collateral_damage_emitter : Area2D = $CollateralDamageEmitter
@onready var collectible_sensor : Area2D = $CollectibleSensor
@onready var collision_shape := $CollisionShape2D
@onready var damage_emitter := $DamageEmitter
@onready var animation_player:= $AnimationPlayer
@onready var damage_reciever : DamageReciever = $DamageReciever
@onready var knife_sprite : Sprite2D = $KnifeSprite
@onready var projectile_aim : RayCast2D = $ProjectileAim
@onready var weapon_position : Node2D = $KnifeSprite/WeaponPosition


const GRAVITY := 600.0

enum State {IDLE, WALK, ATTACK, TAKEOFF, JUMP, LANDING, JUMPKICK, HURT, FALL, GROUNDED, DEATH, FLY, PREP_ATTACK, THROW, PICKUP}


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
	State.THROW : "throw",
	State.PICKUP : "pickup",
	}
	
var attack_combo_index := 0
var current_health := 0
var heading := Vector2.RIGHT
var height := 0.0
var height_speed := 0.0
var is_last_hit_successful := false
var state = State.IDLE
var time_since_grounded := Time.get_ticks_msec()
var time_since_knife_dismiss := Time.get_ticks_msec()

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
	handle_knife_respawns()
	handle_death(_delta)
	set_heading()
	flip_sprites()
	knife_sprite.visible = has_knife
	character_sprite.position = Vector2.UP * height
	knife_sprite.position = Vector2.UP * height
	collision_shape.disabled = is_collision_disabled()
	damage_emitter.monitoring = is_attacking()
	damage_reciever.monitorable = can_get_hurt()
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

func handle_knife_respawns() -> void:
	if can_respawn_knifes and not has_knife and (Time.get_ticks_msec() - time_since_knife_dismiss > duration_between_knife_respawn):
		has_knife = true

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
		knife_sprite.scale.x = 1
		projectile_aim.scale.x = 1
		damage_emitter.scale.x = 1
	else:
		character_sprite.flip_h = true
		knife_sprite.scale.x = -1
		projectile_aim.scale.x = -1
		damage_emitter.scale.x = -1


func can_move() -> bool:
	return state == State.IDLE or state == State.WALK
		
		
func can_attack() -> bool:
	return state == State.IDLE or state == State.WALK
	
func can_jump() -> bool:
	return state == State.IDLE or state == State.WALK

func can_get_hurt() -> bool:
	return [State.IDLE, State.WALK, State.TAKEOFF, State.LANDING, State.PREP_ATTACK].has(state)

func is_attacking() -> bool:
	return [State.ATTACK, State.JUMPKICK].has(state)

func can_pickup_collectibles() -> bool:
	var collectible_areas = collectible_sensor.get_overlapping_areas()
	if collectible_areas.size() == 0:
		return false
	var collectible : Collectible = collectible_areas[0]
	if collectible.type == Collectible.Type.KNIFE and not has_knife:
		return true
	return false

func pickup_collectible() -> void:
	if can_pickup_collectibles():
		var collectible_areas = collectible_sensor.get_overlapping_areas()
		var collectible : Collectible = collectible_areas[0]
		if collectible.type == Collectible.Type.KNIFE and not has_knife:
			has_knife = true
		
		collectible.queue_free()


func is_collision_disabled() -> bool:
	return [State.GROUNDED, State.DEATH, State.FLY].has(state)

func can_jumpkick() -> bool:
	return state == State.JUMP

func on_action_complete():
	state = State.IDLE

func on_throw_complete() -> void:
	state = State.IDLE
	has_knife = false
	var knife_global_position := Vector2(weapon_position.global_position.x, global_position.y)
	var knife_height := -weapon_position.position.y
	EntityManager.spawn_collectible.emit(Collectible.Type.KNIFE, Collectible.State.FLY, knife_global_position, heading, knife_height)

func on_takeoff_complete() -> void:
	state = State.JUMP
	height_speed = jump_intensity
 
func on_pickup_complete() -> void:
	state = State.IDLE
	pickup_collectible()

func on_landing_complete() -> void:
	state = State.IDLE
	
func on_recieve_damage(amount: int, direction: Vector2, hit_type: DamageReciever.HitType) -> void:
	if can_get_hurt():
		can_respawn_knifes = false
		if has_knife:
			has_knife = false
			time_since_knife_dismiss = Time.get_ticks_msec()
		current_health = clamp(current_health - amount,0, max_health)
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

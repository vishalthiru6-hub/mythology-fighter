extends CharacterBody2D

signal knocked_out(id)

@export var player_id := 1
@export var character_name := "Thor"
@export var body_color := Color(0.23, 0.48, 0.84)
@export var special_color := Color(1.0, 0.9, 0.2)
@export var speed := 250.0
@export var jump_velocity := -500.0
@export var punch_damage := 10
@export var special_damage := 25
@export var special_cooldown := 4.0
@export var block_multiplier := 0.2

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health := 100
var facing := 1.0
var is_attacking := false
var is_blocking := false
var is_ko := false
var can_fight := true
var special_ready := true
var already_hit := []

@onready var hitbox = $Hitbox
@onready var hitbox_shape = $Hitbox/CollisionShape2D
@onready var special_hitbox = $SpecialHitbox
@onready var special_shape = $SpecialHitbox/CollisionShape2D
@onready var health_bar = $HealthBar
@onready var body_rect = $ColorRect
@onready var name_label = $NameLabel
@onready var fx = $LightningFX

func _ready():
	health_bar.show_percentage = false
	health_bar.max_value = 100
	health_bar.value = health
	hitbox_shape.disabled = true
	special_shape.disabled = true

	body_rect.color = body_color
	fx.color = special_color
	fx.visible = false

	name_label.position = Vector2(-80, -165)
	name_label.size = Vector2(160, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	update_name_label()

func update_name_label():
	if special_ready:
		name_label.text = character_name + "  [SPECIAL]"
	else:
		name_label.text = character_name

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_ko or not can_fight:
		is_blocking = false
		body_rect.modulate = Color.WHITE
		velocity.x = 0
		move_and_slide()
		return

	var dir = Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id)

	is_blocking = is_on_floor() and not is_attacking and Input.is_action_pressed("p%d_block" % player_id)
	body_rect.modulate = Color(0.5, 0.5, 0.5) if is_blocking else Color.WHITE

	if is_attacking or is_blocking:
		velocity.x = 0
	else:
		velocity.x = dir * speed
		if dir != 0:
			facing = sign(dir)
		if Input.is_action_just_pressed("p%d_jump" % player_id) and is_on_floor():
			velocity.y = jump_velocity
		if Input.is_action_just_pressed("p%d_punch" % player_id):
			punch()
		elif Input.is_action_just_pressed("p%d_special" % player_id) and special_ready and is_on_floor():
			special()

	if is_attacking and not hitbox_shape.disabled:
		for body in hitbox.get_overlapping_bodies():
			if body != self and body.has_method("take_damage") and not already_hit.has(body):
				already_hit.append(body)
				body.take_damage(punch_damage)

	if is_attacking and not special_shape.disabled:
		for body in special_hitbox.get_overlapping_bodies():
			if body != self and body.has_method("take_damage") and not already_hit.has(body):
				already_hit.append(body)
				body.take_damage(special_damage)

	move_and_slide()

func punch():
	is_attacking = true
	already_hit.clear()
	hitbox_shape.position.x = 55 * facing
	hitbox_shape.set_deferred("disabled", false)
	await get_tree().create_timer(0.2).timeout
	hitbox_shape.set_deferred("disabled", true)
	await get_tree().create_timer(0.15).timeout
	is_attacking = false

func special():
	is_attacking = true
	special_ready = false
	update_name_label()
	already_hit.clear()
	special_shape.position.x = 100 * facing
	fx.size = Vector2(30, 220)
	fx.position = Vector2(100 * facing - 15, -220)

	await get_tree().create_timer(0.2).timeout
	fx.visible = true
	special_shape.set_deferred("disabled", false)
	await get_tree().create_timer(0.15).timeout
	special_shape.set_deferred("disabled", true)
	fx.visible = false
	await get_tree().create_timer(0.2).timeout
	is_attacking = false

	await get_tree().create_timer(special_cooldown).timeout
	special_ready = true
	update_name_label()

func take_damage(amount):
	if is_ko or not can_fight:
		return
	if is_blocking:
		amount = roundi(amount * block_multiplier)
	health = maxi(health - amount, 0)
	health_bar.value = health
	if health == 0:
		is_ko = true
		body_rect.color = Color.DIM_GRAY
		body_rect.modulate = Color.WHITE
		knocked_out.emit(player_id)

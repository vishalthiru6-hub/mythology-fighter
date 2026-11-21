extends CharacterBody2D

@export var player_id := 1
@export var speed := 250.0
@export var jump_velocity := -500.0
@export var punch_damage := 10

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health := 100
var facing := 1.0
var is_attacking := false
var is_ko := false
var already_hit := []

@onready var hitbox = $Hitbox
@onready var hitbox_shape = $Hitbox/CollisionShape2D
@onready var health_bar = $HealthBar

func _ready():
	health_bar.show_percentage = false
	health_bar.max_value = 100
	health_bar.value = health
	hitbox_shape.disabled = true

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_ko:
		velocity.x = 0
		move_and_slide()
		return

	var dir = Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id)

	if is_attacking:
		velocity.x = 0
	else:
		velocity.x = dir * speed
		if dir != 0:
			facing = sign(dir)
		if Input.is_action_just_pressed("p%d_jump" % player_id) and is_on_floor():
			velocity.y = jump_velocity
		if Input.is_action_just_pressed("p%d_punch" % player_id):
			punch()

	if is_attacking and not hitbox_shape.disabled:
		for body in hitbox.get_overlapping_bodies():
			if body != self and body.has_method("take_damage") and not already_hit.has(body):
				already_hit.append(body)
				body.take_damage(punch_damage)

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

func take_damage(amount):
	if is_ko:
		return
	health = maxi(health - amount, 0)
	health_bar.value = health
	if health == 0:
		is_ko = true
		$ColorRect.color = Color.DIM_GRAY

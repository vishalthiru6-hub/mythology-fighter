extends CharacterBody2D

@export var player_id := 1
@export var speed := 250.0
@export var jump_velocity := -500.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	var dir = Input.get_axis("p%d_left" % player_id, "p%d_right" % player_id)
	velocity.x = dir * speed

	if Input.is_action_just_pressed("p%d_jump" % player_id) and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

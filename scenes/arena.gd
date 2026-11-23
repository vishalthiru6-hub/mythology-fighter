extends Node2D

@export var round_time := 60

@onready var p1 = $Thor
@onready var p2 = $Anubis
@onready var timer_label = $UI/TimerLabel
@onready var message_label = $UI/MessageLabel

var time_left := 0.0
var round_over := false

func _ready():
	timer_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", 40)

	message_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 56)

	p1.knocked_out.connect(_on_knocked_out)
	p2.knocked_out.connect(_on_knocked_out)
	start_round()

func start_round():
	time_left = round_time
	timer_label.text = str(round_time)
	message_label.text = "FIGHT!"
	await get_tree().create_timer(1.0).timeout
	if not round_over:
		message_label.text = ""

func _process(delta):
	if round_over:
		if Input.is_physical_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return

	time_left -= delta
	timer_label.text = str(maxi(ceili(time_left), 0))
	if time_left <= 0:
		end_round_by_time()

func _on_knocked_out(loser_id):
	if round_over:
		return
	var winner = 2 if loser_id == 1 else 1
	end_round("PLAYER %d WINS!" % winner)

func end_round_by_time():
	if p1.health > p2.health:
		end_round("TIME UP!\nPLAYER 1 WINS!")
	elif p2.health > p1.health:
		end_round("TIME UP!\nPLAYER 2 WINS!")
	else:
		end_round("TIME UP!\nDRAW!")

func end_round(text):
	round_over = true
	p1.can_fight = false
	p2.can_fight = false
	message_label.text = text + "\nPress R to restart"

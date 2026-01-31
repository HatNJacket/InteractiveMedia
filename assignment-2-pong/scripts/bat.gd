extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D

@export var SPEED: float = 200.0
@export var ai_controlled: bool = true

var player_id: int = -1
var is_two_player: bool = false
var is_preview: bool = false
var ball: CharacterBody2D = null

var has_target := false
var target_y := 0.0
var offset := 120.0

const CEILING := 50.0
const FLOOR := 640.0
const DEADZONE := 5.0


var locked_x: float

func _ready() -> void:
	if name == "LeftBat":
		player_id = 1
	elif name == "RightBat":
		player_id = 2

	locked_x = global_position.x
func reset_to_center() -> void:
	has_target = false
	target_y = 350.0

func _on_game_mode_changed(two_player_mode: bool) -> void:
	is_two_player = two_player_mode

func _on_preview_mode_changed(preview: bool) -> void:
	is_preview = preview
	has_target = false

func reflect_between(y: float, top: float, bottom: float) -> float:
	var h := bottom - top
	if h <= 0.0:
		return clamp(y, top, bottom)

	var v := y - top
	var period := 2.0 * h
	var m := fposmod(v, period)
	if m > h:
		m = period - m
	return top + m

func flash_hit() -> void:
	sprite.modulate = Color.WHITE
	var flash_tween := create_tween()
	var sprite_colour = (Color("#4AE1FF") if player_id==1 else Color("#FFD044"))
	sprite.modulate = sprite_colour
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.4)

func _physics_process(delta: float) -> void:
	
	var y_velocity := 0.0
	var use_ai := is_preview or ((not is_two_player) and ai_controlled)

	if use_ai:
		if ball == null:
			y_velocity = 0.0
		else:
			var bx := ball.global_position.x
			var by := ball.global_position.y
			var vx := ball.velocity.x
			var vy := ball.velocity.y

			var halfway_x := get_viewport_rect().size.x * 0.5
			var moving_towards_bat := (player_id == 1 and vx < 0.0) or (player_id == 2 and vx > 0.0)
			var past_halfway := (player_id == 1 and bx > halfway_x) or (player_id == 2 and bx < halfway_x)

			if not moving_towards_bat:
				has_target = false

			if moving_towards_bat and past_halfway and not has_target and abs(vx) > 0.001:
				var t := (global_position.x - bx) / vx
				if t > 0.0:
					var y_pred := by + vy * t
					y_pred = reflect_between(y_pred, CEILING, FLOOR)
					y_pred += randf_range(-offset, offset)
					target_y = y_pred
					has_target = true

			var aim_y := target_y if has_target else ((CEILING + FLOOR) * 0.5)
			var dy := aim_y - global_position.y
			if abs(dy) < DEADZONE:
				y_velocity = 0.0
			else:
				y_velocity = clamp(dy, -1.0, 1.0) * SPEED

	else:
		var up_action := "left_up" if player_id == 1 else "right_up"
		var down_action := "left_down" if player_id == 1 else "right_down"
		var input_dir := Input.get_action_strength(down_action) - Input.get_action_strength(up_action)
		y_velocity = input_dir * SPEED

	velocity = Vector2(0.0, y_velocity)
	move_and_slide()
	global_position.x = locked_x

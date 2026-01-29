extends CharacterBody2D

var SPEED := 300.0
var dir: Vector2 = Vector2.RIGHT
var is_two_player: bool = false

func _ready() -> void:
	randomize() # seed RNG once

# Changes the direction the ball moves when the ball is served
func _on_game_mode_changed(is_two_player_mode: bool) -> void:
	is_two_player = is_two_player_mode

func serve() -> void:
	if is_two_player:
		dir = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT
	else:
		dir = Vector2.RIGHT

	# small vertical variance
	dir.y = randf_range(-0.5, 0.5)
	dir = dir.normalized()

func calculate_offset(collision: KinematicCollision2D) -> float:
	var paddle = collision.get_collider()
	var hit_y = collision.get_position().y
	var paddle_y = paddle.global_position.y

	var offset = hit_y - paddle_y

	var paddle_height = paddle.get_node("CollisionShape2D").shape.size.y
	var normalized_offset = offset / (paddle_height / 1.5)
	return clamp(normalized_offset, -1.0, 1.0)

func _physics_process(delta: float) -> void:
	velocity = dir * SPEED
	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()
		
		dir = dir.bounce(normal).normalized()
		
		if abs(normal.x) > 0.9:
			SPEED = min(SPEED*1.15, 1000.0)
			dir.y = calculate_offset(collision)
			dir = dir.normalized()
			break
		
		if dir.dot(normal) < 0.0:
			dir = dir.bounce(normal).normalized()

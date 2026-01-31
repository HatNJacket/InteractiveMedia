extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_particles: GPUParticles2D = get_node("/root/Pong/BallImpactParticles")
@onready var hit_sound: AudioStreamPlayer = $BallTap

var INIT_SPEED := 300.0
var SPEED = INIT_SPEED
var dir: Vector2 = Vector2.RIGHT
var is_two_player: bool = false
var serve_position: Vector2 = Vector2(540, 350)

func _ready() -> void:
	randomize() # seed RNG once

# Changes the direction the ball moves when the ball is served
func _on_game_mode_changed(is_two_player_mode: bool) -> void:
	is_two_player = is_two_player_mode

func serve() -> void:
	global_position = serve_position
	SPEED = INIT_SPEED
	dir = Vector2.RIGHT

	# small vertical variance
	dir.y = randf_range(-0.05, 0.05)
	dir = dir.normalized()

func flash_hit() -> void:
	sprite.modulate = Color.WHITE

	var flash_tween := create_tween()
	sprite.modulate = Color("FF3322")
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.4)

func calculate_offset(collision: KinematicCollision2D) -> float:
	var paddle = collision.get_collider()
	var hit_y = collision.get_position().y
	var paddle_y = paddle.global_position.y

	var offset = hit_y - paddle_y

	var paddle_height = paddle.get_node("CollisionShape2D").shape.size.y
	var normalized_offset = offset / (paddle_height)
	return clamp(normalized_offset, -1.0, 1.0)

func emit_particles(world_pos: Vector2, normal: Vector2) -> void:
	hit_particles.global_position = world_pos
	hit_particles.restart()
	hit_particles.emitting = true

func play_hit_sound() -> void:
	hit_sound.play()

func _physics_process(delta: float) -> void:
	velocity = dir * SPEED
	move_and_slide()

	for i in range(get_slide_collision_count()):
		flash_hit()
		play_hit_sound()
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()
		emit_particles(collision.get_position(), normal)
		
		dir = dir.bounce(normal).normalized()
		var collider := collision.get_collider()

		if collider.has_method("flash_hit"): # Is it a paddle?
			collider.flash_hit()
			

			var y := calculate_offset(collision) # To prevent the ball moving nearly vertically on a corner-paddle hit
			y = clamp(y, -0.60, 0.60)
			dir.y = y
			SPEED = min(SPEED*1.15, 1000.0)
			dir = dir.normalized()
			break
		
		if dir.dot(normal) < 0.0:
			dir = dir.bounce(normal).normalized()

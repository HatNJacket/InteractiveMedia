extends CharacterBody2D

enum Direction { LEFT, RIGHT }

@onready var anim: AnimatedSprite2D = $RobotAnimation
@onready var main := get_tree().get_first_node_in_group("main")

@onready var body_collider: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var bubble_collider: Area2D = $BubbleCollider

@export var gravity := 900.0
@export var speed := 80.0
@export var bubble_rise_speed := 35.0

var facing: Direction = Direction.RIGHT
var skin := "a"

var bubbled := false
var popping := false

func _ready():
	skin = "a" if randf() < 0.5 else "b"
	_update_animation()

	hitbox.monitoring = true
	hitbox.monitorable = true
	bubble_collider.monitoring = true
	bubble_collider.monitorable = true

	hitbox.body_entered.connect(_on_hitbox_body_entered)
	bubble_collider.set_deferred("monitoring", false)

func _physics_process(delta: float) -> void:
	if bubbled:
		global_position.y -= bubble_rise_speed * delta

		# Poll overlaps every tick
		_check_bubble_overlap()
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	velocity.x = speed if facing == Direction.RIGHT else -speed
	move_and_slide()

	# Touching player = game over (only when not bubbled)
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		print(col)
		var other := col.get_collider()
		if other and other.is_in_group("player"):
			if main:
				main.trigger_game_over()

	if is_on_wall():
		_turn_around()

func _check_bubble_overlap() -> void:
	if popping:
		return
	if not bubble_collider.monitoring:
		return

	var bodies := bubble_collider.get_overlapping_bodies()
	for b in bodies:
		if b and b.is_in_group("player"):
			_pop()
			return

func _on_hitbox_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if bubbled:
		return
	if main:
		main.trigger_game_over()

func bubble_trap() -> void:
	if bubbled or popping:
		return
	bubbled = true
	velocity = Vector2.ZERO

	body_collider.set_deferred("disabled", true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	hitbox.set_deferred("monitoring", false)
	bubble_collider.set_deferred("monitoring", true)

	anim.play("%s_trapped" % skin)
	call_deferred("_check_bubble_overlap")

func _pop() -> void:
	if popping:
		return
	popping = true

	bubble_collider.set_deferred("monitoring", false)

	anim.play("popped")
	bubble_rise_speed = 0
	await anim.animation_finished
	queue_free()

func _turn_around():
	facing = Direction.LEFT if facing == Direction.RIGHT else Direction.RIGHT
	_update_animation()

func _update_animation():
	anim.flip_h = not (facing == Direction.RIGHT)
	anim.play("%s_moving" % skin)

func on_player_touched(player: Node) -> void:
	if popping:
		return

	if bubbled:
		_pop()
	else:
		if main:
			main.trigger_game_over()

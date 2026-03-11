extends CharacterBody2D

enum Direction {
	DOWN,
	LEFT,
	RIGHT
}

const SPEED = 300.0
const JUMP_VELOCITY = -650.0

@onready var main := get_tree().get_first_node_in_group("main")
@onready var anim: AnimatedSprite2D = $PlayerAnimation
@onready var bubble_scene: PackedScene = preload("res://scenes/world/entities/projectiles/bubble.tscn")
@export var max_bubbles: int = 5
@onready var entities: Node = get_parent()

var has_landed = false # Tracks if the player has landed on the stage after spawning
var facing: Direction = Direction.DOWN
var attacking := false
var jumping := false

func _ready() -> void:
	add_to_group("player")
	anim.play("falling")

func _physics_process(delta: float) -> void:
	if is_on_floor() and not has_landed:
		anim.play("spawnIdle")
		has_landed = true
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("attack_button") and is_on_floor():
		_start_attack()

	if jumping and is_on_floor():
		jumping = false

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not attacking:
		velocity.y = JUMP_VELOCITY
		jumping = true
	
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		match -(direction):
			1.0:
				facing = Direction.RIGHT
			-1.0:
				facing = Direction.LEFT
		if not attacking:
			velocity.x = direction * SPEED
	else:
		
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var other := col.get_collider()

		if other == null:
			continue

	# If the thing we hit is a robot, let the robot decide what happens
		if other.has_method("on_player_touched"):
			other.on_player_touched(self)
	
	_update_animation()
	
func _update_animation() -> void:
	if attacking:
		return
	
	if jumping:
		anim.flip_h = (facing==Direction.RIGHT)
		anim.play("jump")
		return

	match facing:
		Direction.LEFT:
			anim.flip_h = false
			if velocity.x == 0:
				anim.play("sideIdle")
			else:
				anim.play("run")
		Direction.RIGHT:
			anim.flip_h = true
			if velocity.x == 0:
				anim.play("sideIdle")
			else:
				anim.play("run")

func _start_attack():
	if attacking:
		return
	attacking = true
	velocity.x = 0
	anim.flip_h = (facing==Direction.RIGHT)
	
	if bubble_scene != null:
		var bubble_count := 0
		
		# Count how many bubbles there are
		for child in entities.get_children(): 
			if child.name.begins_with("Bubble"):
				bubble_count += 1 
		
		if bubble_count < max_bubbles:
			var bubble = bubble_scene.instantiate()
			bubble.name = "Bubble_%d" % Time.get_ticks_msec()
			print("Spawned: ", bubble, " type=", bubble.get_class()) 
			var marker_offset = $BubbleMarker.position
			marker_offset *= (0 if facing == Direction.RIGHT else -2)
			bubble.global_position = $BubbleMarker.global_position + marker_offset
			print($BubbleMarker.global_position)
			entities.add_child(bubble)
			
			var dir_sign := (1 if facing == Direction.RIGHT else -1)
			bubble.launch(-dir_sign)
	else:
		print("bubble_scene is null")
	
	anim.play("attack")
	await anim.animation_finished
	attacking = false
	return

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	main.trigger_game_over()

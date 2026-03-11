extends Area2D

@onready var anim: AnimatedSprite2D = $BubbleAnimation

@export_group("Tuning")

@export var launch_x: float = 350.0
@export var rise_speed_y: float = 90.0
@export var x_decelerate: float = 3.0
@export var min_decel: float = 5.0
@export var offscreen_points: int = 0

signal bubble_offscreen(points: int)

var vx: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("spawn")
	area_entered.connect(_on_area_entered)
	pass # Replace with function body.

func launch(dir_sign: float) -> void:
	var offset = randf_range(-75, 75)
	vx = launch_x * sign(dir_sign) + offset
	print(vx)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var decel_step: float = (abs(vx) * x_decelerate + min_decel) * delta
	vx = move_toward(vx, 0.0, decel_step)
	
	position.x += vx * delta
	position.y -= rise_speed_y * delta
	pass

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	bubble_offscreen.emit(offscreen_points)
	
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# We expect to collide with Robot's Hitbox (Area2D)
	var robot := area.get_parent()
	if robot and robot.has_method("bubble_trap"):
		robot.bubble_trap()
		queue_free()

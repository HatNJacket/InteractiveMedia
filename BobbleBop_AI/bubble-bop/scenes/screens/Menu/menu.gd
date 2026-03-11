extends Node2D

@onready var anim: AnimatedSprite2D = $PressSpace

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.play("pressSpace")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

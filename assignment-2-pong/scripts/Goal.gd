extends Area2D

signal goal_scored(went_in_left_goal: bool)
@export var is_left_goal := true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	print("BODY ENTERED: ", body.name)
	if body is CharacterBody2D:
		goal_scored.emit(is_left_goal)
		print("Goal Scored: ", is_left_goal)

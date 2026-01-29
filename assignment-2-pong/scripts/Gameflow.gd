extends Node2D

var left_score = 0
var right_score = 0
const winning_score = 5

var menu_selection := 1
signal game_mode_changed(is_two_player: bool)

enum GameState {
	MENU,
	PLAYING,
	GAME_OVER
}
var state : GameState

func set_state(new_state : GameState) -> void:
	if state == new_state:
		return

	state = new_state

	match state:
		GameState.MENU:
			# Set both bats to AI
			# Serve ball
			# Show Menu
			# MODE SELECTED
			if menu_selection == 1:
				emit_signal("game_mode_changed", (menu_selection == 2))
			pass
			
		GameState.PLAYING:
			# Hide Menu
			# Serve Ball
			pass
			
		GameState.GAME_OVER:
			# Show Winner Screen
			# Stop ball
			pass

func _ready() -> void:
	menu_selection = 1
	set_state(GameState.MENU)
	pass # Replace with function body.

func _enter_tree() -> void:
	$LeftBat.ball = $Ball
	$RightBat.ball = $Ball

func update_menu() -> void:
	if menu_selection == 1:
		$"UI/MainMenu/1Player".text = "> 1 Player"
		$"UI/MainMenu/2Player".text = "2 Players"
	else:
		$"UI/MainMenu/1Player".text = "1 Player"
		$"UI/MainMenu/2Player".text = "> 2 Players"

func start_game() -> void:
	var two_players := (menu_selection == 2)
	emit_signal("game_mode_changed", two_players)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if state == GameState.MENU:
		if Input.is_action_just_pressed("menu_button"):
			menu_selection = 2 if menu_selection == 1 else 1
			update_menu()
			$UI/MainMenu/MainMenuSelectionTick.play()
		
		if Input.is_action_just_pressed("menu_select"):
			start_game()
	pass

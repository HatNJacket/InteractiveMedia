extends Node2D

var left_score = 0
var right_score = 0
const winning_score = 1

@onready var left_goal = $Walls/LeftGoal
@onready var right_goal = $Walls/RightGoal

@onready var ball = $Ball
@onready var left_bat = $LeftBat
@onready var right_bat = $RightBat

@onready var player_wins: Label = $UI/PlayerWins

@onready var background_music: AudioStreamPlayer = $Background
@onready var score_sound: AudioStreamPlayer = $Score
@onready var win_sound: AudioStreamPlayer = $Win

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
			left_bat.ai_controlled = true
			right_bat.ai_controlled = true
			reset_scoreboard()
			# Serve ball
			ball.serve()
			# Show Menu
			var menu_selection = 1
			player_wins.visible = false
			$UI/MainMenu.visible = true
			# MODE SELECTED
			emit_signal("game_mode_changed", (menu_selection == 2))
			update_menu()
			pass
			
		GameState.PLAYING:
			# Hide Menu
			$UI/MainMenu.visible = false
			# Give player control of bat(s)
			left_bat.ai_controlled = false
			right_bat.ai_controlled = (menu_selection == 1)
			# Serve Ball
			reset_scoreboard()
			serve_ball()
			pass
			
		GameState.GAME_OVER:
			print("GAME OVER")
			win_sound.play()
			$UI/MainMenu.visible = false
			$UI/PlayerWins.visible = true
			var winner = 1 if left_score >= winning_score else 2
			player_wins.text = "Player %d Wins!" % winner
			player_wins.visible = true
			await get_tree().create_timer(5).timeout
			set_state(GameState.MENU)
	
func serve_ball() -> void:
	$LeftBat.reset_to_center()
	$RightBat.reset_to_center()
	ball.serve()
	pass

func reset_scoreboard() -> void:
	var left_label := $UI/Scoreboard/LeftScore as Label
	var right_label := $UI/Scoreboard/RightScore as Label
	left_score = 0
	right_score = 0
	
	left_label.text = "0"
	right_label.text = "0"

func _on_goal_scored(went_in_left_goal: bool) -> void:
	var left_label := $UI/Scoreboard/LeftScore as Label
	var right_label := $UI/Scoreboard/RightScore as Label

	score_sound.play()

	if went_in_left_goal:
		right_score += 1
		right_label.text = str(right_score)
	else:
		left_score += 1
		left_label.text = str(left_score)
	
	if (left_score >= winning_score or right_score >= winning_score) and state == GameState.PLAYING:
		set_state(GameState.GAME_OVER)
	else:
		if state == GameState.PLAYING:
			await get_tree().create_timer(3).timeout
		serve_ball()

func _on_music_finished() -> void:
	background_music .play()

func _ready() -> void:
	background_music.finished.connect(_on_music_finished)
	background_music.play()
	left_goal.goal_scored.connect(_on_goal_scored)
	right_goal.goal_scored.connect(_on_goal_scored)
	menu_selection = 1
	set_state(GameState.MENU)

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
	set_state(GameState.PLAYING)
# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta: float) -> void:
	if state == GameState.MENU:
		if Input.is_action_just_pressed("menu_button"):
			menu_selection = 2 if menu_selection == 1 else 1
			update_menu()
			$UI/MainMenu/MainMenuSelectionTick.play()
		
		if Input.is_action_just_pressed("menu_select"):
			start_game()

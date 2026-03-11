extends Node2D

enum GameState{
	MENU,
	PLAYING,
	GAMEOVER
}
var state: GameState = GameState.MENU

@onready var entities := $Level/Entities
@export var player_scene: PackedScene
@onready var player_spawn := $Level/SpawnMarkers/PlayerSpawn
var player: Node2D = null

@export var enemy_scene: PackedScene
@export var enemy_spawn_min := 3.0
@export var enemy_spawn_max := 5.0

@onready var spawner_left := $Level/SpawnMarkers/LeftSpawn
@onready var spawner_right := $Level/SpawnMarkers/RightSpawn

var enemy_timer: Timer

@onready var level: Node = $Level
@onready var menu: Node = $Menu
@onready var gameover: Node = $GameOver

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemy_timer = Timer.new()
	enemy_timer.one_shot = true
	enemy_timer.timeout.connect(_on_enemy_timer_timeout)
	add_child(enemy_timer)
	add_to_group("main")
	gameover.visible = false
	show_menu()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match state:
		GameState.MENU:
			#print("Menu")
			if Input.is_action_just_pressed("attack_button"):
				#print("STARTED")
				start_game()
		GameState.PLAYING:
			#print(player.position)
			pass
		GameState.GAMEOVER:
			if Input.is_action_just_pressed("attack_button"):
				show_menu()
	pass

func show_menu() -> void:
	state = GameState.MENU
	menu.visible = true
	gameover.visible = false
	if enemy_timer: enemy_timer.stop()

func start_game() -> void:
	state = GameState.PLAYING
	_spawn_player()
	menu.visible = false
	enemy_timer.start()
	
	
func trigger_game_over() -> void:
	state = GameState.GAMEOVER
	gameover.visible = true
	if enemy_timer: enemy_timer.stop()
	_despawn_all_entities()

func _despawn_all_entities() -> void:
	for child in entities.get_children():
		child.call_deferred("queue_free")	

func _spawn_player():
	#print("A")
	if player_scene == null:
		push_warning("Player scene not set")
		return
	
	player = player_scene.instantiate()
	entities.add_child(player)
	
	if player_spawn:
		player.global_position = player_spawn.position

func _spawn_enemy() -> void:
	if state != GameState.PLAYING:
		return
	if enemy_scene == null:
		push_warning("Enemy scene not set")
		return

	var spawn_marker: Marker2D = spawner_left if randf() < 0.5 else spawner_right

	var e := enemy_scene.instantiate() as Node2D
	e.name = "Robot_%d" % Time.get_ticks_msec()
	entities.add_child(e)
	e.global_position = spawn_marker.position
	

func _start_enemy_timer() -> void:
	if state != GameState.PLAYING:
		return

	enemy_timer.wait_time = randf_range(enemy_spawn_min, enemy_spawn_max)
	enemy_timer.start()

func _on_enemy_timer_timeout() -> void:
	if state != GameState.PLAYING:
		return
	
	_spawn_enemy()
	_start_enemy_timer()

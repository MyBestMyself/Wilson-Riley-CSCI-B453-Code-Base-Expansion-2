extends Node

@export var hud_message: String = "Bimble’s\nBoba\nBonanza"
@export var mob_scene: PackedScene
@export var straw_scene: PackedScene
@export var next_level: PackedScene
@export var min_spawn_interval: float = 1.5
@export var max_spawn_interval: float = 3 
@export var min_ice_spawn_interval: float = 3.0
@export var max_ice_spawn_interval: float = 5.0
@export var spawn_margin: float = 50.0
@export var boba = true
@export var ice_bombs = false

var falling_boba_scene = preload("res://falling_boba.tscn")
var falling_ice_bomb = preload("res://ice_bomb.tscn")
var score = 100
var milk_tea_level = 1.0  # 1.0 is full, 0.0 is empty
var milk_tea_left_boundary: float
var milk_tea_right_boundary: float
var game_started = false
var game_done = false

func _ready():
	$Player.hide()
	$HUD.update_score(100)
	$HUD/MessageLabel.text = hud_message
	$ScoreTimer.wait_time = 0.5  # Update every half second instead of every second
	update_milk_tea_boundaries()
	
func game_over():
	game_started = false
	$ScoreTimer.stop()
	$HUD.show_game_over()
	#$Music.stop()
	
	# Hide player and clear all bobas
	$Player.hide()
	get_tree().call_group("falling_boba", "queue_free")
	get_tree().call_group("straw", "queue_free")
	get_tree().call_group("falling_ice_bomb", "queue_free")
	
	# Show the Start Button after the delay
	$HUD/StartButton.show()

func new_game():
	game_started = false
	score = 100
	$HUD.update_score(score)
	milk_tea_level = 1.0
	
	# Place the player in the start position and pass the boundaries
	$Player.start($StartPosition.position, $HUD/MilkTeaLevel, milk_tea_left_boundary, milk_tea_right_boundary)
	$Player.show()
	$StartTimer.start()
	
	$HUD.update_score(score)
	$HUD.update_milk_tea_level(milk_tea_level)
	
	straw_scene = preload("res://straw.tscn")
	var straw_instance = straw_scene.instantiate()
	straw_instance.position = Vector2(225, -550)
	add_child(straw_instance)
	straw_instance.add_to_group("straw")
	
	$HUD.show_message("Get Ready")
	
	start_countdown()
	fade_music_in()

# Spawn timer for the boba
func spawn_boba():
	if not game_started and not game_done:
		return
		
	var spawn_count = randi_range(1, 2)  # Spawn 1 to 2 boba at a time
	for i in range(spawn_count):
		var new_boba = falling_boba_scene.instantiate()
		new_boba.add_to_group("falling_boba")
		
		# Set random x position within the milk tea boundaries
		new_boba.position.x = randf_range(milk_tea_left_boundary, milk_tea_right_boundary)
		new_boba.position.y = -50 - (i * 20)  # Start above the screen, staggered vertically
		
		# Set the boundaries
		new_boba.set_boundaries(milk_tea_left_boundary, milk_tea_right_boundary)
		
		add_child(new_boba)
	
	# Set timer for next spawn
	var next_spawn_time = randf_range(min_spawn_interval, max_spawn_interval)
	get_tree().create_timer(next_spawn_time).timeout.connect(spawn_boba)

func spawn_ice_bomb():
	if not game_started and not game_done:
		return
		
	var new_ice_bomb = falling_ice_bomb.instantiate()
	new_ice_bomb.add_to_group("falling_ice_bomb")
	
	# Connect the exploded signal
	new_ice_bomb.connect("exploded", Callable(self, "_on_ice_bomb_exploded"))
	
	# Set random x position within the milk tea boundaries
	new_ice_bomb.position.x = randf_range(milk_tea_left_boundary, milk_tea_right_boundary)
	new_ice_bomb.position.y = -50  # Start above the screen, staggered vertically
	
	# Set the boundaries
	new_ice_bomb.set_boundaries(milk_tea_left_boundary, milk_tea_right_boundary)
	
	add_child(new_ice_bomb)
	
	# Set timer for next spawn
	var next_spawn_time = randf_range(min_ice_spawn_interval, max_ice_spawn_interval)
	get_tree().create_timer(next_spawn_time).timeout.connect(spawn_ice_bomb)

func _on_ice_bomb_exploded(bomb_position):
	$Player.push_from_explosion(bomb_position)

func update_milk_tea_boundaries():
	var viewport_size = get_viewport().size
	var cup_width = 300  # Adjust this to your cup's width
	milk_tea_left_boundary = (viewport_size.x - cup_width) / 2
	milk_tea_right_boundary = milk_tea_left_boundary + cup_width
	
	# Update boundaries for all existing boba
	get_tree().call_group("falling_boba", "set_boundaries", milk_tea_left_boundary, milk_tea_right_boundary)

func update_boba_positions():
	for boba in get_tree().get_nodes_in_group("falling_boba"):
		if boba.position.x < milk_tea_left_boundary:
			boba.position.x = milk_tea_left_boundary
		elif boba.position.x > milk_tea_right_boundary:
			boba.position.x = milk_tea_right_boundary

func update_player_boundaries():
	$Player.left_boundary = milk_tea_left_boundary
	$Player.right_boundary = milk_tea_right_boundary
	$Player.update_vertical_boundaries()

func start_countdown():
	$HUD.show_message("Get Ready")
	await get_tree().create_timer(0.5).timeout
	$HUD.show_message("3")
	await get_tree().create_timer(0.5).timeout
	$HUD.show_message("2")
	await get_tree().create_timer(0.5).timeout
	$HUD.show_message("1")
	await get_tree().create_timer(0.5).timeout
	$HUD.show_message("Go!")
	await get_tree().create_timer(0.5).timeout
	$HUD.hide_message()
	
	start_game()

func start_game():
	game_started = true
	$StartTimer.start()
	if boba:
		spawn_boba()
	
	if ice_bombs:
		spawn_ice_bomb()

func fade_music_in() -> void:
	const fade_time = 2.0
	const default_music_db = -10.0

	$Music.volume_db = -90.0 # Mute the player
	$Music.play() # Start playing
	
	# Use tweens for transition:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property($Music, "volume_db", default_music_db, fade_time)

func _on_ScoreTimer_timeout():
	score -= 1
	$HUD.update_score(score)
	milk_tea_level -= 0.01  # Decrease by 1% each time 
	milk_tea_level = max(milk_tea_level, 0)  # Ensure it doesn't go below 0
	$HUD.update_milk_tea_level(milk_tea_level)
	update_milk_tea_boundaries()
	update_boba_positions()
	update_player_boundaries()

func _on_StartTimer_timeout():
	#$MobTimer.start()
	$ScoreTimer.start()

func _process(delta):
	if score <= 20 and not game_done:
		game_done = true
		get_node("straw").stop_drinking()
		$ScoreTimer.stop()
		$EndTimer.start()

func _on_music_finished() -> void:
	#$Music.play()
	pass


func _on_end_timer_timeout() -> void:
	if next_level != null:
		get_tree().change_scene_to_packed(next_level)

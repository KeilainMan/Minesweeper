extends Node2D

################################################################################
##NODES
################################################################################
@onready var camera: Camera2D = $Camera2D
@onready var restart: Button = $CanvasLayer/Restart
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var tiles: Node = $Tiles
@onready var bombs: Label = $CanvasLayer/Bombs
@onready var die_screen: TextureRect = $CanvasLayer/DieScreen
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


################################################################################
##IMPORTS
################################################################################
const TILE: PackedScene = preload("res://tile.tscn")


################################################################################
##GRID VARIABLES
################################################################################
const GRID_DIM_X: int = 30
const GRID_DIM_Y: int = 20
const GRID_FIELDSIZE_X: int = 32
const GRID_FIELDSIZE_Y: int = 32

var grid_pos: Array = []
var grid_tiles: Array = []

################################################################################
##GAME VARIABLES
################################################################################
var is_first_click: bool = true
var bomb_count: int = 0:
	set(value):
		bomb_count = value
		bombs.text = "Bombs: " + str(value)
		bombs.visible = true



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("tile_left_clicked", on_tile_left_clicked)
	camera.position = Vector2((GRID_DIM_X * GRID_FIELDSIZE_X) / 2,(GRID_DIM_Y * GRID_FIELDSIZE_Y) / 2 )
	start_game()


func start_game() -> void:
	construct_grid()
	install_tiles()


func construct_grid() -> void:
	for n in GRID_DIM_Y:
		var temp_row: Array = []
		for m in GRID_DIM_X:
			var x: int = m * GRID_FIELDSIZE_X
			var y: int = n * GRID_FIELDSIZE_Y
			temp_row.append([x, y])
		grid_pos.append(temp_row)


func install_tiles() -> void:
	for n in grid_pos.size():
		var temp_row: Array = []
		for pos in grid_pos[n]:
			var tile: TextureRect = TILE.instantiate()
			add_child(tile)
			tile.set("size_x", GRID_FIELDSIZE_X)
			tile.set("size_y", GRID_FIELDSIZE_Y)
			tile.x = pos[0]
			tile.y = pos[1]
			temp_row.append(tile)
		grid_tiles.append(temp_row)


func place_bombs(tile: TextureRect) -> void:
	var starter_fields: Array = find_near_fields(tile)
	var temp: int = 0
	for row in grid_tiles:
		for field in row:
			if starter_fields.has(field) or field == tile:
				continue
			var bomb_chance: int = randi_range(0, 100)
			if bomb_chance >= 20:
				field.set("is_bomb", false)
			else: 
				field.set("is_bomb", true)
				temp += 1
				#field.set("is_open", true)
	bomb_count = temp
	calc_near_bombs()


func calc_near_bombs() -> void:
	for row in grid_tiles:
		for field in row:
			var near_fields: Array = find_near_fields(field)
			var n: int = 0
			for near_field in near_fields:
				if near_field.get("is_bomb"):
					n += 1
			field.set("surrounding_bombs", n)
				

func find_near_fields(tile: TextureRect, only_not_open_fields: bool = false) -> Array:
	var field_row_index: int = 0
	var field_col_index: int = 0
	
	# find indices of clicked field
	for row_index in grid_tiles.size():
		for col_index in grid_tiles[row_index].size():
			if tile == grid_tiles[row_index][col_index]:
				field_row_index = row_index
				field_col_index = col_index
	
	#find surrounding fields (tiles)
	var fields: Array = []
	for n in 3:
		for m in 3:
			var new_row_index: int = field_row_index - 1 + n
			var new_col_index: int = field_col_index - 1 + m
			if new_row_index == field_row_index and new_col_index == field_col_index:
				continue
			if new_row_index < 0 or new_col_index < 0 or new_row_index >= GRID_DIM_Y or new_col_index >= GRID_DIM_X:
				continue
			if only_not_open_fields and grid_tiles[new_row_index][new_col_index].get("is_open"):
				continue
			fields.append(grid_tiles[new_row_index][new_col_index])

	return fields


func on_tile_left_clicked(tile: TextureRect) -> void:
	if is_first_click:
		is_first_click = false
		place_bombs(tile)
	if tile.get("is_bomb"):
		tile.modulate = Color.RED
		finish_game()
		return
	if tile.get("is_open"):
		solve_tile_when_fully_flagged(tile)
		return
	tile.set("is_open", true)
	if tile.get("surrounding_bombs") == 0:
		open_connected_zero_bomb_tiles(tile)


func solve_tile_when_fully_flagged(tile: TextureRect) -> void:
	var near_fields: Array = find_near_fields(tile, true)
	var flags: int = 0
	for field in near_fields:
		if field.get("is_marked"):
			flags += 1
	if flags == tile.get("surrounding_bombs"):
		for field in near_fields:
			if !field.get("is_marked"):
				field.set("is_open", true)
				if field.get("surrounding_bombs") == 0:
					open_connected_zero_bomb_tiles(field)
				if field.get("is_bomb"):
					field.modulate = Color.RED
					finish_game()
					return


func open_connected_zero_bomb_tiles(tile: TextureRect) -> void:
	var near_fields: Array = find_near_fields(tile, true)
	for field in near_fields:
		if !field.get("is_bomb"):
			field.set("is_open", true)
		if field.get("surrounding_bombs") == 0:
			open_connected_zero_bomb_tiles(field)


func finish_game() -> void:
	for row in grid_tiles:
		for field in row:
			if field.get("is_open"):
				continue
			field.set("is_open", true)
	canvas_layer.visible = true
	audio_stream_player_2d.play()
	var tween = get_tree().create_tween()
	tween.tween_property(die_screen, "modulate", Color(1,1,1,1), 2 )
	await tween.finished  

	await get_tree().create_timer(2).timeout  

	var tween2 = get_tree().create_tween()
	tween2.tween_property(die_screen, "modulate", Color(1,1,1,0), 2 )


func _input(event: InputEvent) -> void:
	if event.is_action("wheel_up"):
		camera.zoom += Vector2(0.1,0.1)
	elif event.is_action("wheel_down"):
		camera.zoom -= Vector2(0.1,0.1)


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

extends TextureRect

################################################################################
## NODES
################################################################################
const HIDDEN_TILE = preload("res://assets/hidden_tile.png")
const OPEN_TILE = preload("res://assets/open_tile.png")
const BOMB_TILE = preload("res://assets/bomb_tile.png")
################################################################################
## NODES
################################################################################
@onready var surrounding_bombs_number: Label = $SurroundingBombsNumber
@onready var bomb_mark: TextureRect = $BombMark


################################################################################
## TILE VARIABLES
################################################################################
var size_x: int = 32:
	get:
		return x
	set(value):
		x = value
		size.x = value
		surrounding_bombs_number.add_theme_font_size_override("font_size", value * 0.9)
var size_y: int = 32:
	get:
		return y
	set(value):
		y = value
		size.y = value
var x: int = 0:
	get:
		return x
	set(value):
		x = value
		position.x = value
var y: int = 0:
	get:
		return y
	set(value):
		y = value
		position.y = value
var surrounding_bombs: int = 0:
	get:
		return surrounding_bombs
	set(value):
		surrounding_bombs = value
		surrounding_bombs_number.text = str(value)
		if value == 1:
			surrounding_bombs_number.self_modulate = Color.BLUE
		elif value == 2:
			surrounding_bombs_number.modulate = Color.RED
		elif value == 3:
			surrounding_bombs_number.modulate = Color.GREEN
		elif value == 4:
			surrounding_bombs_number.modulate = Color.ORANGE
		elif value == 5:
			surrounding_bombs_number.modulate = Color.TEAL
		elif value == 6:
			surrounding_bombs_number.modulate = Color.DARK_ORCHID
		elif value == 7:
			surrounding_bombs_number.modulate = Color.PURPLE
var is_edge_tile: bool = false:
	get:
		return is_edge_tile
	set(value):
		is_edge_tile = value
var is_open: bool = false:
	set(value):
		if value:
			if is_bomb:
				texture = BOMB_TILE
			else:
				texture = OPEN_TILE
			is_open = value
			if surrounding_bombs > 0 and !is_bomb:
				surrounding_bombs_number.visible = value
var is_marked: bool = false:
	set(value):
		if value:
			bomb_mark.visible = true
		else:
			bomb_mark.visible = false
		is_marked = value
var is_bomb: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		surrounding_bombs_number.size.x = size_x
		surrounding_bombs_number.size.y = size_y
		bomb_mark.size.x = size_x
		bomb_mark.size.y = size_y


func toggle_bomb_mark() -> void:
	if is_marked:
		bomb_mark.visible = true
	else:
		bomb_mark.visible = false

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left"):
		EventBus.emit_signal("tile_left_clicked", self)
		print("left")
		return
	if event.is_action_pressed("mouse_right"):
		if !is_open:
			set("is_marked", !is_marked)
		return

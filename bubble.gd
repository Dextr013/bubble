# bubble.gd (исправленная версия)
extends Node2D

var color: Color = Color.WHITE
var velocity: Vector2 = Vector2.ZERO
var is_moving: bool = false
var is_shooter: bool = false
var speed: float = 800.0
var bubble_type: String = "normal" # "normal", "bomb", "block"

@onready var sprite = $Sprite2D

func _ready():
	set_bubble_scale(0.5)
	update_appearance()

func set_color(new_color: Color):
	color = new_color
	update_appearance()

func set_bubble_type(type: String):
	bubble_type = type
	update_appearance()

func set_bubble_scale(scale_value: float):
	scale = Vector2(scale_value, scale_value)

func update_appearance():
	if not sprite:
		return
	
	match bubble_type:
		"bomb":
			sprite.texture = load("res://assets/bubble/bomb.png")
		"block":
			sprite.texture = load("res://assets/bubble/blockbubble.png")
		_:
			if color == Color.RED:
				sprite.texture = load("res://assets/bubble/red.png")
			elif color == Color.GREEN:
				sprite.texture = load("res://assets/bubble/green.png")
			elif color == Color.YELLOW:
				sprite.texture = load("res://assets/bubble/yellow.png")
			elif color == Color.MAGENTA:
				sprite.texture = load("res://assets/bubble/violet.png")
			elif color == Color.ORANGE:
				sprite.texture = load("res://assets/bubble/orange.png")
			elif color == Color(1, 0.5, 0.8):
				sprite.texture = load("res://assets/bubble/pink.png")
			else:
				sprite.texture = load("res://assets/bubble/red.png")

func shoot(direction: Vector2):
	velocity = direction * speed
	is_moving = true

func stop():
	velocity = Vector2.ZERO
	is_moving = false

func _process(delta):
	if is_moving:
		position += velocity * delta

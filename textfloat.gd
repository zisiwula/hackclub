extends Sprite2D

@export var altura: float = 13.0
@export var velocidad: float = 2.5

var posicion_inicial: Vector2
var tiempo: float = 0.0

func _ready():
	posicion_inicial = position
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	tiempo += delta

	position.y = posicion_inicial.y + sin(tiempo * velocidad) * altura

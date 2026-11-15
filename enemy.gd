extends CharacterBody2D

@onready var detector_jugador: Area2D = $DetectorJugador
@export var velocidad: float = 60.0
@export var gravedad: float = 980.0
@export var distancia_adelante: float = 18.0
@export var largo_rayo: float = 25.0

var direccion: int = 1

@onready var detector_suelo: RayCast2D = $DetectorSuelo
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D



func _on_detector_jugador_area_entered(area: Area2D):

	var jugador = area.get_parent() as CharacterBody2D

	if jugador == null:
		return

	# Obtener la colisión principal del jugador
	var colision_principal = jugador.get_node_or_null("CollisionShape2D")

	if colision_principal == null:
		return

	print("morido")

	# Desactivar su colisión principal
	colision_principal.set_deferred("disabled", true)


func _ready():
	detector_jugador.area_entered.connect(_on_detector_jugador_area_entered)
	sprite.play("default")

func _physics_process(delta):

	# Aplicar gravedad
	if not is_on_floor():
		velocity.y += gravedad * delta
	else:
		velocity.y = 0

	# Comprobar si hay suelo delante
	detector_suelo.target_position = Vector2(
		distancia_adelante * direccion,
		largo_rayo
	)

	detector_suelo.force_raycast_update()

	# Cambiar de dirección si no hay suelo
	if is_on_floor() and not detector_suelo.is_colliding():
		cambiar_direccion()

	# Movimiento horizontal
	velocity.x = velocidad * direccion

	move_and_slide()

	# Cambiar de dirección al chocar con una pared
	if is_on_wall():
		cambiar_direccion()

	# Voltear el sprite
	sprite.flip_h = direccion < 0


func cambiar_direccion():
	direccion *= -1

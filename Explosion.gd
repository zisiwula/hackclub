extends Node2D

@export_group("Explosion")
@export var cantidad_pixeles: int = 120
@export var duracion: float = 4.0
@export var intervalo_rafaga: float = 0.03
@export var particulas_por_rafaga: int = 20

@export_group("Movimiento")
@export var velocidad_min: float = 500.0
@export var velocidad_max: float = 1500.0
@export var gravedad: float = 981.0
@export var rebote: float = 0.65
@export var collision_mask: int = 1

@export_group("Apariencia")
@export var tamano_pixel: float = 20.0
@export var longitud_estela: int = 10

var particulas: Array = []
var tiempo := 0.0
var acumulador := 0.0
var emitidas := 0

func _ready():
	randomize()
	
	emitir_rafaga()

func emitir_rafaga():
	var restantes = cantidad_pixeles - emitidas
	var cantidad = min(particulas_por_rafaga, restantes)
	
	for i in range(cantidad):
		var angulo = randf_range(0.0, TAU)
		var direccion = Vector2.RIGHT.rotated(angulo)
		
		particulas.append({
			"pos": Vector2.ZERO,
			"vel": direccion * randf_range(velocidad_min, velocidad_max),
			"tamano": randf_range(1.0, tamano_pixel),
			"vida": duracion,
			"estela": [],
			"color": Color(
				randf_range(0.55, 0.95),
				randf_range(0.0, 0.035),
				randf_range(0.04, 0.16)
			)
		})
	
	emitidas += cantidad

func _physics_process(delta):
	tiempo += delta
	acumulador += delta
	
	# Generar nuevas ráfagas
	if emitidas < cantidad_pixeles and acumulador >= intervalo_rafaga:
		acumulador = 0.0
		emitir_rafaga()
	
	var espacio = get_world_2d().direct_space_state
	
	for p in particulas:
		var siguiente = p.pos + p.vel * delta
		
		# Detectar colisiones mediante raycast
		var origen = to_global(p.pos)
		var destino = to_global(siguiente)
		
		var consulta = PhysicsRayQueryParameters2D.create(
			origen,
			destino,
			collision_mask
		)
		
		consulta.collide_with_areas = true
		
		var choque = espacio.intersect_ray(consulta)
		
		if not choque.is_empty():
			var normal = global_transform.basis_xform_inv(
				choque.normal
			).normalized()
			
			p.pos = to_local(choque.position) + normal * 1.5
			
			# Rebote
			p.vel = p.vel.bounce(normal) * rebote
			
		else:
			p.pos = siguiente
		
		# Gravedad
		p.vel.y += gravedad * delta
		
		# Guardar posiciones para las estelas
		p.estela.push_front(p.pos)
		
		if p.estela.size() > longitud_estela:
			p.estela.pop_back()
		
		p.vida -= delta
	
	# Eliminar partículas agotadas
	for i in range(particulas.size() - 1, -1, -1):
		if particulas[i].vida <= 0:
			particulas.remove_at(i)
	
	queue_redraw()
	
	if tiempo >= duracion or particulas.is_empty():
		queue_free()

func _draw():
	for p in particulas:
		var alpha = clamp(p.vida / duracion, 0.0, 1.0)
		
		# Dibujar estela
		for i in range(p.estela.size()):
			var factor = 1.0 - float(i + 1) / (longitud_estela + 1)
			var tamano = p.tamano * factor
			
			draw_rect(
				Rect2(
					p.estela[i],
					Vector2.ONE * tamano
				),
				Color(p.color, alpha * factor)
			)
		
		# Dibujar píxel principal
		draw_rect(
			Rect2(p.pos, Vector2.ONE * p.tamano),
			Color(p.color, alpha)
		)

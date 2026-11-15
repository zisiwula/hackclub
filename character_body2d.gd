extends CharacterBody2D

const speed = 300.0
const jump_velocity = -1000.0

const rotation_acceleration = 860.0
const rotation_deceleration = 1250.0
const max_rotation_speed = 280.0

const rot_impulse_multiplier = 12.0
const max_rot_impulse = 1800.0
const max_horizontal_speed = 2200.0

const zero_angle_limit = 3.0
const horizontal_deceleration = 500.0

const wall_jump_horizontal_speed = 850.0
const wall_jump_vertical_speed = 1100.0
const wall_jump_angle_tolerance = 70.0
const wall_bounce_min_speed = 350.0

const fly_speed = 700.0
const fly_acceleration = 1800.0

const respawn_position = Vector2.ZERO

var sore = 0
var to_points = 0

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $CollisionShape2D
@onready var pre_jump_sound = $PreJumpSound
@onready var jump_sound = $JumpSound
@onready var smoke = get_parent().get_node("SmokeParticles")
@onready var coll = $CollideSound
@onready var coll_part = get_parent().get_node("CollideParticles")
@onready var points = get_parent().get_node("SeePoints")
@onready var score_sound = $Score
@onready var camera = $Camera2D
@onready var exp_s = $Explosion

var can_lose = true

var current_rot = 0.0
var rotation_speed = 0.0
var last_angle = 0.0

var can_imp = true
var wall_jump_locked = false
var is_flying = false

func _show_score():
	score_sound.play()
	points.visible = true
	points.global_position = hitbox.global_position
	for i in range(1,3):
		await get_tree().create_timer(0.01).timeout
		points.position.y -= 32
	for i in range(1,4):
		await get_tree().create_timer(0.01).timeout
		points.position.y -= 16
	for i in range(1,5):
		await get_tree().create_timer(0.01).timeout
		points.position.y -= 8
	for i in range(1,6):
		await get_tree().create_timer(0.01).timeout
		points.position.y -= 4
	for i in range(1,6):
		await get_tree().create_timer(0.01).timeout
		points.position.y -= 2
	await get_tree().create_timer(0.3).timeout
	points.visible = false

func _smooth(normal, bounce):
	print("discarded", normal, bounce)
#	can_imp = false
#	for i in range(1,5):
#		await get_tree().create_timer(0.01).timeout
#		current_rot += (normal.x * (bounce/5))/6
#	for i in range(1,6):
#		await get_tree().create_timer(0.01).timeout
#		current_rot += (normal.x * (bounce/5))/25
#	for i in range(1,7):
#		await get_tree().create_timer(0.01).timeout
#		current_rot += (normal.x * (bounce/5))/50
#	await get_tree().create_timer(0.05).timeout
#	can_imp = true

func _is_base_wall_contact(collision):
	if hitbox.shape == null:
		return false

	var shape_rect = hitbox.shape.get_rect()
	var contact_local = hitbox.to_local(collision.get_position())
	var base_local = Vector2(shape_rect.position.x + shape_rect.size.x / 2.0, shape_rect.position.y + shape_rect.size.y)

	var tolerance = maxf(shape_rect.size.x * 1.5, 12.0)
	var near_base = contact_local.distance_to(base_local) <= tolerance

	var base_direction = Vector2.DOWN.rotated(hitbox.global_rotation).normalized()
	var toward_wall = -collision.get_normal().normalized()
	var angle_ok = base_direction.dot(toward_wall) >= cos(deg_to_rad(wall_jump_angle_tolerance))

	return near_base and angle_ok


func _get_wall_collision():
	var fallback = null

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)

		if absf(collision.get_normal().x) < 0.7:
			continue

		if _is_base_wall_contact(collision):
			return collision

		if fallback == null:
			fallback = collision

	return fallback


func _set_impulse(wall_normal: Vector2 = Vector2.ZERO) -> void:
	if not can_imp or is_flying:
		return
	
	
	can_imp = false

	var stand_vel = velocity
	var is_wall_jump = wall_normal != Vector2.ZERO
	var angle = wrapf(current_rot, -180.0, 180.0)
	var forward = Vector2.UP.rotated(deg_to_rad(current_rot))

	var impulse_magnitude = clampf(absf(current_rot) * rot_impulse_multiplier, 0.0, max_rot_impulse)
	var the_rot = forward.x * impulse_magnitude

	var new_direction = signf(forward.x)

	if absf(forward.x) < 0.001:
		new_direction = 0.0

	var previous_direction = signf(stand_vel.x)
	var moving_to_zero = last_angle != 0.0 and signf(angle) == signf(last_angle) and absf(angle) < absf(last_angle)

	print("angle: ", current_rot)
	print("impulse: ", the_rot)

	sprite.play("Impulse")
	pre_jump_sound.play()

	# Vector3.new() god Vector2.ZERO zzz
	velocity = Vector2.ZERO

	await get_tree().create_timer(0.195).timeout

	if is_flying:
		can_imp = true
		return

	if is_wall_jump:
		velocity.x = wall_normal.x * wall_jump_horizontal_speed
		velocity.y = -wall_jump_vertical_speed
	else:
		velocity.y = jump_velocity

		if new_direction == 0.0:
			velocity.x = stand_vel.x

		elif previous_direction == 0.0:
			velocity.x = clampf(stand_vel.x + the_rot, -max_horizontal_speed, max_horizontal_speed)

		elif previous_direction != new_direction:
			velocity.x = clampf(the_rot, -max_horizontal_speed, max_horizontal_speed)

		elif moving_to_zero:
			var reduction = clampf(absf(angle) / maxf(absf(last_angle), 0.001), 0.0, 1.0)
			velocity.x = stand_vel.x * reduction

		else:
			velocity.x = clampf(stand_vel.x + the_rot, -max_horizontal_speed, max_horizontal_speed)

		last_angle = angle

	jump_sound.play()
	smoke.visible = true
	smoke.global_position = hitbox.global_position
	smoke.rotation = hitbox.rotation
	smoke.play("default")
	
	to_points = 0

	# 676767
	print("speed: ", velocity)

	await get_tree().create_timer(0.075).timeout
	can_imp = true

const EXPLOSION = preload("res://Explosion.tscn")

func crear_explosion():
	var explosion = EXPLOSION.instantiate()
	var escena = get_tree().current_scene
	
	escena.add_child(explosion)
	
	explosion.global_position = global_position

func _return_to_origin():
	if not can_lose:
		return
	to_points = 0
	can_lose = false
	print("lose")
	
	exp_s.play()
	
	hitbox.disabled = true
	
	can_imp = false
	sprite.visible = false
	
	crear_explosion()
	
	for i in range(1,36):
		await get_tree().create_timer(0.01).timeout
		camera.position.x += randi_range(-35, 35)
		camera.position.y += randi_range(-35, 35)
	camera.position.x = 0
	camera.position.y = 0
	
	await get_tree().create_timer(1).timeout
	
	global_position = respawn_position
	velocity = Vector2.ZERO
	current_rot = 0.0
	rotation_speed = 0.0
	last_angle = 0.0
	
	sprite.rotation_degrees = 0.0
	hitbox.rotation_degrees = 0.0
	
	wall_jump_locked = false
	sprite.visible = true
	can_lose = true
	hitbox.disabled = false
	
	await get_tree().create_timer(0.5).timeout
	
	can_imp = true


func _physics_process(delta: float) -> void:
	if hitbox.disabled:
		_return_to_origin()
		return
	
	if global_position.y > 2000:
		_return_to_origin()
		return
	
	if not can_lose:
		return
	
	if Input.is_physical_key_pressed(KEY_T):
		is_flying = not is_flying
		print("in_fly: ", is_flying)
	
		if is_flying:
			wall_jump_locked = false
			velocity.y = 0.0
	
	var direction = 0.0
	
	if Input.is_key_pressed(KEY_A):
		direction -= 1.0
	
	if Input.is_key_pressed(KEY_D):
		direction += 1.0
	
	if direction == 0.0:
		rotation_speed = move_toward(rotation_speed, 0.0, rotation_deceleration * delta)
	else:
		rotation_speed = move_toward(rotation_speed, direction * max_rotation_speed, rotation_acceleration * delta)
	
	current_rot += rotation_speed * delta
	to_points += rotation_speed * delta
	
	if abs(to_points) >= 300:
		to_points = 0
		sore += 100
		print("sore: ", sore)
		_show_score()
	
	while current_rot >= 360.0:
		current_rot -= 360.0
	
	while current_rot <= -360.0:
		current_rot += 360.0
	
	hitbox.rotation_degrees = current_rot
	sprite.rotation_degrees = current_rot
	
	if is_flying:
		var fly_direction = 0.0
		
		if Input.is_key_pressed(KEY_W):
			fly_direction += 1.0
		if Input.is_key_pressed(KEY_S):
			fly_direction -= 1.0
		var forward = Vector2.UP.rotated(deg_to_rad(current_rot))
		var target_velocity = forward * fly_direction * fly_speed
		
		velocity = velocity.move_toward(target_velocity, fly_acceleration * delta)
		
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			var landing_angle = wrapf(current_rot, -180.0, 180.0)
			if can_imp:
				print("lands: ", landing_angle)
			if absf(landing_angle) >= 80.0:
				_return_to_origin()
				return
			elif can_imp:
				_set_impulse()
		if absf(current_rot) <= zero_angle_limit:
			velocity.x = move_toward(velocity.x, 0.0, horizontal_deceleration * delta)
	var velocity_before_move = velocity
	
	move_and_slide()
	
	if not is_flying:
		var wall_collision = _get_wall_collision()
		
		if wall_collision != null and not is_on_floor():
			if not wall_jump_locked:
				wall_jump_locked = true
				if _is_base_wall_contact(wall_collision):
					print("wall")
					_set_impulse(wall_collision.get_normal())
				else:
					var wall_normal = wall_collision.get_normal()
					var bounce_speed = maxf(absf(velocity_before_move.x), wall_bounce_min_speed)
					coll.play()
					velocity.x = wall_normal.x * (bounce_speed/5)
					print("boing: ", velocity.x)
					coll_part.visible = true
					coll_part.global_position = hitbox.global_position
					coll_part.rotation = hitbox.rotation-90
					coll_part.play("default")
					_smooth(wall_normal, bounce_speed)
		else:
			wall_jump_locked = false
	else:
		wall_jump_locked = false
		
	# mandarina embolsada

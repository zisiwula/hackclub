extends Node

@onready var sonido = $"../Start"
@onready var icon = $"../Icon"
@onready var texto = $"../Text"

var juego_iniciado = false


func _ready():
	# Este controlador funciona incluso cuando el juego está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	sonido.process_mode = Node.PROCESS_MODE_ALWAYS

	# Pausar el juego al iniciar
	get_tree().paused = true

	print("presiona enter amiguito")


func _input(event):

	# PAUSAR Y REANUDAR CON ESC
	if event.is_action_pressed("ui_cancel") and juego_iniciado:
		
		get_tree().paused = not get_tree().paused
		get_tree().current_scene.get_node("PauseScreen").global_position = get_tree().current_scene.get_node("CharacterBody2D").get_node("CollisionShape2D").global_position
		get_tree().current_scene.get_node("PauseScreen").visible = get_tree().paused
		if get_tree().paused:
			print("pausacion")
		else: #como hace el juego para pausarse sin que la pausa se pause?
			print("despausacion")

		get_viewport().set_input_as_handled()
		return


	# INICIAR EL JUEGO CON ENTER
	if event is InputEventKey:
		if event.pressed and not event.echo:

			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:

				if not juego_iniciado:
					juego_iniciado = true

					sonido.play()

					get_tree().paused = false

					print("start")
					
					icon.set_script(null)
					texto.set_script(null)
					
					for i in range(1,15):
						await get_tree().create_timer(0.01).timeout
						icon.global_position.y += 12
						texto.global_position.y += 12
					for i in range(1,15):
						await get_tree().create_timer(0.01).timeout
						icon.global_position.y += 5
						texto.global_position.y += 5
					for i in range(1,35):
						await get_tree().create_timer(0.01).timeout
						icon.global_position.y -= 80
						texto.global_position.y -= 80

					icon.visible = false
					texto.visible = false

					get_viewport().set_input_as_handled()

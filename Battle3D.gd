
extends Node3D

# ==========================================
# WSC BATTLE 4.0
# ARENE 3D - CONTROLE CLAVIER
# GODOT 4.0
# ==========================================

const ARENA_LIMIT := 3.5
const MOVE_DURATION := 1.5

const MOVE_POINTS := {
	"toprock": 10,
	"footwork": 15,
	"powermove": 25,
	"freeze": 20,
	"windmill": 30
}

var player: Node3D
var opponent: Node3D

var player_label: Label3D
var opponent_label: Label3D
var info_label: Label3D

var player_score := 0
var opponent_score := 0

var player_move := "idle"
var opponent_move := "idle"

var player_move_time := 0.0
var opponent_move_time := 0.0
var opponent_timer := 0.0

var player_base_position := Vector3(-2.0, 0.0, 0.0)
var opponent_base_position := Vector3(2.0, 0.0, 0.0)

var player_base_rotation := 0.0
var opponent_base_rotation := PI


func _ready() -> void:
	randomize()

	_create_arena()

	player = _create_dancer(
		player_base_position,
		Color(0.05, 0.4, 1.0),
		"JOUEUR"
	)

	opponent = _create_dancer(
		opponent_base_position,
		Color(1.0, 0.15, 0.08),
		"ADVERSAIRE"
	)

	player.rotation.y = player_base_rotation
	opponent.rotation.y = opponent_base_rotation

	_create_hud()

	print("WSC BATTLE 4.0 : ARÈNE PRÊTE")


func _process(delta: float) -> void:
	_update_player(delta)
	_update_opponent(delta)
	_update_hud()


# ==========================================
# COMMANDES CLAVIER
# ==========================================

func _unhandled_input(event: InputEvent) -> void:

	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	match event.keycode:

		KEY_1:
			_play_player_move("toprock")

		KEY_2:
			_play_player_move("footwork")

		KEY_3:
			_play_player_move("powermove")

		KEY_4:
			_play_player_move("freeze")

		KEY_5:
			_play_player_move("windmill")


# ==========================================
# CREATION DE L'ARENE
# ==========================================

func _create_arena() -> void:

	# Sol principal
	var floor_mesh := MeshInstance3D.new()
	var floor_shape := BoxMesh.new()

	floor_shape.size = Vector3(12.0, 0.2, 8.0)

	floor_mesh.mesh = floor_shape
	floor_mesh.position.y = -0.15
	floor_mesh.material_override = _make_material(
		Color(0.025, 0.035, 0.065)
	)

	add_child(floor_mesh)

	# Cercle central
	var circle := MeshInstance3D.new()
	var circle_mesh := CylinderMesh.new()

	circle_mesh.top_radius = 3.2
	circle_mesh.bottom_radius = 3.2
	circle_mesh.height = 0.035

	circle.mesh = circle_mesh
	circle.position.y = -0.035
	circle.material_override = _make_material(
		Color(0.10, 0.13, 0.21)
	)

	add_child(circle)

	# Bordures lumineuses
	_create_box(
		Vector3(0, 0.02, -3.8),
		Vector3(10, 0.08, 0.08),
		Color(1.0, 0.65, 0.05)
	)

	_create_box(
		Vector3(0, 0.02, 3.8),
		Vector3(10, 0.08, 0.08),
		Color(1.0, 0.65, 0.05)
	)

	_create_box(
		Vector3(-5.0, 0.02, 0),
		Vector3(0.08, 0.08, 7.6),
		Color(1.0, 0.65, 0.05)
	)

	_create_box(
		Vector3(5.0, 0.02, 0),
		Vector3(0.08, 0.08, 7.6),
		Color(1.0, 0.65, 0.05)
	)

	# Lumière générale
	var light := DirectionalLight3D.new()

	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 1.3

	add_child(light)

	# Projecteurs
	_add_spotlight(
		Vector3(-3, 6, 1),
		Color(0.1, 0.35, 1.0)
	)

	_add_spotlight(
		Vector3(3, 6, -1),
		Color(1.0, 0.12, 0.08)
	)

	# Caméra
	var camera := Camera3D.new()

	camera.position = Vector3(0, 5.2, 11.5)
	camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	camera.current = true

	add_child(camera)

	# Environnement
	var world := WorldEnvironment.new()
	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.008, 0.012, 0.03)

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.5, 0.5, 0.65)
	environment.ambient_light_energy = 0.7

	world.environment = environment

	add_child(world)


func _create_box(
	pos: Vector3,
	size: Vector3,
	color: Color
) -> void:

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = size

	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _make_material(color)

	add_child(mesh_instance)


func _add_spotlight(
	pos: Vector3,
	color: Color
) -> void:

	var light := SpotLight3D.new()

	light.position = pos
	light.look_at(Vector3.ZERO, Vector3.UP)

	light.light_color = color
	light.light_energy = 3.0
	light.spot_range = 12.0
	light.spot_angle = 45.0

	add_child(light)


func _make_material(color: Color) -> StandardMaterial3D:

	var material := StandardMaterial3D.new()

	material.albedo_color = color
	material.roughness = 0.65

	return material


# ==========================================
# CREATION DES DANSEURS
# ==========================================

func _create_dancer(
	pos: Vector3,
	color: Color,
	dancer_name: String
) -> Node3D:

	var root := Node3D.new()

	root.position = pos

	add_child(root)

	var body_material := _make_material(color)
	var dark_material := _make_material(
		Color(0.025, 0.03, 0.045)
	)
	var skin_material := _make_material(
		Color(0.75, 0.48, 0.32)
	)

	# Torse
	_add_capsule(
		root,
		Vector3(0, 1.25, 0),
		Vector3(0.65, 0.8, 0.4),
		body_material
	)

	# Tête
	_add_sphere(
		root,
		Vector3(0, 2.25, 0),
		Vector3(0.32, 0.32, 0.32),
		skin_material
	)

	# Bras
	_add_capsule(
		root,
		Vector3(-0.52, 1.45, 0),
		Vector3(0.22, 0.62, 0.22),
		body_material,
		Vector3(0, 0, -35)
	)

	_add_capsule(
		root,
		Vector3(0.52, 1.45, 0),
		Vector3(0.22, 0.62, 0.22),
		body_material,
		Vector3(0, 0, 35)
	)

	# Jambes
	_add_capsule(
		root,
		Vector3(-0.2, 0.48, 0),
		Vector3(0.25, 0.65, 0.25),
		dark_material
	)

	_add_capsule(
		root,
		Vector3(0.2, 0.48, 0),
		Vector3(0.25, 0.65, 0.25),
		dark_material
	)

	# Pieds
	_add_box_to(
		root,
		Vector3(-0.2, 0.12, 0.12),
		Vector3(0.35, 0.16, 0.55),
		dark_material
	)

	_add_box_to(
		root,
		Vector3(0.2, 0.12, 0.12),
		Vector3(0.35, 0.16, 0.55),
		dark_material
	)

	# Nom au-dessus du danseur
	var name_tag := Label3D.new()

	name_tag.text = dancer_name
	name_tag.position = Vector3(0, 2.8, 0)
	name_tag.font_size = 48
	name_tag.pixel_size = 0.005
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	root.add_child(name_tag)

	return root


func _add_capsule(
	parent: Node3D,
	pos: Vector3,
	part_scale: Vector3,
	material: Material,
	rot: Vector3 = Vector3.ZERO
) -> void:

	var part := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()

	mesh.radius = 0.25
	mesh.height = 1.0

	part.mesh = mesh
	part.position = pos
	part.scale = part_scale
	part.rotation_degrees = rot
	part.material_override = material

	parent.add_child(part)


func _add_sphere(
	parent: Node3D,
	pos: Vector3,
	part_scale: Vector3,
	material: Material
) -> void:

	var part := MeshInstance3D.new()
	var mesh := SphereMesh.new()

	part.mesh = mesh
	part.position = pos
	part.scale = part_scale
	part.material_override = material

	parent.add_child(part)


func _add_box_to(
	parent: Node3D,
	pos: Vector3,
	size: Vector3,
	material: Material
) -> void:

	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = size

	part.mesh = mesh
	part.position = pos
	part.material_override = material

	parent.add_child(part)


# ==========================================
# MOUVEMENTS DU JOUEUR
# ==========================================

func _play_player_move(move_name: String) -> void:

	if player_move_time > 0.0:
		return

	player_move = move_name
	player_move_time = MOVE_DURATION

	player_score += int(MOVE_POINTS[move_name])

	print(
		"JOUEUR : ",
		move_name,
		" +",
		MOVE_POINTS[move_name],
		" points"
	)


func _play_opponent_move(move_name: String) -> void:

	opponent_move = move_name
	opponent_move_time = MOVE_DURATION

	opponent_score += int(MOVE_POINTS[move_name])

	print(
		"ADVERSAIRE : ",
		move_name,
		" +",
		MOVE_POINTS[move_name],
		" points"
	)


# ==========================================
# MISE A JOUR DU JOUEUR
# ==========================================

func _update_player(delta: float) -> void:

	player_move_time = maxf(
		0.0,
		player_move_time - delta
	)

	var direction := Vector3.ZERO

	if Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0

	if Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0

	if Input.is_key_pressed(KEY_UP):
		direction.z -= 1.0

	if Input.is_key_pressed(KEY_DOWN):
		direction.z += 1.0

	player.position += direction.normalized() * delta * 3.0

	player.position.x = clampf(
		player.position.x,
		-ARENA_LIMIT,
		-0.5
	)

	player.position.z = clampf(
		player.position.z,
		-2.5,
		2.5
	)

	_animate_dancer(
		player,
		player_move,
		player_move_time,
		player_base_rotation
	)


# ==========================================
# INTELLIGENCE ARTIFICIELLE PROVISOIRE
# ==========================================

func _update_opponent(delta: float) -> void:

	opponent_move_time = maxf(
		0.0,
		opponent_move_time - delta
	)

	opponent_timer += delta

	if opponent_timer >= 2.5:

		opponent_timer = 0.0

		var moves: Array[String] = [
			"toprock",
			"footwork",
			"powermove",
			"freeze",
			"windmill"
		]

		var random_move: String = moves[
			randi() % moves.size()
		]

		_play_opponent_move(random_move)

	_animate_dancer(
		opponent,
		opponent_move,
		opponent_move_time,
		opponent_base_rotation
	)


# ==========================================
# ANIMATIONS PROVISOIRES
# ==========================================

func _animate_dancer(
	dancer: Node3D,
	move_name: String,
	remaining: float,
	base_rotation: float
) -> void:

	var phase := float(Time.get_ticks_msec()) / 1000.0

	var strength := clampf(
		remaining / MOVE_DURATION,
		0.0,
		1.0
	)

	dancer.rotation.x = 0.0
	dancer.rotation.z = 0.0
	dancer.rotation.y = base_rotation

	dancer.position.y = 0.0

	match move_name:

		"toprock":
			dancer.position.y = absf(
				sin(phase * 9.0)
			) * 0.25 * strength

			dancer.rotation.z = sin(
				phase * 7.0
			) * 0.18 * strength

		"footwork":
			dancer.position.y = 0.12 * strength

			dancer.rotation.x = sin(
				phase * 12.0
			) * 0.35 * strength

			dancer.rotation.z = sin(
				phase * 10.0
			) * 0.25 * strength

		"powermove":
			dancer.position.y = 0.25 * strength

			dancer.rotation.y = base_rotation + (
				phase * 7.0 * strength
			)

		"freeze":
			dancer.position.y = -0.15 * strength
			dancer.rotation.z = -0.65 * strength
			dancer.rotation.x = 0.25 * strength

		"windmill":
			dancer.position.y = -0.25 * strength

			dancer.rotation.x = sin(
				phase * 10.0
			) * 0.8 * strength

			dancer.rotation.z = cos(
				phase * 10.0
			) * 0.8 * strength

		_:
			dancer.position.y = absf(
				sin(phase * 2.0)
			) * 0.04


# ==========================================
# AFFICHAGE DES SCORES
# ==========================================

func _create_hud() -> void:

	player_label = _create_label(
		"JOUEUR : 0",
		Vector3(-3.0, 4.0, 0),
		Color(0.2, 0.65, 1.0)
	)

	opponent_label = _create_label(
		"ADVERSAIRE : 0",
		Vector3(1.2, 4.0, 0),
		Color(1.0, 0.3, 0.2)
	)

	info_label = _create_label(
		"1 TOPROCK | 2 FOOTWORK | 3 POWERMOVE | 4 FREEZE | 5 WINDMILL",
		Vector3(-4.5, 3.4, 0),
		Color(1.0, 0.8, 0.2)
	)


func _create_label(
	label_text: String,
	pos: Vector3,
	color: Color
) -> Label3D:

	var label := Label3D.new()

	label.text = label_text
	label.position = pos
	label.font_size = 40
	label.pixel_size = 0.006
	label.modulate = color

	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	add_child(label)

	return label


func _update_hud() -> void:

	player_label.text = "JOUEUR : " + str(player_score)

	opponent_label.text = (
		"ADVERSAIRE : " + str(opponent_score)
	)

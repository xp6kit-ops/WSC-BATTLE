
extends Control

# ==========================================
# WSC BATTLE - BATTLE EN LIGNE
# 2 JOUEURS + 3 JUGES
# GODOT 4.0
# ==========================================

var score_joueur_1 := 0
var score_joueur_2 := 0
var temps_restant := 60
var battle_en_cours := false

var score_label: Label
var chrono_label: Label
var statut_label: Label
var camera_1_label: Label
var camera_2_label: Label
var juge_labels: Array[Label] = []

var battle_timer: Timer


func _ready() -> void:
	creer_interface()
	creer_timer()
	afficher_scores()


# ==========================================
# INTERFACE GENERALE
# ==========================================

func creer_interface() -> void:

	var fond := ColorRect.new()
	fond.color = Color("#080D19")
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 24)
	marge.add_theme_constant_override("margin_right", 24)
	marge.add_theme_constant_override("margin_top", 18)
	marge.add_theme_constant_override("margin_bottom", 18)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	marge.add_child(colonne)

	# TITRE
	var titre := Label.new()
	titre.text = "WSC BATTLE"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 38)
	titre.add_theme_color_override("font_color", Color("#20B9FF"))
	colonne.add_child(titre)

	var sous_titre := Label.new()
	sous_titre.text = "BATTLE EN LIGNE"
	sous_titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sous_titre.add_theme_font_size_override("font_size", 15)
	sous_titre.add_theme_color_override("font_color", Color.WHITE)
	colonne.add_child(sous_titre)

	# DEUX CAMERAS
	var cameras := HBoxContainer.new()
	cameras.add_theme_constant_override("separation", 16)
	cameras.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(cameras)

	camera_1_label = creer_fenetre_camera(
		cameras,
		"JOUEUR 1",
		Color("#087EFF")
	)

	camera_2_label = creer_fenetre_camera(
		cameras,
		"JOUEUR 2",
		Color("#FF385C")
	)

	# SCORES
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	colonne.add_child(score_label)

	# CHRONOMETRE
	chrono_label = Label.new()
	chrono_label.text = "01:00"
	chrono_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chrono_label.add_theme_font_size_override("font_size", 42)
	chrono_label.add_theme_color_override("font_color", Color("#20B9FF"))
	colonne.add_child(chrono_label)

	# JURY
	var titre_jury := Label.new()
	titre_jury.text = "JURY OFFICIEL - 3 JUGES"
	titre_jury.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre_jury.add_theme_font_size_override("font_size", 21)
	titre_jury.add_theme_color_override("font_color", Color("#FFC857"))
	colonne.add_child(titre_jury)

	var jury := HBoxContainer.new()
	jury.add_theme_constant_override("separation", 12)
	colonne.add_child(jury)

	for numero in range(1, 4):
		var juge := creer_carte_juge(jury, numero)
		juge_labels.append(juge)

	# STATUT
	statut_label = Label.new()
	statut_label.text = "EN ATTENTE DES PARTICIPANTS"
	statut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	statut_label.add_theme_font_size_override("font_size", 16)
	statut_label.add_theme_color_override("font_color", Color("#20B9FF"))
	colonne.add_child(statut_label)

	# BOUTONS
	var boutons := HBoxContainer.new()
	boutons.alignment = BoxContainer.ALIGNMENT_CENTER
	boutons.add_theme_constant_override("separation", 15)
	colonne.add_child(boutons)

	var commencer := Button.new()
	commencer.text = "LANCER LE BATTLE"
	commencer.custom_minimum_size = Vector2(200, 48)
	commencer.pressed.connect(lancer_battle)
	boutons.add_child(commencer)

	var terminer := Button.new()
	terminer.text = "TERMINER"
	terminer.custom_minimum_size = Vector2(160, 48)
	terminer.pressed.connect(terminer_battle)
	boutons.add_child(terminer)


# ==========================================
# FENETRES VIDEO
# ==========================================

func creer_fenetre_camera(
	parent: HBoxContainer,
	nom: String,
	couleur: Color
) -> Label:

	var carte := PanelContainer.new()
	carte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	carte.size_flags_vertical = Control.SIZE_EXPAND_FILL
	carte.add_theme_stylebox_override(
		"panel",
		creer_style(couleur.darkened(0.65))
	)
	parent.add_child(carte)

	var contenu := VBoxContainer.new()
	contenu.alignment = BoxContainer.ALIGNMENT_CENTER
	contenu.add_theme_constant_override("separation", 12)
	carte.add_child(contenu)

	var titre := Label.new()
	titre.text = nom
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 24)
	titre.add_theme_color_override("font_color", couleur)
	contenu.add_child(titre)

	var icone := Label.new()
	icone.text = "CAMERA"
	icone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icone.add_theme_font_size_override("font_size", 36)
	contenu.add_child(icone)

	var statut := Label.new()
	statut.text = "EN ATTENTE DE CONNEXION"
	statut.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	statut.add_theme_color_override("font_color", Color.WHITE)
	contenu.add_child(statut)

	return statut


# ==========================================
# CARTES DES TROIS JUGES
# ==========================================

func creer_carte_juge(
	parent: HBoxContainer,
	numero: int
) -> Label:

	var carte := PanelContainer.new()
	carte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	carte.add_theme_stylebox_override(
		"panel",
		creer_style(Color("#202B40"))
	)
	parent.add_child(carte)

	var contenu := VBoxContainer.new()
	contenu.alignment = BoxContainer.ALIGNMENT_CENTER
	carte.add_child(contenu)

	var titre := Label.new()
	titre.text = "JUGE " + str(numero)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 19)
	titre.add_theme_color_override("font_color", Color("#FFC857"))
	contenu.add_child(titre)

	var statut := Label.new()
	statut.text = "EN ATTENTE"
	statut.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	statut.add_theme_font_size_override("font_size", 13)
	contenu.add_child(statut)

	return statut


# ==========================================
# STYLE DES CARTES
# ==========================================

func creer_style(couleur: Color) -> StyleBoxFlat:

	var style := StyleBoxFlat.new()
	style.bg_color = couleur
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12

	return style


# ==========================================
# CHRONOMETRE
# ==========================================

func creer_timer() -> void:

	battle_timer = Timer.new()
	battle_timer.wait_time = 1.0
	battle_timer.timeout.connect(actualiser_chronometre)
	add_child(battle_timer)


func lancer_battle() -> void:

	if battle_en_cours:
		return

	temps_restant = 60
	battle_en_cours = true

	statut_label.text = "BATTLE EN COURS !"

	afficher_chronometre()
	battle_timer.start()


func actualiser_chronometre() -> void:

	temps_restant -= 1
	afficher_chronometre()

	if temps_restant <= 0:
		terminer_battle()


func afficher_chronometre() -> void:

	var minutes := int(temps_restant / 60)
	var secondes := temps_restant % 60

	chrono_label.text = "%02d:%02d" % [minutes, secondes]


func terminer_battle() -> void:

	battle_timer.stop()
	battle_en_cours = false

	if score_joueur_1 > score_joueur_2:
		statut_label.text = "VICTOIRE DU JOUEUR 1 !"
	elif score_joueur_2 > score_joueur_1:
		statut_label.text = "VICTOIRE DU JOUEUR 2 !"
	else:
		statut_label.text = "EGALITE !"

	print("BATTLE TERMINE")
	afficher_scores()


# ==========================================
# SCORES
# ==========================================

func afficher_scores() -> void:

	if score_label != null:
		score_label.text = (
			"JOUEUR 1 : %d       VS       JOUEUR 2 : %d"
			% [score_joueur_1, score_joueur_2]
		)


func ajouter_points(joueur: int, points: int) -> void:

	if joueur == 1:
		score_joueur_1 += points

	elif joueur == 2:
		score_joueur_2 += points

	afficher_scores()

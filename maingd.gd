
extends Control

# ==================================================
# WSC BATTLE 3.2
# Godot 4.0
# Windows + Android
# Matchmaking automatique par niveau
# ==================================================

const LOGO_PATH = "res://assets/images/wsc_battle_logo.png"

# SERVEUR LOCAL PC + ANDROID
const SERVER_URL = "ws://192.168.1.99:3000"
const CONNECTION_TIMEOUT = 10000

# COULEURS
const BG = Color("#0B0D14")
const SIDEBAR = Color("#121622")
const CARD = Color("#191F2E")
const CARD_LIGHT = Color("#242D40")
const GOLD = Color("#F5B928")
const GOLD_DARK = Color("#B98517")
const BLUE = Color("#168BFF")
const RED = Color("#EF4444")
const WHITE = Color("#FFFFFF")
const GREY = Color("#AAB1C5")
const GREEN = Color("#36D399")

# INTERFACE
var page_body: VBoxContainer
var page_title: Label
var dialog: AcceptDialog
var logo_texture: Texture2D

var current_page = "Accueil"

# CONNEXION
var webrtc_available = false
var websocket_available = false
var matchmaking_socket: WebSocketPeer
var matchmaking_active = false
var matchmaking_request_sent = false
var matchmaking_connected = false
var matchmaking_started_at = 0

# PROFIL
var player_name = "Danseur"
var player_level = 10

# MATCHMAKING
var match_discipline = "Breakdance"
var match_status_label: Label
var match_button: Button
var opponent_level = 0
var opponent_id = ""

# STATISTIQUES
var total_battles = 0
var total_wins = 0
var total_losses = 0

# BATTLE
var opponent_name = ""
var selected_discipline = ""
var selected_level = ""
var current_round = 0
var player_round_wins = 0
var opponent_round_wins = 0
var battle_active = false


# ==================================================
# DEMARRAGE
# ==================================================

func _ready():

	print("================================")
	print("WSC BATTLE 3.2")
	print("================================")

	webrtc_available = ClassDB.class_exists(
		"WebRTCPeerConnection"
	)

	websocket_available = ClassDB.class_exists(
		"WebSocketPeer"
	)

	print("WebRTC : ", webrtc_available)
	print("WebSocket : ", websocket_available)
	print("Serveur : ", SERVER_URL)

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	if ResourceLoader.exists(LOGO_PATH):
		logo_texture = load(LOGO_PATH)

	_build_interface()
	_show_page("Accueil")


# ==================================================
# TRAITEMENT RESEAU
# ==================================================

func _process(_delta):

	if matchmaking_socket == null:
		return

	matchmaking_socket.poll()

	var state = matchmaking_socket.get_ready_state()

	if state == WebSocketPeer.STATE_CONNECTING:

		if Time.get_ticks_msec() - matchmaking_started_at > CONNECTION_TIMEOUT:

			_close_matchmaking()
			matchmaking_active = false

			_show_message(
				"Le serveur met trop de temps à répondre."
			)

			if current_page == "Battles":
				_page_battles()

		return

	if state == WebSocketPeer.STATE_OPEN:

		matchmaking_connected = true

		if matchmaking_active and not matchmaking_request_sent:
			_send_matchmaking_request()

		while matchmaking_socket != null and matchmaking_socket.get_available_packet_count() > 0:

			var packet = matchmaking_socket.get_packet()

			var message = JSON.parse_string(
				packet.get_string_from_utf8()
			)

			if message is Dictionary:
				_handle_matchmaking_message(message)

	elif state == WebSocketPeer.STATE_CLOSED:

		var was_active = matchmaking_active

		matchmaking_active = false
		matchmaking_connected = false
		matchmaking_request_sent = false

		matchmaking_socket = null

		if was_active:

			_show_message(
				"Connexion au serveur perdue."
			)

			if current_page == "Battles":
				_page_battles()


# ==================================================
# INTERFACE GENERALE
# ==================================================

func _build_interface():

	var background = ColorRect.new()
	background.color = BG

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var layout = HBoxContainer.new()

	layout.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	layout.add_theme_constant_override(
		"separation", 0
	)

	add_child(layout)

	_build_sidebar(layout)
	_build_main_area(layout)

	dialog = AcceptDialog.new()
	dialog.title = "WSC BATTLE"
	add_child(dialog)


# ==================================================
# MENU LATERAL
# ==================================================

func _build_sidebar(parent):

	var sidebar = PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(245, 0)

	var style = StyleBoxFlat.new()
	style.bg_color = SIDEBAR

	sidebar.add_theme_stylebox_override(
		"panel", style
	)

	parent.add_child(sidebar)

	var margin = MarginContainer.new()

	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 18)

	sidebar.add_child(margin)

	var content = VBoxContainer.new()

	content.add_theme_constant_override(
		"separation", 15
	)

	margin.add_child(content)

	if logo_texture != null:

		var logo = TextureRect.new()
		logo.texture = logo_texture
		logo.custom_minimum_size = Vector2(0, 145)
		logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		content.add_child(logo)

	else:

		var logo_label = Label.new()
		logo_label.text = "WSC BATTLE"
		logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		logo_label.add_theme_font_size_override(
			"font_size", 25
		)

		logo_label.add_theme_color_override(
			"font_color", GOLD
		)

		content.add_child(logo_label)

	_add_separator(content)
	_add_section_label(content, "MENU PRINCIPAL")

	_add_menu_button(content, "⌂   ACCUEIL", "Accueil")
	_add_menu_button(content, "♟   MON PROFIL", "Mon profil")
	_add_menu_button(content, "⚔   BATTLES", "Battles")
	_add_menu_button(content, "TOURNOIS", "Tournois")
	_add_menu_button(content, "★   CLASSEMENTS", "Classements")

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	_add_separator(content)

	_add_menu_button(
		content, "⚙   PARAMÈTRES", "Paramètres"
	)

	var version = Label.new()
	version.text = "WSC BATTLE • VERSION 3.2"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	version.add_theme_font_size_override(
		"font_size", 10
	)

	version.add_theme_color_override(
		"font_color", GREY
	)

	content.add_child(version)


func _add_separator(parent):

	var separator = HSeparator.new()

	separator.add_theme_color_override(
		"separator", CARD_LIGHT
	)

	parent.add_child(separator)


func _add_section_label(parent, text_value):

	var label = Label.new()
	label.text = text_value

	label.add_theme_font_size_override(
		"font_size", 11
	)

	label.add_theme_color_override(
		"font_color", GREY
	)

	parent.add_child(label)


func _add_menu_button(parent, text_value, page_name):

	var button = Button.new()

	button.text = text_value
	button.custom_minimum_size = Vector2(0, 47)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE

	button.add_theme_font_size_override(
		"font_size", 14
	)

	button.add_theme_color_override(
		"font_color", WHITE
	)

	button.add_theme_color_override(
		"font_hover_color", GOLD
	)

	var normal = StyleBoxFlat.new()
	normal.bg_color = SIDEBAR
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 12

	var hover = StyleBoxFlat.new()
	hover.bg_color = CARD_LIGHT
	hover.set_corner_radius_all(8)
	hover.content_margin_left = 12

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color("#35415B")
	pressed.set_corner_radius_all(8)
	pressed.content_margin_left = 12

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

	button.pressed.connect(
		_show_page.bind(page_name)
	)

	parent.add_child(button)


# ==================================================
# ZONE PRINCIPALE
# ==================================================

func _build_main_area(parent):

	var main = VBoxContainer.new()

	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL

	main.add_theme_constant_override(
		"separation", 0
	)

	parent.add_child(main)

	var header = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 72)

	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color("#111622")
	header_style.border_color = CARD_LIGHT
	header_style.border_width_bottom = 1

	header.add_theme_stylebox_override(
		"panel", header_style
	)

	main.add_child(header)

	var header_margin = MarginContainer.new()

	header_margin.add_theme_constant_override(
		"margin_left", 28
	)

	header_margin.add_theme_constant_override(
		"margin_right", 28
	)

	header.add_child(header_margin)

	var header_row = HBoxContainer.new()

	header_row.alignment = BoxContainer.ALIGNMENT_CENTER

	header_margin.add_child(header_row)

	page_title = Label.new()
	page_title.text = "ACCUEIL"

	page_title.add_theme_font_size_override(
		"font_size", 21
	)

	page_title.add_theme_color_override(
		"font_color", WHITE
	)

	page_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	header_row.add_child(page_title)

	var online = Label.new()
	online.text = "●  PLATEFORME ACTIVE"

	online.add_theme_font_size_override(
		"font_size", 12
	)

	online.add_theme_color_override(
		"font_color", GREEN
	)

	header_row.add_child(online)

	var scroll = ScrollContainer.new()

	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	main.add_child(scroll)

	var margin = MarginContainer.new()

	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 35)

	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	scroll.add_child(margin)

	page_body = VBoxContainer.new()

	page_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	page_body.add_theme_constant_override(
		"separation", 20
	)

	margin.add_child(page_body)


# ==================================================
# NAVIGATION
# ==================================================

func _show_page(page_name):

	current_page = page_name
	page_title.text = page_name.to_upper()

	for child in page_body.get_children():
		child.queue_free()

	match page_name:

		"Accueil":
			_page_home()

		"Mon profil":
			_page_profile()

		"Battles":
			_page_battles()

		"Tournois":
			_page_tournaments()

		"Classements":
			_page_ranking()

		"Paramètres":
			_page_settings()


# ==================================================
# ACCUEIL
# ==================================================

func _page_home():

	_add_hero()

	_add_heading("TABLEAU DE BORD")

	_add_text(
		"Retrouve ton activité et prépare tes prochaines compétitions."
	)

	var stats = HBoxContainer.new()

	stats.add_theme_constant_override(
		"separation", 12
	)

	page_body.add_child(stats)

	stats.add_child(
		_make_stat("BATTLES", str(total_battles), GOLD)
	)

	stats.add_child(
		_make_stat("VICTOIRES", str(total_wins), GREEN)
	)

	stats.add_child(
		_make_stat("DÉFAITES", str(total_losses), RED)
	)

	_add_heading("ACCÈS RAPIDE")

	var actions = HBoxContainer.new()

	actions.add_theme_constant_override(
		"separation", 12
	)

	page_body.add_child(actions)

	var battle = _make_button(
		"⚔ TROUVER UN ADVERSAIRE",
		GOLD,
		Color("#171717")
	)

	battle.custom_minimum_size.y = 58
	battle.pressed.connect(_create_battle)

	actions.add_child(battle)

	var profile = _make_button(
		"MON PROFIL",
		CARD_LIGHT,
		WHITE
	)

	profile.custom_minimum_size.y = 58

	profile.pressed.connect(
		_show_page.bind("Mon profil")
	)

	actions.add_child(profile)

	_add_heading("ACTUALITÉS WSC")

	page_body.add_child(
		_make_card(
			"BIENVENUE DANS L'ARÈNE",
			"Prépare-toi à affronter des danseurs, progresser et construire ta réputation dans WSC BATTLE."
		)
	)

	page_body.add_child(
		_make_card(
			"PROCHAINEMENT",
			"Battles en ligne, défis, tournois communautaires et classements des danseurs."
		)
	)


func _add_hero():

	var hero = PanelContainer.new()
	hero.custom_minimum_size = Vector2(0, 215)

	var style = StyleBoxFlat.new()
	style.bg_color = Color("#20283B")
	style.set_corner_radius_all(15)
	style.border_color = GOLD_DARK
	style.set_border_width_all(1)

	hero.add_theme_stylebox_override(
		"panel", style
	)

	page_body.add_child(hero)

	var margin = MarginContainer.new()

	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)

	hero.add_child(margin)

	var content = VBoxContainer.new()

	content.add_theme_constant_override(
		"separation", 12
	)

	margin.add_child(content)

	var eyebrow = Label.new()
	eyebrow.text = "WELCOME TO THE ARENA"

	eyebrow.add_theme_font_size_override(
		"font_size", 12
	)

	eyebrow.add_theme_color_override(
		"font_color", GOLD
	)

	content.add_child(eyebrow)

	var title = Label.new()
	title.text = "LA BATTLE COMMENCE ICI."

	title.add_theme_font_size_override(
		"font_size", 30
	)

	title.add_theme_color_override(
		"font_color", WHITE
	)

	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	content.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Affronte. Danse. Progresse. Deviens une légende."

	subtitle.add_theme_font_size_override(
		"font_size", 15
	)

	subtitle.add_theme_color_override(
		"font_color", GREY
	)

	content.add_child(subtitle)

	var button = _make_button(
		"TROUVER UN ADVERSAIRE →",
		GOLD,
		Color("#171717")
	)

	button.custom_minimum_size = Vector2(230, 46)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.pressed.connect(_create_battle)

	content.add_child(button)


# ==================================================
# PROFIL
# ==================================================

func _page_profile():

	_add_heading("MON PROFIL DE DANSEUR")

	_add_text(
		"Construis ton identité et suis ta progression."
	)

	page_body.add_child(
		_make_card(
			"IDENTITÉ",
			"Pseudo : " + player_name +
			"\nDiscipline : Breakdance" +
			"\nNiveau : " + str(player_level) +
			"\nPays : France"
		)
	)

	_add_heading("MES STATISTIQUES")

	var stats = HBoxContainer.new()

	stats.add_theme_constant_override(
		"separation", 12
	)

	page_body.add_child(stats)

	stats.add_child(
		_make_stat("BATTLES", str(total_battles), GOLD)
	)

	stats.add_child(
		_make_stat("VICTOIRES", str(total_wins), GREEN)
	)

	stats.add_child(
		_make_stat("DÉFAITES", str(total_losses), RED)
	)

	page_body.add_child(
		_make_card(
			"MON ÉVOLUTION",
			"Participe à tes premières battles pour faire évoluer ton niveau et ton classement."
		)
	)

	page_body.add_child(
		_make_card(
			"MES DISCIPLINES",
			"Breakdance\nToprock\nFootwork\nPowermoves\nFreezes"
		)
	)


# ==================================================
# MATCHMAKING - PAGE BATTLES
# ==================================================

func _page_battles():

	_add_heading("L'ARÈNE DES BATTLES")

	_add_text(
		"Affronte automatiquement un danseur de niveau proche."
	)

	page_body.add_child(
		_make_card(
			"TON PROFIL COMPÉTITEUR",
			"Pseudo : " + player_name +
			"\nNiveau : " + str(player_level) +
			"\nRecherche : niveaux proches"
		)
	)

	_add_heading("CHOISIR TA DISCIPLINE")

	var discipline_select = OptionButton.new()

	discipline_select.add_item("Breakdance")
	discipline_select.add_item("Powermove")
	discipline_select.add_item("Footwork")
	discipline_select.add_item("Toprock")
	discipline_select.add_item("Freestyle")

	discipline_select.custom_minimum_size = Vector2(0, 45)

	discipline_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	page_body.add_child(discipline_select)

	_add_heading("MATCHMAKING AUTOMATIQUE")

	match_status_label = Label.new()

	if matchmaking_active:
		match_status_label.text = "Recherche d'un adversaire..."
	else:
		match_status_label.text = "Prêt à rechercher un adversaire."

	match_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	match_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	match_status_label.add_theme_color_override(
		"font_color", GREEN
	)

	page_body.add_child(match_status_label)

	match_button = _make_button(
		"TROUVER UN ADVERSAIRE",
		GOLD,
		Color("#171717")
	)

	match_button.custom_minimum_size.y = 65

	if matchmaking_active:
		match_button.text = "ANNULER LA RECHERCHE"

	match_button.pressed.connect(
		func():
			if matchmaking_active:
				_cancel_matchmaking()
			else:
				_find_opponent(
					discipline_select.get_item_text(
						discipline_select.selected
					)
				)
	)

	page_body.add_child(match_button)

	_add_heading("STATISTIQUES")

	var stats = HBoxContainer.new()

	stats.add_theme_constant_override(
		"separation", 12
	)

	page_body.add_child(stats)

	stats.add_child(
		_make_stat("BATTLES", str(total_battles), GOLD)
	)

	stats.add_child(
		_make_stat("VICTOIRES", str(total_wins), GREEN)
	)

	stats.add_child(
		_make_stat("DÉFAITES", str(total_losses), RED)
	)


# ==================================================
# RECHERCHE AUTOMATIQUE
# ==================================================

func _find_opponent(discipline):

	if matchmaking_active:
		return

	if battle_active:
		_show_message("Une battle est déjà en cours.")
		return

	if player_level < 1 or player_level > 100:
		_show_message("Niveau de joueur invalide.")
		return

	if matchmaking_socket != null:
		_close_matchmaking()

	match_discipline = discipline

	matchmaking_socket = WebSocketPeer.new()

	matchmaking_active = true
	matchmaking_connected = false
	matchmaking_request_sent = false

	matchmaking_started_at = Time.get_ticks_msec()

	if match_status_label != null:
		match_status_label.text = "Connexion au serveur..."

	if match_button != null:
		match_button.text = "ANNULER LA RECHERCHE"

	var error = matchmaking_socket.connect_to_url(
		SERVER_URL
	)

	if error != OK:

		_close_matchmaking()
		matchmaking_active = false

		_show_message(
			"Impossible de contacter le serveur. Vérifie son adresse."
		)

		_page_battles()
		return

	print("Connexion au matchmaking...")


func _send_matchmaking_request():

	if matchmaking_socket == null:
		return

	var request = {
		"type": "join",
		"name": player_name,
		"level": player_level,
		"discipline": match_discipline
	}

	var error = matchmaking_socket.send_text(
		JSON.stringify(request)
	)

	if error != OK:

		_show_message(
			"Impossible d'envoyer la demande de recherche."
		)

		_cancel_matchmaking()
		return

	matchmaking_request_sent = true

	print("Recherche envoyée au serveur.")


# ==================================================
# RECEPTION DES MESSAGES
# ==================================================

func _handle_matchmaking_message(message):

	var message_type = message.get("type", "")

	match message_type:

		"waiting":

			if match_status_label != null:
				match_status_label.text = "Recherche d'un danseur de niveau proche..."

			print("En attente d'un adversaire.")

		"matched":

			matchmaking_active = false
			matchmaking_request_sent = false

			opponent_name = str(
				message.get("opponent_name", "Adversaire")
			)

			opponent_level = int(
				message.get("opponent_level", 0)
			)

			opponent_id = str(
				message.get("opponent_id", "")
			)

			selected_discipline = match_discipline

			selected_level = "Niveau " + str(player_level)

			current_round = 0
			player_round_wins = 0
			opponent_round_wins = 0

			battle_active = true

			print("ADVERSAIRE TROUVÉ : ", opponent_name)
			print("NIVEAU ADVERSAIRE : ", opponent_level)

			_show_battle_round()

		"error":

			matchmaking_active = false
			matchmaking_request_sent = false

			_show_message(
				str(
					message.get(
						"message",
						"Erreur de matchmaking."
					)
				)
			)

			if current_page == "Battles":
				_page_battles()

		_:

			print("Message serveur inconnu : ", message_type)


# ==================================================
# ANNULER LA RECHERCHE
# ==================================================

func _cancel_matchmaking():

	if matchmaking_socket != null:

		if matchmaking_socket.get_ready_state() == WebSocketPeer.STATE_OPEN:

			matchmaking_socket.send_text(
				JSON.stringify({
					"type": "cancel"
				})
			)

		_close_matchmaking()

	matchmaking_active = false
	matchmaking_connected = false
	matchmaking_request_sent = false

	print("Recherche annulée.")

	_show_page("Battles")


func _close_matchmaking():

	if matchmaking_socket != null:

		matchmaking_socket.close()
		matchmaking_socket = null

	matchmaking_connected = false
	matchmaking_request_sent = false


# ==================================================
# BATTLE
# ==================================================

func _create_battle():

	_show_page("Battles")


func _show_battle_round():

	current_page = "Battle"

	page_title.text = "BATTLE EN COURS"

	for child in page_body.get_children():
		child.queue_free()

	_add_heading("⚔ WSC BATTLE ARENA")

	_add_text(
		"Discipline : " + selected_discipline +
		"\nTon niveau : " + selected_level +
		"\nAdversaire : " + opponent_name +
		"\nNiveau adverse : " + str(opponent_level)
	)

	var arena = PanelContainer.new()

	var arena_style = StyleBoxFlat.new()

	arena_style.bg_color = Color("#20283B")
	arena_style.set_corner_radius_all(15)
	arena_style.border_color = GOLD
	arena_style.set_border_width_all(2)

	arena.add_theme_stylebox_override(
		"panel", arena_style
	)

	page_body.add_child(arena)

	var arena_margin = MarginContainer.new()

	arena_margin.add_theme_constant_override("margin_left", 18)
	arena_margin.add_theme_constant_override("margin_right", 18)
	arena_margin.add_theme_constant_override("margin_top", 20)
	arena_margin.add_theme_constant_override("margin_bottom", 20)

	arena.add_child(arena_margin)

	var arena_content = VBoxContainer.new()

	arena_content.add_theme_constant_override(
		"separation", 18
	)

	arena_margin.add_child(arena_content)

	var round_title = Label.new()

	round_title.text = "MANCHE " + str(current_round + 1) + " / 3"

	round_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	round_title.add_theme_font_size_override(
		"font_size", 25
	)

	round_title.add_theme_color_override(
		"font_color", GOLD
	)

	arena_content.add_child(round_title)

	var fighters = HBoxContainer.new()

	fighters.add_theme_constant_override(
		"separation", 12
	)

	arena_content.add_child(fighters)

	fighters.add_child(
		_make_card(
			"TON DANSEUR",
			"🔥 " + player_name +
			"\n\nManches gagnées : " + str(player_round_wins)
		)
	)

	fighters.add_child(
		_make_card(
			opponent_name,
			"⚡ ADVERSAIRE" +
			"\nNiveau : " + str(opponent_level) +
			"\n\nManches gagnées : " + str(opponent_round_wins)
		)
	)

	var instruction = Label.new()

	instruction.text = "DÉMONSTRATION DU SYSTÈME DE VOTE LOCAL"

	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	instruction.add_theme_font_size_override(
		"font_size", 16
	)

	instruction.add_theme_color_override(
		"font_color", WHITE
	)

	arena_content.add_child(instruction)

	var warning = Label.new()

	warning.text = "Les votes ne sont pas encore synchronisés entre les joueurs."

	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	warning.add_theme_color_override(
		"font_color", GREY
	)

	arena_content.add_child(warning)

	var vote_player = _make_button(
		"🏆 VICTOIRE POUR MOI",
		GOLD,
		Color("#171717")
	)

	vote_player.custom_minimum_size.y = 55

	vote_player.pressed.connect(
		_cast_vote.bind(true)
	)

	arena_content.add_child(vote_player)

	var vote_opponent = _make_button(
		"⚔ VICTOIRE POUR " + opponent_name.to_upper(),
		BLUE,
		WHITE
	)

	vote_opponent.custom_minimum_size.y = 55

	vote_opponent.pressed.connect(
		_cast_vote.bind(false)
	)

	arena_content.add_child(vote_opponent)

	var score = Label.new()

	score.text = "SCORE : " + str(player_round_wins) + " - " + str(opponent_round_wins)

	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	score.add_theme_font_size_override(
		"font_size", 17
	)

	score.add_theme_color_override(
		"font_color", GOLD
	)

	arena_content.add_child(score)

	var quit = _make_button(
		"QUITTER LA BATTLE",
		RED,
		WHITE
	)

	quit.pressed.connect(
		_quit_battle
	)

	page_body.add_child(quit)


# ==================================================
# VOTE LOCAL
# ==================================================

func _cast_vote(player_wins):

	if not battle_active:
		return

	if player_wins:
		player_round_wins += 1
	else:
		opponent_round_wins += 1

	current_round += 1

	if current_round >= 3:
		_finish_battle()
	else:
		_show_battle_round()


func _quit_battle():

	battle_active = false

	if matchmaking_socket != null:
		_close_matchmaking()

	_show_page("Accueil")


# ==================================================
# RESULTAT FINAL
# ==================================================

func _finish_battle():

	battle_active = false

	total_battles += 1

	var result_title = ""
	var result_description = ""

	if player_round_wins > opponent_round_wins:

		total_wins += 1

		result_title = "🏆 VICTOIRE !"

		result_description = (
			"Bravo ! Tu as remporté la battle contre " +
			opponent_name + "."
		)

	elif player_round_wins < opponent_round_wins:

		total_losses += 1

		result_title = "DÉFAITE"

		result_description = (
			opponent_name + " a remporté la battle."
		)

	else:

		result_title = "ÉGALITÉ"

		result_description = "Les deux danseurs sont à égalité."

	page_title.text = "RÉSULTAT DE LA BATTLE"

	for child in page_body.get_children():
		child.queue_free()

	_add_heading(result_title)

	page_body.add_child(
		_make_card(
			"FIN DE LA CONFRONTATION",
			result_description +
			"\n\nDiscipline : " + selected_discipline +
			"\nNiveau : " + selected_level +
			"\nScore final : " + str(player_round_wins) +
			" - " + str(opponent_round_wins)
		)
	)

	_add_heading("MES STATISTIQUES")

	var stats = HBoxContainer.new()

	stats.add_theme_constant_override(
		"separation", 12
	)

	page_body.add_child(stats)

	stats.add_child(
		_make_stat("BATTLES", str(total_battles), GOLD)
	)

	stats.add_child(
		_make_stat("VICTOIRES", str(total_wins), GREEN)
	)

	stats.add_child(
		_make_stat("DÉFAITES", str(total_losses), RED)
	)

	var replay = _make_button(
		"RECHERCHER UN AUTRE ADVERSAIRE",
		GOLD,
		Color("#171717")
	)

	replay.pressed.connect(_create_battle)

	page_body.add_child(replay)

	var home = _make_button(
		"RETOUR À L'ACCUEIL",
		CARD_LIGHT,
		WHITE
	)

	home.pressed.connect(
		_show_page.bind("Accueil")
	)

	page_body.add_child(home)


# ==================================================
# TOURNOIS
# ==================================================

func _page_tournaments():

	_add_heading("TOURNOIS WSC")

	_add_text(
		"Entre dans les compétitions et tente de décrocher la première place."
	)

	page_body.add_child(
		_make_card(
			"TOURNOIS COMMUNAUTAIRES",
			"Des tournois créés par les membres de la communauté."
		)
	)

	page_body.add_child(
		_make_card(
			"TOURNOIS OFFICIELS",
			"Les grandes compétitions organisées par WSC BATTLE."
		)
	)

	var button = _make_button(
		"CRÉER UN TOURNOI",
		BLUE,
		WHITE
	)

	button.custom_minimum_size.y = 55

	button.pressed.connect(
		func():
			_show_message(
				"La création des tournois sera développée prochainement."
			)
	)

	page_body.add_child(button)


# ==================================================
# CLASSEMENTS
# ==================================================

func _page_ranking():

	_add_heading("HALL OF FAME")

	_add_text(
		"Les meilleurs danseurs de la communauté WSC."
	)

	page_body.add_child(
		_make_card(
			"🥇 CLASSEMENT DÉBUTANTS",
			"1. En attente de danseurs\n2. En attente de danseurs\n3. En attente de danseurs"
		)
	)

	page_body.add_child(
		_make_card(
			"🥈 CLASSEMENT INTERMÉDIAIRES",
			"Le classement apparaîtra ici."
		)
	)

	page_body.add_child(
		_make_card(
			"🥉 CLASSEMENT EXPERTS",
			"Le classement apparaîtra ici."
		)
	)


# ==================================================
# PARAMETRES
# ==================================================

func _page_settings():

	_add_heading("PARAMÈTRES")

	page_body.add_child(
		_make_card(
			"APPLICATION",
			"Nom : WSC BATTLE\nVersion : 3.2\nPlateformes : Windows et Android"
		)
	)

	page_body.add_child(
		_make_card(
			"COMPATIBILITÉ WEBRTC",
			"WebRTC : " + str(webrtc_available) +
			"\nWebSocket : " + str(websocket_available)
		)
	)

	page_body.add_child(
		_make_card(
			"MATCHMAKING",
			"Serveur : " + SERVER_URL +
			"\nNiveau du joueur : " + str(player_level)
		)
	)

	page_body.add_child(
		_make_card(
			"COMPTE",
			"Le système de comptes et de sauvegarde sera connecté dans la prochaine étape."
		)
	)


# ==================================================
# STATISTIQUES
# ==================================================

func _make_stat(title_text, value_text, accent):

	var panel = PanelContainer.new()

	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 105)

	var style = StyleBoxFlat.new()

	style.bg_color = CARD
	style.set_corner_radius_all(10)
	style.border_color = CARD_LIGHT
	style.set_border_width_all(1)

	panel.add_theme_stylebox_override(
		"panel", style
	)

	var margin = MarginContainer.new()

	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)

	panel.add_child(margin)

	var content = VBoxContainer.new()

	content.alignment = BoxContainer.ALIGNMENT_CENTER

	content.add_theme_constant_override(
		"separation", 7
	)

	margin.add_child(content)

	var value = Label.new()

	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	value.add_theme_font_size_override(
		"font_size", 27
	)

	value.add_theme_color_override(
		"font_color", accent
	)

	content.add_child(value)

	var title = Label.new()

	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	title.add_theme_font_size_override(
		"font_size", 10
	)

	title.add_theme_color_override(
		"font_color", GREY
	)

	content.add_child(title)

	return panel


# ==================================================
# CARTES
# ==================================================

func _make_card(title_text, description):

	var panel = PanelContainer.new()

	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()

	style.bg_color = CARD
	style.set_corner_radius_all(11)
	style.border_color = CARD_LIGHT
	style.set_border_width_all(1)

	style.content_margin_left = 17
	style.content_margin_right = 17
	style.content_margin_top = 17
	style.content_margin_bottom = 17

	panel.add_theme_stylebox_override(
		"panel", style
	)

	var content = VBoxContainer.new()

	content.add_theme_constant_override(
		"separation", 9
	)

	panel.add_child(content)

	var title = Label.new()

	title.text = title_text

	title.add_theme_font_size_override(
		"font_size", 17
	)

	title.add_theme_color_override(
		"font_color", GOLD
	)

	content.add_child(title)

	var body = Label.new()

	body.text = description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	body.add_theme_font_size_override(
		"font_size", 14
	)

	body.add_theme_color_override(
		"font_color", GREY
	)

	content.add_child(body)

	return panel


# ==================================================
# TITRES ET TEXTES
# ==================================================

func _add_heading(text_value):

	var label = Label.new()

	label.text = text_value

	label.add_theme_font_size_override(
		"font_size", 21
	)

	label.add_theme_color_override(
		"font_color", GOLD
	)

	page_body.add_child(label)


func _add_text(text_value):

	var label = Label.new()

	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	label.add_theme_font_size_override(
		"font_size", 14
	)

	label.add_theme_color_override(
		"font_color", GREY
	)

	page_body.add_child(label)


# ==================================================
# BOUTONS
# ==================================================

func _make_button(text_value, background_color, text_color):

	var button = Button.new()

	button.text = text_value

	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 48)

	button.focus_mode = Control.FOCUS_NONE

	button.add_theme_font_size_override(
		"font_size", 15
	)

	button.add_theme_color_override(
		"font_color", text_color
	)

	var normal = StyleBoxFlat.new()

	normal.bg_color = background_color
	normal.set_corner_radius_all(8)

	var hover = StyleBoxFlat.new()

	hover.bg_color = background_color.lightened(0.15)
	hover.set_corner_radius_all(8)

	var pressed = StyleBoxFlat.new()

	pressed.bg_color = background_color.darkened(0.12)
	pressed.set_corner_radius_all(8)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

	return button


# ==================================================
# MESSAGES
# ==================================================

func _show_message(message):

	dialog.dialog_text = message
	dialog.popup_centered()

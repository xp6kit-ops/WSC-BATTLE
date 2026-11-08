
extends Control

# =========================================
# WSC BATTLE - APPLICATION PRINCIPALE
# Compatible Godot 4.0
# Tous les éléments sont créés par le code.
# =========================================

const FOND = Color("#10121B")
const MENU = Color("#191D2B")
const CARTE = Color("#22283A")
const OR = Color("#F5B928")
const BLANC = Color("#FFFFFF")
const GRIS = Color("#AAB1C5")
const BLEU = Color("#168BFF")
const ROUGE = Color("#EF4444")

var contenu: VBoxContainer
var titre_page: Label
var fenetre_message: AcceptDialog


func _ready():
	construire_application()
	afficher_page("Accueil")


# =========================================
# CONSTRUCTION GÉNÉRALE
# =========================================

func construire_application():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fond = ColorRect.new()
	fond.color = FOND
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fond)

	var disposition = HBoxContainer.new()
	disposition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	disposition.add_theme_constant_override("separation", 0)
	add_child(disposition)

	construire_menu(disposition)
	construire_zone_principale(disposition)

	fenetre_message = AcceptDialog.new()
	fenetre_message.title = "WSC BATTLE"
	add_child(fenetre_message)


# =========================================
# MENU LATÉRAL
# =========================================

func construire_menu(parent):
	var panneau = PanelContainer.new()
	panneau.custom_minimum_size.x = 220

	var style = StyleBoxFlat.new()
	style.bg_color = MENU
	panneau.add_theme_stylebox_override("panel", style)
	parent.add_child(panneau)

	var marge = MarginContainer.new()
	marge.add_theme_constant_override("margin_left", 15)
	marge.add_theme_constant_override("margin_right", 15)
	marge.add_theme_constant_override("margin_top", 25)
	marge.add_theme_constant_override("margin_bottom", 15)
	panneau.add_child(marge)

	var colonne = VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 12)
	marge.add_child(colonne)

	var logo = Label.new()
	logo.text = "WSC"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 42)
	logo.add_theme_color_override("font_color", OR)
	colonne.add_child(logo)

	var sous_logo = Label.new()
	sous_logo.text = "B A T T L E"
	sous_logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sous_logo.add_theme_font_size_override("font_size", 17)
	sous_logo.add_theme_color_override("font_color", BLANC)
	colonne.add_child(sous_logo)

	ajouter_separateur(colonne)

	ajouter_bouton_menu(colonne, "⌂   ACCUEIL", "Accueil")
	ajouter_bouton_menu(colonne, "♙   MON PROFIL", "Mon profil")
	ajouter_bouton_menu(colonne, "⚔   BATTLES", "Battles")
	ajouter_bouton_menu(colonne, "🏆   TOURNOIS", "Tournois")
	ajouter_bouton_menu(colonne, "☷   CLASSEMENTS", "Classements")

	var espace = Control.new()
	espace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(espace)

	ajouter_bouton_menu(colonne, "⚙   PARAMÈTRES", "Paramètres")

	var version = Label.new()
	version.text = "WSC BATTLE  •  VERSION 1.0"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 9)
	version.add_theme_color_override("font_color", GRIS)
	colonne.add_child(version)


func ajouter_bouton_menu(parent, texte, destination):
	var bouton = Button.new()
	bouton.text = texte
	bouton.custom_minimum_size.y = 43
	bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bouton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	bouton.focus_mode = Control.FOCUS_NONE
	bouton.add_theme_font_size_override("font_size", 13)
	bouton.add_theme_color_override("font_color", BLANC)

	var normal = StyleBoxFlat.new()
	normal.bg_color = CARTE
	normal.set_corner_radius_all(7)

	var survol = StyleBoxFlat.new()
	survol.bg_color = Color("#39435D")
	survol.set_corner_radius_all(7)

	bouton.add_theme_stylebox_override("normal", normal)
	bouton.add_theme_stylebox_override("hover", survol)
	bouton.add_theme_stylebox_override("pressed", survol)

	bouton.pressed.connect(afficher_page.bind(destination))
	parent.add_child(bouton)


# =========================================
# ZONE PRINCIPALE
# =========================================

func construire_zone_principale(parent):
	var zone = VBoxContainer.new()
	zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(zone)

	var barre = PanelContainer.new()
	barre.custom_minimum_size.y = 68

	var style = StyleBoxFlat.new()
	style.bg_color = Color("#171B28")
	barre.add_theme_stylebox_override("panel", style)
	zone.add_child(barre)

	var marge = MarginContainer.new()
	marge.add_theme_constant_override("margin_left", 25)
	marge.add_theme_constant_override("margin_right", 25)
	marge.add_theme_constant_override("margin_top", 10)
	marge.add_theme_constant_override("margin_bottom", 10)
	barre.add_child(marge)

	var ligne = HBoxContainer.new()
	marge.add_child(ligne)

	titre_page = Label.new()
	titre_page.text = "ACCUEIL"
	titre_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titre_page.add_theme_font_size_override("font_size", 22)
	titre_page.add_theme_color_override("font_color", BLANC)
	ligne.add_child(titre_page)

	var statut = Label.new()
	statut.text = "● WSC BATTLE"
	statut.add_theme_color_override("font_color", OR)
	ligne.add_child(statut)

	var defilement = ScrollContainer.new()
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zone.add_child(defilement)

	var marge_page = MarginContainer.new()
	marge_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	marge_page.add_theme_constant_override("margin_left", 25)
	marge_page.add_theme_constant_override("margin_right", 25)
	marge_page.add_theme_constant_override("margin_top", 25)
	marge_page.add_theme_constant_override("margin_bottom", 25)
	defilement.add_child(marge_page)

	contenu = VBoxContainer.new()
	contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenu.add_theme_constant_override("separation", 16)
	marge_page.add_child(contenu)


# =========================================
# NAVIGATION
# =========================================

func afficher_page(nom):
	titre_page.text = nom.to_upper()

	for enfant in contenu.get_children():
		enfant.queue_free()

	match nom:
		"Accueil":
			page_accueil()
		"Mon profil":
			page_profil()
		"Battles":
			page_battles()
		"Tournois":
			page_tournois()
		"Classements":
			page_classements()
		"Paramètres":
			page_parametres()


# =========================================
# PAGE ACCUEIL
# =========================================

func page_accueil():
	ajouter_titre("BIENVENUE DANS WSC BATTLE")
	ajouter_texte("L'arène du breakdance. Défie les danseurs et montre ton talent.")

	var bouton = creer_bouton("⚔   CRÉER UNE BATTLE", OR, Color("#171717"))
	bouton.custom_minimum_size.y = 65
	bouton.add_theme_font_size_override("font_size", 21)
	bouton.pressed.connect(creer_battle)
	contenu.add_child(bouton)

	ajouter_titre("MON ESPACE")

	var ligne = HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 12)
	contenu.add_child(ligne)

	ligne.add_child(creer_carte("MON PROFIL",
		"Nouveau membre\nNiveau : Débutant\nDiscipline : Breakdance"))

	ligne.add_child(creer_carte("MES STATISTIQUES",
		"Battles : 0\nVictoires : 0\nDéfaites : 0"))

	ajouter_titre("COMPÉTITIONS")

	var competitions = HBoxContainer.new()
	competitions.add_theme_constant_override("separation", 12)
	contenu.add_child(competitions)

	competitions.add_child(creer_carte("TOURNOIS",
		"Participe aux compétitions communautaires et officielles."))

	competitions.add_child(creer_carte("CLASSEMENTS",
		"Découvre les meilleurs danseurs de chaque niveau."))


# =========================================
# PAGE PROFIL
# =========================================

func page_profil():
	ajouter_titre("MON PROFIL DE DANSEUR")

	contenu.add_child(creer_carte("IDENTITÉ",
		"Pseudo : Nouveau membre\nDiscipline : Breakdance\nNiveau : Débutant\nPays : France"))

	contenu.add_child(creer_carte("MES RÉSULTATS",
		"Battles disputées : 0\nVictoires : 0\nDéfaites : 0\nÉgalités : 0"))

	contenu.add_child(creer_carte("ÉVOLUTION",
		"Tes résultats permettront de faire évoluer ton niveau."))


# =========================================
# PAGE BATTLES
# =========================================

func page_battles():
	ajouter_titre("ESPACE BATTLES")
	ajouter_texte("Affronte un autre danseur.")

	var bouton = creer_bouton("CRÉER UNE BATTLE", OR, Color("#171717"))
	bouton.custom_minimum_size.y = 58
	bouton.pressed.connect(creer_battle)
	contenu.add_child(bouton)

	contenu.add_child(creer_carte("BATTLES EN ATTENTE",
		"Aucune battle pour le moment."))

	contenu.add_child(creer_carte("HISTORIQUE",
		"Tes anciennes battles apparaîtront ici."))


# =========================================
# PAGE TOURNOIS
# =========================================

func page_tournois():
	ajouter_titre("TOURNOIS WSC")

	contenu.add_child(creer_carte("TOURNOIS COMMUNAUTAIRES",
		"Les membres pourront organiser leurs propres tournois."))

	contenu.add_child(creer_carte("TOURNOIS OFFICIELS",
		"Les compétitions officielles seront administrées par WSC."))

	var bouton = creer_bouton("CRÉER UN TOURNOI", BLEU, BLANC)
	bouton.pressed.connect(func():
		afficher_message("La création de tournois sera développée dans une prochaine étape.")
	)
	contenu.add_child(bouton)


# =========================================
# PAGE CLASSEMENTS
# =========================================

func page_classements():
	ajouter_titre("CLASSEMENTS DES DANSEURS")

	contenu.add_child(creer_carte("🥉 DÉBUTANTS",
		"1. En attente de danseurs\n2. En attente de danseurs\n3. En attente de danseurs"))

	contenu.add_child(creer_carte("🥈 INTERMÉDIAIRES",
		"Le classement apparaîtra ici."))

	contenu.add_child(creer_carte("🥇 EXPERTS",
		"Le classement apparaîtra ici."))


# =========================================
# PAGE PARAMÈTRES
# =========================================

func page_parametres():
	ajouter_titre("PARAMÈTRES")

	contenu.add_child(creer_carte("APPLICATION",
		"Nom : WSC BATTLE\nVersion : 1.0\nPlateformes : Windows et Android"))

	contenu.add_child(creer_carte("INFORMATIONS",
		"Les réglages du compte, du son et des notifications seront ajoutés ensuite."))


# =========================================
# CRÉATION D'UNE BATTLE
# =========================================

func creer_battle():
	afficher_message(
		"CRÉER UNE BATTLE\n\n" +
		"La prochaine étape permettra de choisir :\n\n" +
		"• Ton adversaire\n" +
		"• Ta discipline\n" +
		"• Ton niveau\n" +
		"• Le format de la battle\n\n" +
		"Les caméras et les juges seront ajoutés ensuite."
	)


# =========================================
# OUTILS D'AFFICHAGE
# =========================================

func ajouter_titre(texte):
	var label = Label.new()
	label.text = texte
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", OR)
	contenu.add_child(label)


func ajouter_texte(texte):
	var label = Label.new()
	label.text = texte
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", GRIS)
	contenu.add_child(label)


func ajouter_separateur(parent):
	var separateur = HSeparator.new()
	parent.add_child(separateur)


func creer_carte(titre, description):
	var panneau = PanelContainer.new()
	panneau.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panneau.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var style = StyleBoxFlat.new()
	style.bg_color = CARTE
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panneau.add_theme_stylebox_override("panel", style)

	var colonne = VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 10)
	panneau.add_child(colonne)

	var label_titre = Label.new()
	label_titre.text = titre
	label_titre.add_theme_font_size_override("font_size", 18)
	label_titre.add_theme_color_override("font_color", OR)
	colonne.add_child(label_titre)

	var label_description = Label.new()
	label_description.text = description
	label_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_description.add_theme_font_size_override("font_size", 14)
	label_description.add_theme_color_override("font_color", BLANC)
	colonne.add_child(label_description)

	return panneau


func creer_bouton(texte, couleur_fond, couleur_texte):
	var bouton = Button.new()
	bouton.text = texte
	bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bouton.custom_minimum_size.y = 48
	bouton.focus_mode = Control.FOCUS_NONE

	bouton.add_theme_font_size_override("font_size", 16)
	bouton.add_theme_color_override("font_color", couleur_texte)

	var normal = StyleBoxFlat.new()
	normal.bg_color = couleur_fond
	normal.set_corner_radius_all(8)

	var survol = StyleBoxFlat.new()
	survol.bg_color = couleur_fond.lightened(0.15)
	survol.set_corner_radius_all(8)

	bouton.add_theme_stylebox_override("normal", normal)
	bouton.add_theme_stylebox_override("hover", survol)
	bouton.add_theme_stylebox_override("pressed", survol)

	return bouton


func afficher_message(texte):
	fenetre_message.dialog_text = texte
	fenetre_message.popup_centered()

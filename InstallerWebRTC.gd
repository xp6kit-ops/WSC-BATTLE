
extends SceneTree

func _initialize():
	print("=== INSTALLATION WSC BATTLE ===")

	var dossier = "res://addons/webrtc"
	var chemin = ProjectSettings.globalize_path(dossier)

	# Création du dossier
	var resultat = DirAccess.make_dir_recursive_absolute(chemin)

	if resultat != OK and resultat != ERR_ALREADY_EXISTS:
		print("ERREUR : impossible de créer le dossier.")
		print("Code erreur : ", resultat)
		quit()
		return

	print("Dossier WebRTC créé avec succès !")

	# Création d'un fichier de vérification
	var fichier = FileAccess.open(
		dossier + "/README.txt",
		FileAccess.WRITE
	)

	if fichier == null:
		print("ERREUR : impossible de créer README.txt")
		print("Code erreur : ", FileAccess.get_open_error())
		quit()
		return

	fichier.store_string(
		"Dossier WebRTC de WSC BATTLE - Godot 4.0"
	)
	fichier.close()

	print("Fichier README créé avec succès !")
	print("INSTALLATION DU DOSSIER TERMINEE !")

	quit()

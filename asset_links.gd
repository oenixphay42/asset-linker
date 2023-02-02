@tool
extends EditorPlugin

# Set to the location your assets.
# Only has an effect if the environment variable ASSETS is undefined.
var assets : String = get_editor_interface().get_editor_paths().get_data_dir() + "/assets"

var config_path : String = get_editor_interface().get_editor_paths().get_config_dir() + "/asset_linker.conf"

var button : Button

var dock : VSplitContainer

func _enter_tree():
	dock = load("res://addons/asset_links/asset_linker.scn").instantiate()
	if OS.get_name() == "Windows":
		dock.windows = true
		assets.replace("/", "\\")
		config_path.replace("/", "\\")
	if OS.get_environment("ASSETS") == "":
		OS.set_environment("ASSETS", assets)
	if !DirAccess.dir_exists_absolute(assets):
		DirAccess.make_dir_recursive_absolute(assets)
	if !FileAccess.file_exists(config_path):
		# I'm sorry you had to see this :(
		var file := FileAccess.open(config_path, FileAccess.WRITE)
		file.store_line("; Configuration for the plugin Asset Linker.")
		file.store_line("; Changes will be applied when the editor is reloaded, or the plugin is disabled then enabled again.")
		file.store_line("[config]")
		file.store_line("\t; Set to false to force copying files instead of making symlinks.")
		file.store_line("\t; Default is true.")
		file.store_line("\tsymlinks=true")
		file.store_line("\t")
		file.store_line("\t; Set to 2 to remove the Move To Trash button.")
		file.store_line("\t; Set to 1 to remove the Delete / Delete Perm. button.")
		file.store_line("\t; Set to 0 to remove both.")
		file.store_line("\t; Default is 3.")
		file.store_line("\tcan_trash=3")
		file.store_line("\t")
		file.store_line("\t; Set to true to automatically make directories that do not exist when setting the path to them.")
		file.store_line("\t; Default is false.")
		file.store_line("\tauto_mkdir=false")
		file.store_line("\t")
		file.store_line("\t; Set to true to use the names Delete and Delete Perm. instead of Move To Trash and Delete.")
		file.store_line("\twindows_names=" + str(OS.get_name() == "Windows"))
		file.store_line("\t")
		file.store_line("\t; Set to false to put the buttons on the right.")
		file.store_line("\t; Default is true.")
		file.store_line("\tleft=true")
	var config := ConfigFile.new()
	config.load(config_path)
	dock.interface = get_editor_interface()
	dock.config_path = config_path
	dock.symlinks = config.get_value("config", "symlinks", true)
	dock.auto_mkdir = config.get_value("config", "auto_mkdir", false)
	add_control_to_bottom_panel(dock, "Asset Linker")
	if config.get_value("config", "windows_names", false):
		dock.trash_button.text = "Delete"
		dock.delete_button.text = "Delete Perm."
	match int(config.get_value("config", "can_trash", 3)):
		2 : 
			dock.trash_button.queue_free()
		1 : 
			dock.delete_button.queue_free()
		0 : 
			dock.trash_button.queue_free()
			dock.delete_button.queue_free()
	if !config.get_value("config", "left", true):
		var node := dock.get_node(^"VBox/HBox") as HBoxContainer
		node.move_child(node.get_child(1), 0)
	button = Button.new()
	button.text = "Add To Assets"
	button.tooltip_text = "Copy the currently selected file or directory to the directory selected in the Asset Linker."
	get_editor_interface().get_file_system_dock().add_child(button)
	button.pressed.connect(dock._add_asset)

func _exit_tree():
	remove_control_from_bottom_panel(dock)
	dock.free()
	button.queue_free()

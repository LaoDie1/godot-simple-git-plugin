@tool
extends EditorPlugin


const MAIN = preload("res://addons/git_plugin/src/main.tscn")

var plugin_control : GitPlugin_Main


func _enter_tree() -> void:
	GitPluginConst.enabled_plugin = true
	plugin_control = MAIN.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, plugin_control)
	
	resource_saved.connect(update_commit_files, Object.CONNECT_DEFERRED)


func _exit_tree() -> void:
	GitPluginConst.enabled_plugin = false
	remove_control_from_docks(plugin_control)


var _updating : bool = false
func update_commit_files(resource):
	if _updating:
		return
	_updating = true
	await Engine.get_main_loop().process_frame
	
	plugin_control.commit_panel.commit.update()
	
	_updating = false


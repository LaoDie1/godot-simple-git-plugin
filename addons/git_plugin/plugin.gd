@tool
extends EditorPlugin


const MAIN = preload("res://addons/git_plugin/src/main.tscn")

var plugin_control : GitPlugin_Main


func _enter_tree() -> void:
	GitPluginConst.enabled_plugin = true
	plugin_control = MAIN.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, plugin_control)
	
	resource_saved.connect(
		func(resource):
			plugin_control.commit_panel.commit.update()
	)


func _exit_tree() -> void:
	remove_control_from_docks(plugin_control)

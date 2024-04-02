@tool
extends EditorPlugin


const MAIN = preload("res://addons/git_plugin/src/main.tscn")

var plugin_control : Control


func _enter_tree() -> void:
	plugin_control = MAIN.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, plugin_control)


func _exit_tree() -> void:
	remove_control_from_docks(plugin_control)

#============================================================
#    Remotes
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 18:17:00
# - version: 4.2.1.stable
#============================================================
@tool
extends VBoxContainer


@onready var add_remote_window: ConfirmationDialog = %AddRemoteWindow
@onready var remote_url_tree = %RemoteUrlTree


func _ready() -> void:
	remote_url_tree.update()


func _on_add_remote_url_button_pressed() -> void:
	add_remote_window.popup_centered()


#============================================================
#    Remotes
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 18:17:00
# - version: 4.2.1.stable
#============================================================
@tool
extends VBoxContainer

const ICON = preload("res://addons/git_plugin/src/icon.tres")


@onready var add_remote_window: ConfirmationDialog = %AddRemoteWindow
@onready var remote_url_tree : Tree = %RemoteUrlTree

@onready var _root : TreeItem = remote_url_tree.create_item()



#============================================================
#  内置
#============================================================
func _ready() -> void:
	remote_url_tree.columns = 2
	remote_url_tree.hide_root = true
	remote_url_tree.hide_folding = true
	remote_url_tree.select_mode = Tree.SELECT_ROW
	remote_url_tree.column_titles_visible = true
	remote_url_tree.set_column_title(0, "Name")
	remote_url_tree.set_column_title(1, "URL")
	remote_url_tree.button_clicked.connect(
		func(item: TreeItem, column: int, id: int, mouse_button_index: int):
			if mouse_button_index == MOUSE_BUTTON_LEFT:
				if id == 0: # 删除
					_root.remove_child(item)
					
	)
	
	update()



#============================================================
#  自定义
#============================================================
func add_item(remote_name: String, url: String):
	var item = remote_url_tree.create_item(_root)
	item.set_text(0, remote_name)
	item.set_text(1, url)
	item.add_button(1, ICON.get_icon("Remove", "EditorIcons"))


func update():
	var result = await GitPlugin_Remote.version()
	for item: String in result:
		if item != "":
			var split = item.split("\t")
			var remote_name = split[0]
			var url = split[1]
			add_item(remote_name, url)



#============================================================
#  连接信号
#============================================================
func _on_add_remote_url_button_pressed() -> void:
	add_remote_window.popup_centered()


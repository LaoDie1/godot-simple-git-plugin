#============================================================
#    File Tree
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 16:10:02
# - version: 4.2.1.stable
#============================================================
@tool
class_name GitPlugin_FileTree
extends Tree

# item_text: 显示到 TreeItem 中的文本
# file: 这个 TreeItem 的文件路径

signal actived_file(item_text: String, file: String)
signal edited_file(item_text: String, file: String)
signal deleted_file(item_text: String, file: String)


enum ButtonID {
	EDIT,
	DELETE,
	ACTIVE,
}

@export var enabled_action : bool = true
@export var enabled_edit : bool = true
@export var enabled_delete : bool = true
@export var action_texture : Texture2D
@export_multiline() var active_button_tooltip: String = ""
@export var new_file_color : Color = Color8(143, 171, 130)
@export var modified_file_color : Color = Color8(250, 227, 69)
@export var deleted_file_color : Color = Color8(196, 89, 89)

var _last_select_item : TreeItem
var _root : TreeItem
var _file_to_item_dict : Dictionary = {}
var _file_to_checked_dict : Dictionary = {}


func _init() -> void:
	hide_root = true
	hide_folding = true
	
	_root = create_item()
	button_clicked.connect(button_click)
	#item_activated.connect(
		#func():
			## 双击
			#var item = get_selected()
			#var item_text = item.get_meta("item_text")
			#var file = item.get_meta("file")
			#actived_file.emit(item_text, file)
	#)
	item_selected.connect(
		func():
			await Engine.get_main_loop().process_frame
			_last_select_item = get_selected()
	)
	item_mouse_selected.connect(
		func(position: Vector2, mouse_button_index: int):
			if mouse_button_index == MOUSE_BUTTON_LEFT:
				if position.x >= 4 and position.x <= 24:
					# 点击复选框
					var item = get_selected()
					var status = not item.is_checked(0)
					set_checked(item, status)
					
					# Shift 多个操作
					if (Input.is_key_pressed(KEY_SHIFT) 
						and _last_select_item
						and _last_select_item != item
					):
						var begin = _last_select_item.get_index()
						var end = item.get_index()
						if end < begin:
							var tmp = end
							end = begin
							begin = tmp
						for i in range(begin, end + 1):
							set_checked(_root.get_child(i), status)
	)



func init_items(items: Array):
	_last_select_item = null
	_file_to_item_dict.clear()
	clear_items()
	add_items(items)


func add_items(items: Array):
	for item_text:String in items:
		add_item(item_text)


func add_item(item_text: String):
	if _file_to_item_dict.has(item_text):
		return
	
	var tag : String = item_text[1] if item_text[1] != " " else item_text[0]
	var type_desc : String = GitPlugin_Status.get_type_description(item_text)
	if tag == GitPlugin_Status.Type.untracked:
		type_desc = "New File"
	
	var file : String = item_text.substr(3)
	if tag == GitPlugin_Status.Type.renamed:
		file = file.split("->", true, 1)[1].strip_edges(true, false)
	
	# 创建
	var item : TreeItem = _root.create_child()
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	set_checked(item, _file_to_checked_dict.get(item_text, true), item_text)
	
	# 颜色
	match tag:
		GitPlugin_Status.Type.modified:
			if modified_file_color != Color.WHITE:
				item.set_custom_color(0, modified_file_color)
			
		GitPlugin_Status.Type.deleted: 
			if deleted_file_color != Color.WHITE:
				item.set_custom_color(0, deleted_file_color)
			
		GitPlugin_Status.Type.new_file, \
		GitPlugin_Status.Type.untracked, \
		GitPlugin_Status.Type.renamed:
			if new_file_color != Color.WHITE:
				item.set_custom_color(0, new_file_color)
			
		_:
			print(" >>> FileTree: item type = ", type_desc)
	
	# 文件名
	item.set_text(0, file + " (%s)" % type_desc.capitalize())
	item.set_tooltip_text(0, item_text)
	item.set_meta("file", file)
	item.set_meta("item_text", item_text)
	
	# 图标
	item.set_icon_max_width(0, 16)
	item.set_icon(0, GitPlugin_Icons.get_icon_by_path(file))
	
	# 按钮
	if enabled_edit and Engine.is_editor_hint():
		item.add_button(0, GitPlugin_Icons.get_icon("Edit"), ButtonID.EDIT, false, "Edit this file")
	if enabled_delete:
		item.add_button(0, GitPlugin_Icons.get_icon("Close"), ButtonID.DELETE, false, "Delete this file")
	if enabled_action and action_texture:
		item.add_button(0, action_texture, ButtonID.ACTIVE, false, active_button_tooltip, active_button_tooltip)
	_file_to_item_dict[item_text] = item


func clear_items():
	for child: TreeItem in _root.get_children():
		_root.remove_child(child)


func clear_select_items():
	var children = _root.get_children()
	children.reverse()
	for child in children:
		if child.is_checked(0):
			remove_item(child.get_meta("item_text"))


func remove_item(item_text: String):
	if _file_to_item_dict.has(item_text):
		var item : TreeItem = _file_to_item_dict[item_text]
		_root.remove_child(item)
		_file_to_item_dict.erase(item_text)


func set_checked(item: TreeItem, checked: bool, item_text: String = ""):
	if item_text == "":
		item_text = item.get_meta("item_text")
	item.set_checked(0, checked)
	_file_to_checked_dict[item_text] = checked


## 获取选中的文件原始名
func get_selected_item_file() -> PackedStringArray:
	var list := PackedStringArray()
	for item in _root.get_children():
		if item.is_checked(0):
			list.append(item.get_meta("item_text"))
	return list


## 获取选中的文件路径
func get_selected_files() -> PackedStringArray:
	var list := PackedStringArray()
	for item in _root.get_children():
		if item.is_checked(0):
			list.append(item.get_meta("file"))
	return list


## 获取所有文件
func get_files():
	return _file_to_item_dict.keys()


func button_click(item: TreeItem, column: int, id: int, mouse_button_index: int):
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		var file : String = item.get_meta("file")
		var item_text : String = item.get_meta("item_text")
		match id:
			ButtonID.EDIT:
				edited_file.emit(item_text, file)
			ButtonID.DELETE:
				deleted_file.emit(item_text, file)
				#print("删除 ", file)
			ButtonID.ACTIVE:
				actived_file.emit(item_text, file)
			_:
				print("点击", id)
	

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


## item_file: 原始的带有其他信息的文件名
## file: 纯文件名，没有其他信息
signal edited_file(item_file: String, file: String)
signal actived_file(item_file: String, file: String)


const ICON = preload("res://addons/git_plugin/src/icon.tres")


@export var action_texture : Texture2D
@export var new_file_color : Color = Color8(143, 171, 130)
@export var modified_file_color : Color = Color8(250, 227, 69)
@export var deleted_file_color : Color = Color8(196, 89, 89)
@export var enabled_edit : bool = true
@export var enabled_delete : bool = true
@export var enabled_action : bool = true


var _last_select_item : TreeItem
var _root : TreeItem
var _file_to_item_dict : Dictionary = {}
var _file_to_checked_dict : Dictionary = {}
var _file_name_regex : RegEx:
	get:
		if _file_name_regex == null:
			_file_name_regex = RegEx.new()
			_file_name_regex.compile(
				"((?<type>[^:]+):\\s+)?" # 改动类型
				+ "("
				+ "(?<origin>.*?)\\s->\\s(?<current>.*)"  # 文件重命名或发生了移动
				+ "|(?<path>.*)" # 文件内容发生改动
				+ ")"
			)
		return _file_name_regex


var enum_edit: int = 1:
	get: return 1 if enabled_edit else 0
var enum_delete : int:
	get: return (enum_edit + 1) if enabled_delete else 0
var enum_action : int:
	get: return (sign(enum_edit) + sign(enum_delete) + 1) if enabled_action else 0


#============================================================
#  内置
#============================================================
func _init() -> void:
	hide_root = true
	hide_folding = true
	
	_root = create_item()
	button_clicked.connect(button_click)
	item_activated.connect(
		func():
			# 双击
			var item = get_selected()
			var item_file = item.get_meta("item_file")
			var file = item.get_meta("file")
			actived_file.emit(item_file, file)
	)
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



#============================================================
#  自定义
#============================================================
func init_items(items: Array):
	_last_select_item = null
	_file_to_item_dict.clear()
	clear_items()
	add_items(items)


func add_items(items: Array):
	for item_file:String in items:
		add_item(item_file)


func add_item(item_file: String):
	if _file_to_item_dict.has(item_file):
		return
	
	# 创建
	var item : TreeItem = _root.create_child()
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	set_checked(item, _file_to_checked_dict.get(item_file, true), item_file)
	
	# 颜色
	var file : String
	var type : String
	var result : RegExMatch = _file_name_regex.search(item_file)
	if result != null:
		type = result.get_string("type")
		if result.get_string("origin") != "":
			var old_path = result.get_string("origin")
			var new_path = result.get_string("current")
			file = new_path
		
		elif result.get_string("path") != "":
			file = result.get_string("path")
	
	if file == "":
		file = item_file
	if type == "":
		type = "new file"
	
	match type.to_lower():
		"modified", "renamed":
			if modified_file_color != Color.WHITE:
				item.set_custom_color(0, modified_file_color)
		"deleted": 
			if deleted_file_color != Color.WHITE:
				item.set_custom_color(0, deleted_file_color)
		"new file":
			if new_file_color != Color.WHITE:
				item.set_custom_color(0, new_file_color)
		_:
			print(" >>> FileTree: item type = ", type)
	
	# 文件名
	file = file.trim_prefix("\t")
	item.set_text(0, file + " (%s)" % type)
	item.set_tooltip_text(0, file)
	item.set_meta("file", file)
	item.set_meta("item_file", item_file)
	
	# 图标
	item.set_icon_max_width(0, 16)
	match file.get_extension():
		"gd":
			item.set_icon(0, ICON.get_icon("Script", "EditorIcons"))
		"tscn":
			item.set_icon(0, ICON.get_icon("PackedScene", "EditorIcons"))
		"":
			item.set_icon(0, ICON.get_icon("Folder", "EditorIcons"))
		_:
			item.set_icon(0, ICON.get_icon("ResourcePreloader", "EditorIcons"))
	
	# 按钮
	if enabled_edit:
		item.add_button(0, ICON.get_icon("File", "EditorIcons")) # 编辑
	if enabled_delete:
		item.add_button(0, ICON.get_icon("Close", "EditorIcons")) # 删除
	if enabled_action:
		if action_texture:
			item.add_button(0, action_texture)
	
	_file_to_item_dict[item_file] = item


func clear_items():
	for child in _root.get_children():
		_root.remove_child(child)


func clear_select_items():
	var children = _root.get_children()
	children.reverse()
	for child in children:
		if child.is_checked(0):
			remove_item(child.get_meta("item_file"))


func remove_item(item_file: String):
	if _file_to_item_dict.has(item_file):
		var item : TreeItem = _file_to_item_dict[item_file]
		_root.remove_child(item)
		_file_to_item_dict.erase(item_file)


func set_checked(item: TreeItem, checked: bool, item_file: String = ""):
	if item_file == "":
		item_file = item.get_meta("item_file")
	item.set_checked(0, checked)
	_file_to_checked_dict[item_file] = checked


## 获取选中的文件
func get_selected_item_file() -> PackedStringArray:
	var list = PackedStringArray()
	for item in _root.get_children():
		if item.is_checked(0):
			list.append(item.get_meta("item_file"))
	return list

func get_selected_files() -> PackedStringArray:
	var list = PackedStringArray()
	for item in _root.get_children():
		if item.is_checked(0):
			list.append(item.get_meta("file"))
	return list


## 获取所有文件
func get_files():
	return _file_to_item_dict.keys()


#============================================================
#  连接信号
#============================================================
func button_click(item: TreeItem, column: int, id: int, mouse_button_index: int):
	id += 1
	
	var file : String = item.get_meta("file")
	var item_file : String = item.get_meta("item_file")
	if id == enum_edit:
		edited_file.emit(item_file, file)
	elif id == enum_delete:
		print("删除 ", file)
	elif id == enum_action:
		actived_file.emit(item_file, file)
	else:
		print("点击", id)
	



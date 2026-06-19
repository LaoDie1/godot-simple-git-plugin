#============================================================
#    File Tree
#============================================================
# - author: zhangxuetu
# - datetime: 2024-11-30 16:33:28
# - version: 4.3.0.stable
#============================================================
## 文件树
##
##方便处理文件显示。以下为添加文件的图标和按钮功能：
##[codeblock]
### 文件按钮的类型
##enum ButtonType {
##    SHOW,
##    REMOVE,
##}
##
### 连接 added_item 信号，设置项目的图标和按钮
##func _on_file_tree_added_item(path: String, item: TreeItem) -> void:
##    item.set_icon(0, Icons.get_icon("AudioStreamMP3")) # 文件图标
##    file_tree.add_item_button(path, Icons.get_icon("Load"), ButtonType.SHOW) # 文件按钮
##    file_tree.add_item_button(path, Icons.get_icon("Remove"), ButtonType.REMOVE)
##
### 连接 button_pressed 实现上面添加的按钮的实际效果
##func _on_file_tree_button_pressed(path: String, button_type: int) -> void:
##    match button_type:
##        ButtonType.SHOW:
##            FileUtil.shell_open(path)
##        ButtonType.REMOVE:
##            file_tree.remove_item(path)
##[/codeblock]
class_name FileTree
extends Tree


## 新添加的 TreeItem，更改 [member show_type] 属性时将会重新添加 item 并发出这个信号
signal added_item(file_path: String, item: TreeItem)
## 移除一个 TreeItem
signal removed_item(file_path: String, item: TreeItem)
## 按下添加的按钮之后发出这个信号
signal button_pressed(file_path: String, button_id: int)
## Item 重命名
signal renamed_item(new_path: String, old_path: String, item: TreeItem)
## 选中这个项
signal selected_item(file_path: String)


enum ShowType {
	ONLY_NAME, ## 只有名称
	ONLY_PATH, ## 只有路径
	INFO, ## 详细信息
	TREE, ## 树形
}
const MetaKey = {
	PATH = "_path",
}

@export var show_type : ShowType = ShowType.ONLY_NAME:
	set(v):
		if show_type != v:
			show_type = v
			if show_type == ShowType.INFO:
				column_titles_visible = true
				columns = _titles.size()
				for idx in _titles.size():
					set_column_title(idx, str(_titles[idx]).to_pascal_case())
					set_column_title_alignment(idx, HORIZONTAL_ALIGNMENT_LEFT)
				for idx in range(1, _titles.size()):
					set_column_expand(idx, false)
				set_column_custom_minimum_width(1, 80)
				set_column_custom_minimum_width(2, 110)
				set_column_custom_minimum_width(3, 180)
			else:
				column_titles_visible = false
				columns = 1
			
			reload()

var root : TreeItem

var _titles = ["name", "type", "size", "time"]
var _file_path_to_item : Dictionary = {}
var _file_path_dict : Dictionary = {}


func _init() -> void:
	root = create_item()
	hide_root = true
	button_clicked.connect(
		func(item: TreeItem, column: int, button_type: int, mouse_button_index: int):
			if mouse_button_index == MOUSE_BUTTON_LEFT:
				var mouse_item: TreeItem = get_item_at_position(get_local_mouse_position())
				if mouse_item == item:
					var path : String = item.get_meta(MetaKey.PATH, "")
					self.button_pressed.emit(path, button_type)
	)
	set_column_custom_minimum_width(0, 150)
	item_edited.connect(
		func():
			var item : TreeItem = get_selected()
			var file_path : String = item.get_meta(MetaKey.PATH, "") as String
			var new_file_name : String = item.get_text(0)
			var new_file_path : String = file_path.get_base_dir().path_join(new_file_name)
			renamed_item.emit(new_file_path, file_path, item)
	)
	item_selected.connect(
		func():
			var file_path : String = get_selected_file()
			if file_path:
				selected_item.emit(file_path)
	)


func get_view_colums_count() -> int:
	return 1 if show_type != ShowType.INFO else _titles.size()

func has_item(path: String) -> bool:
	return _file_path_dict.has(path.replace("\\", "/"))

func add_item(path: String) -> TreeItem:
	if has_item(path):
		return get_item(path)
	
	path = path.replace("\\", "/")
	var item : TreeItem
	match show_type:
		ShowType.ONLY_NAME:
			item = root.create_child()
			item.set_text(0, path.get_file())
			item.set_meta(MetaKey.PATH, path)
			item.set_tooltip_text(0, path)
		ShowType.ONLY_PATH:
			item = root.create_child()
			item.set_text(0, path)
			item.set_meta(MetaKey.PATH, path)
			item.set_tooltip_text(0, path)
		ShowType.INFO:
			item = root.create_child()
			if path.get_extension() != "":
				item.set_text(0, path.get_basename().get_file())
			else:
				item.set_text(0, path.get_file())
			item.set_tooltip_text(0, path)
			item.set_text(1, path.get_extension().to_upper()) # 扩展名
			var file_size = FileUtil.get_file_size(path, FileUtil.SizeFlag.KB)
			item.set_tooltip_text(2, "%s KB" % str(snappedf(file_size, 0.01)))
			if file_size < 1000:
				item.set_text(2, "%s KB" % str(snappedf(file_size, 0.01)))
			else:
				file_size /= 1024
				if file_size < 1000:
					item.set_text(2, "%s MB" % str(snappedf(file_size, 0.01)))
				else:
					file_size /= 1024
					item.set_text(2, "%s GB" % str(snappedf(file_size, 0.01)))
			item.set_text(3, FileUtil.get_modified_time_string(path))
			item.set_meta(MetaKey.PATH, path)
		ShowType.TREE:
			var last_dir = ""
			var dirs = path.split("/")
			var parent_item : TreeItem
			for idx in dirs.size():
				var dir_name = dirs[idx]
				parent_item = get_item(last_dir)
				if parent_item == null:
					parent_item = root
				last_dir = last_dir.path_join(dir_name)
				if not _file_path_to_item.has(last_dir):
					# 没有父节点
					item = parent_item.create_child()
					_file_path_to_item[last_dir] = item
					item.set_text(0, dir_name)
					item.set_meta(MetaKey.PATH, last_dir)
					item.set_tooltip_text(0, last_dir)
	_file_path_to_item[path] = item
	assert(item != null, "不能没有 item")
	_file_path_dict[path] = null
	self.added_item.emit(path, item)
	return item

func get_item(path: String) -> TreeItem:
	return _file_path_to_item.get(path)

func remove_item(path: String) -> void:
	var item = get_item(path)
	if item:
		_file_path_to_item.erase(path)
		_file_path_dict.erase(path)
		self.removed_item.emit(path, item)
		item.get_parent().remove_child(item)

## 选中一个 Item
func select_item(path: String) -> void:
	var item = get_item(path)
	if item:
		item.select(0)

## 重新加载所有
func reload():
	clear()
	_file_path_to_item.clear()
	root = create_item()
	for file in _file_path_dict:
		add_item(file)

## 是否为空的
func is_empty() -> bool:
	return root.get_child_count() == 0

## 所有 Item
func clear_items():
	clear()
	root = create_item()
	_file_path_to_item.clear()
	_file_path_dict.clear()

## 更新 Item 路径
func update_item(file_path:String, new_path: String):
	var item = get_item(file_path)
	if item:
		var parent = item.get_parent()
		var idx = item.get_index()-1
		remove_item(file_path)
		add_item(new_path)
		if idx > -1:
			item = get_item(new_path)
			var previous_item = parent.get_child(idx)
			item.move_after(previous_item)

## 获取选中的文件
func get_selected_file() -> String:
	var item : TreeItem = get_selected()
	if item and item.has_meta(MetaKey.PATH):
		return item.get_meta(MetaKey.PATH)
	return ""

## 添加 Item 按钮
func add_item_button(path: String, texture: Texture2D, button_type:int) -> void:
	var item = get_item(path)
	columns = get_view_colums_count() + 1
	set_column_expand(columns-1, false)
	var idx = columns - 1
	item.add_button(idx, texture, button_type)

## 移除 Item 按钮
func remove_item_button(path: String, button_type: int):
	var item = get_item(path)
	item.erase_button(get_view_colums_count() + 1, button_type)

## 获取 Item 列表
func get_item_list() -> Array[String]:
	return Array(_file_path_dict.keys(), TYPE_STRING, "", null)

## 设置不可用状态
func set_disabled(path: String, disable: bool) -> void:
	var item : TreeItem = get_item(path)
	if item:
		if disable:
			if item.is_selectable(0):
				var color : Color = item.get_custom_color(0)
				if color == Color.BLACK:
					color = get_theme_color("font_color")
				color.a *= 0.5
				item.set_selectable(0, false)
				item.deselect(0)
				item.set_custom_color(0, color)
				item.set_icon_modulate(0, color)
		else:
			if not item.is_selectable(0):
				item.clear_custom_color(0)
				item.set_icon_modulate(0, Color.WHITE)
				item.set_selectable(0, true)

## 获取这个Item的路径
func get_item_path(item: TreeItem) -> String:
	return item.get_meta(MetaKey.PATH, "")


const _META_KEY_BIND_DATA = "_custom_data"
## 添加自定义数据
func add_custom_data(path: String, key, value) -> void:
	var item : TreeItem = get_item(path)
	if item: 
		if not item.has_meta(_META_KEY_BIND_DATA):
			item.set_meta(_META_KEY_BIND_DATA, {})
		var data := Dictionary(item.get_meta(_META_KEY_BIND_DATA))
		data[key] = value

## 获取自定义数据
func get_custom_data(path: String, key, default = null):
	var item : TreeItem = get_item(path)
	if item and item.has_meta(_META_KEY_BIND_DATA): 
		var data := Dictionary(item.get_meta(_META_KEY_BIND_DATA, {}))
		return data.get(key,  default)
	return default

## 移除自定义数据中的一个值
func remove_custom_data(path: String, key) -> void:
	var item : TreeItem = get_item(path)
	if item and item.has_meta(_META_KEY_BIND_DATA): 
		var data := Dictionary(item.get_meta(_META_KEY_BIND_DATA, {}))
		return data.erase(key)

## 清空自定义的数据
func clear_custom_data(path: String) -> void:
	var item : TreeItem = get_item(path)
	if item and item.has_meta(_META_KEY_BIND_DATA): 
		item.remove_meta(_META_KEY_BIND_DATA)

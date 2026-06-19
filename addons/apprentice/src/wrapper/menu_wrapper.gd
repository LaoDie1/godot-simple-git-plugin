#============================================================
#    Menu Wrapper
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-12 16:10:23
# - version: 4.4.0.dev
#============================================================
# NOTE 继承 Object 类型是因为防止在方法内添加这个对象
# 而这个对象在方法结束后引用就消失了，那会导致连接的信号失效

## 菜单包装器，方便的添加菜单项
class_name MenuWrapper
extends Object


## 菜单被点击
signal menu_pressed(id: int, menu_path: String)

var _id_to_menu_path_dict : Dictionary = {}
var _menu_path_to_id_dict : Dictionary = {}
var _path_to_menu_node_dict: Dictionary = {}
var _current_id: int = -1


var root_menu: PopupMenu:
	set(v):
		root_menu = v
		_register_menu(-1, "/", root_menu)

func _init(menu: PopupMenu = null) -> void:
	self.root_menu = menu

## 初始化菜单
func init_item(data: Variant):
	root_menu.clear(true)
	_current_id = -1
	_path_to_menu_node_dict.clear()
	_id_to_menu_path_dict.clear()
	_register_menu(-1, "/", root_menu)
	_add_item(data, "/")


func _add_item(item_data, parent_menu_path: String):
	parent_menu_path = valid_path(parent_menu_path)
	if item_data is String:
		add_item(item_data, parent_menu_path)
	elif item_data is Array:
		for i in item_data:
			_add_item(i, parent_menu_path)
	elif item_data is Dictionary:
		var parent_menu : PopupMenu = get_menu_node(parent_menu_path) as PopupMenu
		for sub_menu_name:String in item_data:
			var sub_menu_path : String = valid_path(parent_menu_path.path_join(sub_menu_name))
			if not has_menu(sub_menu_path):
				add_sub_item(sub_menu_name, parent_menu_path) # 添加子菜单
			_add_item(item_data[sub_menu_name], sub_menu_path)


## 有效路径。将路径转为有效的路径，防止格式不对导致错误
func valid_path(menu_path: String) -> String:
	if not menu_path.begins_with("/"):
		menu_path = "/" + menu_path
	if menu_path.ends_with("/"):
		menu_path = menu_path.trim_suffix("/")
	return menu_path


func get_menu_node(menu_path: String) -> PopupMenu:
	menu_path = valid_path(menu_path)
	return _path_to_menu_node_dict.get(menu_path, root_menu)

func has_menu_node(menu_path: String) -> bool:
	return _path_to_menu_node_dict.has(menu_path)

func has_menu(menu_path: String) -> bool:
	return _menu_path_to_id_dict.has(valid_path(menu_path))

func get_menu_path(id: int) -> String:
	return _id_to_menu_path_dict.get(id, "/")

func get_menu_id(menu_path: String) -> int:
	return _menu_path_to_id_dict.get(menu_path, -1)


func add_item(menu_name: String, parent_menu_path: String = "/", accel: Key = 0) -> int:
	if not menu_name.begins_with("-"):
		var menu_path : String = parent_menu_path.path_join(menu_name)
		if has_menu(menu_path):
			push_error("已经存在有这个菜单：", menu_path)
			return -1
		var parent_menu : PopupMenu = get_menu_node(parent_menu_path)
		_current_id += 1
		var id : int = _current_id
		parent_menu.add_item(menu_name, id, accel)
		_register_menu(id, menu_path, null)
		return id
	else:
		var parent_menu : PopupMenu = get_menu_node(parent_menu_path)
		parent_menu.add_separator()
		return -1

func get_id(menu_path: String) -> int:
	return _menu_path_to_id_dict.get(valid_path(menu_path), -1)


func _set_params(menu_path: String, method_name:StringName, arg_array:Array) -> void:
	menu_path = valid_path(menu_path)
	var menu : PopupMenu = get_menu_node(menu_path.get_base_dir())
	var id : int = get_id(menu_path)
	if id > -1:
		var index : int = menu.get_item_index(id)
		arg_array.push_front(index)
		menu.callv(method_name, arg_array)

func set_icon(menu_path: String, icon: Texture2D) -> void:
	_set_params(menu_path, "set_item_icon", [icon])

func set_check(menu_path: String, status: bool) -> void:
	_set_params(menu_path, "set_item_checked", [status])

func toggle_item_checked(menu_path: String) -> void:
	_set_params(menu_path, "toggle_item_checked", [])

func set_item_disabled(menu_path: String, disabled: bool) -> void:
	_set_params(menu_path, "set_item_disabled", [disabled])

func set_item_as_checkable(menu_path: String, status: bool) -> void:
	_set_params( menu_path, "set_item_as_checkable", [status])

func set_shortcut(menu_path: String, shortcut_str: String) -> void:
	var event : InputEventKey = parse_shortcut(shortcut_str)
	var shortcut : Shortcut = Shortcut.new()
	shortcut.events.push_back(event)
	var menu_id = get_menu_id(menu_path)
	_set_params(menu_path, "set_item_shortcut", [shortcut])

func add_sub_item(sub_menu_name: String, parent_menu_path: String) -> int:
	assert(sub_menu_name != "", "菜单名称不能为空")
	parent_menu_path = valid_path(parent_menu_path)
	# 添加子菜单节点
	var sub_menu : PopupMenu = PopupMenu.new()
	sub_menu.name = sub_menu_name.trim_prefix("/").trim_suffix("/")
	var parent_menu : PopupMenu = get_menu_node(parent_menu_path) as PopupMenu
	parent_menu.add_child(sub_menu)
	# 添加到父项中
	_current_id += 1
	var id : int = _current_id
	parent_menu.add_submenu_node_item(sub_menu_name, sub_menu, id)
	_register_menu(id, parent_menu_path.path_join(sub_menu_name), sub_menu)
	return id

## 返回添加的项的 id 列表
func add_items(menu_name_list: PackedStringArray, parent_menu_path: String = "/", accel: Key = 0) -> PackedInt32Array:
	var id_list : PackedInt32Array = []
	var id : int
	for menu_name in menu_name_list:
		id = add_item(menu_name, parent_menu_path, accel)
		id_list.push_back(id)
	return id_list


func _register_menu(id: int, menu_path: String, menu: PopupMenu) -> void:
	menu_path = valid_path(menu_path)
	_id_to_menu_path_dict[id] = menu_path
	_menu_path_to_id_dict[menu_path] = id
	_path_to_menu_node_dict[menu_path] = menu
	if menu and not menu.id_pressed.is_connected(_menu_id_pressed):
		menu.id_pressed.connect(_menu_id_pressed)


func add_item_by_path(menu_path: String, auto_create_parent_item: bool = true) -> int:
	menu_path = valid_path(menu_path)
	assert(not _menu_path_to_id_dict.has(menu_path), "不能存在有相同的名称的菜单")
	var items = menu_path.rsplit("/", true, 1)
	var parent_menu_path : String = items[0]
	if auto_create_parent_item:
		if not has_menu(parent_menu_path):
			var last_menu_path = "/"
			var list = parent_menu_path.split("/")
			for i in list:
				if not has_menu(last_menu_path.path_join(i)):
					add_sub_item(i, last_menu_path)
				last_menu_path = last_menu_path.path_join(i)
	
	var menu_name : String = items[1]
	return add_item(menu_name, parent_menu_path)


func queue_free():
	Engine.get_main_loop().queue_delete(self)


## 解析快捷键字符串。将 [code]Ctrl+S[/code] 转为 [code]{"ctrl": true, "keycode": KEY_S}[/code]
static func parse_shortcut(shortcut_text: String) -> InputEventKey:
	const CONTROL_KEY = ["ctrl", "shift", "alt"]
	var list = shortcut_text.split("+")
	var keymap : Dictionary = {
		"keycode": KEY_NONE,
		"ctrl": false,
		"shift": false,
		"alt": false,
	}
	for key in list:
		key = str(key).strip_edges().to_lower()
		if CONTROL_KEY.has(key):
			keymap[key] = true
		else:
			keymap["keycode"] = OS.find_keycode_from_string(key)
	var event := InputEventKey.new()
	event.keycode = keymap.keycode
	event.alt_pressed = keymap.alt
	event.ctrl_pressed = keymap.ctrl
	event.shift_pressed = keymap.shift
	return event


func _menu_id_pressed(id: int) -> void:
	var menu_path : String = get_menu_path(id)
	if menu_path:
		menu_pressed.emit(id, menu_path)

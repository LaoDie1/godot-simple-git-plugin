#============================================================
#    Data File
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-28 11:52:24
# - version: 4.2.1
#============================================================
## 用于管理和保存数据为文件的对象，或者用于对象属性的同步，方便对绑定的数据 key 进行统一的管理。通过 [method bind_object] 进行快速绑定节点进行数据的同步。
##如果绑定的是同一个 key，则在这个 key 的数据发生更改之后同步更新到绑定的对象上
##
##绑定节点的配置到数据里。在下次加载的时候，自动加载数据到这个节点中。
##[codeblock]
##data_file.bind_object($Button, "key_toggle_status")
##data_file.bind_object($LineEdit, "key_input_text", "这个对象的自定义默认值，也可以不传入保持缺省状态")
##[/codeblock]
##
##添加一个配置节点 [b]config.gd[/b] 脚本，添加到 [b]自动加载[/b] 中，即可快速创建程序的配置数据
##[codeblock]
##extends Node
##
##var data_file : DataFile = DataFile.instance(data_file_path)
##var exclude_config_propertys : Array[String] = ["exclude_config_propertys", "data_file"]
##
### Custom data
##var files: Array
##var current_path: String
##
##func _init():
##    # 加载 Config 数据
##    data_file.update_object_property(self, exclude_config_propertys)
##
##func _exit_tree() -> void:
##    # 保存 Config 数据
##    data_file.set_value_by_object(self, exclude_config_propertys)
##    data_file.save()
##[/codeblock]
##
##设置配置当前程序数据文件的方法：
##[codeblock]
#### 获取当前的配置文件
##static func get_config_file() -> DataFile:
##    var dir = OS.get_executable_path().get_base_dir()
##    var file_path = dir.path_join("config.data")
##    return DataFile.instance(file_path)
##[/codeblock]
##
class_name DataFile
extends RefCounted


signal value_changed(key, previous_value, value)


enum {
	BYTES,   ## 原始数据
	STRING,  ## 字符串类型数据。但对部分数据类型转换后会出现转换错误问题
}

## 文件所在路径
var file_path : String
## 数据
var data : Dictionary
## 保存的文件的数据格式
var data_format : int = BYTES

# 绑定的 key 计数
var _binded_key_count: Dictionary[Variant, int] = {}


## 实例化数据对象，如果不传入文件路径，则
##[br]
##[br]如果有这个文件，则会自动读取这个文件的数据，这个文件必须是 [Dictionary] 类型的数据
static func instance(file_path_: String, data_format_ : int = BYTES, default_data: Dictionary = {}) -> DataFile:
	var real_path = _get_real_path(file_path_)
	make_dir_if_not_exists(real_path.get_base_dir())
	
	const KEY = &"DataFile_singlton_dict"
	if not Engine.has_meta(KEY):
		Engine.set_meta(KEY, {})
	var data_file_dict : Dictionary = Engine.get_meta(KEY)
	if not data_file_dict.has(real_path): # 相同的文件路径返回的是单例对象
		var data_file := DataFile.new()
		data_file.file_path = real_path
		data_file.data_format = data_format_
		if FileAccess.file_exists(real_path):
			match data_format_:
				BYTES:
					var v = read_as_bytes_to_var(real_path)
					if v is Dictionary:
						data_file.data = v
				STRING:
					var v = read_as_str_var(real_path)
					if v is Dictionary:
						data_file.data = v
		data_file.data.merge(default_data, false)
		data_file_dict[real_path] = data_file
	return data_file_dict[real_path]


## 是否存在有这个 key 的数据
func has_value(key) -> bool:
	return data.has(key)

## 移除这个 key 的值
func remove_value(key) -> bool:
	return data.erase(key)

## 获取数据
func get_data() -> Dictionary:
	return data

## 获取数据的所有的 key
func get_keys() -> Array:
	return data.keys()

## 设置到对象这些属性
func update_object_property(object: Object, exclude_propertys: Array = []):
	for key in data:
		if (not exclude_propertys.has(key) 
			and key in object
		):
			object.set(key, data[key])

## 根据对象的脚本的属性设置值
func set_value_by_object(object: Object, exclude_propertys: Array = []):
	var script = object.get_script() as GDScript
	if script == null:
		return
	var p_name : String
	for p_data in script.get_script_property_list():
		p_name = p_data["name"]
		if not p_name in exclude_propertys and p_name in object:
			set_value(p_name, object[p_name])

## 获取数据值。如果没有这个值，则会自动添加默认值为这个 key 的值
func get_value(key, default : Variant = null, no_exists_add: bool = false) -> Variant:
	if not data.has(key):
		if typeof(default) != TYPE_NIL and no_exists_add:
			set_value(key, default)
		else:
			return default
	return data[key]

## 设置数据
##[br]
##[br]- [param force] 哪怕值相同也进行赋值处理，进行强制更新
func set_value(key, value, force: bool = false, _emit_signal: bool = true) -> void:
	var update_status : bool = false
	var previous : Variant = null
	if data.has(key):
		previous = data[key]
		if typeof(previous) != typeof(value) or previous != value or force:
			if _bind_node_data_dict.has(key):
				var items : Array = _bind_node_data_dict.get(key, [])
				for item in items:
					var object : Object = item[0]
					var property : String = item[1]
					var handle_callback : Callable = item[3]
					var condition_callback : Callable = item[4]
					if (typeof(object.get(property)) != typeof(value) 
						or object.get(property) != value
						or force
						or (not condition_callback.is_valid() or condition_callback.call(value))
					):
						if handle_callback.is_valid():
							value = handle_callback.call(value)
						data[key] = value
						object.set(property, value)
						update_status = true
			else:
				data[key] = value
				update_status = true
	else:
		data[key] = value
		update_status = true
	
	if update_status or force:
		# 更新绑定值的方法
		if _binded_method_dict.has(key):
			for callback: Callable in _binded_method_dict[key]:
				callback.call(value)
		if _emit_signal:
			value_changed.emit(key, previous, value)


var _bind_node_data_dict: Dictionary[Variant, Array] = {}

## 绑定这个节点，自动更新属性。他会自动绑定不同类型的 [Control] 节点的属性和信号。
##[br]
##[br]- [param set_value_handle_callback] 对 [param object] 调用 [method set_value] 修改其绑定的 key 值时触发这个方法。
##[b]需要返回处理或原来的数据值[/b]。这个方法需要有两个参数，第一个接收改变前的数据值，第二个参数接收当前的数据值
##[br]- [param update_condition_callback] 在调用 [method set_value] 修改当前绑定的 [param object] 的属性时，是否进行修改的条件判断。
##这个方法需要有一个参数接收修改时的数据
func bind_object(
	object: Object, 
	key, 
	default_value = null, 
	property : String = "", 
	set_value_handle_callback : Callable = Callable(),
	update_condition_callback: Callable = Callable()
) -> void:
	_binded_key_count[key] = _binded_key_count.get_or_add(key, 0) + 1
	
	if not object is Node and property.is_empty():
		const MESSAGE = "如果绑定的对象不是 Node 类型，则需要传入要同步绑定修改的 property 参数"
		push_error(MESSAGE)
		printerr(MESSAGE)
	
	if property:
		if object is Window:
			object.close_requested.connect(
				func(): 
					var value = object.get(property)
					set_value(key, value)
			)
		elif object is Node:
			object.tree_exiting.connect(
				func():
					var value = object.get(property)
					set_value(key, value)
			)
		
	else:
		# 自动绑定节点的信号
		if object is Control:
			var value_changed_callback : Callable = func(v):
				set_value(key, v)
			# 绑定信号
			if object is BaseButton:
				if object is OptionButton:
					property = "selected"
					object.item_selected.connect(value_changed_callback)
				elif object is ColorPickerButton:
					property = "color"
					object.color_changed.bind(value_changed_callback)
				else:
					property = "button_pressed"
					object.toggled.connect(value_changed_callback)
			elif object is Range:
				property = "value"
				object.value_changed.connect(value_changed_callback)
			elif object is LineEdit:
				property = "text"
				object.text_changed.connect(value_changed_callback)
			elif object is TextEdit:
				property = "text"
				object.text_changed.connect(
					func(): set_value(key, object.text)
				)
			elif object is SplitContainer:
				property = "split_offsets"
				object.drag_ended.connect(
					func(): set_value(key, object[property])
				)
			else:
				printerr("这个节点不是自动绑定的类型，请传入 property 参数的值")
	
	if property:
		_bind_node_data_dict.get_or_add(key, []).append([object, property, key, set_value_handle_callback, update_condition_callback])
		if typeof(default_value) == TYPE_NIL:
			set_value(key, get_value(key, object.get(property)), true)
		else:
			set_value(key, get_value(key, default_value), true)
	else:
		printerr("这个对象需要传入 property 参数绑定属性名: ", object)


var _binded_method_dict: Dictionary = {}
## 绑定值对象，属性改变时触发这个方法回调。这个回调方法需要有 1 个参数接收改变的 [code]value[/code] 值
##[br]
##[br] - [param first_call] 绑定的时候是否进行调用一次，进行一次初始的触发
##[br] - [param default_value] 第一次触发的时候，如果还没有这个 [code]key[/code] 的数据则自动设置为这个默认值 
func bind_method(key, callback: Callable, first_call: bool = false, default_value = null) -> void:
	_binded_key_count[key] = _binded_key_count.get_or_add(key, 0) + 1
	var callbacks : Array = _binded_method_dict.get_or_add(key, [])
	callbacks.append(callback)
	if not has_value(key) and typeof(default_value) !=  TYPE_NIL:
		set_value(key, default_value)
	if first_call:
		callback.call(get_value(key, default_value))


## 获取还未绑定的 Key
func get_unbind_keys() -> Array:
	var list := []
	for key in _binded_key_count:
		if _binded_key_count[key] == 0:
			list.append(key)
	return list


## 更新所有有关于绑定的节点的数据内容，从绑定的节点上获取数据，记录到当前数据缓存中。在退出程序前最好调用一次
func update_data_by_bind_nodes() -> void:
	for items in _bind_node_data_dict.values():
		for item in items:
			var object : Object = item[0]
			var property : String = item[1]
			var key = item[2]
			var v : Variant = object.get(property)
			set_value(key, v)

var _last_save_hash_value: int = -1
## 保存数据
func save() -> bool:
	if file_path:
		if data.hash() != _last_save_hash_value:
			_last_save_hash_value = data.hash()
			make_dir_if_not_exists(file_path.get_base_dir())
			match data_format:
				BYTES:
					return write_as_bytes(file_path, data)
				STRING:
					return write_as_str_var(file_path, data)
		else:
			print("数据未发生改变，未执行保存")
	else:
		printerr("没有设置文件名，保存失败")
	return false



#============================================================
#  文件操作
#============================================================
## 如果目录不存在，则进行创建
##[br]
##[br][code]return[/code] 如果不存在则进行创建并返回 [code]true[/code]，否则返回 [code]false[/code]
static func make_dir_if_not_exists(dir_path: String) -> bool:
	if not DirAccess.dir_exists_absolute(dir_path):
		if DirAccess.make_dir_recursive_absolute(dir_path) == OK:
			return true
	return false

## 读取字节数据
static func read_as_bytes(file_path: String) -> PackedByteArray:
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			return file.get_file_as_bytes(file_path)
	return PackedByteArray()

## 读取字节数据，并转为原来的数据
static func read_as_bytes_to_var(file_path: String) -> Variant:
	var bytes = read_as_bytes(file_path)
	if not bytes.is_empty():
		return bytes_to_var_with_objects(bytes)
	return null

## 读取字符串并转为变量数据
static func read_as_str_var(file_path: String) -> Variant:
	var text = FileAccess.get_file_as_string(file_path)
	if text:
		return str_to_var(text)
	return null


## 写入为二进制文件
static func write_as_bytes(file_path: String, data) -> bool:
	var bytes = var_to_bytes_with_objects(data)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_buffer(bytes)
		file.flush()
		return true
	return false

## 写入字符串变量数据
static func write_as_str_var(file_path: String, data) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var text = var_to_str(data)
		file.store_string(text)
		file.flush()
		return true
	return false


## 获取实际路径
static func _get_real_path(path: String) -> String:
	if OS.has_feature("editor"): # 编辑器中运行
		if path.is_relative_path():
			path = "res://".path_join(path)
		return ProjectSettings.globalize_path(path.simplify_path())
	else: # 导出后运行
		if path.begins_with("res://"):
			var relative_path : String = path.substr("res://".length())
			return OS.get_executable_path().get_base_dir().path_join(relative_path).simplify_path()
		elif path.begins_with("user://"):
			#var relative_path : String = path.substr("user://".length())
			#return OS.get_user_data_dir().path_join(relative_path)
			return ProjectSettings.globalize_path(path.simplify_path())
		elif path.is_relative_path():
			path = OS.get_executable_path().get_base_dir().path_join(path)
			return ProjectSettings.globalize_path(path.simplify_path())
		return path

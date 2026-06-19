#============================================================
#    Bind Property Item
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-29 13:14:59
# - version: 4.3.0.dev5
#============================================================
## 绑定属性项
##
##绑定属性后，设置修改这个项，会自动更新绑定的所有对象的属性。
class_name BindPropertyItem
extends RefCounted

signal value_changed(previous, value)

const META_KEY = &"_PropertyBindItem_value"

var _name: String
var _method_list : Array[Callable] = []
var _bind_propertys : Array[Dictionary] = []
var _value


func _init(name: String = "", value = null) -> void:
	_name = name
	_value = value


## 获取当前属性名
func get_name() -> String:
	return _name

## 值相同
func equals_value(value) -> bool:
	return typeof(_value) == typeof(value) and hash(_value) == hash(value) and _value == value

## 绑定对象属性到当前属性
func bind_property(object: Object, property: StringName, update: bool = false) -> BindPropertyItem:
	assert(property in object, "这个对象没有这个属性")
	_bind_propertys.append({
		"object": object,
		"property": property,
	})
	if update and typeof(_value) != TYPE_NIL and not equals_value(object[property]):
		object[property] = _value
		#print_debug("修改 ", object, " 的 ", property, " 属性为 ", _value)
	return self

## 获取绑定的对象的属性列表
func get_bind_property_list() -> Array[Dictionary]:
	return _bind_propertys

func get_bind_method_list() -> Array[Callable]:
	return _method_list

## 绑定方法。这个方法需要有 1 个参数接收这个发生变化的值
func bind_method(method: Callable, update: bool = false):
	_method_list.append(method)
	if update and typeof(_value) != TYPE_NIL:
		method.call(_value)


## 绑定信号到当前属性。这个信号需要有一个参数，接收改变的值
func bind_signal(_signal: Signal) -> BindPropertyItem:
	_signal.connect(update)
	return self


## 取消绑定属性
func unbind_property(object: Object, property):
	var data = hash([object, property])
	for idx in _bind_propertys.size():
		if hash(_bind_propertys[idx]) == data:
			_bind_propertys.remove_at(idx)
			break


## 断开绑定属性
func unbind_method(method: Callable):
	_method_list.erase(method)

func set_value(value):
	update(value)

## 更新属性
func update(value) -> void:
	if not equals_value(value):
		var previous = _value
		_value = value
		
		# 调用绑定的方法属性
		for method:Callable in _method_list:
			if method.is_valid():
				method.call(value)
		
		# 更新绑定的属性
		if not _bind_propertys.is_empty():
			var invalid_items : Array = [] #无效的项
			var object: Object
			var property: String
			for arg in _bind_propertys:
				object = arg.object
				if is_instance_valid(object):
					property = arg.property
					# 属性不同则进行更新
					if typeof(object[property]) != typeof(value) or object[property] != value or hash(object[property]) != hash(value):
						object.set(property, value)
				else:
					invalid_items.push_back(arg)
			
			# 删除无效的项
			if not invalid_items.is_empty():
				invalid_items.reverse()
				for item in invalid_items:
					_bind_propertys.erase(item)
		
		value_changed.emit(previous, value)


## 获取属性值
func get_value(default = null):
	if typeof(_value) == TYPE_NIL:
		return default
	return _value

func has_value() -> bool:
	return typeof(_value) != TYPE_NIL

## 获取这个值，如果没有则设置为默认值
func get_value_or_add(default = null):
	if typeof(_value) == TYPE_NIL:
		update(default)
		return default
	return _value


func get_number(default : float = 0.0) -> float:
	if typeof(_value) == TYPE_NIL:
		return default
	return float(_value)


func get_text(default: String = "") -> String:
	if typeof(_value) == TYPE_NIL:
		return default
	return str(_value)


func get_dictionary(default : Dictionary = {}) -> Dictionary:
	if typeof(_value) == TYPE_NIL:
		return default
	return Dictionary(_value)


func get_array(default : Array = [], type = null) -> Array:
	# 根据传入的 Type 数据设置数组的类型
	if typeof(type) != TYPE_NIL:
		var v = _value
		if typeof(v) == TYPE_NIL:
			v = default
		
		# 设置数组类型
		if type is int:
			return Array(v, type, &"", null)
		elif type is String:
			if ClassDB.class_exists(type):
				# 内置的类
				return Array(v, TYPE_OBJECT, type, null) 
			elif ClassDB.can_instantiate(type):
				# 脚本类
				var script = _get_script_by_global_name(type)
				return Array(v, TYPE_OBJECT, type, script) 
			else:
				assert(false, "不存在 %s 这个名称的类" % type)
		elif type is Object:
			if type is Script:
				if type.get_global_name() != &"":
					return Array(v, TYPE_OBJECT, type.get_global_name(), type) 
				else:
					return Array(v, TYPE_OBJECT, type.get_instance_base_type(), type) 
			else:
				return Array(v, TYPE_OBJECT, "", type) 
	
	if typeof(_value) == TYPE_NIL:
		return default
	else:
		return _value


static var _script_by_global_name_dict : Dictionary = {}
static func _get_script_by_global_name(global_name: StringName) -> GDScript:
	if not _script_by_global_name_dict.has(global_name):
		var script = GDScript.new()
		script.source_code = "var script_object = %s as GDScript" % global_name
		script.reload()
		_script_by_global_name_dict[global_name] = script.script_object
	return _script_by_global_name_dict[global_name]

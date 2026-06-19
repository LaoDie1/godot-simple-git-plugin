#============================================================
#    Property Item
#============================================================
# - author: zhangxuetu
# - datetime: 2024-06-12 13:24:41
# - version: 4.5
#============================================================
##属性项。监听属性的值发生的变化。用于 [DynamicProperties] 类的属性对象
class_name PropertyItem
extends RefCounted

##  数据发生改变
##[br]- [param previous]  改变前的数据值
##[br]- [param current]  改变后的当前的数据值
signal value_changed(previous, current)

var _property
var _value: Variant = null

func _init(property = null, default = null):
	_property = property
	_value = default

func _to_string():
	var s_name = get_script().get_global_name()
	var id = get_instance_id()
	return "<%s#%d>" % [s_name, id]

## 设置值。如果参数 [param _emit_signal] 值为 [code]true[/code] 则会发出属性改变信号。
func set_value(value, _emit_signal: bool = true) -> void:
	if typeof(_value) != typeof(value) or _value != value:
		if _emit_signal:
			var previous = _value
			_value = value
			value_changed.emit(previous, _value)
		else:
			_value = value
		
		if _bind_data:
			var object: Object
			var property
			var set_object_handle_method: Callable 
			for data in _bind_data:
				object = data[0]
				property = data[1]
				set_object_handle_method = data[2]
				object.set(property, set_object_handle_method.call(_value) if set_object_handle_method.is_valid() else _value)


## 清除数据。回到默认数据
func clear() -> void:
	set_value(DataUtil.get_default_value( typeof(_value) ))

var _type: int 
## 添加值。大多数数据进行 [kbd]+[/kbd] 运算，默认第一个项为[code]属性值[/code]，第二个项为[code]是否要发送信号的状态[/code]。如果这个属性的值为 [Dictionary]，则第一个项为 [code]key[/code]，第二个项为 [code]value[/code]，第三个项为[code]是否要发送信号的状态[/code]。
##[br]
##[br]如果修改的是 [Array] 或 [Dictionary] 类型的值，则最好不要频繁调用，或者调用时不要发送信号，否则它会频繁的创建数据的副本以用来发送 [signal value_changed] 信号
func add_value(...params) -> void:
	_type = typeof(_value)
	if _type in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING, TYPE_OBJECT, TYPE_STRING_NAME, TYPE_VECTOR2, TYPE_VECTOR2I]:
		set_value(_value + params[0], params[1] if params.size() > 1 else true)
	elif _type in [
		TYPE_ARRAY,
		TYPE_DICTIONARY,
		TYPE_STRING,
		TYPE_STRING_NAME,
		TYPE_NODE_PATH,
		TYPE_PACKED_BYTE_ARRAY,
		TYPE_PACKED_INT32_ARRAY,
		TYPE_PACKED_INT64_ARRAY,
		TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_PACKED_FLOAT64_ARRAY,
		TYPE_PACKED_STRING_ARRAY,
		TYPE_PACKED_VECTOR2_ARRAY,
		TYPE_PACKED_VECTOR3_ARRAY,
		TYPE_PACKED_COLOR_ARRAY,
		TYPE_PACKED_VECTOR4_ARRAY,
	]:
		var _emit_signal: bool = true
		if params.size() > 1:
			_emit_signal = params[1]
		# 追加数组的值
		if _emit_signal:
			var previous : Variant = _value.duplicate()
			_value.append(params[0])
			value_changed.emit(previous, _value)
		else:
			_value.append(params[0])
	elif _type == TYPE_DICTIONARY:
		# 追加字典的值
		var key = params[0]
		var value = null
		if params.size() > 1:
			value = params[1]
		var _emit_signal: bool = true
		if params.size() > 2:
			_emit_signal = params[2]
		if _emit_signal:
			var previous = _value.duplicate()
			_value[value] = value
			value_changed.emit(previous, _value)
		else:
			_value[value] = value
	else:
		set_value(_value + params[0], params[1] if params.size() > 1 else true)

## 减去值。[kbd]-[/kbd] 运算
func sub_value(...params)-> void:
	_type = typeof(_value)
	if _type in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING, TYPE_OBJECT, TYPE_STRING_NAME, TYPE_VECTOR2, TYPE_VECTOR2I]:
		set_value(_value - params[0], params[1] if params.size() > 1 else true)
	elif _type in [
		TYPE_ARRAY,
		TYPE_DICTIONARY,
		TYPE_STRING,
		TYPE_STRING_NAME,
		TYPE_NODE_PATH,
		TYPE_PACKED_BYTE_ARRAY,
		TYPE_PACKED_INT32_ARRAY,
		TYPE_PACKED_INT64_ARRAY,
		TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_PACKED_FLOAT64_ARRAY,
		TYPE_PACKED_STRING_ARRAY,
		TYPE_PACKED_VECTOR2_ARRAY,
		TYPE_PACKED_VECTOR3_ARRAY,
		TYPE_PACKED_COLOR_ARRAY,
		TYPE_PACKED_VECTOR4_ARRAY,
	]: 
		# erase 操作
		var _emit_signal : bool = true
		if params.size() > 1:
			_emit_signal = params[1]
		if _emit_signal:
			var previous = _value.duplicate()
			_value.erase(params[0])
			value_changed.emit(previous, _value)
		else:
			_value.erase(params[0])
	elif _type == TYPE_DICTIONARY:
		# erase 操作
		var key = params[0]
		var _emit_signal : bool = true
		if params.size() > 1:
			_emit_signal = params[1]
		if _emit_signal:
			var previous = _value.duplicate()
			_value.erase(key)
			value_changed.emit(previous, _value)
		else:
			_value.erase(key)
	else:
		set_value(_value - params[0], params[1] if params.size() > 1 else true)

## 乘以值。[kbd]*[/kbd] 运算
func mul_value(value) -> void:
	set_value(_value * value)

## 除以值。 [kbd]/[/kbd] 运算
func div_value(value) -> void:
	set_value(_value / value)

## 与运算。传入的值需要是 [int] / [bool] 值
func and_value(value) -> void:
	if value is int:
		set_value(get_int() & value)
	elif value is bool:
		set_value(get_bool() and value)
	else:
		set_value(value)

## 或运算。传入的值需要是 [int] / [bool] 值
func or_value(value) -> void:
	if value is int:
		set_value(int(_value) | value)
	elif value is bool:
		set_value(bool(_value) or value)
	else:
		set_value(value)

## 拿取值，如果拿取的值超出原来的值，则返回剩余的值
func take_value(value: float) -> float:
	if not is_zero_approx(value):
		if _value >= value:
			set_value(_value - value)
		else:
			value = _value
			set_value(0)
		return value
	return _value

## 值是否相同。只对值进行比较。引用数据根据 [method @GlobalScope.hash] 值进行断
func equals(value) -> bool:
	return typeof(value) == typeof(_value) and hash(value) == hash(_value)

## 值是否是 [code]null[/code]
func is_null() -> bool:
	return typeof(_value) == TYPE_NIL

## 是否为空的数据
func is_empty() -> bool:
	var type := typeof(_value)
	return (
		type == TYPE_NIL 
		or (
			type in [
				TYPE_ARRAY,
				TYPE_DICTIONARY,
				TYPE_STRING,
				TYPE_STRING_NAME,
				TYPE_NODE_PATH,
				TYPE_PACKED_BYTE_ARRAY,
				TYPE_PACKED_INT32_ARRAY,
				TYPE_PACKED_INT64_ARRAY,
				TYPE_PACKED_FLOAT32_ARRAY,
				TYPE_PACKED_FLOAT64_ARRAY,
				TYPE_PACKED_STRING_ARRAY,
				TYPE_PACKED_VECTOR2_ARRAY,
				TYPE_PACKED_VECTOR3_ARRAY,
				TYPE_PACKED_COLOR_ARRAY,
				TYPE_PACKED_VECTOR4_ARRAY,
			] and _value.is_empty()
		)
		or (type in [TYPE_FLOAT, TYPE_INT] and is_zero_approx(_value))
	)

## 值为零
func is_zero() -> bool:
	return (_value is float or _value is int) and is_zero_approx(_value)

## 自动增加
func incr(value: int = 1) -> int:
	if typeof(_value) not in [TYPE_INT, TYPE_FLOAT]:
		_value = 0
	set_value(_value + value, true)
	return _value

## 自动减少
func decr(value: int = 1) -> int:
	if typeof(_value) not in [TYPE_INT, TYPE_FLOAT]:
		_value = 0
	set_value(_value - value, true)
	return _value

## 值为 [/code]true[/code]
func is_true() -> bool:
	return _value is bool and _value

## 获取当前对象的属性
func get_property_name():
	return _property

##获取这个属性当前的值
func get_value() -> Variant:
	return _value

## 获取数据。如果数据为 [code]null[/code]，则自动添加默认值并返回
func get_or_add(default = null) -> Variant:
	if typeof(_value) != TYPE_NIL:
		_value = default
	return _value

## 以 [bool] 类型返回这个值
func get_bool() -> bool:
	return bool(_value) if typeof(_value) != TYPE_NIL else false

## 以 [float] 类型返回这个值
func get_float() -> float:
	return float(_value) if typeof(_value) != TYPE_NIL else 0.0

## 以 [int] 类型返回这个值
func get_int() -> int:
	return int(_value) if typeof(_value) != TYPE_NIL else 0

## 以 [String] 类型返回这个值
func get_string() -> String:
	return str(_value) if typeof(_value) != TYPE_NIL else ""

# 类型化数组和字典中的对应类名的脚本信息
static var __class_to_script_path_dict__ : Dictionary = {}
static func __find_script_path__(_class_name: String) -> String:
	if not __class_to_script_path_dict__.has(_class_name):
		for d in ProjectSettings.get_global_class_list():
			if d["class"] == _class_name:
				__class_to_script_path_dict__[_class_name] = d["path"]
				return d["path"]
	return __class_to_script_path_dict__.get(_class_name, "")


const _NAME_TO_DATA_TYPE : Dictionary[String, int] = {
	&"null": TYPE_NIL,
	&"bool": TYPE_BOOL,
	&"int": TYPE_INT,
	&"float": TYPE_FLOAT,
	&"String": TYPE_STRING,
	&"Rect2": TYPE_RECT2,
	&"Vector2": TYPE_VECTOR2,
	&"Vector2i": TYPE_VECTOR2I,
	&"Vector3": TYPE_VECTOR3,
	&"Vector3i": TYPE_VECTOR3I,
	&"Transform2D": TYPE_TRANSFORM2D,
	&"Vector4": TYPE_VECTOR4,
	&"Vector4i": TYPE_VECTOR4I,
	&"Plane": TYPE_PLANE,
	&"Quaternion": TYPE_QUATERNION,
	&"AABB": TYPE_AABB,
	&"Basis": TYPE_BASIS,
	&"Transform3D": TYPE_TRANSFORM3D,
	&"Projection": TYPE_PROJECTION,
	&"Color": TYPE_COLOR,
	&"StringName": TYPE_STRING_NAME,
	&"NodePath": TYPE_NODE_PATH,
	&"RID": TYPE_RID,
	&"Object": TYPE_OBJECT,
	&"Callable": TYPE_CALLABLE,
	&"Signal": TYPE_SIGNAL,
	&"Dictionary": TYPE_DICTIONARY,
	&"Array": TYPE_ARRAY,
	&"PackedByteArray": TYPE_PACKED_BYTE_ARRAY,
	&"PackedInt32Array": TYPE_PACKED_INT32_ARRAY,
	&"PackedInt64Array": TYPE_PACKED_INT64_ARRAY,
	&"PackedStringArray": TYPE_PACKED_STRING_ARRAY,
	&"PackedVector2Array": TYPE_PACKED_VECTOR2_ARRAY,
	&"PackedVector3Array": TYPE_PACKED_VECTOR3_ARRAY,
	&"PackedFloat32Array": TYPE_PACKED_FLOAT32_ARRAY,
	&"PackedFloat64Array": TYPE_PACKED_FLOAT64_ARRAY,
	&"PackedColorArray": TYPE_PACKED_COLOR_ARRAY,
}


## 以 [Array] 类型返回这个值。如果传入的参数不为 [code]null[/code]，则返回类型化数组。
##[br] - [param type] 值可以是 [enum Variant.Type]、类名、脚本类名对象、内置类名或者脚本类名。
##内置类默认按照 [Object] 类型的数组进行返回
func get_array(type : Variant = null) -> Array:
	if typeof(_value) == TYPE_NIL:
		# 如果当前的值为 null 则设置默认值空数组
		_value = []
	if typeof(type) == TYPE_NIL:
		# 获取的数组没有类型，则直接返回这个值
		return _value
	
	if _value.get_typed_builtin() == TYPE_NIL:
		if type is int:
			_value = Array(_value, type, &"", null)
		elif type is String or type is StringName:
			if _NAME_TO_DATA_TYPE.has(type):
				var _data_type : int = _NAME_TO_DATA_TYPE[type]
				_value = Array(_value, _data_type, &"", null)
			elif ClassDB.class_exists(type):
				_value = Array(_value, TYPE_OBJECT, type, null)
			else:
				var path : String = __find_script_path__(type)
				if path and ResourceLoader.exists(path):
					var script : Script = load(path)
					_value = Array(_value, TYPE_OBJECT, script.get_instance_base_type(), script)
				else:
					push_error("不存在的类 %s" % type)
		elif type is Script:
			_value = Array(_value, TYPE_OBJECT, type.get_instance_base_type(), type)
		elif type is Object:
			# 内部类参数，按照 Object 类型的数组进行处理
			var _obj_string : String = var_to_str(type)
			if _obj_string.begins_with('Object(GDScriptNativeClass,"script":null)'):
				_value = Array(_value, TYPE_OBJECT, "Object", null)
	return _value

## 以 [Dictionary] 类型返回这个值。如果传入的参数不为 [code]null[/code]，则返回类型化字典
##[br]
##[br]- [param key_type]  key 键名的类型。值可以是 [enum Variant.Type]、类名、脚本类名对象、内部类名或者脚本类名。
##[br]- [param value_type]  value 数据值的类型。值可以是 [enum Variant.Type]、类名、脚本类名对象、内部类名或者脚本类名。
func get_dictionary(key_type : Variant = null, value_type : Variant = null) -> Dictionary:
	if typeof(key_type) == TYPE_NIL and typeof(value_type) == TYPE_NIL:
		return Dictionary(_value)
	else:
		var _key_type: int = TYPE_NIL
		var _key_class_name: StringName = &""
		var _key_script: Script = null
		if key_type is String or key_type is StringName:
			if _NAME_TO_DATA_TYPE.has(key_type):
				_key_type = _NAME_TO_DATA_TYPE[key_type]
			else:
				_key_type = TYPE_OBJECT
				_key_class_name = key_type
				if not ClassDB.class_exists(_key_class_name):
					var script_path : String = __find_script_path__(_key_class_name)
					if script_path and ResourceLoader.exists(script_path):
						_key_script = load(script_path)
		elif key_type is Script:
			_key_type = TYPE_OBJECT
			_key_class_name = key_type.get_instance_base_type()
			_key_script = key_type
		
		var _value_type: int = TYPE_NIL
		var _value_class_name: StringName = &""
		var _value_script: Script = null
		if value_type is String or value_type is StringName:
			if _NAME_TO_DATA_TYPE.has(value_type):
				_value_type = _NAME_TO_DATA_TYPE[value_type]
			else:
				_value_type = TYPE_OBJECT
				_value_class_name = value_type
				if not ClassDB.class_exists(_value_class_name):
					var script_path : String = __find_script_path__(_value_class_name)
					if script_path and ResourceLoader.exists(script_path):
						_value_script = load(script_path)
		elif value_type is Script:
			_value_type = TYPE_OBJECT
			_value_class_name = value_type.get_instance_base_type()
			_value_script = value_type
		
		_value = Dictionary(_value, _key_type, _key_class_name, _key_script, _value_type, _value_class_name, _value_script)
	return _value

var _bind_data: Array = []
## 绑定这个对象的属性。在这个属性项的值发生改变的时候同步更新这个对象的属性
##[br]
##[br]- [param object]  要绑定的对象
##[br]- [param property]  设置的这个对象的属性值
##[br]- [param immediately_update]  是否立即将值更新到这个对象上
##[br]- [param set_object_handle_method]  对设置的到这个对象上的值重新进行加工处理。这个方法需要有一个参数用于接收要处理的值
func bind_object(object: Object, property: String, immediately_update: bool = true, set_object_handle_method: Callable = Callable()):
	_bind_data.append([object, property, set_object_handle_method])
	if immediately_update:
		object[property] = set_object_handle_method.call(_value) if set_object_handle_method.is_valid() else _value

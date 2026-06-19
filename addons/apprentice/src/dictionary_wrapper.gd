#============================================================
#    Dictionary Wrapper
#============================================================
# - author: zhangxuetu
# - datetime: 2025-12-31 19:17:49
# - version: 4.5.1.stable
#============================================================
class_name DictionaryWrapper

var data : Dictionary


func get_var(key) -> Variant:
	return data.get(key)

func get_string(key) -> String:
	return data.get(key, "")

func get_int(key) -> int:
	return int(data.get(key, 0))

func get_float(key) -> float:
	return float(data.get(key, 0.0))

func get_bool(key) -> bool:
	return bool(data.get(key, false))

func get_vector2(key) -> Vector2:
	return Vector2( data.get(key, Vector2()) )

func get_vector2i(key) -> Vector2i:
	return Vector2i( data.get(key, Vector2i()) )

func get_vector3(key) -> Vector3:
	return Vector3( data.get(key, Vector3()) )

func get_vector3i(key) -> Vector3i:
	return Vector3i( data.get(key, Vector3i()) )

func get_vector4(key) -> Vector4:
	return Vector4( data.get(key, Vector4()) )

func get_vector4i(key) -> Vector4i:
	return Vector4i( data.get(key, Vector4i()) )

func get_rect2(key) -> Rect2:
	return Rect2(data.get(key, Rect2()))

func get_rect2i(key) -> Rect2i:
	return Rect2i( data.get(key, Rect2i()) )

func get_callable(key) -> Callable:
	return Callable(data.get(key, Callable()))


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

# 类型化数组和字典中的对应类名的脚本信息
var __class_to_script_path_dict__ : Dictionary = {}
func __find_script_path__(_class_name: String) -> String:
	if not __class_to_script_path_dict__.has(_class_name):
		for d in ProjectSettings.get_global_class_list():
			if d["class"] == _class_name:
				__class_to_script_path_dict__[_class_name] = d["path"]
				return d["path"]
	return __class_to_script_path_dict__.get(_class_name, "")


## 以 [Array] 类型返回这个值。如果传入的参数不为 [code]null[/code]，则返回类型化数组。
##[br] - [param type] 值可以是 [enum Variant.Type]、类名、脚本类名对象、内部类名或者脚本类名。
##内部类默认按照 [Object] 类型的数组进行返回
func get_array(key, type : Variant = null) -> Array:
	var value : Variant = data.get(key, [])
	if typeof(value) == TYPE_NIL:
		# 如果当前的值为 null 则设置默认值空数组
		value = []
	
	if typeof(type) == TYPE_NIL:
		# 获取的数组没有类型，则直接返回这个值
		return value
	
	if value.get_typed_builtin() == TYPE_NIL:
		if type is int:
			value = Array(value, type, &"", null)
		elif type is String or type is StringName:
			if _NAME_TO_DATA_TYPE.has(type):
				var _data_type : int = _NAME_TO_DATA_TYPE[type]
				value = Array(value, _data_type, &"", null)
			elif ClassDB.class_exists(type):
				value = Array(value, TYPE_OBJECT, type, null)
			else:
				var path : String = __find_script_path__(type)
				if path and ResourceLoader.exists(path):
					var script : Script = load(path)
					value = Array(value, TYPE_OBJECT, script.get_instance_base_type(), script)
				else:
					push_error("不存在的类 %s" % type)
		elif type is Script:
			value = Array(value, TYPE_OBJECT, type.get_instance_base_type(), type)
		elif type is Object:
			# 内部类参数，按照 Object 类型的数组进行处理
			var _obj_string : String = var_to_str(type)
			if _obj_string.begins_with('Object(GDScriptNativeClass,"script":null)'):
				value = Array(value, TYPE_OBJECT, "Object", null)
	return value


## 以 [Dictionary] 类型返回这个值。如果传入的参数不为 [code]null[/code]，则返回类型化字典
##[br]
##[br]- [param key_type]  key 键名的类型。值可以是 [enum Variant.Type]、类名、脚本类名对象、内部类名或者脚本类名。
##[br]- [param value_type]  value 数据值的类型。值可以是 [enum Variant.Type]、类名、脚本类名对象、内部类名或者脚本类名。
func get_dictionary(key, key_type : Variant = null, value_type : Variant = null) -> Dictionary:
	var value : Variant = data.get(key, {})
	if typeof(key_type) == TYPE_NIL and typeof(value_type) == TYPE_NIL:
		return Dictionary(value)
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
		else:
			_key_type = TYPE_NIL
			_key_class_name = &""
			_key_script = null
		
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
		else:
			_value_type = TYPE_NIL
			_value_class_name = &""
			_value_script = null
		
		value = Dictionary(value, _key_type, _key_class_name, _key_script, _value_type, _value_class_name, _value_script)
	return value

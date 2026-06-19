#============================================================
#    Data Util
#============================================================
# - datetime: 2022-12-21 21:19:10
#============================================================
## 数据工具
##
##用作全局获取数据使用
class_name DataUtil

static var _data : Dictionary = {}

##  获取场景树 [SceneTree] 对象的 meta 数据作为单例数据，如果返回的数据为 [code]null[/code]
## 则会在下次继续调用这个 default 回调方法，直到返回的数据不为 [code]null[/code] 为止 
##[br]
##[br]- [param key]  数据的 key
##[br]- [param default]  如果没有这个key，则默认返回的数据
##[br]- [param ignore_null]  忽略 null 值。如果为 true，则在默认值为 null 的时候不记录到元数据，直到有数据为止
static func singleton(key: StringName, default: Callable = Callable(), ignore_null: bool = true):
	if _data.has(key) and _data.get(key) != null:
		return _data.get(key)
	else:
		if default.is_valid():
			var value = default.call()
			if ignore_null:
				if value != null:
					_data[key] = value
			else:
				_data[key] = value
			return value
		return null


## 是否有这个 key 的据
static func has_singleton(key: StringName) -> bool:
	return _data.has(key)

##  移除数据
static func remove_singleton(key: StringName) -> bool:
	return _data.erase(key)

## 移除所有单例数据
static func clear_all_singleton() -> void:
	for key in Engine.get_meta_list():
		_data.erase(key)

## 获取 Autoload 节点
static func get_auotload(name: String) -> Node:
	return Engine.get_main_loop().root.get_node_or_null(name)


##  获取 [Dictionary] 数据
static func singleton_dict(key: StringName, default: Dictionary = {}) -> Dictionary:
	return _data.get_or_add(key, default)


##  获取 [Array] 数据
static func singleton_array(key: StringName, default: Array = []) -> Array:
	if Engine.has_meta(key):
		return Engine.get_meta(key)
	else:
		Engine.set_meta(key, default)
		return default


## 获取目标的默认数据，以目标对象作为基础存储数据
static func singleton_from_object(object: Object, key: StringName, default: Callable ):
	if object.has_meta(key):
		return object.get_meta(key)
	else:
		var data = default.call()
		object.set_meta(key, data)
		return data


## 获取标 [Dictionary] 类型数据 
static func singleton_dict_from_object(object: Object, key: StringName, default: Dictionary = {}) -> Dictionary:
	return singleton_from_object(object, key, func(): return default)


## 获取类型化数组
##[br]
##[br][code]_class[/code]  数据的类型。比如 [code]"Dictionary", Node, Sprite2D[/code] 等类名（基础数据类型需要加双引号），
##或者自定义类名 Player，或者字符串形式的类名，或者 TYPE_INT, TYPE_DICTIONARY
##[br][code]default[/code]  默认有哪些数据
static func get_type_array(_class, default : Array = []) -> Array:
	# 返回类型化数组
	var data := ObjectUtil.get_class_info(_class)
	return Array(default, data["type"], data["class_name"], data["script"] )


## 转为类型化数组
static func to_type_array(iterator, _class) -> Array:
	if iterator is Dictionary:
		return get_type_array(_class, iterator.keys())
	return get_type_array(_class, Array(iterator))


## 数组转为字典
##[br]
##[br]示例，将节点列表转为，以 node.name 为 key 的字典
##[codeblock]
##var dict_data = DataUtil.to_dictionary( 
##    node_list, 
##    func(node): return node.name, # key 键
##    func(node): return node 
##) 
##[/codeblock]
static func to_dictionary(
	list: Array, 
	get_key: Callable = Callable(), 
	get_value: Callable = Callable()
) -> Dictionary:
	if get_key.is_null() and get_value.is_null():
		var data : Dictionary = {}
		for i in list:
			data[i] = null
		return data
	else:
		if get_key.is_null():
			get_key = func(item): return item
		if get_value.is_null():
			get_value = func(item): return null
		var data : Dictionary = {}
		var key
		var value
		for i in list:
			key = get_key.call(i)
			value = get_value.call(i)
			data[key] = value
		return data


## 引用数据
class RefObjectData:
	
	var value
	
	func _init(value) -> void:
		self.value = value
	
	func _to_string():
		return str(value)
	
	func get_value():
		return value
	
	func queue_free() -> void:
		if value is Object:
			ObjectUtil.queue_free(value)
	


## 获取引用数据。
##[br]
##[br][b]Note:[/b] 主要用在匿名函数里，以处理基本数据类型的值。因为匿名函数之外的基本数据类型的值
##在匿名函数修改不会发生改变。
static func get_ref_data(default, dependent: Object = null) -> RefObjectData:
	var r_data = RefObjectData.new(default)
	if dependent != null and dependent is Node:
		dependent.tree_exited.connect(Engine.get_main_loop().queue_delete.bind(r_data))
	return r_data


## 获取字典的值，如果没有，则获取并设置默认值
##[br]
##[br][code]dict[/code]  获取的字典
##[br][code]key[/code]  key 键
##[br][code]not_exists_set[/code]  没有则返回值设置这个值。这个参数值若是 Callabe，则会自动数据为调用的返回结果
static func get_value_or_add(dict: Dictionary, key, not_exists_set = null):
	if dict.has(key) and not typeof(dict[key]) == TYPE_NIL:
		return dict[key]
	else:
		if not_exists_set is Callable and not_exists_set.is_valid():
			dict[key] = not_exists_set.call()
		else:
			dict[key] = not_exists_set
		return dict[key]

## 获取这个字典的键的值
static func get_value(dict: Dictionary, key, default = null) -> Variant:
	return dict.get(key, default)


## 生成id
static func generate_id(data) -> StringName:
	if data is Array:
		var list : Array = []
		for i in data:
			list.append(hash(i))
		return "id_%s" % ",".join(list).sha1_text()
	elif data is Dictionary:
		return &"id_%d" % data.hash()
	elif data is Resource:
		return get_res_id(data)
	elif data is Object:
		return &"id_%d" % data.get_instance_id()
	else:
		return &"id_%d" % hash(data)


## 如果不为空值结果值
class NotNullValueChain:
	
	var _value
	
	func _init(value) -> void:
		_value = value
	
	func get_value(default : Variant = null) -> Variant:
		return _value
	
	func or_else(object, else_object: Callable) -> NotNullValueChain:
		return NotNullValueChain.new( object if object else else_object.call() )
	
	## 返回结果不为空时，这个方法需要一个参数接收值
	func if_not_null(else_object: Callable, default : Variant = null) -> NotNullValueChain:
		var value : Variant = get_value()
		return NotNullValueChain.new( else_object.call(value) if value else default )


##  如果对象不为 null 则调用。可以链式调用逐步执行功能
##[codeblock]
##func get_data(object: Object):
##    return DataUtil.if_not_null(object, func():
##        return object.get_script()
##    ).or_else(func():
##        print("")
##    ).get_value()
##[/codeblock]
static func if_not_null(object, else_object: Callable) -> NotNullValueChain:
	return NotNullValueChain.new((
		else_object.call() if object != null else object
	))


## 获取正则
static func get_regex(pattern: String) -> RegEx:
	var re = RegEx.new()
	re.compile(pattern)
	return re

static func get_regex_math_data(regex_match: RegExMatch) -> Dictionary:
	var data := {}
	for name in regex_match.names:
		if regex_match.get_string(name):
			data[name] = regex_match.get_string(name)
	return data

##  合并数据
##[br]
##[br][code]merge_to[/code]  合并到的目标
##[br][code]data[/code]  要追加合并的数据
##[br][return]return[/return]  返回合并后的数据
static func merge(merge_to, data) -> Variant:
	if merge_to is Dictionary:
		if data is Dictionary:
			merge_to.merge(data, true)
		else:
			for item in data:
				merge_to[item] = null
	elif merge_to is Array:
		if data is Array:
			merge_to.append_array(data)
		elif data is Dictionary:
			merge_to.append_array(data.keys())
		else:
			merge_to.append(data)
	else:
		merge_to += data
	return merge_to


static var _data_id : int = -1
## 获取一个唯一的数字 ID，从 0 始
static func get_id() -> int:
	_data_id += 1
	return _data_id


## 列表转为集合hash值，这样即便列表顺序不一致他的值也是相同的
static func as_set_hash(list: Array) -> int:
	var tmp = list.map(func(item): return hash(item))
	tmp.sort()
	return tmp.hash()


## 去除重复
static func remove_duplicates(list: Array) -> Array:
	var dict = {}
	for i in list:
		dict[i] = null
	return dict.keys()


## 格式化 _to_string 的字符串
static func format_to_string(object: Object, _class_name: StringName = &"") -> String:
	if _class_name == &"":
		var script : Script = object.get_script()
		if script:
			if script.get_global_name():
				_class_name = script.get_global_name()
			else:
				_class_name = script.resource_path \
					.get_basename() \
					.get_file() \
					.capitalize() \
					.replace(" ", "")
		else:
			_class_name = object.get_class()
	if object is Node:
		return "%s:<%s#%s>" % [object.name, _class_name, object.get_instance_id()]
	else:
		return "<%s#%s>" % [_class_name, object.get_instance_id()]

## 数据是否为 null
static func is_null(data) -> bool:
	return typeof(data) == TYPE_NIL

## 数据是否不为 null
static func not_null(data) -> bool:
	return typeof(data) != TYPE_NIL

## 值是否为数字
static func is_number(value) -> bool:
	return typeof(value) in [TYPE_FLOAT, TYPE_INT]

static func get_float(data: Dictionary, key, default: float = 0.0) -> float:
	return float(data.get(key, default))

static func get_int(data: Dictionary, key, default: int = 0) -> int:
	return int(data.get(key, default))

static func get_string(data: Dictionary, key, default: String = "") -> String:
	return str(data.get(key, default))

static func get_bool(data: Dictionary, key, default: bool = false) -> bool:
	return bool(data.get(key, default))

static func get_array(data: Dictionary, key, default: Array = []) -> Array:
	return Array(data.get(key, default))

static func get_dictionary(data: Dictionary, key, default: Dictionary = {}) -> Dictionary:
	return Dictionary(data.get(key, default))


static func erase(key, data: Dictionary) -> bool:
	return data.erase(key)


static func offset(value, offset_value):
	return value + offset_value

static func offset_array(list: Array, value) -> Array:
	var arr : Array = list.duplicate()
	offset_origin_array(arr, value)
	return arr

## 偏移整个数组，他会修改原数组，而非产生新的数组
static func offset_origin_array(list: Array, value) -> Array:
	if value:
		for idx in list.size():
			list[idx] += value
	return list

static func append(data, value):
	if data is Dictionary:
		data[value] = null
	else:
		data += value

static func append_to(value, to_data):
	if to_data is Dictionary:
		to_data[value] = null
	else:
		to_data += value

static func duplicates(value, deep: bool = false):
	if value is Dictionary or value is Array or value is Object:
		return value.duplicate(deep)
	else:
		return value

static func equals(a, b) -> bool:
	return typeof(a) == typeof(b) and hash(a) == hash(b)

## 获取这个数据类型的默认值
static func get_default_value(type: int) -> Variant:
	match type:
		TYPE_INT: return 0
		TYPE_FLOAT: return 0.0
		TYPE_STRING: return ""
		TYPE_STRING_NAME: return &""
		TYPE_BOOL: return false
		TYPE_NIL, TYPE_OBJECT: return null
		TYPE_VECTOR2: return Vector2()
		TYPE_VECTOR2I: return Vector2i()
		TYPE_RECT2: return Rect2()
		TYPE_RECT2I: return Rect2i()
		TYPE_VECTOR3: return Vector3()
		TYPE_VECTOR3I: return Vector3i()
		TYPE_TRANSFORM2D: return Transform2D()
		TYPE_VECTOR4: return Vector4()
		TYPE_VECTOR4I: return Vector4i()
		TYPE_PLANE: return Plane()
		TYPE_QUATERNION: return Quaternion()
		TYPE_AABB: return AABB()
		TYPE_BASIS: return Basis()
		TYPE_TRANSFORM3D: return Transform3D()
		TYPE_PROJECTION: return Projection()
		TYPE_COLOR: return Color()
		TYPE_STRING_NAME: return StringName()
		TYPE_NODE_PATH: return NodePath()
		TYPE_RID: return RID()
		TYPE_CALLABLE: return Callable()
		TYPE_SIGNAL: return Signal()
		TYPE_DICTIONARY: return Dictionary()
		TYPE_ARRAY: return Array()
		TYPE_PACKED_BYTE_ARRAY: return PackedByteArray()
		TYPE_PACKED_INT32_ARRAY: return PackedInt32Array()
		TYPE_PACKED_INT64_ARRAY: return PackedInt64Array()
		TYPE_PACKED_FLOAT32_ARRAY: return PackedFloat32Array()
		TYPE_PACKED_FLOAT64_ARRAY: return PackedFloat64Array()
		TYPE_PACKED_STRING_ARRAY: return PackedStringArray()
		TYPE_PACKED_VECTOR2_ARRAY: return PackedVector2Array()
		TYPE_PACKED_VECTOR3_ARRAY: return PackedVector3Array()
		TYPE_PACKED_COLOR_ARRAY: return PackedColorArray()
		_:
			assert(false, "没有添加这种类型")
			return null

## 获取资源ID
static func get_res_id(resource: Resource) -> StringName:
	#if resource.resource_path:
		#return &"id_%d" % hash(resource.resource_path)
	return &"id_%d" % hash(resource.get_instance_id())


## 打乱原数组项的顺序
static func shuffle(iterator: Array, random_number_generator: RandomNumberGenerator = null) -> Array:
	var tmp: Variant
	var j : int 
	for i:int in range(iterator.size() - 1, 0, -1):
		# 生成 0 到 i 之间的随机整数（包含 i）
		j = (random_number_generator.randi() if random_number_generator else randi()) % (i + 1)
		# 交换第 i 个和第 j 个元素
		tmp = iterator[i]
		iterator[i] = iterator[j]
		iterator[j] = tmp
	return iterator


## 随机选取一个项
static func pick_random(iterator: Array, random_number_generator: RandomNumberGenerator = null) -> Variant:
	if iterator.is_empty():
		return null
	return iterator[(random_number_generator.randi() if random_number_generator else randi()) % iterator.size()]


##[br]简化连续共线的点
##[br]
##[br]- [param points]: 原始点数组 (PackedVector2Array)
##[br]- [param epsilon]: 容差值 (默认 0.1，值越大越宽松，允许轻微偏离直线的点被移除)
##[br]- [param is_closed]: 是否为闭合多边形 (默认 true，会检查首尾点的连接)
##[br]
##[br]返回: 简化后的点数组
static func simplify_collinear_points(points: PackedVector2Array, epsilon: float = 0.1, is_closed: bool = true) -> PackedVector2Array:
	if points.size() < 3:
		return points.duplicate()

	var simplified = PackedVector2Array()
	simplified.append(points[0]) # 始终保留第一个点

	# 遍历中间点
	for i in range(1, points.size() - 1):
		var prev = simplified[simplified.size() - 1]
		var curr = points[i]
		var next = points[i + 1]

		# 计算叉积：(curr - prev) cross (next - prev)
		var cross = (curr - prev).cross(next - prev)
		
		# 如果叉积的绝对值大于容差，说明不共线，保留当前点
		if abs(cross) > epsilon:
			simplified.append(curr)

	# 保留最后一个点
	simplified.append(points[points.size() - 1])

	# 如果是闭合多边形，额外检查首尾和倒数第二个点是否共线
	if is_closed and simplified.size() >= 3:
		var first = simplified[0]
		var last = simplified[simplified.size() - 1]
		var second_last = simplified[simplified.size() - 2]
		
		var cross = (second_last - last).cross(first - last)
		if abs(cross) <= epsilon:
			simplified.remove_at(simplified.size() - 2)
	return simplified


static func get_fill_array(size: int = 0, default_value = null) -> Array:
	var array = [] 
	array.resize(size)
	array.fill(default_value)
	return array


## 找到第一个对应 [param key] 值的数据。这个 key 不区分大小写和数据类型
static func find_first_key_value(data: Dictionary, key: Variant) -> Variant:
	var tmp_key = str(key).to_lower()
	for k in data:
		if str(k).to_lower() == key:
			return data[k]
	return null

static func to_v3(v: Vector2) -> Vector3:
	return Vector3(v.x, v.y, 0.0)

#============================================================
#    Hash Set
#============================================================
# - author: zhangxuetu
# - datetime: 2023-05-25 10:09:55
# - version: 4.0
#============================================================
## 集合对象。用于处理那些不重复的，数量较多且频繁需要对比的数据。
class_name HashSet

var _data : Dictionary = {}


func _init(iterator = null) -> void:
	if typeof(iterator) != TYPE_NIL:
		append_iterator(iterator)

func _to_string():
	return "<%s#%s>" % ["HashSet", get_instance_id()]


## 从可迭代数据中创建
static func create_from_iterator(value) -> HashSet:
	var s = HashSet.new()
	s.append_iterator(value)
	return s

## 添加元素
func append(value) -> void:
	_data[value] = null

## 添加一组数据
func append_array(values: Array) -> void:
	merge(values, true)

## 添加迭代器数据。数据需要是可以迭代的值
func append_iterator(values) -> void:
	merge(values, true)

## 擦除这个数据
func erase(value) -> bool:
	return _data.erase(value)

## 合并数据
func merge(values, overwrite: bool = false) -> void:
	if values is Dictionary:
		_data.merge(values, overwrite)
	else:
		if overwrite:
			for i in values:
				_data[i] = null
		else:
			for i in values:
				if not _data.has(i):
					_data[i] = null

## 清除所有数据
func clear() -> void:
	_data.clear()

## 是否有这个值的数据
func has(value) -> bool:
	return _data.has(value)

## 是否存在所有这些数据
func has_all(values) -> bool:
	if values is HashSet:
		return _data.has_all(values.to_array())
	elif values is Array:
		return _data.has_all(values)
	return false

## 转为 [Array] 类型
func to_array() -> Array:
	return _data.keys()

## 数据数量
func size() -> int:
	return _data.size()

## 是否为空的集合
func is_empty() -> bool:
	return _data.is_empty()

## 复制一份数据
func duplicate(deep: bool = true) -> HashSet:
	if deep:
		return HashSet.create_from_iterator(_data.keys())
	else:
		var hashset = HashSet.new()
		hashset._data = self._data
		return hashset

## 数据的哈希值
func hash() -> int:
	return _data.keys().hash()

## 返回一个随机值
func pick_random():
	return _data.keys().pick_random()

func get_data() -> Dictionary:
	return _data

func get_index_value(index: int) -> Variant:
	return _data.keys()[index]


## 是否相同
func equals(hash_set: HashSet) -> bool:
	return _data.hash() == hash_set._data.hash()

## 有部分内容相同
func any(hash_set: HashSet) -> bool:
	# 有存在相同的部分
	for item in hash_set.to_array():
		if _data.has(item):
			return true
	return false

## 所有内容都相同
func all(hash_set: HashSet) -> bool:
	# 没有不同的部分
	return hash_set._data.has_all(_data.keys())


func map(method: Callable) -> HashSet:
	return HashSet.create_from_iterator( to_array().map(method) )

func filter(method: Callable) -> HashSet:
	return HashSet.create_from_iterator( to_array().filter(method) )

func slice(begin: int, end: int = 0x7FFFFFFF, step: int = 1, deep: bool = false) -> HashSet:
	return HashSet.create_from_iterator( to_array().slice(begin, end, step, deep) )

## 并集。两个集合中的所有的元素合并后的集合
func union(hash_set: HashSet) -> HashSet:
	var tmp = HashSet.create_from_iterator(_data.keys())
	tmp.merge(hash_set)
	return tmp

## 交集。两个集合中都存在的元素的集合
func intersection(hash_set: HashSet) -> HashSet:
	var list = []
	var tmp = HashSet.create_from_iterator(self.to_array())
	tmp.append_array(hash_set.to_array())
	for item in tmp:
		if has(item) and hash_set.has(item):
			list.append(item)
	return HashSet.create_from_iterator(list)


## 差集。两个集合之间存在有不相同的元素的集合
func difference(hash_set: HashSet) -> HashSet:
	var list = []
	var tmp = HashSet.create_from_iterator(self.to_array())
	tmp.append_array(hash_set.to_array())
	for item in tmp:
		if not has(item) or not hash_set.has(item):
			list.append(item)
	return HashSet.create_from_iterator(list)


## 补集/余集。a 集合中不在此集合的元素的集合
func complementary(hash_set: HashSet) -> HashSet:
	var list = []
	if self.has_all(hash_set):
		for item in _data:
			if not hash_set.has(item):
				list.append(item)
	return HashSet.create_from_iterator(list)


## 减去集合中的元素后的集合
func subtraction(hash_set: HashSet) -> HashSet:
	var list = []
	for item in _data.keys():
		if not hash_set.has(item):
			list.append(item)
	return HashSet.create_from_iterator(list)

func _get(property):
	if property.is_valid_int():
		var items = _data.keys()
		return items[int(property)]
	return null

#============================================================
#  迭代器
#============================================================
var _iter_tmp : Array
var _current : int = 0

func _iter_init(arg):
	_current = 0
	_iter_tmp = _data.keys()
	return _current < _iter_tmp.size()

func _iter_next(arg):
	_current += 1
	return _current < _iter_tmp.size()

func _iter_get(arg):
	return _iter_tmp[_current]

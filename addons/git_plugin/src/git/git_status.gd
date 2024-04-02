#============================================================
#    Git Status
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 22:42:34
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Status


static func execute(params: Array = []):
	var command = ["git", "status"]
	command.append_array(params)
	var result = await GitPlugin_Console.execute(command)
	return _handle_result(result)


# 分组。每个项的第一个为这个组的类别
static func __group(output: Array) -> Array[Array]:
	var data : Array[Array] = []
	var group = []
	for line in output:
		# 新的一块
		if line == "":
			if not group.is_empty():
				data.append(group)
			group = []
		else:
			group.append(line)
	if not group.is_empty():
		data.append(group)
	return data


# __group 结果中的每个组里的每个项，祛除其他杂乱的项
static func __get_group_items(group: Array) -> Array:
	for i in group.size():
		if group[i].begins_with("\t"):
			return group.slice(i).map(func(item: String): return item.trim_prefix("\t") ) # 去掉前面的\t
	return []


static func _handle_result(output: Array):
	var data : Dictionary = {}
	for group:Array in __group(output):
		data[group[0]] = __get_group_items(group)
	return data

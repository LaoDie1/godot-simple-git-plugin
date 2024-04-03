#============================================================
#    Git Status
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 22:42:34
# - version: 4.2.1.stable
#============================================================
## 文件状态  https://blog.csdn.net/weixin_44567318/article/details/119701438
class_name GitPlugin_Status


static func get_files():
	var result = await GitPlugin_Console.execute(["git status -s"])
	
	#第一列字符表示版本库与暂存区之间的比较状态。
	#第二列字符表示暂存区与工作区之间的比较状态。
	
	#' ' （空格）表示文件未发生更改
	#M 表示文件发生改动。
	#A 表示新增文件。
	#D 表示删除文件。
	#R 表示重命名。
	#C 表示复制。
	#U 表示更新但未合并。
	#? 表示未跟踪文件。
	#! 表示忽略文件。
	
	for item in result:
		pass
	


static func execute():
	var command = ["git status -u" ]
	var result = await GitPlugin_Console.execute(command)
	return _handle_result(result)


static var _block_regex: RegEx:
	get:
		if _block_regex == null:
			_block_regex = RegEx.new()
			_block_regex.compile("^\\w+")
		return _block_regex

# 分组。每个项的第一个为这个组的类别
static func __group(output: Array) -> Array[Array]:
	var data : Array[Array] = []
	var group = []
	for line in output:
		# 新的一块
		if _block_regex.search(line) != null:
			if not group.is_empty():
				data.append(group)
			group = []
			if line:
				group.append(line)
		else:
			if line:
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

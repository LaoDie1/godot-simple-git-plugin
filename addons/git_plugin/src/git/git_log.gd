#============================================================
#    Git Log
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 23:00:46
# - version: 4.2.1.stable
#============================================================
## 查看提交记录日志
class_name GitPlugin_Log


static func execute():
	var output = await GitPlugin_Console.execute(["git", "log", "--stat"])
	return _handle_result(output)


# 处理结果
static func _handle_result(output):
	var _regex = RegEx.new()
	_regex.compile("^commit (\\w+)")
	# 对每次提交进行分组
	var list = []
	var group = []
	for line in output:
		if line:
			if _regex.search(line):
				_append(list, group)
				group = []
				group.append(line)
			else:
				group.append(line)
	_append(list, group)
	return list


static func _append(list: Array, group: Array):
	if not group.is_empty():
		var tmp = group.slice(0, 4)
		var files = group.slice(4, group.size() - 1)
		tmp.append(files)
		tmp.append(group.back())
		list.append(tmp)


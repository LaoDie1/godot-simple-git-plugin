#============================================================
#    Git Log
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 23:00:46
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Log


static func execute():
	var output = await GitPlugin_Console.execute(["git", "log"])
	return _handle_result(output)


static func _handle_result(output):
	var _regex = RegEx.new()
	_regex.compile("^commit (\\w+)")
	
	var list = []
	var group = []
	for line in output:
		if line:
			if _regex.search(line):
				if not group.is_empty():
					list.append(group)
				group = []
				group.append(line)
			else:
				group.append(line)
	if not group.is_empty():
		list.append(group)
	
	return list

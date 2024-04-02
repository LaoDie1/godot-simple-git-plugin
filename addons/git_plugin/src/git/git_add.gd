#============================================================
#    Git Add
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 01:02:55
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Add


static func execute(params):
	var command = ["git", "add"]
	if params is Array or params is PackedStringArray:
		command.append_array(params)
	elif params is String:
		command.append(params)
	else:
		assert(false, "错误的参数类型")
	return await GitPlugin_Console.execute(command)

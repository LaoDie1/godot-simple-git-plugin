#============================================================
#    Git Add
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 01:02:55
# - version: 4.2.1.stable
#============================================================
## 添加文件
class_name GitPlugin_Add


static func execute(file_or_files):
	var command = ["git", "add"]
	if file_or_files is Array or file_or_files is PackedStringArray:
		command.append_array(file_or_files)
	elif file_or_files is String:
		command.append(file_or_files)
	else:
		assert(false, "错误的参数类型")
	var result = await GitPlugin_Executor.execute(command)
	return result["output"]

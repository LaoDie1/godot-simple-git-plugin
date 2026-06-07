#============================================================
#    Git Show
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-06 16:47:58
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Show


## 此次提交的文件列表
static func files(commit_id: String) -> Array[String]:
	var result : Dictionary = await GitPlugin_Executor.execute("git show --name-only %s" % commit_id)
	var output : String = result["output"]
	
	var lines : PackedStringArray = output.split("\n")
	# 找到文件所在行，从这一行开始
	var from_line_idx : int = 0
	for line:String in lines:
		if not line.begins_with(" ") and FileAccess.file_exists(line.strip_edges()):
			break
		from_line_idx += 1
	
	# 所有文件
	var files : Array[String] = []
	for i in range(from_line_idx, lines.size()):
		files.append(lines[i])
	
	return files

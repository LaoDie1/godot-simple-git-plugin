#============================================================
#    Git Add
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 01:02:55
# - version: 4.2.1.stable
#============================================================
## 添加文件
class_name GitPlugin_Add


static func add_one(file: String) -> Dictionary:
	# 使用文件路径的方式添加
	var result = await GitPlugin_Executor.execute("git add %s" % file)
	return result


static func execute(file_or_files) -> Dictionary:
	var files : PackedStringArray
	if file_or_files is Array or file_or_files is PackedStringArray:
		files = PackedStringArray(file_or_files)
	elif file_or_files is String:
		files = PackedStringArray([file_or_files])
	else:
		printerr("错误的参数类型", typeof(file_or_files), file_or_files)
	
	# 将所有文件添加到文本里
	var tmp_path : String = OS.get_temp_dir().path_join("git_add_list.tmp")
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	for f:String in files:
		file.store_line(f) # 每行一个路径
	file.close()
	
	# 使用文件路径的方式添加
	var result = await GitPlugin_Executor.execute("git add --pathspec-from-file=%s " % tmp_path)
	return result

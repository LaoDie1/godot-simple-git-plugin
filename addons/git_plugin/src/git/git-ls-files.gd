#============================================================
#    Git-ls-files
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 19:47:53
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_ls_files


## 列出所有跟踪的文件
static func all():
	return await GitPlugin_Console.execute(["git ls-files"])


static func get_unstaged_changes():
	var deleted = await GitPlugin_Console.execute(["git ls-files --deleted"])
	var modified = await GitPlugin_Console.execute(["git ls-files --modified"])
	var other: Array = await GitPlugin_Console.execute(["git ls-files", " --other", "-- . ':!.godot/*' "])
	
	return {
		"deleted": deleted,
		"modified": modified,
		"other": other,
	}

#============================================================
#    Git Restore
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-04 13:55:15
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Restore


static func execute(files: Array):
	if files.is_empty():
		return
	
	var command = ["git restore --staged"]
	command.append_array(files)
	var result = await GitPlugin_Executor.execute(command)
	return result["output"]

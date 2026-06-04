#============================================================
#    Git Reset
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 13:02:43
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Reset


static func execute():
	var result = await GitPlugin_Executor.execute("git reset HEAD")
	return result["output"]

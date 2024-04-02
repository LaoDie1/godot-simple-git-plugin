#============================================================
#    Git Log
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 23:00:46
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Log


static func execute():
	return await GitPlugin_Console.execute(["git", "log"])

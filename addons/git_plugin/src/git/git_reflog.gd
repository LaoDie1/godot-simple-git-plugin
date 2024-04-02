#============================================================
#    Git Reflog
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 23:03:46
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Reflog


static func execute():
	return await GitPlugin_Console.execute(["git", "reflog"])

#============================================================
#    Git Init
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 22:46:39
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Init


static func execute():
	return await GitPlugin_Console.execute(["git", "init"])

#============================================================
#    Git Push
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 23:02:48
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Push


static func execute():
	return await GitPlugin_Console.execute(["git", "push"])

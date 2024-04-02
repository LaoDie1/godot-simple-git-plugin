#============================================================
#    Git Pull
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 23:03:14
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Pull


static func execute():
	return await GitPlugin_Console.execute(["git", "pull"])

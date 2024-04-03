#============================================================
#    Git Pull
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 23:03:14
# - version: 4.2.1.stable
#============================================================
## 拉取合并，更新到新代码
class_name GitPlugin_Pull


static func execute(remote_name: String = "", branch_name: String = ""):
	
	return await GitPlugin_Console.execute(["git", "pull"])

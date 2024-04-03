#============================================================
#    Git Branch
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 09:38:34
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Branch


## 所有分支
static func all():
	var result = await GitPlugin_Console.execute(["git", "branch", "-a"])
	
	
	return result



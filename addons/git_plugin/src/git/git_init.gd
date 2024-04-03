#============================================================
#    Git Init
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 22:46:39
# - version: 4.2.1.stable
#============================================================
## 初始化 git
class_name GitPlugin_Init


static func execute(branch_name: String = "main"):
	var result = await GitPlugin_Console.execute(["git", "init"])
	GitPlugin_Console.execute(["git", "branch", "-M", branch_name])




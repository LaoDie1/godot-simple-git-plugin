#============================================================
#    Git Init
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 22:46:39
# - version: 4.2.1.stable
#============================================================
## 初始化 git
class_name GitPlugin_Init


static func execute(branch_name: String = "master"):
	var init_result = await GitPlugin_Executor.execute(["git", "init"])
	var branch_result = await GitPlugin_Executor.execute(["git", "branch", "-M", branch_name])
	




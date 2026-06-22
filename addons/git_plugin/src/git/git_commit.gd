#============================================================
#    Git Commit
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 22:53:41
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Commit

## 提交这次添加的文件
static func execute(desc: String) -> String:
	var result = await GitPlugin_Executor.execute('git commit -m "%s"' % desc)
	return result["output"]

## 所有提交了还未推送的 commit id 列表
static func rev_list(request: GitPlugin_CommandRequest = null) -> Array:
	var current_branch_name : String = await GitPlugin_Branch.show_current()
	#var result = await GitPlugin_Executor.execute(r'git rev-list "%s..HEAD"' % current_branch_name, request)
	var result = await GitPlugin_Executor.execute(r'git rev-list HEAD --not --remotes=origin' % current_branch_name, request)
	if result["error"] == OK:
		return str(result["output"]).split("\n")
	else:
		printerr(result["output"])
	return []

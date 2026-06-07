#============================================================
#    Git Push
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 23:02:48
# - version: 4.2.1.stable
#============================================================
## 推送
class_name GitPlugin_Push


## 设置推流
static func set_upstream(remote_name: String, branch_name: String) -> String:
	var result = await GitPlugin_Executor.execute("git push --set-upstream %s %s " % [remote_name, branch_name])
	return result["output"]


## 执行推送
static func execute(remote_name: String, branch_name: String) -> String:
	var result = await GitPlugin_Executor.execute("git push -u %s %s" % [remote_name, branch_name] )
	if result["error"] == OK:
		print("推送完成")
	else:
		printerr(result["output"])
	return result["output"]

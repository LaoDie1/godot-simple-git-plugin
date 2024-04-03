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
static func set_upstream(remote_name: String, branch_name: String):
	return await GitPlugin_Console.execute(["git", "push", "--set-upstream", remote_name, branch_name], 30)


## 执行推送
static func execute(remote_name: String = "", branch_name: String = ""):
	var command = ["git", "push"]
	if remote_name != "":
		command.append_array([ "-u", remote_name, branch_name ])
	return await GitPlugin_Console.execute(command)

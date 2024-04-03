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
static func set_upstream(short_name: String, branch_name: String):
	return await GitPlugin_Console.execute(["git", "push", "--set-upstream", short_name, branch_name])


## 执行推送
static func execute(short_name: String = "", branch_name: String = ""):
	var command = ["git", "push"]
	if short_name != "":
		command.append_array([ "-u", short_name, branch_name ])
	return await GitPlugin_Console.execute(command)

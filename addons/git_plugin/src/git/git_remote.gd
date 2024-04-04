#============================================================
#    Git Remote
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 08:20:23
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Remote


static func version():
	var result = await GitPlugin_Executor.execute(["git", "remote", "-v"])
	return result["output"]


static func add(remote_name: String, url: String):
	var command = ["git", "remote", "add", remote_name, url]
	return (
		await GitPlugin_Executor.execute(command)
	)["output"]


static func remove(remote_name: String):
	return (
		await GitPlugin_Executor.execute(["git", "remote", "rm", remote_name])
	)["output"]

## 修改仓库名
static func rename(old_remote_name: String, new_remote_name: String):
	return (
		await GitPlugin_Executor.execute(["git", "remote", "rename", old_remote_name, new_remote_name])
	)["output"]

## 显示远程仓库信息
static func show(remote_name: String):
	return (
		await GitPlugin_Executor.execute(["git", "remote", "show", remote_name])
	)["output"]



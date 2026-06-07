#============================================================
#    Git Remote
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 08:20:23
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Remote


## 冗长信息显示
static func verbose() -> String:
	var result = await GitPlugin_Executor.execute("git remote --verbose")
	return result["output"]

## 仓库名列表
static func list() -> Array:
	var result = await GitPlugin_Executor.execute("git remote")
	return str(result["output"]).split("\n")

## 添加仓库
static func add(name: String, url: String) -> String:
	return (
		await GitPlugin_Executor.execute("git remote add %s %s " % [name, url])
	)["output"]

## 移除仓库
static func remove(name: String) -> String:
	return (
		await GitPlugin_Executor.execute("git remote rm %s" % name)
	)["output"]

## 修改仓库名
static func rename(old_remote_name: String, new_remote_name: String) -> String:
	return (
		await GitPlugin_Executor.execute("git remote rename %s %s" % [old_remote_name, new_remote_name])
	)["output"]


## 显示远程仓库信息
static func show(name: String) -> String:
	# TODO 处理信息
	var result = await GitPlugin_Executor.execute("git remote show %s" % name)
	return result["output"]


## 检查是否是有效的 URL
static func valid_url(url: String) -> bool:
	var result = await GitPlugin_Executor.execute("git ls-remote %s" % url)
	return result["error"] == OK

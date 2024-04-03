#============================================================
#    Git Remote
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 08:20:23
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Remote


static func version():
	var result = await GitPlugin_Console.execute(["git", "remote", "-v"])
	return result


static func add(short_name: String, url: String):
	var command = ["git", "remote", "add", short_name, url]
	return await GitPlugin_Console.execute(command)


static func remove(short_name: String):
	return await GitPlugin_Console.execute(["git", "remote", "rm", short_name])

## 修改仓库名
static func rename(old_short_name: String, new_short_name: String):
	return await GitPlugin_Console.execute(["git", "remote", "rename", old_short_name, new_short_name])

## 显示远程仓库信息
static func show(short_name: String):
	return await GitPlugin_Console.execute(["git", "remote", "show", short_name])



#============================================================
#    Git Log
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 23:00:46
# - version: 4.2.1.stable
#============================================================
## 查看提交记录日志
class_name GitPlugin_Log


static func execute():
	# 格式化输出
	var output = await GitPlugin_Console.execute(['git log --pretty="%H;;;%cd;;;%s\t" --date=iso'])
	return _handle_result(output)


# 处理结果
static func _handle_result(output):
	# 对每次提交进行分组
	var list = []
	for line:String in output:
		if line != "":
			var items = line.split(";;;")
			list.append({
				"id": items[0],
				"date": items[1].substr(0, 19),
				"desc": items[2].strip_edges(),
			})
	return list

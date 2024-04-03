#============================================================
#    Terminal
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 12:56:04
# - version: 4.2.1.stable
#============================================================
# Linux / MacOS 平台
extends GitPlugin_Shell


func _execute(command):
	var output = []
	var p = command.pop_front()
	var err = OS.execute(p, command, output)
	if err != OK:
		printerr("执行失败：", err, " ", error_string(err) )
	return output

#============================================================
#    Command Prompt
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 12:56:11
# - version: 4.2.1.stable
#============================================================
# Windows CMD
extends GitPlugin_Shell


func _execute(command: Array):
	var output = []
	var c = ["/C"]
	c.append_array(command)
	var err = OS.execute("CMD.exe", c, output)
	if err != OK:
		printerr("执行失败：", err, " ", error_string(err) )
	return output

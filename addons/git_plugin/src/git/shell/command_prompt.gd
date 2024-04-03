#============================================================
#    Command Prompt
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 12:56:11
# - version: 4.2.1.stable
#============================================================
# Windows CMD
extends GitPlugin_Shell


func _execute(command):
	var output = []
	OS.execute("CMD.exe", command, output)
	return output

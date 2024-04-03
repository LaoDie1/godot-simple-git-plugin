#============================================================
#    Power Shell
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 12:56:06
# - version: 4.2.1.stable
#============================================================
# Windows PowerShell
extends GitPlugin_Shell


func _execute(command):
	var output = []
	if str(command[0]).to_lower() != "-command":
		command.push_front("-Command")
	OS.execute("powershell.exe", command, output)
	return output

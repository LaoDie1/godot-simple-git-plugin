#============================================================
#    03.add Git
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-31 00:26:46
# - version: 4.4.0.beta1
#============================================================
## 添加改动的文件到 Git 上
extends AbstractCustomMenu


func _get_menu_name():
	return "添加改动到 git"

func _execute():
	OS.execute("git", ["add", "."])
	var output = []
	OS.execute("git", ["status"], output)
	print(output[0])

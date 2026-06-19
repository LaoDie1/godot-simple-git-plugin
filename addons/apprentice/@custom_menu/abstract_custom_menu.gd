#============================================================
#    Abstract Custom Menu
#============================================================
# - author: zhangxuetu
# - datetime: 2024-11-30 20:54:57
# - version: 4.3.0.stable
#============================================================
@abstract
class_name AbstractCustomMenu
extends RefCounted


func _enter():
	pass

func _exit():
	pass

## 快捷键
func _get_shortcut() -> Shortcut:
	return null

@abstract
func _execute()

@abstract
func _get_menu_name()

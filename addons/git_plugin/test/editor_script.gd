#============================================================
#    Editor Script
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 23:31:14
# - version: 4.2.1.stable
#============================================================
@tool
extends EditorScript


func _run() -> void:
	var text : String = "娣诲姞鎻掍欢鍒扮紪杈戝櫒涓?"
	
	print(text.unicode_at(0))
	
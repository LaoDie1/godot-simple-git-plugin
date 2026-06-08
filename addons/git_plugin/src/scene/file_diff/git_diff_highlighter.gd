#============================================================
#    Git Diff Highlighter
#============================================================
# - author: zhangxuetu
# - datetime: 2026-06-08 18:02:04
# - version: 4.7.0.beta5
#============================================================
@tool
class_name GitPlugin_DiffHighlighter
extends SyntaxHighlighter

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var text_edit : TextEdit = get_text_edit()
	
	var data : Dictionary = {}
	var text : String = text_edit.get_line(line)
	if text.begins_with("+"):
		data[0] = {"color": Color.LIME_GREEN}
	elif text.begins_with("-"):
		data[0] = {"color": Color.RED}
	elif text.begins_with("@@ "):
		data[0] = {"color": Color.AQUA}
		var end : int = text.find(" @@", 3) + 3
		var default_color : Color = text_edit.get_theme_color("font_color")
		data[end] = {"color": default_color}
	
	return data

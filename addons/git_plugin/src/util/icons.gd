#============================================================
#    Icons
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-06 18:10:18
# - version: 4.2.1.stable
#============================================================
class_name GitPlugin_Icons

const ICON = preload("uid://dmomu7e45rfed")

static func get_icon_by_path(file: String) -> Texture2D:
	match file.get_extension():
		"gd": return get_icon("Script")
		"tscn", "scn": return get_icon("PackedScene")
		"tres", "res": return get_icon("ResourcePreloader")
		_:
			if file.get_file() == "":
				return get_icon("Folder")
			else:
				return get_icon("File")

static func get_icon(name: String) -> Texture2D:
	if DisplayServer.is_dark_mode_supported():
		if not DisplayServer.is_dark_mode():
			return ICON.get_icon(name, "EditorIcons")
	return EditorInterface.get_base_control().get_theme_icon(name, "EditorIcons")

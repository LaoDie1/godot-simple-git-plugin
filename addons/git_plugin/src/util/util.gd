class_name GitPlugin_Util

## 点击文件
static func edit_file(file: String) -> void:
	if Engine.is_editor_hint() and ResourceLoader.exists(file):
		if not file.begins_with("res://"):
			file = "res://" + file
		
		match file.get_extension():
			"tres", "res", "gd":
				var res : Resource = ResourceLoader.get_cached_ref(file)
				EditorInterface.edit_resource(res)
			"tscn", "scn":
				EditorInterface.open_scene_from_path(file)
			_:
				pass
		
		EditorInterface.get_file_system_dock().navigate_to_path(file)
		EditorInterface.select_file(file)
	else:
		if FileAccess.file_exists(file):
			print_rich("Cannot edit this file: [i]", file, "[/i]. File type: [i]", file.get_extension(), "[/i]")
		else:
			print_rich("Cannot edit this file: [s]", file, "[/s]. File type: [i]", file.get_extension(), "[/i]")

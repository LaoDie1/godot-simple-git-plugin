#============================================================
#    04.create Editor Script
#============================================================
# - author: zhangxuetu
# - datetime: 2024-12-08 10:34:52
# - version: 4.3.0.stable
#============================================================
## 创建编辑器脚本
extends AbstractCustomMenu

func _get_menu_name():
	return "创建 EditorScript"

func _execute():
	var list = EditorInterface.get_selected_paths()
	if not list.is_empty():
		var path : String = list[0]
		if not DirAccess.dir_exists_absolute(path):
			path = path.get_base_dir()
		
		var id = 0
		var script_path = path.path_join("editor_script_%02d.gd" % id)
		while FileAccess.file_exists(script_path):
			id += 1
			script_path = path.path_join("editor_script_%02d.gd" % id)
		var script = GDScript.new()
		script.source_code = """# {datetime}
@tool
extends EditorScript

func _run() -> void:
	pass
""".format({"datetime": Time.get_datetime_string_from_system(false, true)})
		var err = ResourceSaver.save(script, script_path)
		print("已创建：" if err == OK else "创建失败：", script_path)

#============================================================
#    05.init Folder
#============================================================
# - author: zhangxuetu
# - datetime: 2025-09-26 20:22:17
# - version: 4.5.0.stable
#============================================================
extends AbstractCustomMenu

func _execute():
	var dict = {
		"src": {
			"assets": {},
			"commons": {},
			"game": {
				"map": {},
				"object": {},
				"prop": {},
				"ui": {},
			},
		},
		"test": {},
	}
	_init_folder(dict, "res://")
	EditorInterface.get_resource_filesystem().scan()

func _init_folder(dict: Dictionary, parent_path: String):
	var temp_path: String
	for dir in dict:
		temp_path = parent_path.path_join(dir)
		if not DirAccess.dir_exists_absolute(temp_path):
			DirAccess.make_dir_absolute(temp_path)
			print("创建目录：", temp_path)
		_init_folder(dict[dir], temp_path)

func _get_menu_name():
	return "初始化目录"

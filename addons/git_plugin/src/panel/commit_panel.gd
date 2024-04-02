#============================================================
#    Commit Panel
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 17:53:38
# - version: 4.2.1.stable
#============================================================
extends Panel


@onready var unstaged_changes_file_tree: GitPlugin_FileTree = %UnstagedChangesFileTree
@onready var staged_changes_file_tree: GitPlugin_FileTree = %StagedChangesFileTree
@onready var committed_file_tree: GitPlugin_FileTree = %CommittedFileTree


#============================================================
#  内置
#============================================================
func _ready() -> void:
	update_files()



#============================================================
#  自定义
#============================================================
func update_files():
	var data = await GitPlugin_Status.execute(["-u"])
	
	var untracked_files : Array = data.get("Untracked files:", [])
	var changes_not_staged_for_commit : Array = data.get("Changes not staged for commit:", [])
	staged_changes_file_tree.add_items(changes_not_staged_for_commit)
	
	# 过滤重复的文件
	var filter_method = func(item_file):
		return not staged_changes_file_tree._file_to_item_dict.has(item_file)
	var files = untracked_files.filter(filter_method)
	files.append_array(changes_not_staged_for_commit.filter(filter_method))
	
	# 未提交
	unstaged_changes_file_tree.add_items(files)
	# 已提交
	committed_file_tree.add_items(data.get("Changes to be committed:", []))



#============================================================
#  连接信号
#============================================================
func _on_add_all_pressed() -> void:
	staged_changes_file_tree.add_items(
		unstaged_changes_file_tree.get_selected_file()
	)
	unstaged_changes_file_tree.clear_select_items()


func _on_commit_changes_pressed() -> void:
	var list = []
	for file in committed_file_tree.get_selected_file():
		var idx = file.find(":")
		if idx > -1:
			file = file.substr(idx + 1)
		list.append('\"' + file.strip_edges() + '\"')
	
	var command = ["git", "add"]
	command.append_array(list)
	var result = await GitPlugin_Console.execute(command)
	
	print(" ".join(command))
	print_debug("   添加完成 ", result)
	
	update_files()
	


func _on_unstaged_changes_file_tree_action_file(item_file: String) -> void:
	unstaged_changes_file_tree.remove_item(item_file)
	staged_changes_file_tree.add_item(item_file)


func _on_staged_changes_file_tree_action_file(item_file: String) -> void:
	staged_changes_file_tree.remove_item(item_file)
	unstaged_changes_file_tree.add_item(item_file)


func _on_remove_all_pressed() -> void:
	unstaged_changes_file_tree.add_items(
		staged_changes_file_tree.get_selected_file()
	)
	staged_changes_file_tree.clear_select_items()


func _on_add_staged_files_pressed() -> void:
	var files = staged_changes_file_tree.get_selected_file()
	if files.is_empty():
		return
	files = Array(files).map(
		func(item: String):
			var idx = item.find(":")
			if idx > -1:
				return item.substr(idx + 1).strip_edges()
			return item
	)
	
	# 添加提交的文件
	var command = [ "git", "add" ]
	command.append_array(files)
	GitPlugin_Console.execute(command)
	
	# 添加到树中
	committed_file_tree.add_items(staged_changes_file_tree.get_selected_file())
	staged_changes_file_tree.clear_select_items()

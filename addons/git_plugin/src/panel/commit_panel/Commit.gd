#============================================================
#    Commit
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 17:42:32
# - version: 4.2.1.stable
#============================================================
@tool
extends VBoxContainer


@onready var unstaged_changes_file_tree: GitPlugin_FileTree = %UnstagedChangesFileTree
@onready var staged_changes_file_tree: GitPlugin_FileTree = %StagedChangesFileTree
@onready var committed_file_tree: GitPlugin_FileTree = %CommittedFileTree
@onready var commit_message_text_edit: TextEdit = %CommitMessageTextEdit
@onready var commit_changes: Button = %CommitChanges
@onready var commit_message_prompt_animation_player = %CommitMessagePromptAnimationPlayer


#============================================================
#  内置
#============================================================
func _ready() -> void:
	if not GitPluginConst.enabled_plugin:
		return
	update.call_deferred()



#============================================================
#  自定义
#============================================================
## 更新文件列表
func update():
	var data = await GitPlugin_Status.execute()
	var untracked_files : Array = data.get("Untracked files:", [])
	var changes_not_staged_for_commit : Array = data.get("Changes not staged for commit:", [])
	staged_changes_file_tree.init_items(changes_not_staged_for_commit)
	
	# 过滤重复的文件
	var filter_method = func(item_file):
		return not staged_changes_file_tree._file_to_item_dict.has(item_file)
	var files = untracked_files.filter(filter_method)
	files.append_array(changes_not_staged_for_commit.filter(filter_method))
	
	# 未提交
	unstaged_changes_file_tree.init_items(files)
	# 已提交
	committed_file_tree.init_items(data.get("Changes to be committed:", []))


func print_data(result, desc):
	print( "\n".join(result) )
	print_debug("   ", desc)


## 点击文件
func edit_file(item_file: String, file: String):
	if Engine.is_editor_hint() and ResourceLoader.exists(file):
		if not file.begins_with("res://"):
			file = "res://" + file
		
		match file.get_extension():
			"tres", "res", "gd":
				var res = load(file)
				EditorInterface.edit_resource(res)
			"tscn", "scn":
				EditorInterface.open_scene_from_path(file)
		
		if ResourceLoader.exists(file):
			print_debug("编辑文件：", file)
			EditorInterface.get_file_system_dock().navigate_to_path(file)
			EditorInterface.select_file(file)


#============================================================
#  连接信号
#============================================================
func _on_add_all_unstaged_file_pressed() -> void:
	var files = unstaged_changes_file_tree.get_selected_files()
	if not files.is_empty():
		var result = await GitPlugin_Add.execute(files)
		update()


func _on_remove_all_pressed() -> void:
	var files = staged_changes_file_tree.get_selected_files()
	if not files.is_empty():
		var result = await GitPlugin_Restore.execute(files)
		update()


func _on_add_all_staged_files_pressed() -> void:
	var files = staged_changes_file_tree.get_selected_files()
	if not files.is_empty():
		var result = await GitPlugin_Add.execute(files)
		update()


func _on_commit_changes_pressed() -> void:
	if committed_file_tree.get_selected_item_file().is_empty():
		push_error("没有选中文件")
		return
	if commit_message_text_edit.text.strip_edges() == "":
		commit_message_prompt_animation_player.play("flicker")
		return
	
	# 提交
	var result = await GitPlugin_Commit.execute(
		commit_message_text_edit.text.strip_edges()
	)
	
	commit_message_text_edit.text = ""
	update()


func _on_push_pressed() -> void:
	GitPlugin_Push.execute()


func _on_staged_changes_file_tree_actived_file(item_file: String, file: String) -> void:
	staged_changes_file_tree.remove_item(item_file)
	committed_file_tree.add_item(item_file)
	GitPlugin_Add.execute([ file ])


func _on_unstaged_changes_file_tree_actived_file(item_file: String, file: String) -> void:
	unstaged_changes_file_tree.remove_item(item_file)
	committed_file_tree.add_item(item_file)
	GitPlugin_Add.execute([file])


func _on_committed_file_tree_actived_file(item_file, file):
	staged_changes_file_tree.add_item(item_file)
	committed_file_tree.remove_item(item_file)
	GitPlugin_Restore.execute([ file ])



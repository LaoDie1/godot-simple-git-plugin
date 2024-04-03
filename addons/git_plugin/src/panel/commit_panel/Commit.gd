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
	update_files.call_deferred()



#============================================================
#  自定义
#============================================================
func update_files():
	
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



#============================================================
#  连接信号
#============================================================
func _on_add_all_pressed() -> void:
	staged_changes_file_tree.add_items(
		unstaged_changes_file_tree.get_selected_file()
	)
	unstaged_changes_file_tree.clear_select_items()


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
	
	# 获取文件列表
	var list = []
	for file in staged_changes_file_tree.get_selected_file():
		var idx = file.find(":")
		if idx > -1:
			file = file.substr(idx + 1)
		list.append('\"' + file.strip_edges() + '\"')
	
	var result = await GitPlugin_Add.execute(list)
	print_data(result, "已添加")
	
	# 添加到树中
	update_files.call_deferred()


func _on_commit_changes_pressed() -> void:
	if committed_file_tree.get_selected_file().is_empty():
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
	update_files.call_deferred()


func _on_push_pressed() -> void:
	GitPlugin_Pull.execute()

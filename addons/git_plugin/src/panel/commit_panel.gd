#============================================================
#    Commit Panel
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 17:53:38
# - version: 4.2.1.stable
#============================================================
@tool
extends Panel


@onready var unstaged_changes_file_tree: GitPlugin_FileTree = %UnstagedChangesFileTree
@onready var staged_changes_file_tree: GitPlugin_FileTree = %StagedChangesFileTree
@onready var committed_file_tree: GitPlugin_FileTree = %CommittedFileTree
@onready var commit_message_text_edit: TextEdit = %CommitMessageTextEdit
@onready var commit_message_prompt_animation_player: AnimationPlayer = %CommitMessagePromptAnimationPlayer
@onready var log_item_list: ItemList = %LogItemList


#============================================================
#  内置
#============================================================
func _ready() -> void:
	update_files()
	update_log()



#============================================================
#  自定义
#============================================================
func print_data(result, desc):
	print( "\n".join(result) )
	print_debug("   ", desc)


func update_files():
	var data = await GitPlugin_Status.execute(["-u"])
	
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


## 更新日志列表
func update_log():
	log_item_list.clear()
	var result = await GitPlugin_Log.execute()
	var idx = 0
	for item:Array in result:
		var id = str(item[0]).substr(7)
		var desc = str(item[3]).strip_edges()
		var date = str(item[2]).substr(5).strip_edges()
		var split_data = date.split(" ")
		date = "{year} {month} {day} {time}".format({
			"month": split_data[1],
			"day": split_data[2],
			"time": split_data[3],
			"year": split_data[4],
		})
		
		var text = "%s  %s  %s" % [ id.substr(0, 7), date, desc.replace("\n", " ") ]
		log_item_list.add_item(text, null)
		
		var commit_files = item.slice(4, item.size() - 1)
		log_item_list.set_item_tooltip(idx, "\n".join(commit_files) )
		log_item_list.set_item_metadata(idx, commit_files)
		
		idx += 1



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
		return
	if commit_message_text_edit.text.strip_edges() == "":
		commit_message_prompt_animation_player.play("flicker")
		return
	
	var result = await GitPlugin_Commit.execute(commit_message_text_edit.text.strip_edges())
	commit_message_text_edit.text = ""
	
	update_files.call_deferred()
	update_log.call_deferred()



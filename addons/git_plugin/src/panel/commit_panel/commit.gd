#============================================================
#    Commit
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 17:42:32
# - version: 4.2.1.stable
#============================================================
@tool
extends VBoxContainer

const ICON = preload("res://addons/git_plugin/src/icon.tres")

@onready var branch_name_option = %BranchNameOption
@onready var remote_name_option = %RemoteNameOption
@onready var unstaged_changes_file_tree: GitPlugin_FileTree = %UnstagedChangesFileTree
@onready var staged_changes_file_tree: GitPlugin_FileTree = %StagedChangesFileTree
@onready var committed_file_tree: GitPlugin_FileTree = %CommittedFileTree
@onready var commit_message_text_edit: TextEdit = %CommitMessageTextEdit
@onready var commit_changes: Button = %CommitChanges
@onready var commit_message_prompt_animation_player = %CommitMessagePromptAnimationPlayer
@onready var committed_file_tree_animation_player = %CommittedFileTreeAnimationPlayer
@onready var push_button = %PushButton
@onready var pull_button = %PullButton
@onready var unstaged_changes_file_count_label = %UnstagedChangesFileCountLabel
@onready var staged_files_count_label = %StagedFilesCountLabel
@onready var committed_file_count_label = %CommittedFileCountLabel


#============================================================
#  内置
#============================================================
func _ready() -> void:
	# TODO 对两个 OptionButton 添加切换远程名称和分支的功能
	
	# 远程仓库名
	var remote_name_list = await GitPlugin_Remote.list()
	if not remote_name_list.is_empty():
		remote_name_option.clear()
		for item in remote_name_list:
			remote_name_option.add_item(item)
	
	# 分支信息
	var current_branch = await GitPlugin_Branch.show_current()
	var branch_list = await GitPlugin_Branch.list()
	if not branch_list.is_empty():
		branch_name_option.clear()
	var idx = -1
	for item:String in branch_list:
		item = item.trim_prefix("*").strip_edges()
		idx += 1
		branch_name_option.add_item(item)
		branch_name_option.set_item_metadata(idx, item)
		branch_name_option.set_item_icon(idx, ICON.get_icon("VcsBranches", "EditorIcons"))
		if item == current_branch:
			branch_name_option.selected = idx
	
	# call_deferred 用于等待节点显示出来
	update.call_deferred()


#============================================================
#  自定义
#============================================================
## 更新文件列表
func update():
	if not visible:
		return
	
	var data = await GitPlugin_Status.execute()
	# 暂存
	var untracked_files : Array = data.get("Untracked files:", [])
	var changes_not_staged_for_commit : Array = data.get("Changes not staged for commit:", [])
	staged_changes_file_tree.init_items(changes_not_staged_for_commit)
	staged_files_count_label.text = "(%d)" % changes_not_staged_for_commit.size()
	
	# 过滤重复的文件
	var filter_method = func(item_file):
		return not staged_changes_file_tree._file_to_item_dict.has(item_file)
	var unstaged_changes_files = untracked_files.filter(filter_method)
	unstaged_changes_files.append_array(changes_not_staged_for_commit.filter(filter_method))
	
	# 未提交
	unstaged_changes_file_tree.init_items(unstaged_changes_files)
	unstaged_changes_file_count_label.text = "(%d)" % unstaged_changes_files.size()
	
	# 已提交
	var committed_files : Array = data.get("Changes to be committed:", [])
	committed_file_tree.init_items(committed_files)
	committed_file_count_label.text = "(%d)" % committed_files.size()


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
	var files = committed_file_tree.get_selected_files()
	if not files.is_empty():
		var result = await GitPlugin_Restore.execute(files)
		update()


func _on_add_all_staged_files_pressed() -> void:
	var files = staged_changes_file_tree.get_selected_files()
	if not files.is_empty():
		var result = await GitPlugin_Add.execute(files)
		update()


func _on_commit_changes_pressed() -> void:
	var enabled : bool = true
	if committed_file_tree.get_selected_item_file().is_empty():
		committed_file_tree_animation_player.play("flicker")
		enabled = false
	if commit_message_text_edit.text.strip_edges() == "":
		commit_message_prompt_animation_player.play("flicker")
		enabled = false
	if not enabled:
		return
	
	# 提交
	var result = await GitPlugin_Commit.execute(
		commit_message_text_edit.text.strip_edges()
	)
	commit_message_text_edit.text = ""
	update()


func _on_push_pressed() -> void:
	push_button.disabled = true
	await GitPlugin_Push.execute()
	push_button.disabled = false


func _on_pull_button_pressed():
	pull_button.disabled = true
	await GitPlugin_Pull.execute()
	pull_button.disabled = false


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


#============================================================
#    Log
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 18:13:59
# - version: 4.2.1.stable
#============================================================
@tool
extends VBoxContainer


@onready var log_item_tree: Tree = %LogItemTree
@onready var log_number_option = %LogNumberOption

@onready var tree_root : TreeItem = log_item_tree.create_item()


#============================================================
#  内置
#============================================================
func _init():
	visibility_changed.connect(update_log)

func _ready() -> void:
	if not GitPluginConst.enabled_plugin:
		return
	
	for item in ["10", "20", "50", "100", "All"]:
		log_number_option.add_item(item)
	
	log_item_tree.set_column_title(0, "ID")
	log_item_tree.set_column_title(1, "Date")
	log_item_tree.set_column_title(2, "Description")
	
	update_log()


#============================================================
#  自定义
#============================================================
## 更新日志列表
func update_log():
	if not visible:
		return
	
	log_item_tree.clear()
	tree_root = log_item_tree.create_item()
	
	# 显示的日志数量
	var log_number : int = 0
	var item_id = log_number_option.get_selected_id()
	var item_text = log_number_option.get_item_text(item_id)
	if item_text != "All":
		log_number = int(item_text)
	print("显示日志数量：", log_number)
	
	var result = await GitPlugin_Log.execute(log_number)
	var idx = 0
	for item in result:
		var tree_item = log_item_tree.create_item(tree_root)
		tree_item.set_text(0, item["id"].substr(0, 11))
		tree_item.set_text(1, item["date"])
		tree_item.set_text(2, item["desc"])
		
		idx += 1


#============================================================
#  连接信号
#============================================================
func _on_log_number_option_item_selected(index):
	update_log.call_deferred()

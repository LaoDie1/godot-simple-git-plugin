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

@onready var tree_root : TreeItem = log_item_tree.create_item()


#============================================================
#  内置
#============================================================
func _ready() -> void:
	if not GitPluginConst.enabled_plugin:
		return
	
	log_item_tree.set_column_title(0, "ID")
	log_item_tree.set_column_title(1, "Date")
	log_item_tree.set_column_title(2, "Description")
	
	update_log.call_deferred()


#============================================================
#  自定义
#============================================================
## 更新日志列表
func update_log():
	log_item_tree.clear()
	tree_root = log_item_tree.create_item()
	
	var result = await GitPlugin_Log.execute()
	var idx = 0
	for item in result:
		var tree_item = log_item_tree.create_item(tree_root)
		tree_item.set_text(0, item["id"].substr(0, 11))
		tree_item.set_text(1, item["date"])
		tree_item.set_text(2, item["desc"])
		
		idx += 1


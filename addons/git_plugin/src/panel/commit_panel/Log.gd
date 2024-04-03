#============================================================
#    Log
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 18:13:59
# - version: 4.2.1.stable
#============================================================
@tool
extends VBoxContainer


@onready var log_item_list: ItemList = %LogItemList



#============================================================
#  内置
#============================================================
func _ready() -> void:
	if not GitPluginConst.enabled_plugin:
		return
	update_log.call_deferred()


#============================================================
#  自定义
#============================================================
## 更新日志列表
func update_log():
	log_item_list.clear()
	var result = await GitPlugin_Log.execute()
	var idx = 0
	for item: Array in result:
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
		
		var commit_files = item[4]
		log_item_list.set_item_metadata(idx, commit_files)
		log_item_list.set_item_tooltip(idx, "\n".join(commit_files) )
		
		idx += 1


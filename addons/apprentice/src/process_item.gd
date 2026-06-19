#============================================================
#    Process Item
#============================================================
# - author: zhangxuetu
# - datetime: 2025-05-29 21:51:46
# - version: 4.2.1
#============================================================
class_name ProcessItem
extends Object


signal finished #时间执行完成
signal ended #结束了。只要不执行了就会发出这个信号

var _timeleft: float = 0.0
var _method: Callable
var _end_status: bool = false

func stop():
	if _end_status:
		return
	_end_status = true
	ended.emit()
	_timeleft = 0
	if is_queued_for_deletion():
		Engine.get_main_loop().queue_delete(self)

func _execute(delta):
	pass

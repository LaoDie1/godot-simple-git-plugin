#============================================================
#    Time Stopwatch
#============================================================
# - author: zhangxuetu
# - datetime: 2026-04-14 14:50:28
# - version: 4.6.2.stable
#============================================================
##秒表计时功能
class_name StopwatchTimer

static var _time_dict: Dictionary = {}

var _time : int = -1

func _init() -> void:
	start()

func start() -> void:
	_time = Time.get_ticks_msec()

## 获取从上次时间到现在的经过的时间
func get_time() -> float:
	return (Time.get_ticks_msec() - _time) / 1000.0

## 从创建或 reset 时的时间开始到现在的时间帧
func get_tick_msec() -> int:
	return int((Time.get_ticks_msec() - _time) * Engine.time_scale)

## 重置计时
func reset() -> void:
	_time = Time.get_ticks_msec()

## 如果超出这个时间则重置
func reset_if_more(ticks_msec: int) -> bool:
	if get_tick_msec() > ticks_msec:
		reset()
		return true
	return false

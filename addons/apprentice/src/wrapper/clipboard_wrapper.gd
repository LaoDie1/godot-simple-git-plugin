#============================================================
#    Clipboard
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-08 22:58:39
# - version: 4.4.0.dev7
#============================================================
## 剪贴板包装器
##
##使用前必须调用 [method init_instance] 方法进行初始化
##用于检测剪贴板的当前数据和上次是否一样，需要不断地调用 [method update] 方法来检测是否发生改变
class_name ClipboardWrapper
extends Object


## 剪贴板发生改变信号
static var changed: Signal
signal _changed


static var _instance: ClipboardWrapper
static var _last_image_hash: int
static var _current_data


func _init() -> void:
	if DisplayServer.clipboard_has_image():
		_current_data = DisplayServer.clipboard_get_image()
		if _current_data:
			_last_image_hash = _current_data.data.hash()
	else:
		_current_data = DisplayServer.clipboard_get()
	
	# 进行更新检测
	Engine.get_main_loop().process_frame.connect(
		func():
			# 每隔几帧进行一次检测
			if Engine.get_process_frames() % 5 == 0:
				update.call_deferred()
	)


static func init_instance() -> void:
	if _instance == null:
		_instance = ClipboardWrapper.new()
		ClipboardWrapper.changed = _instance._changed


static func get_data():
	return _current_data


## 强制更新内容到当前数据。（注意：这个方法不会发出信号，如果需要则要主动调用信号）
static func force_update(data):
	if data is String:
		_current_data = data
	elif data is Image:
		_current_data = data
		_last_image_hash = data.data.hash()


## 更新检测数据。如果返回 true 代表剪贴板内容发生了改变
static func update() -> bool:
	# 获取剪贴板内容
	var _temp
	if DisplayServer.clipboard_has_image():
		_temp = DisplayServer.clipboard_get_image()
	else:
		if DisplayServer.clipboard_has():
			_temp = DisplayServer.clipboard_get()
		else:
			if OS.get_name() in ["Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"]:
				_temp = DisplayServer.clipboard_get_primary()
	
	# 判断类型并处理
	if _temp is String:
		if _temp != "" and (_current_data is not String or _current_data != _temp):
			_current_data = _temp
			_last_image_hash = 0
			ClipboardWrapper.changed.emit()
			return true
	elif _temp is Image:
		if _last_image_hash != _temp.data.hash():
			_current_data = _temp
			_last_image_hash = _temp.data.hash()
			ClipboardWrapper.changed.emit()
			return true
	return false

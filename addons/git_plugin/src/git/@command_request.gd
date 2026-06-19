#============================================================
#    Command Request
#============================================================
# - author: zhangxuetu
# - datetime: 2026-06-08 00:16:20
# - version: 4.7.0.beta5
#============================================================
## 命令请求
##
##以 [signal SceneTree.process_frame] 信号执行 [method OS.execute_with_pipe] 命令，以非阻塞的方式执行命令
@tool
class_name GitPlugin_CommandRequest
extends Node


## 响应输出的数据块内容
signal respond_body_chunk(body: PackedByteArray)
## 响应输出的出现异常的数据块内容
signal respond_error_body_chunk(body: PackedByteArray)
## 命令执行完成
signal finished

signal respond_error(err: int)

var _stdio: FileAccess
var _stderr: FileAccess
var _pid: int = 0
var _has_err: bool = false

var _retry_count : int = 0
var _body_bytes_result: PackedByteArray
var _err_body_bytes_result : PackedByteArray

var _bash_path : String = "cmd.exe"
var _bash_param: String = "/C"


func get_body_result() -> PackedByteArray:
	return _body_bytes_result

func get_err_result() -> PackedByteArray:
	return _err_body_bytes_result

func is_running() -> bool:
	return _pid != 0

func has_error() -> bool:
	return not _err_body_bytes_result.is_empty()


func _init() -> void:
	match OS.get_name():
		"Linux", "macOS":
			# TODO 修改为这个平台的执行命令
			_bash_path = ""
			_bash_param = ""
		"Windows":
			# 保持默认
			pass
		_:
			assert(false, "不支持这个平台：" + OS.get_name())


func _process(delta) -> void:
	if _pid:
		if _retry_count > 0:
			_err_body_bytes_result = _read_next(_stderr)
			if _err_body_bytes_result:
				respond_error_body_chunk.emit(_err_body_bytes_result)
				_retry_count = 0
				return
			
			var bytes : PackedByteArray = _read_next(_stdio)
			if bytes:
				respond_body_chunk.emit(bytes)
				_body_bytes_result.append_array(bytes)
			if _stdio.get_error() == OK or OS.is_process_running(_pid):
				_retry_count = 3
			else:
				_retry_count -= 1
		else:
			OS.kill(_pid)
			_pid = 0
			finished.emit(_body_bytes_result)


func _read_next(std: FileAccess) -> PackedByteArray:
	var time : int = Time.get_ticks_msec()
	var bytes: PackedByteArray = []
	var tmp_byte : PackedByteArray = std.get_buffer(1024)
	while tmp_byte and Time.get_ticks_msec() - time <= 100:
		bytes.append_array(tmp_byte)
		tmp_byte = std.get_buffer(1024)
	if bytes and bytes[-1] == 10:
		bytes = bytes.slice(0, -1)  #去掉末尾的 10 字节数据
	return bytes


func execute(command: String) -> void:
	_body_bytes_result = PackedByteArray()
	_err_body_bytes_result = PackedByteArray()
	var items : Array = command.split(" ", true, 2)
	var data: Dictionary = OS.execute_with_pipe(_bash_path, [_bash_param, " ".join(items)] , false)
	if data:
		_has_err = false
		_stdio = data["stdio"]
		_stderr = data["stderr"]
		_pid = data["pid"]
		_retry_count = 3
		#print(data)
		#printt(_stdio.get_error(), _stdio.get_as_text(), _stderr.get_error(), _stderr.get_as_text())
	else:
		respond_error.emit(Error.ERR_INVALID_PARAMETER)
		printerr("出现错误", _bash_path, _bash_param)

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
class_name CommandRequest
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


func _process(delta) -> void:
	if _pid:
		if _retry_count > 0:
			var err_bytes : PackedByteArray = _read_next(_stderr)
			if err_bytes:
				respond_error_body_chunk.emit(err_bytes)
				_retry_count = 0
				return
			
			var bytes : PackedByteArray = _read_next(_stdio)
			if bytes:
				respond_body_chunk.emit(bytes)
			if _stdio.get_error() == OK or OS.is_process_running(_pid):
				_retry_count = 3
			else:
				_retry_count -= 1
		else:
			OS.kill(_pid)
			_pid = 0
			finished.emit()


func _read_next(std: FileAccess) -> PackedByteArray:
	var time : int = Time.get_ticks_msec()
	var bytes: PackedByteArray = []
	var tmp_byte : PackedByteArray = std.get_buffer(1024)
	while tmp_byte and Time.get_ticks_msec() - time <= 100:
		bytes.append_array(tmp_byte)
		tmp_byte = std.get_buffer(1024)
	if bytes:
		bytes = bytes.slice(0, -1)  #去掉末尾的 10 字节数据
	return bytes


func execute(command: String) -> void:
	var items : Array = command.split(" ", true, 2)
	var data: Dictionary = OS.execute_with_pipe("cmd.exe", ["/C", " ".join(items)] , false)
	if data:
		_has_err = false
		#print(data)
		_stdio = data["stdio"]
		_stderr = data["stderr"]
		_pid = data["pid"]
		_retry_count = 3
		#printt(_stdio.get_error(), _stdio.get_as_text(), _stderr.get_error(), _stderr.get_as_text())
	else:
		respond_error.emit(Error.ERR_INVALID_PARAMETER)

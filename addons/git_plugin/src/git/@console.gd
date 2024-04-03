#============================================================
#    Console
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 13:09:01
# - version: 4.2.1.stable
#============================================================
# 控制台，接收用户命令，进行异步处理
# 这个节点不能是 Node 类型，否则添加到场景后，异步功能不能使用
class_name GitPlugin_Console
extends RefCounted


const CommandPrompt = preload("shell/command_prompt.gd")
const PowerShell = preload("shell/power_shell.gd")
const Terminal = preload("shell/terminal.gd")


static var instance : GitPlugin_Console:
	get:
		if instance == null:
			instance = GitPlugin_Console.new()
		return instance

static var _incr_id : int = 0

## 使用命令请求后的结果
var _id_to_request_result_cache : Dictionary = {}

var thread: Thread
var shell : GitPlugin_Shell


#============================================================
#  内置
#============================================================
func _init() -> void:
	match OS.get_name():
		"Linux", "macOS":
			shell = Terminal.new()
		"Windows":
			if DirAccess.dir_exists_absolute("C:\\Windows\\System32\\WindowsPowerShell"):
				shell = PowerShell.new()
			else:
				shell = CommandPrompt.new()
		_:
			assert(false, "不支持这个平台：" + OS.get_name())
	
	# 命令处理完成
	shell.request_finished.connect(
		func(id, command, output):
			var result : String = output[0]
			# 结果为 "" 执行可能失败
			if result != "":
				# FIXME 需要修复中文乱码问题
				#result = result.to_ascii_buffer().get_string_from_utf8()
				
				if result.find("\r\n") != -1:
					output = result.split("\r\n")
				else:
					output = result.split("\n")
			else:
				output = []
			self._id_to_request_result_cache[id] = output
			
			if self.thread != null:
				self.thread.wait_to_finish()
				self.thread = null
	, Object.CONNECT_DEFERRED)



#============================================================
#  自定义
#============================================================
## 执行命令
static func execute(command: Array, wait_time: float = 10.0):
	print("=".repeat(60))
	print_debug("Execute Command: ", " ".join(command) )
	print()
	
	var id = instance._execute(command.duplicate(true))
	var result = await instance.get_request_result(id, wait_time)
	if typeof(result) == TYPE_NIL:
		printerr("id 为 ", id, " 的 ", command, " 命令结果为 null")
	return result


# 返回执行时的 id
func _execute(command: Array) -> int:
	if thread != null:
		thread.wait_to_finish()
	thread = Thread.new()
	# 执行 shell 命令
	_incr_id += 1
	thread.start(shell.execute.bind(_incr_id, command))
	return _incr_id


## 获取这个ID请求的结果，超时返回 [code]null[/code]
func get_request_result(id: int, wait_time: float) -> Variant:
	wait_time = int(max(0.001, wait_time) * 1000)
	var start_time = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_time < wait_time :
		await Engine.get_main_loop().process_frame
		if _id_to_request_result_cache.has(id):
			var result = _id_to_request_result_cache[id]
			_id_to_request_result_cache.erase(id) # 请求到结果，清除结果缓存
			return result
	return null


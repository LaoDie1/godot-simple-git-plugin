#============================================================
#    Executor
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 13:09:01
# - version: 4.2.1.stable
#============================================================
# 接收用户命令，进行异步处理
# 这个节点不能是 Node 类型，否则添加到场景后，异步功能不能使用
class_name GitPlugin_Executor
extends RefCounted

static var plugin: EditorPlugin


## 执行 git 命令
static func execute(command: String) -> Dictionary:
	if not Engine.is_editor_hint() or plugin:
		# 等待上次的执行完成
		while GitPlugin_CommandRequest.instance.is_running():
			await GitPlugin_CommandRequest.instance.finished
		
		print("[ GitPlugin_Executor ] Execute Command:  %s" % [command])
		
		# 正式执行 
		GitPlugin_CommandRequest.instance.execute(command)
		if GitPlugin_CommandRequest.instance.is_running():
			await GitPlugin_CommandRequest.instance.finished
		var bytes : PackedByteArray = GitPlugin_CommandRequest.instance.get_body_result()
		var err_bytes : PackedByteArray = GitPlugin_CommandRequest.instance.get_err_result()
		if err_bytes.is_empty():
			return {
				"error": OK,
				"output": bytes.get_string_from_utf8(),
			}
		else:
			return {
				"error": FAILED,
				"output": err_bytes.get_string_from_utf8(),
			}
	return {
		"error": FAILED,
		"output": "",
	}

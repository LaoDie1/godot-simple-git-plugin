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


static var _request: GitPlugin_CommandRequest:
	get:
		if not is_instance_valid(_request):
			_request = GitPlugin_CommandRequest.new()
			var scene_tree = Engine.get_main_loop()
			if scene_tree is SceneTree:
				scene_tree.root.add_child.call_deferred(_request)
		return _request


## 执行 git 命令
static func execute(command: String, request: GitPlugin_CommandRequest = null) -> Dictionary:
	if not Engine.is_editor_hint() or plugin:
		if request == null:
			request = _request
		
		# 等待上次的执行完成
		while request.is_running():
			await request.finished
		
		print("[ GitPlugin_Executor ] Execute Command:  %s" % [command])
		
		# 正式执行 
		request.execute(command)
		if request.is_running():
			await request.finished
		var bytes : PackedByteArray = request.get_body_result()
		var err_bytes : PackedByteArray = request.get_err_result()
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

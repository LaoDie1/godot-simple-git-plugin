#============================================================
#    Command Prompt
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 12:56:11
# - version: 4.2.1.stable
#============================================================
# Windows CMD
extends GitPlugin_Shell


func _execute(command: Array) -> Dictionary:
	var args = PackedStringArray(["/C", " ".join(command)])
	var proc = OS.execute_with_pipe("CMD.exe", args, true)
	var stdio : FileAccess = proc["stdio"]
	var stderr : FileAccess = proc["stderr"] #读取会卡死，别读
	var pid : int = proc["pid"]
	
	# 循环读取直到没有数据
	var idx : int = 0
	var output_bytes := PackedByteArray()
	while not stdio.eof_reached() or idx < 1024:
		# 每次读 4096 字节，直到读完
		var chunk = stdio.get_buffer(4096)
		if chunk.size() == 0:
			break
		output_bytes.append_array(chunk)
		await (Engine.get_main_loop() as SceneTree).process_frame
		idx += 1
	var output_string : String = output_bytes.get_string_from_utf8()
	
	OS.kill(pid)
	return {"output": [output_string], "error": OK}

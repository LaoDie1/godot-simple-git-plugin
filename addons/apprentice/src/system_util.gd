#============================================================
#    System Util
#============================================================
# - author: zhangxuetu
# - datetime: 2024-12-01 15:35:25
# - version: 4.3.0.stable
#============================================================
## 系统工具
class_name SystemUtil


enum ThemeType {
	System, ##跟随系统
	DARK, ##暗色
	LIGHT, ##亮色
}


## 获取主题类型
static func get_theme_type() -> ThemeType:
	if DisplayServer.is_dark_mode_supported():
		return ThemeType.LIGHT if not DisplayServer.is_dark_mode() else ThemeType.DARK
	return ThemeType.DARK

static func thread_execute_command(params: Array, callback: Callable):
	var root : SceneTree = Engine.get_main_loop()
	var thread = Thread.new()
	thread.start(execute_command.bind(params))
	while thread.is_alive():
		await root.create_timer(0.2).timeout
	var result : String = thread.wait_to_finish()
	callback.call(result)

## 执行CMD命令
static func execute_command(params: Array) -> String:
	var output: Array = []
	var error = OS.execute("CMD.exe", ["/C", " ".join(params)], output, true)
	return output[0]

## 查找系统配置程序的可执行文件位置
static func find_program(program_name: String) -> PackedStringArray:
	var output = SystemUtil.execute_command(["where", "ffmpeg"])
	return output.replace("\\", "/").strip_edges(false, true).split("\r\n")

## 名称区分大小写
static func find_running_program(program_name_or_id) -> Array[Dictionary]:
	# TODO 后续增加为 Get-CimInstance 命令
	var result: String
	const CMD_CODE = 'wmic process where "%s" get name,processid,executablepath /format:csv'
	var command : String
	if program_name_or_id is String:
		command = CMD_CODE % ('name like "%' + str(program_name_or_id) + '%"')
	elif program_name_or_id is int:
		command = CMD_CODE % ('processid=' + str(program_name_or_id))
	result = execute_command([command])
	result = str(result).strip_edges().replace("\\", "/")
	# 转换为字典格式数据
	var lines = result.split("\r\n")
	if lines.size() == 1:
		return []
	var list : Array[Dictionary] = []
	var keys = lines[0].replace("\r", "").split(",")
	for idx in range(1, lines.size()):
		var items = lines[idx].replace("\r", "").split(",")
		var data = {}
		for kid in keys.size():
			data[keys[kid]] = items[kid]
		list.append(data)
	return list


## 是否有这个相同的程序正在运行
static func current_is_running() -> bool:
	var path = OS.get_executable_path().replace("/", "\\\\")
	var code = 'wmic process where "executablepath LIKE \'%' + path + '%\'" get name,processid,executablepath /format:csv'
	var output = execute_command([code])
	var result : String = str(output).strip_edges()
	var items = result.split("\r\n")
	print(items)
	return items.size() > 2 # 只能有一个这样


## 这个线程的程序是否正在执行
static func is_running(pid: int) -> bool:
	return not find_running_program(pid).is_empty()


enum {
	CONFIR_OK,
	CONFIR_CANCEL,
	CONFIR_NOT,
}

static var _confirmation_dialog_list : Array[ConfirmationDialog] = []
## 弹出确认框。传入的方法中需要有一个参数接收点击的结果，如果是 0 则为点击确认，其他结果则为取消
static func popup_confirmation_dialog(message: String, result_callback: Callable=Callable(), title:="", show_not_button:bool=true, rect:=Rect2()) -> ConfirmationDialog:
	if title.is_empty():
		title = "请确认..."
	if _confirmation_dialog_list.is_empty():
		var dialog := ConfirmationDialog.new()
		var not_button : Button = dialog.add_cancel_button("NOT")
		not_button.visible = show_not_button
		dialog.set_meta("btn_not", not_button)
		dialog.visibility_changed.connect(
			func():
				# 隐藏后断开所有连接
				if not dialog.visible:
					for item in dialog.confirmed.get_connections():
						dialog.confirmed.disconnect(item["callable"])
					for item in dialog.canceled.get_connections():
						dialog.canceled.disconnect(item["callable"])
					for item in not_button.pressed.get_connections():
						not_button.pressed.disconnect(item["callable"])
				_confirmation_dialog_list.append(dialog)
		, Object.CONNECT_DEFERRED)
		_confirmation_dialog_list.append(dialog)
		Engine.get_main_loop().current_scene.add_child(dialog)
	
	# 弹窗节点
	var confir_dialog := _confirmation_dialog_list.pop_back() as ConfirmationDialog
	confir_dialog.size = Vector2()
	if rect == Rect2():
		confir_dialog.popup_centered()
	else:
		confir_dialog.popup(rect)
	confir_dialog.title = title
	confir_dialog.dialog_text = message
	if result_callback.is_valid():
		var not_button : Button = confir_dialog.get_meta("btn_not")
		not_button.pressed.connect(func():
			result_callback.call(CONFIR_NOT)
			confir_dialog.hide()
		, Object.CONNECT_ONE_SHOT)
		confir_dialog.confirmed.connect(result_callback.bind(CONFIR_OK), Object.CONNECT_ONE_SHOT)
		confir_dialog.canceled.connect(result_callback.bind(CONFIR_CANCEL), Object.CONNECT_ONE_SHOT)
	return confir_dialog


static var _file_dialog_list : Array[FileDialog] = []
static func popup_file_dialog(file_mode: FileDialog.FileMode, filters: PackedStringArray, callback: Callable, global:bool=true, current_dir: String = "", rect:=Rect2()) -> FileDialog:
	if _file_dialog_list.is_empty():
		var dialog := FileDialog.new()
		dialog.size = Vector2(700, 400)
		dialog.visibility_changed.connect(
			func():
				# 隐藏后断开所有连接
				if not dialog.visible:
					for item in dialog.file_selected.get_connections():
						dialog.file_selected.disconnect(item["callable"])
					for item in dialog.dir_selected.get_connections():
						dialog.dir_selected.disconnect(item["callable"])
					for item in dialog.files_selected.get_connections():
						dialog.files_selected.disconnect(item["callable"])
				_file_dialog_list.append(dialog)
		, Object.CONNECT_DEFERRED)
		_file_dialog_list.append(dialog)
		Engine.get_main_loop().current_scene.add_child(dialog)
	# 开始处理
	var file_dialog := _file_dialog_list.pop_back() as FileDialog
	if global:
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	else:
		file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.file_mode = file_mode
	file_dialog.filters = filters
	file_dialog.current_file = ""
	file_dialog.current_dir = current_dir
	file_dialog.current_path = ""
	if rect == Rect2():
		file_dialog.popup_centered.call_deferred()
	else:
		file_dialog.popup.call_deferred(rect)
	# 信号执行方式
	match file_mode:
		FileDialog.FILE_MODE_OPEN_FILE, FileDialog.FILE_MODE_SAVE_FILE, FileDialog.FILE_MODE_OPEN_ANY:
			file_dialog.file_selected.connect(callback, Object.CONNECT_ONE_SHOT)
		FileDialog.FILE_MODE_OPEN_DIR:
			file_dialog.dir_selected.connect(callback, Object.CONNECT_ONE_SHOT)
		FileDialog.FILE_MODE_OPEN_FILES:
			file_dialog.files_selected.connect(callback, Object.CONNECT_ONE_SHOT)
	return file_dialog


static func add_to_startup() -> void:
	var os_name : String = OS.get_name()
	match os_name:
		"Windows":
			var appdata : String = OS.get_environment("APPDATA")
			var startup_path = appdata + "\\Microsoft\\Windows\\Start Menu\\Programs\\Startup"
			var shortcut_path = startup_path.plus_file("YourGame.lnk")
			var exe_path : String = OS.get_executable_path()
			OS.execute("cmd", ["/c", "echo", "set", "ws=wscript.createobject(\"wscript.shell\")", ">", "create_shortcut.vbs"], [], true)
			OS.execute("cmd", ["/c", "echo", "set", "sc=ws.createshortcut(\"" + shortcut_path + "\")", ">>", "create_shortcut.vbs"], [], true)
			OS.execute("cmd", ["/c", "echo", "sc.targetpath=\"" + exe_path + "\"", ">>", "create_shortcut.vbs"], [], true)
			OS.execute("cmd", ["/c", "echo", "sc.save", ">>", "create_shortcut.vbs"], [], true)
			OS.execute("cmd", ["/c", "cscript", "create_shortcut.vbs"], [], true)
		
		"macOS":
			var plist_path = OS.get_user_data_dir() + "/Library/LaunchAgents/com.yourgame.plist"
			var plist_content = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.yourgame</string>
	<key>ProgramArguments</key>
	<array>
		<string>{exe_path}</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
""".format({"exe_path": OS.get_executable_path()})
			var file = FileAccess.open(plist_path, FileAccess.WRITE)
			file.store_string(plist_content)
			file.close()
		
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":  # Linux
			var desktop_path = OS.get_user_data_dir() + "/.config/autostart/yourgame.desktop"
			var desktop_content = """[Desktop Entry]
Type=Application
Exec={exe_path}
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Your Game
Comment=Start Your Game on login
""".format({"exe_path": OS.get_executable_path()})
			var file = FileAccess.open(desktop_path, FileAccess.WRITE)
			file.store_string(desktop_content)
			file.close()


static func find_pids_by_port(port) -> Array:
	var output = []
	OS.execute("cmd", ["/c", 'netstat -ano | findstr ":28666"'], output)
	var content : String = output[0]
	content = content.replace("\r", "")
	var list = content.split("\n")
	var pids = []
	for line: String in list:
		if line != "":
			var items : PackedStringArray = line.split("  ")
			var pid : String = items[-1].strip_edges()
			if items.size() > 0 and not pids.has(pid):
				pids.append(pid)
	return pids

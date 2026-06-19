#============================================================
#    Apprentice Autoload
#============================================================
# - author: zhangxuetu
# - datetime: 2025-05-26 22:28:26
# - version: 4.2.1
#============================================================
extends Node


func _init():
	await Engine.get_main_loop().process_frame
	_project_setting.call_deferred()

func _project_setting():
	# 日志等级
	var log_display_value = ProjectSettings.get_setting(Log.LOG_DISPLAY_PATH)
	if log_display_value:
		Log.display = log_display_value
	else:
		ProjectSettings.set_setting(Log.LOG_DISPLAY_PATH, Log.DefaultValue.DISPLAY)
	# 日志打印
	var log_print_value = ProjectSettings.get_setting(Log.LOG_PRINT_PATH)
	if log_print_value:
		Log.print_path = log_print_value
	else:
		ProjectSettings.set_setting(Log.LOG_PRINT_PATH, Log.DefaultValue.PRINT_PATH)
	

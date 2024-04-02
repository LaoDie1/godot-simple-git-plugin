#============================================================
#    Main
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 12:28:22
# - version: 4.2.1.stable
#============================================================
extends Control


@onready var init_panel: Panel = %InitPanel
@onready var commit_panel: Panel = %CommitPanel


#============================================================
#  内置
#============================================================
func _init() -> void:
	GitPluginCustomData.init()


func _ready() -> void:
	commit_panel.visible = not init_panel.visible


#============================================================
#  连接信号
#============================================================
func _on_test_pressed() -> void:
	var result = await GitPlugin_Log.execute()
	print_debug( JSON.stringify(result, "\t") )


func _on_init_panel_visibility_changed() -> void:
	if commit_panel:
		commit_panel.update_files()
		commit_panel.visible = not init_panel.visible

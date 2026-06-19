#============================================================
#    Main
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 12:28:22
# - version: 4.2.1.stable
#============================================================
@tool
class_name GitPlugin_Main
extends Control

const CommitPanel = preload("uid://bia558sh3e7pf")
const InitPanel = preload("uid://dyecx61a10tjb")

@onready var init_panel : InitPanel = %InitPanel
@onready var commit_panel : CommitPanel = %CommitPanel

func _ready() -> void:
	commit_panel.visible = not init_panel.visible

func _on_init_panel_visibility_changed() -> void:
	if commit_panel:
		commit_panel.commit.update()
		commit_panel.visible = not init_panel.visible 

#============================================================
#    Commit Panel
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-02 17:53:38
# - version: 4.2.1.stable
#============================================================
@tool
extends Panel


@onready var commit = %Commit
@onready var log: VBoxContainer = %Log
@onready var remotes: VBoxContainer = %Remotes


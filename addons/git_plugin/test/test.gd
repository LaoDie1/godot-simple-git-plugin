#============================================================
#    Test
#============================================================
# - author: zhangxuetu
# - datetime: 2024-04-03 21:08:18
# - version: 4.2.1.stable
#============================================================
extends Node2D


func print_data(data):
	print( JSON.stringify(data, "\t") )
	


func _ready() -> void:
	
	var result = await GitPlugin_Log.execute()
	print_data(result)


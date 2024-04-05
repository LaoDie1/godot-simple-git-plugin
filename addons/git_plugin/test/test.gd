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
	var info = await GitPlugin_Remote.show("origin")
	print_data(info)
	
	
	return
	
	var exists = await GitPlugin_Remote.valid_url("https://github.com/LaoDie1/godot-simple-git-plugin")
	print(exists)
	
	#print(await GitPlugin_Remote.valid_url("http://"))
	#print_data( await GitPlugin_Status.execute() )
	
	

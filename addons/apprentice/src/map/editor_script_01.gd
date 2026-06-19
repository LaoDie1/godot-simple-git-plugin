# editor_script_01.gd
@tool
extends EditorScript


func _run():
	var r = RandomRooms.new()
	r.size = Vector2i(15, 8)
	r.generate(2, 5)
	r.display()

@tool
extends EditorScript

func _run():
	pass
	
	var list = LinkList.new()
	list.append(1)
	
	print(list.get_first())
	print(list.get_last())

extends Control

@export var text_edit: TextEdit

func _on_button_pressed() -> void:
	var result = await GitPlugin_Executor.execute(text_edit.text.strip_edges())
	print(result["output"])

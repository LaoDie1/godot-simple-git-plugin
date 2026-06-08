#============================================================
#    File Diff
#============================================================
# - author: zhangxuetu
# - datetime: 2026-06-08 17:53:13
# - version: 4.7.0.beta5
#============================================================
@tool
extends Control

@export var code_edit: CodeEdit
@export var container: VBoxContainer

var _regex_line_block: RegEx = RegEx.new()

func _init() -> void:
	_regex_line_block.compile("diff --git a/(?<a>.*?) b/(?<b>.*)")

func _ready() -> void:
	if get_parent() and get_parent().owner:
		visibility_changed.connect(
			func():
				if visible:
					update()
		)
		if visible:
			update()


func update():
	print("update")
	for child in container.get_children():
		child.queue_free()
	
	var result = await GitPlugin_Executor.execute("git diff")
	var output = result["output"]
	
	var lines : PackedStringArray = output.split("\n")
	var groups : Array[String] = []
	var tmp_group : PackedStringArray = []
	var line_block_result : RegExMatch
	for line:String in lines:
		line_block_result = _regex_line_block.search(line)
		if line_block_result:
			if tmp_group:
				groups.append("\n".join(tmp_group.slice(2)))
			tmp_group = []
		tmp_group.append(line)
	
	for group_string in groups:
		var td = code_edit.duplicate()
		td.visible = true
		container.add_child(td)
		td.text = group_string
	
	#code_edit.text = output

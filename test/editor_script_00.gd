# 2026-06-08 18:19:55
@tool
extends EditorScript

var _regex: RegEx = RegEx.new()

func _run() -> void:
	_regex.compile("diff --git a/(?<a>.*?) b/(?<b>.*)")
	
	var r = _regex.search("diff --git a/addons/git_plugin/src/scene/commit_panel/Log.gd b/addons/git_plugin/src/scene/commit_panel/Log.gd")
	print(r.get_string("a"))
	print(r.get_string("b"))

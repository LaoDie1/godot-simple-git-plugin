#============================================================
#    Videos Container
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-03 14:54:51
# - version: 4.3.0.stable
#============================================================
## 自动将节点的缩放匹配到和节点一样的大小
@tool
class_name AdaptiveContainer
extends Container


func _ready() -> void:
	resized.connect(
		func():
			for child in get_children():
				_update_child_scale(child)
	)
	child_entered_tree.connect(_update_child_scale)
	child_exiting_tree.connect(
		func(node): 
			if node is Control:
				node.scale = Vector2.ONE
	)

func update():
	resized.emit()

func _update_child_scale(node: Node):
	if node is Control:
		var vector : Vector2 = size / node.size
		var axis_value : float = min(vector.x, vector.y)
		node.scale = Vector2(axis_value, axis_value)
		if is_inf(node.scale.x) or is_inf(node.scale.y):
			node.scale = Vector2(1,1)
		
		if node.size_flags_horizontal & SIZE_SHRINK_CENTER == SIZE_SHRINK_CENTER:
			node.position.x = (size.x - node.size.x * axis_value) / 2
		elif node.size_flags_horizontal & SIZE_SHRINK_END == SIZE_SHRINK_END:
			node.position.x = (size.x - node.size.x * axis_value)
		
		if node.size_flags_vertical & SIZE_SHRINK_CENTER == SIZE_SHRINK_CENTER:
			node.position.y = (size.y - node.size.y * axis_value) / 2
		elif node.size_flags_vertical & SIZE_SHRINK_END == SIZE_SHRINK_END:
			node.position.y = (size.y - node.size.y * axis_value)
		
		if is_nan(node.position.x) or is_nan(node.position.y):
			node.position = Vector2(0,0)
		if is_nan(node.size.x) or is_nan(node.size.y):
			node.size = Vector2(0,0)
		

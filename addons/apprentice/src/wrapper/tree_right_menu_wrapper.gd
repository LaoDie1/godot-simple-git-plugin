#============================================================
#    Tree Right Menu Wrapper
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-30 20:37:14
# - version: 4.4.0.beta1
#============================================================
class_name TreeRightMenuWrapper
extends Object


signal actived(item: TreeItem)


var right_menu: PopupMenu
var right_selected_item: TreeItem


func _init(tree: Tree):
	tree.gui_input.connect(
		func(event):
			if event is InputEventMouseButton:
				if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
					right_selected_item = tree.get_item_at_position(tree.get_local_mouse_position())
					if right_selected_item:
						right_menu.popup(Rect2(
							Vector2(tree.get_tree().root.position) + tree.get_global_mouse_position(),
							Vector2()
						))
						right_selected_item.select(0)
						actived.emit(right_selected_item)
	)

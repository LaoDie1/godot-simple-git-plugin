#============================================================
#    跳起晃动
#============================================================
# - author: zhangxuetu
# - datetime: 2025-06-21 22:29:08
# - version: 4.4.1.stable
#============================================================
class_name JumpAndShakeEffect
extends EffectNode

signal finished(canvas_item_node: CanvasItem)

@export var position_curve: Curve
@export var rotate_curve: Curve


func start(canvas_item_node: CanvasItem):
	var origin_position = canvas_item_node.position
	var origin_scale = canvas_item_node.scale
	
	var pos_y = origin_position.y
	pos_y -= 50
	FuncUtil.execute_curve_tween(position_curve, canvas_item_node, "position:y", pos_y, 0.4)
	FuncUtil.execute_curve_tween(position_curve, canvas_item_node, "scale", origin_scale * 1.5, 0.4)
	await Engine.get_main_loop().create_timer(0.2).timeout
	FuncUtil.tween_curve(rotate_curve, canvas_item_node, "rotation", 1.5)
	await Engine.get_main_loop().create_timer(1.).timeout
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(canvas_item_node, "position:y", origin_position.y, 1) \
		.set_trans(Tween.TRANS_BOUNCE) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(canvas_item_node, "scale", origin_scale, 1) \
		.set_trans(Tween.TRANS_EXPO) \
		.set_ease(Tween.EASE_OUT).finished.connect(
			func():
				finished.emit(canvas_item_node)
				,
		)
	

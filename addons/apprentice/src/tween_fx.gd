#============================================================
#    Tween FX
#============================================================
# - author: zhangxuetu
# - datetime: 2026-03-04 20:24:52
# - version: 4.6.1.stable
#============================================================
class_name TweenFX


static func get_tree() -> SceneTree:
	return Engine.get_main_loop()

static func create_tween() -> Tween:
	return get_tree().create_tween()

## 漂浮动画
static func label_tornado(label: RichTextLabel) -> void:
	label.bbcode_enabled = true
	label.text = "[tornado radius=10.0 freq=2.0 connected=1]%s[/tornado]" % label.text 
	label.z_index = 20
	label.add_theme_font_size_override("normal_font_size", 12)

## 生命周期。到时间删除
static func lifecycle(node: Node, time: float) -> void:
	var tween : Tween = Engine.get_main_loop().create_tween()
	tween.tween_callback(node.queue_free).set_delay(time)
	tween.bind_node(node)

## 果冻弹动效果
static func jelly(
	node: CanvasItem, 
	target_scale: Vector2, 
	duration_to_target: float = 0.2, 
	duration_back: float = 0.2, 
	play_count: int = 1,
) -> Tween:
	if not "scale" in node:
		return null
	
	var original_scale : Vector2 = node.scale
	var tween: Tween = create_tween()
	tween.bind_node(node)
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) # 物理进程，避免帧率影响
	target_scale *= original_scale.sign() # 保持和原来的方向一致
	
	# 快速缩放到目标大小（用平滑过渡）
	tween.tween_property(node, ^"scale", target_scale, duration_to_target) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	
	# 从目标大小弹性弹回原大小（核心：TRANS_ELASTIC）
	tween.tween_property(node, ^"scale", original_scale, duration_back) \
		.set_trans(Tween.TRANS_ELASTIC) \
		.set_ease(Tween.EASE_OUT)
	
	tween.set_loops(play_count)
	return tween


## 透明度渐变
static func fade(node: CanvasItem, fade_in_time: float, interval: float, fade_out_time: float) -> Tween:
	var tween : Tween = create_tween()
	tween.bind_node(node)
	# 渐入
	fade_in_time = maxf(0, fade_in_time)
	if fade_in_time > 0:
		node.modulate.a = 0.0
		tween.tween_property(node, ^"modulate:a", 1.0, fade_in_time)
	# 渐出
	fade_out_time = maxf(0, fade_out_time)
	tween.tween_property(node, ^"modulate:a", 0.0, fade_out_time).set_delay(maxf(0.0, interval))
	return tween


## 蒸汽漂浮
static func steam(node: CanvasItem, duration: float, distance: float = -50) -> Tween:
	var tween : Tween = create_tween()
	tween.set_parallel(true)
	tween.bind_node(node)
	# 位置
	var final_pos_y : float = node.position.y + distance
	tween.tween_property(node, ^"position:y", final_pos_y, duration + 0.1)
	# 缩放
	#node.scale = Vector2(0.1, 0.1)
	#tween.tween_property(node, ^"scale", Vector2(1, 1), 0.2) \
		#.set_trans(Tween.TRANS_ELASTIC) \
		#.set_ease(Tween.EASE_OUT)
	# 显示
	node.modulate.a = 0
	tween.tween_property(node, ^"modulate:a", 0.8, 0.2).set_ease(Tween.EASE_OUT)
	# 消失
	var delay_time : float = maxf(0.0, duration - 0.2)
	#tween.tween_property(node, ^"scale", Vector2(0.2, 0.2), duration - 0.2).set_delay(0.2)
	tween.tween_property(node, ^"modulate:a", 0.0, 0.2).set_delay(delay_time)
	return tween


## 闪烁
static func glimmer(node: CanvasItem, count: int, duration: float, end_is_show_status: bool = true) -> Tween:
	var tween : Tween = create_tween()
	tween.bind_node(node)
	tween.tween_method(
		func(v):
			var index : int = int(v / duration)
			if node:
				node.visible = index % 2
			,
		0.0, duration * count * 2, duration
	).finished.connect(node.set_indexed.bind(^"visible", end_is_show_status), Object.CONNECT_DEFERRED)
	return tween
	

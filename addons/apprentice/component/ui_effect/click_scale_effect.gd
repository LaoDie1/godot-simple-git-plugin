#============================================================
#    点击缩放
#============================================================
# - author: zhangxuetu
# - datetime: 2025-06-22 14:28:40
# - version: 4.4.1.stable
#============================================================
class_name ClickScaleEffect
extends EffectNode

@export var canvas_item: Control:
	set(v):
		canvas_item = v
		canvas_item.gui_input.connect(
			func(event):
				if event is InputEventMouseButton:
					if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
						if time_left <= 0:
							play()
		)
@export var scale_ratio: float = 2.0 ##缩放最大倍率
@export var time: float = 1.0 ##播放时间
@export var scale_curve: Curve ##缩放倍数曲线

var time_left : float = 0.0
var origin_value
var origin_pivot_offset


func _ready():
	set_process(false)


func _process(delta):
	var ratio = 1.0 - time_left / time
	var v = scale_curve.sample(ratio) * scale_ratio
	canvas_item.scale = origin_value * v
	
	time_left -= delta
	if time_left <= 0:
		set_process(false)
		canvas_item.pivot_offset = origin_pivot_offset

func play():
	time_left = time
	origin_value = canvas_item.scale
	origin_pivot_offset = canvas_item.pivot_offset_ratio
	canvas_item.pivot_offset_ratio = Vector2(0.5, 0.8)
	set_process(true)

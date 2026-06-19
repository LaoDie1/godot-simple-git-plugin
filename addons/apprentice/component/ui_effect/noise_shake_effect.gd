#============================================================
#    Noise Shake Effect
#============================================================
# - author: zhangxuetu
# - datetime: 2025-06-22 13:42:31
# - version: 4.4.1.stable
#============================================================
class_name CanvasItemNoiseShakeEffect
extends EffectNode

@export var canvas: CanvasItem
@export var property: String = "position"  ##修改的对象的属性
@export var span : float = 50 ##震动跨度范围。在噪声上取值时的偏移幅度
@export var amplitude: float = 40 ##震动幅度
@export_range(0, 1) var evenness: float = 1: ##平滑度
	set(v):
		evenness = v
		if is_zero_approx(evenness):
			interval_frame = 1
		else:
			interval_frame = 1 / evenness
@export var shake_noise: FastNoiseLite ##震动噪波
@export var curve: Curve  ##震动幅度曲线

var v : int = 0
var start_status : bool = false
var play_time : float = 0.0
var time_left : float = 0.0
var interval_frame: int = 1

var tmp_pos: Vector2
var origin_pos : Vector2

func _ready():
	set_process(start_status)

func _process(delta):
	if start_status:
		if Engine.get_physics_frames() % interval_frame == 0:
			v += span 
			var x = shake_noise.get_noise_2d(v, 0)
			var y = shake_noise.get_noise_2d(v, v)
			if curve:
				var ratio = 1.0 - time_left / play_time
				var scale = curve.sample(ratio)
				tmp_pos = origin_pos + Vector2(x, y) * amplitude * scale
			else:
				tmp_pos = origin_pos + Vector2(x, y) * amplitude
		canvas[property] = lerp(canvas[property], tmp_pos, evenness)
		time_left -= delta
		start_status = time_left > 0
	else:
		set_process(false)


func start(time: float = 1.0):
	origin_pos = canvas[property]
	tmp_pos = canvas[property]
	start_status = true
	play_time = time
	time_left = time
	set_process(true)

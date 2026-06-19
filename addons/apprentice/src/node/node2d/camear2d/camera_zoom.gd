#============================================================
#	Camera Zoom
#============================================================
# @datetime: 2022-3-16 16:41:15
#============================================================
## 设置相机镜头为地图的大小范围的缩放
class_name CameraZoom
extends BaseCameraByTileMap


enum ScaleType {
	Normal,	## 按照常比例进行缩放
	Min,	## 按照最小的范围进行缩放
	Max,	## 按照最大的范围进行缩放
}

@export var scale_type : ScaleType = ScaleType.Min:
	set(v):
		scale_type = v
		_update_camera()
@export var min_zoom : Vector2 = Vector2.ZERO:
	set(v):
		min_zoom = v
		_update_camera()
@export var max_zoom : Vector2 = Vector2.INF:
	set(v):
		max_zoom = v
		_update_camera()
# 在缩放后的基础上再次计算缩放
@export var zoom_scale : Vector2 = Vector2(1.0, 1.0):
	set(v):
		if not zoom_scale.is_equal_approx(v):
			zoom_scale = v
			_update_camera()

var _last_zoom : Vector2 = Vector2(0, 0):
	set(v):
		if _last_zoom != v and v.is_finite() and v != Vector2.ZERO:
			_last_zoom = v
			if not is_node_ready():
				await ready
			camera.zoom = _last_zoom
			Log.dev("CameraZoom", "缩放大小 %s" % _last_zoom)


#(override)
func _update_camera():
	if not is_node_ready():
		await ready
	var rect : Rect2 = tilemap.get_used_rect()
	rect.size *= Vector2(tilemap.tile_set.tile_size)
	var camera_scale = (tilemap.get_viewport_rect().size / rect.size)
	camera_scale *= zoom_scale
	var value = Vector2()
	match scale_type:
		ScaleType.Normal:
			value = camera_scale
		
		ScaleType.Min:
			var z = min(camera_scale.x, camera_scale.y)
			value = Vector2(z, z)
		
		ScaleType.Max:
			var z = max(camera_scale.x, camera_scale.y)
			value = Vector2(z, z)
	
	# 不能低于最小也不能超出最大
	value.x = clamp(value.x, min_zoom.x, max_zoom.x)
	value.y = clamp(value.y, min_zoom.y, max_zoom.y)
	if value != Vector2.INF:
		_last_zoom = value

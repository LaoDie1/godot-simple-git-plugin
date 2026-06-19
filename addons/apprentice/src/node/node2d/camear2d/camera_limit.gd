#============================================================
#	Camera Limit By Map
#============================================================
# @datetime: 2022-3-15 00:34:43
#============================================================
## 设置镜头的有限的范围
class_name CameraLimit
extends BaseCameraByTileMap

## 额外设置的范围
@export var margin : Rect2 = Rect2(0,0,0,0):
	set(v):
		margin = v
		update_camera()

var __init_update_zoom_timer : Variant = (
	func():
		var method : Callable = func():
			if not enabled:
				return
			while not tilemap:
				await get_tree().process_frame
		if not is_node_ready():
			self.ready.connect(method, Object.CONNECT_ONE_SHOT)
		else:
			method.call_deferred()
).call()


func get_limit() -> Rect2:
	return CameraUtil.get_limit(camera)


#(override)
func _update_camera():
	if not is_node_ready():
		await ready
	
	var rect = Rect2(tilemap.get_used_rect())
	if tilemap.tile_set == null:
		Log.error("CameraLimit", "这个 TileMapLayer 没有设置 tile_set 属性")
		return
	
	var tile_size = Vector2(tilemap.tile_set.tile_size)
	rect.position *= tile_size
	#rect.size += Vector2.ONE
	rect.size *= tile_size
	rect.position += tilemap.global_position
	
#	rect.size *= camera.zoom
	
	if not rect.size.is_zero_approx():
		camera.limit_left = rect.position.x + margin.position.x
		camera.limit_right = rect.end.x + margin.size.x
		camera.limit_top = rect.position.y + margin.position.y
		camera.limit_bottom = rect.end.y + margin.size.y

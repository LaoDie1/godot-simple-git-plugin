#============================================================
#    Camera Util
#============================================================
# - datetime: 2022-09-04 10:30:56
#============================================================

##  摄像机工具类
class_name CameraUtil


##  获取当前镜头
static func get_current_camera2d() -> Camera2D:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		return tree.root.get_camera_2d()
	return null

##  缩放镜头
static func zoom(camera: Camera2D, value: Vector2, duration: float):
	if is_instance_valid(camera):
		# 镜头缩放
		var tree := Engine.get_main_loop() as SceneTree
		tree.create_tween().tween_property(camera, "zoom", value, duration)

## 获取相机的范围
static func get_limit(camera: Camera2D) -> Rect2:
	return Rect2( Vector2(camera.limit_left, camera.limit_top), Vector2(camera.limit_right, camera.limit_bottom) )

## 设置相机的可见范围
static func set_limit(camera: Camera2D, rect: Rect2, scale: float = -1):
	if scale == -1:
		scale = 1 / camera.zoom.x
	camera.limit_left = rect.position.x * scale
	camera.limit_right = rect.end.x * scale
	camera.limit_top = rect.position.y * scale
	camera.limit_bottom = rect.end.y * scale

static func get_current_zoom() -> Vector2:
	return get_current_camera2d().zoom

static func get_view_position() -> Vector2:
	var camera : Camera2D = get_current_camera2d()
	# 1. 相机偏移（offset）
	var cam_offset: Vector2 = camera.offset
	# 2. 相机缩放（zoom）
	var cam_zoom: Vector2 = camera.zoom
	# 3. 相机真实屏幕中心（含平滑、偏移、限界）
	var screen_center: Vector2 = camera.get_screen_center_position()
	# 4. 视口/屏幕像素大小
	var viewport_size: Vector2 = camera.get_viewport_rect().size
	# 5. 最终：屏幕左上角世界坐标（重点！）
	var top_left: Vector2 = screen_center - (viewport_size / 2.0) / cam_zoom
	return top_left

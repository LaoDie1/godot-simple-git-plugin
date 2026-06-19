#============================================================
#    Ffmpeg Util
#============================================================
# - author: zhangxuetu
# - datetime: 2024-12-02 14:56:08
# - version: 4.3.0.stable
#============================================================
class_name FFMpegUtil

## ffmpeg.exe 文件路径 
static var ffmpeg_path: String = ""
static var enabled_print_command: bool = false
static var finished: Signal:
	get:
		if not finished:
			pass
		return finished


class FFMpegExecutor:
	extends Object
	
	signal finished
	
	var result: Dictionary
	func execute(params: Array):
		assert(FFMpegUtil.ffmpeg_path != "", "没有置 ffmpeg 的路径")
		var output: Array = []
		var err = OS.execute("CMD.exe", ["/C", " ".join(params)], output, true)
		if FFMpegUtil.enabled_print_command:
			print("CMD.exe /C ", " ".join(params))
		result = {
			"command": " ".join(params),
			"error": err,
			"output": output[0]
		}


static func _execute_command(params: Array) -> FFMpegExecutor:
	var executor = FFMpegExecutor.new()
	executor.execute(params)
	return executor


## 生成预览图片
static func get_video_preview_image(video_path: String) -> Image:
	assert(ffmpeg_path != "", "没有设置 ffmpeg_path 属性")
	var file_name : String = FileUtil.get_file_md5(video_path, false) + ".png"
	var path : String = OS.get_cache_dir() + "/Temp".path_join(file_name)
	if not FileAccess.file_exists(path):
		_execute_command(["chcp 65001 &&  %s" % ffmpeg_path, "-i", '"%s"' % video_path, "-ss", "00:00:10", "-vframes", "1", '"%s"' % path])
	if FileAccess.file_exists(path):
		return Image.load_from_file(path)
	return null

## 转为 mp3 文件
static func convert_to_mp3(file_path: String, new_path: String) -> FFMpegExecutor:
	new_path = new_path.replace("\\", "/")
	return _execute_command(["chcp 65001 &&  %s" % ffmpeg_path, '-i', '"%s"' % file_path, '"%s"' % new_path])


# 编码速度和质量
const Preset = {
	ULTRAFAST = "ultrafast",
	SUPERFAST = "superfast",
	VERYFAST = "veryfast",
	FASTER = "faster",
	FAST = "fast",
	MEDIUM = "medium",
	SLOW = "slow",
	SLOWER = "slower",
	VERYSLOW = "veryslow",
}

## 压缩视频
static func compress_video(video_path: String, new_path: String, preset: String = "medium") -> FFMpegExecutor:
	return _execute_command([
		ffmpeg_path, 
		'-i', '"%s"' % video_path, 
		"-c:v", "libx264",
		"-preset", preset,
		'"%s"' % new_path
	])


# 极速提取视频封面（极小体积JPG，无重名，2秒封面）
static func get_video_cover_fast(video_path: String, cover_output_path: String = "") -> String:
	var abs_video = ProjectSettings.globalize_path(video_path)
	var abs_cover: String

	# 唯一ID（MD5 视频完整路径，永不重名）
	var video_hash = abs_video.md5_text()
	var cover_name = "%s_cover.jpg" % video_hash

	if cover_output_path.is_empty():
		abs_cover = ProjectSettings.globalize_path("user://covers/%s" % cover_name)
	else:
		abs_cover = ProjectSettings.globalize_path(cover_output_path)

	# 缓存直接返回
	if FileAccess.file_exists(abs_cover):
		return abs_cover

	# 确保目录
	var cover_dir = abs_cover.get_base_dir()
	if not DirAccess.dir_exists_absolute(cover_dir):
		DirAccess.make_dir_recursive_absolute(cover_dir)

	# 时长判断：2秒封面，不足则0秒
	var duration = get_video_duration(abs_video)
	var seek_time = "2.0" if duration >= 2.0 else "0.0"

	# ====================== 关键优化：极小体积 JPG ======================
	var args = [
		"-ss", seek_time,
		"-i", abs_video,
		"-vframes", "1",
		"-q:v", "15",       # 10~15 极小体积，封面完全够用
		"-vf", "scale=320:-1",  # 可选：缩宽度到320，体积更小
		"-y",
		abs_cover
	]
	# ====================================================================

	var output = []
	var exit_code = OS.execute(ffmpeg_path, args, output)

	if exit_code == 0 and FileAccess.file_exists(abs_cover):
		return abs_cover
	else:
		printerr("封面提取失败:", output)
		return ""


# 获取视频时长
static func get_video_duration(video_abs_path: String) -> float:
	var args = [
		"-v", "error",
		"-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		video_abs_path
	]

	var probe_path = ffmpeg_path.replace("ffmpeg", "ffprobe")
	if not FileAccess.file_exists(probe_path):
		probe_path = ffmpeg_path

	var output = []
	var exit_code = OS.execute(probe_path, args, output)

	if exit_code == 0 and output.size() > 0:
		var s = output[0].strip_edges()
		var f = float(s)
		if f > 0:
			return f
	return 0.0

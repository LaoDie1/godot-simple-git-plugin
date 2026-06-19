#============================================================
#    Icns Util
#============================================================
# - author: zhangxuetu
# - datetime: 2026-03-04 19:46:09
# - version: 4.6.1.stable
#============================================================
class_name IcnsUtil

# ==========================================
# 辅助函数：处理大端序（Big-Endian）读写
# icns 格式遵循苹果大端序规范
# ==========================================

# 读取大端序 32 位整数
static func _read_u32_be(file: FileAccess) -> int:
	if file.get_available_bytes() < 4:
		return 0
	var b0 = file.get_8()
	var b1 = file.get_8()
	var b2 = file.get_8()
	var b3 = file.get_8()
	return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3

# 写入大端序 32 位整数
static func _write_u32_be(file: FileAccess, value: int):
	file.store_8((value >> 24) & 0xff)
	file.store_8((value >> 16) & 0xff)
	file.store_8((value >> 8) & 0xff)
	file.store_8(value & 0xff)

# 读取 4 字符类型标识（如 "icns"、"ic07"）
static func _read_fourcc(file: FileAccess) -> String:
	if file.get_available_bytes() < 4:
		return ""
	var buffer = file.get_buffer(4)
	return buffer.get_string_from_utf8()

# 写入 4 字符类型标识
static func _write_fourcc(file: FileAccess, fourcc: String):
	var buffer = fourcc.to_utf8_buffer()
	# 确保长度为 4 字节，不足则补 0
	if buffer.size() < 4:
		var padded = PackedByteArray()
		padded.resize(4)
		for i in buffer.size():
			padded[i] = buffer[i]
		for i in range(buffer.size(), 4):
			padded[i] = 0
		buffer = padded
	file.store_buffer(buffer)

# ==========================================
# 核心功能 1：读取 icns 文件
# ==========================================

# 读取 icns 文件，返回包含所有图标的 Image 数组
# 现代 icns 通常包含多个尺寸（如 128x128、512x512）
static func load_icns(file_path: String) -> Array[Image]:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("无法打开文件: " + file_path)
		return []

	var images: Array[Image] = []

	# 1. 验证文件头（魔数 "icns"）
	var magic = _read_fourcc(file)
	if magic != "icns":
		push_error("无效的 icns 文件：魔数不匹配")
		file.close()
		return []

	# 2. 读取文件总大小
	var file_size = _read_u32_be(file)

	# 3. 遍历所有数据块
	while file.get_position() < file_size:
		# 读取块头：4字节类型 + 4字节块大小
		var block_type = _read_fourcc(file)
		var block_size = _read_u32_be(file)

		if block_size < 8:
			push_error("无效的数据块大小")
			break

		# 读取块数据（跳过 8 字节块头）
		var data_size = block_size - 8
		if file.get_available_bytes() < data_size:
			push_error("文件意外结束")
			break
		var block_data = file.get_buffer(data_size)

		# 4. 尝试将数据加载为 Image（现代 icns 通常是 PNG 格式）
		var img = Image.new()
		var err = img.load_from_buffer(block_data)
		if err == OK:
			images.append(img)

	file.close()
	return images

# ==========================================
# 核心功能 2：保存 Image 为 icns 文件
# ==========================================

# 定义常用的 icns 类型与对应尺寸（覆盖主流 Retina 屏幕需求）
const ICNS_TYPES = [
	{"type": "ic07", "size": 128},  # 128x128
	{"type": "ic08", "size": 256},  # 256x256
	{"type": "ic09", "size": 512},  # 512x512
	{"type": "ic10", "size": 1024}, # 1024x1024
	{"type": "ic11", "size": 32},   # 16x16@2x (32x32)
	{"type": "ic12", "size": 64},   # 32x32@2x (64x64)
	{"type": "ic13", "size": 256},  # 128x128@2x (256x256)
	{"type": "ic14", "size": 512},  # 256x256@2x (512x512)
]

# 将单个 Image 保存为 icns 文件（自动缩放到多尺寸）
# 参数：
#   image: 源图像（建议尺寸 >= 1024x1024 以保证清晰度）
#   file_path: 保存路径，如 "res://app_icon.icns"
static func save_icns_single(image: Image, file_path: String) -> bool:
	# 1. 预处理源图：确保为 RGBA8 格式
	var source = image.duplicate()
	if source.get_format() != Image.FORMAT_RGBA8:
		source.convert(Image.FORMAT_RGBA8)

	# 2. 生成所有尺寸的图标数据块
	var blocks = []
	for spec in ICNS_TYPES:
		var size = spec["size"]
		# 高质量缩放（Lanczos 算法）
		var scaled = source.duplicate()
		scaled.resize(size, size, Image.INTERPOLATE_LANCZOS)
		# 转换为 PNG 字节流
		var png_data = scaled.save_png_to_buffer()
		if png_data.is_empty():
			push_error("无法生成尺寸 " + str(size) + " 的 PNG 数据")
			continue
		blocks.append({"type": spec["type"], "data": png_data})

	if blocks.is_empty():
		push_error("未生成任何有效图标数据")
		return false

	# 3. 计算文件总大小
	var file_size = 8  # 文件头（8字节）
	for block in blocks:
		file_size += 8 + block["data"].size()  # 块头（8字节）+ 数据

	# 4. 写入文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("无法打开文件写入: " + file_path)
		return false

	# 写入文件头
	_write_fourcc(file, "icns")
	_write_u32_be(file, file_size)

	# 写入每个数据块
	for block in blocks:
		_write_fourcc(file, block["type"])
		_write_u32_be(file, 8 + block["data"].size())
		file.store_buffer(block["data"])

	file.close()
	print("icns 保存成功: " + file_path)
	return true


# ==========================================
# 进阶功能：自定义多图保存
# ==========================================

##自定义保存：将多个指定尺寸的 Image 打包为 icns.
##[br]
##[br]  - [param type_to_image]:  [Dictionary] 类型的数据。[code]key[/code] 为 icns 类型（如 [code]"ic07"[/code]），
##[code]value[/code] 为对应 [Image]。参看 [member ICNS_TYPES] 常量类型和大小。
static func save_icns_custom(type_to_image: Dictionary, file_path: String) -> bool:
	var blocks = []
	for type_str in type_to_image:
		var img = type_to_image[type_str] as Image
		if not img:
			continue
		# 预处理
		var cpy = img.duplicate()
		if cpy.get_format() != Image.FORMAT_RGBA8:
			cpy.convert(Image.FORMAT_RGBA8)
		# 转 PNG
		var png_data = cpy.save_png_to_buffer()
		if png_data.is_empty():
			continue
		blocks.append({"type": type_str, "data": png_data})

	if blocks.is_empty():
		return false

	# 写入文件（逻辑同上）
	var file_size = 8
	for block in blocks:
		file_size += 8 + block["data"].size()

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return false

	_write_fourcc(file, "icns")
	_write_u32_be(file, file_size)

	for block in blocks:
		_write_fourcc(file, block["type"])
		_write_u32_be(file, 8 + block["data"].size())
		file.store_buffer(block["data"])

	file.close()
	return true

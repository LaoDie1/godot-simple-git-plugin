#============================================================
#    Ico Util
#============================================================
# - author: zhangxuetu
# - datetime: 2026-03-04 19:28:40
# - version: 4.6.1.stable
#============================================================
class_name IcoUtil

# 加载并解析 ICO 文件，返回 Image 对象数组（因为 ICO 可包含多个尺寸）
static func load_ico(file_path: String) -> Array[Image]:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("无法打开文件: " + file_path)
		return []

	var images: Array[Image] = []

	# === 1. 解析 ICONDIR (文件头) ===
	var id_reserved = file.get_16() # 必须为 0
	var id_type = file.get_16()     # 1 表示图标, 2 表示光标
	var id_count = file.get_16()    # 图标数量

	if id_reserved != 0 or id_type != 1:
		push_error("无效的 ICO 文件")
		file.close()
		return []

	# === 2. 解析 ICONDIRENTRY (目录入口数组) ===
	var entries = []
	for i in range(id_count):
		var entry = {
			"width": file.get_8(),          # 宽度 (0=256)
			"height": file.get_8(),         # 高度 (0=256)
			"color_count": file.get_8(),    # 颜色数
			"reserved": file.get_8(),       # 保留值
			"planes": file.get_16(),        # 色平面数
			"bit_count": file.get_16(),     # 位深
			"bytes_in_res": file.get_32(),  # 图像数据大小
			"image_offset": file.get_32()   # 图像数据偏移量
		}
		# 处理 0 代表 256 的情况
		if entry["width"] == 0: entry["width"] = 256
		if entry["height"] == 0: entry["height"] = 256
		entries.append(entry)

	# === 3. 逐个解析图像数据 ===
	for entry in entries:
		file.seek(entry["image_offset"])
		var data = file.get_buffer(entry["bytes_in_res"])
		
		# 判断是否为 PNG 格式 (检查 PNG 签名)
		if _is_png_data(data):
			var img = _load_png_from_data(data)
			if img: images.append(img)
		else:
			# 否则视为 ICO 格式的 BMP (需要手动解析)
			var img = _parse_ico_bmp(data, entry)
			if img: images.append(img)

	file.close()
	return images

# 检查数据头是否为 PNG
static func _is_png_data(data: PackedByteArray) -> bool:
	if data.size() < 8: return false
	return (data[0] == 0x89 and data[1] == 0x50 and data[2] == 0x4E and data[3] == 0x47)

# 从内存加载 PNG
static func _load_png_from_data(data: PackedByteArray) -> Image:
	var img = Image.new()
	# Godot 4.0+ 可以直接从内存识别格式加载
	var err = img.load_from_buffer(data)
	if err != OK:
		push_error("无法解析 PNG 图像数据")
		return null
	return img

# 解析 ICO 内嵌的 BMP 格式 (最复杂的部分)
static func _parse_ico_bmp(data: PackedByteArray, entry: Dictionary) -> Image:
	# 使用 StreamPeerBuffer 方便按字节读取
	var stream = StreamPeerBuffer.new()
	stream.set_data_array(data)
	stream.set_big_endian(false) # Windows 格式是小端序

	# === 解析 BITMAPINFOHEADER ===
	var bi_size = stream.get_u32()       # 头大小 (40)
	var bi_width = stream.get_u32()      # 宽度
	var bi_height = stream.get_u32()     # 高度 (注意: ICO中这里是双倍高度，包含了 AND 掩码)
	var bi_planes = stream.get_u16()     # 平面数
	var bi_bit_count = stream.get_u16()  # 位深
	var bi_compression = stream.get_u32()# 压缩类型 (0=无压缩)
	
	# 只支持无压缩的 BMP
	if bi_compression != 0:
		push_error("不支持压缩的 BMP 格式")
		return null

	var real_height = bi_height / 2 # 真实高度是一半
	
	# === 读取颜色表 (如果位深 <= 8) ===
	var color_table = []
	if bi_bit_count <= 8:
		var color_count = stream.get_u32() # bi_clr_used
		if color_count == 0: color_count = 1 << bi_bit_count
		
		for i in range(color_count):
			var b = stream.get_u8()
			var g = stream.get_u8()
			var r = stream.get_u8()
			var a = stream.get_u8() # 通常为 0
			color_table.append(Color(r/255.0, g/255.0, b/255.0, 1.0))

	# 行宽对齐到 4 字节
	var xor_row_size = ((bi_width * bi_bit_count + 31) / 32) * 4
	var and_row_size = ((bi_width + 31) / 32) * 4 # AND 掩码是 1bit per pixel

	# 读取 XOR (颜色数据) 和 AND (透明度掩码)
	# 注意：StreamPeerBuffer 没有 seek 方便的相对跳转，我们一次性读取剩余字节然后切片
	var remaining_data = stream.get_data(stream.get_available_bytes())[1]
	
	var xor_data = remaining_data.slice(0, xor_row_size * int(real_height))
	var and_data = remaining_data.slice(xor_row_size * int(real_height), xor_row_size * int(real_height) + and_row_size * int(real_height))

	# 锁定图像以进行快速像素操作
	var img = Image.create(bi_width, real_height, false, Image.FORMAT_RGBA8)
	for y in range(real_height):
		# BMP 是倒序存储的 (Bottom-up)
		var src_y = int(real_height) - 1 - y
		
		for x in range(bi_width):
			var r = 0
			var g = 0
			var b = 0
			var a = 255
			
			# --- 1. 从 XOR 掩码获取颜色 ---
			if bi_bit_count == 32:
				var pos = src_y * xor_row_size + x * 4
				b = xor_data[pos]
				g = xor_data[pos+1]
				r = xor_data[pos+2]
				a = xor_data[pos+3] # 32位通常有 Alpha
			elif bi_bit_count == 24:
				var pos = src_y * xor_row_size + x * 3
				b = xor_data[pos]
				g = xor_data[pos+1]
				r = xor_data[pos+2]
				a = 255
			elif bi_bit_count == 8:
				var pos = src_y * xor_row_size + x
				var idx = xor_data[pos]
				var col = color_table[idx]
				r = int(col.r * 255)
				g = int(col.g * 255)
				b = int(col.b * 255)
				a = 255
			# TODO: 可以在此扩展 4bit 和 1bit 支持

			# --- 2. 从 AND 掩码处理透明度 (Icon 特性) ---
			# AND 掩码是 1bit 表示一个像素
			var byte_idx = src_y * and_row_size + (x / 8)
			var bit_idx = 7 - (x % 8) # 从高位到低位
			
			if byte_idx < and_data.size():
				var bit = (and_data[byte_idx] >> bit_idx) & 1
				if bit == 1:
					a = 0 # AND 掩码为 1 表示透明

			# 设置像素
			img.set_pixel(x, y, Color(r/255.0, g/255.0, b/255.0, a/255.0))

	return img



# 将单个 Image 保存为 ICO 文件（使用 PNG 格式存储图像数据）
# 参数：
#   image: 要保存的 Image 对象（建议为 RGBA8 格式）
#   file_path: 保存路径，如 "res://output.ico"
static func save_ico_single(image: Image, file_path: String) -> bool:
	# 1. 预处理图像：确保是 RGBA8 格式
	var img = image.duplicate()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	# 2. 将 Image 编码为 PNG 字节流
	var png_data = img.save_png_to_buffer()
	if png_data.is_empty():
		push_error("Image 转 PNG 失败")
		return false

	# 3. 打开文件准备写入
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("无法打开文件写入: " + file_path)
		return false

	# === 4. 写入 ICONDIR (文件头，6 字节) ===
	file.store_16(0)                # idReserved (必须为 0)
	file.store_16(1)                # idType (1=图标, 2=光标)
	file.store_16(1)                # idCount (图标数量)

	# === 5. 写入 ICONDIRENTRY (目录入口，16 字节) ===
	var width = img.get_width()
	var height = img.get_height()
	
	file.store_8(width if width != 256 else 0)  # bWidth (256 存 0)
	file.store_8(height if height != 256 else 0) # bHeight (256 存 0)
	file.store_8(0)                               # bColorCount (0=真彩色)
	file.store_8(0)                               # bReserved (必须为 0)
	file.store_16(1)                              # wPlanes (色平面数，通常为 1)
	file.store_16(32)                             # wBitCount (位深，RGBA8 是 32)
	file.store_32(png_data.size())                # dwBytesInRes (图像数据大小)
	file.store_32(6 + 16)                         # dwImageOffset (数据偏移：头6 + 入口16)

	# === 6. 写入 PNG 图像数据 ===
	file.store_buffer(png_data)

	file.close()
	print("ICO 保存成功: " + file_path)
	return true


# 将多个 Image 保存为一个 ICO 文件（支持多尺寸）
# 参数：
#   images: Image 数组，每个元素代表一个尺寸的图标
#   file_path: 保存路径
static func save_ico_multi(images: Array[Image], file_path: String) -> bool:
	if images.is_empty():
		push_error("Image 数组为空")
		return false

	# 1. 预处理所有图像并编码为 PNG
	var icon_datas = []
	var total_size = 0
	
	for img in images:
		var cpy = img.duplicate()
		if cpy.get_format() != Image.FORMAT_RGBA8:
			cpy.convert(Image.FORMAT_RGBA8)
		
		var png = cpy.save_png_to_buffer()
		if png.is_empty():
			push_error("Image 转 PNG 失败")
			return false
		
		icon_datas.append({
			"img": cpy,
			"data": png
		})
		total_size += png.size()

	# 2. 打开文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("无法打开文件写入: " + file_path)
		return false

	# === 3. 写入 ICONDIR ===
	file.store_16(0)
	file.store_16(1)
	file.store_16(icon_datas.size()) # 图标数量

	# === 4. 计算偏移量并写入 ICONDIRENTRY 数组 ===
	# 偏移量 = 头大小(6) + 所有入口大小(16*n) + 前面图像数据的大小
	var current_offset = 6 + 16 * icon_datas.size()
	
	for icon in icon_datas:
		var img = icon["img"]
		var data = icon["data"]
		var w = img.get_width()
		var h = img.get_height()
		
		file.store_8(w if w != 256 else 0)
		file.store_8(h if h != 256 else 0)
		file.store_8(0)
		file.store_8(0)
		file.store_16(1)
		file.store_16(32)
		file.store_32(data.size())
		file.store_32(current_offset)
		
		current_offset += data.size()

	# === 5. 依次写入所有图像数据 ===
	for icon in icon_datas:
		file.store_buffer(icon["data"])

	file.close()
	print("多尺寸 ICO 保存成功: " + file_path)
	return true

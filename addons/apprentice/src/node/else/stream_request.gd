#============================================================
#    Stream Request
#============================================================
# - author: zhangxuetu
# - datetime: 2025-01-06 17:47:33
# - version: 4.3.0.stable
#============================================================
## 流式获取数据请求
class_name StreamRequest
extends MyNode


signal responded(body_chunk: PackedByteArray) ##响应数据中
signal responded_error(status: HTTPClient.Status)  ##响应出现错误
signal connect_closed   ##连接关闭
signal connected  ##连接成功并结束
signal received_headers(headers: Dictionary) ##收到响应头
signal redirected(redirect_url: String)  ##重定向

@export_range(-1, 64, 1.0) var max_redirects : int = 8

var _http_client : HTTPClient = HTTPClient.new()
var _connected_status : bool = false  #是否已经连接
var _has_received_headers : bool = false


func request(url: String, headers: PackedStringArray = PackedStringArray(), method: HTTPClient.Method = 0, request_body: String = "") -> int:
	var url_parts = url.split("://")
	var protocol : String = url_parts[0]  # "https" 或 "http"
	var host_and_path = url_parts[1].split("/", true, 1)
	var host_and_port = host_and_path[0].split(":")  # "api.deepseek.com"
	var host : String = host_and_port[0]
	var path : String = ("/" + host_and_path[1] if host_and_path.size() > 1 else "/")  # "/chat/completions"
	
	# 设置端口和 SSL
	var port : int = 443 if protocol == "https" else 80
	if host_and_port.size() > 1:
		port = int(host_and_port[1])
	var tls_options = TLSOptions.client() if protocol == "https" else null
	
	# 连接到主机
	print("开始连接到主机")
	_http_client.close()
	var error : int = _http_client.connect_to_host(host, port, tls_options)
	if error != OK:
		push_error("Failed to connect to host: ", error, "  ", error_string(error))
		prints("  ", host, port)
		responded_error.emit(_http_client.get_status())
		return error
	
	# 等待连接完成
	_call_method(
		func():
			print("开始建立与 %s 的连接" % host)
			while _http_client.get_status() == HTTPClient.STATUS_CONNECTING or _http_client.get_status() == HTTPClient.STATUS_RESOLVING:
				_http_client.poll()
				await get_tree().create_timer(0.2).timeout
			if _http_client.get_status() != HTTPClient.STATUS_CONNECTED:
				push_error("Failed to connect to host. Status: ", _http_client.get_status())
				responded_error.emit(_http_client.get_status())
				return _http_client.get_status()
			print("已连接")
			
			print("开始发送请求：", path)
			error = _http_client.request(method, path, headers, request_body)
			if error != OK:
				push_error("Failed to send request: ", error, "  ", error_string(error))
				responded_error.emit(_http_client.get_status())
				return error
			print("请求成功，开始读取数据流...")
			# 开始读取流式响应
			_has_received_headers = false
			_connected_status = true
			set_process(true)
	)
	
	return OK

func _call_method(method: Callable) -> void:
	method.call()

func is_connecting() -> bool:
	return _connected_status

func _ready() -> void:
	set_process(false)

var _last_headers: Dictionary
func _process(delta):
	if not _connected_status:
		return
	
	_http_client.poll()
	match _http_client.get_status():
		HTTPClient.STATUS_BODY:
			# 🔥 修正逻辑：如果还没读取过 Header，先读取 Header
			if not _has_received_headers:
				_has_received_headers = true
				_last_headers = _http_client.get_response_headers_as_dictionary()
				received_headers.emit(_last_headers)
				# 处理重定向
				for key in _last_headers:
					if key.to_lower() == "location":
						_connected_status = false
						set_process(false)
						_http_client.close()
						var redirect_url : String = _last_headers[key]
						request(redirect_url)
						redirected.emit(redirect_url)
						break
				return
			
			# 读取流式数据
			var chunk = _http_client.read_response_body_chunk()
			if chunk.size() > 0:
				responded.emit(chunk)
		
		HTTPClient.STATUS_DISCONNECTED:
			close()
		
		HTTPClient.STATUS_CONNECTED:
			close()
			connected.emit()
		
		HTTPClient.STATUS_REQUESTING:
			pass
		
		_:
			print_debug(_http_client.get_status())
			responded_error.emit(_http_client.get_status())
			close()


func close():
	# 连接关闭
	if _connected_status:
		_connected_status = false
		connect_closed.emit()
	set_process(false)
	_http_client.close()

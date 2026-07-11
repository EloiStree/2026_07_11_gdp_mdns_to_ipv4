class_name MDNSGetPublicIPv4
extends Node

signal on_found_public_ipv4(ipv4: String)
signal on_not_found_public_ipv4()

@export var ipv4_found: String = ""
@export var refresh_at_ready: bool = true
@export var timeout: float = 10.0

const IP_SERVICES: PackedStringArray = [
	"https://api.ipify.org",
	"https://ifconfig.me/ip",
	"https://checkip.amazonaws.com",
	"https://icanhazip.com",
    "https://ipinfo.io/ip"
]

var _http_request: HTTPRequest
var _is_requesting: bool = false

func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	if refresh_at_ready:
		refresh_ipv4()

func refresh_ipv4() -> void:
	_cancel_request()
	_fetch_ipv4()

func _fetch_ipv4() -> void:
	_is_requesting = true
	
	for url in IP_SERVICES:
		if not _is_requesting:
			break
		
		var ip := await _fetch_from_url(url)
		
		if not _is_requesting:
			break
		
		if not ip.is_empty():
			ipv4_found = ip
			on_found_public_ipv4.emit(ip)
			_is_requesting = false
			return
	
	ipv4_found = ""
	on_not_found_public_ipv4.emit()
	_is_requesting = false

func _fetch_from_url(url: String) -> String:
	var err := _http_request.request(url)
	if err != OK:
		return ""
	
	var timed_out := false
	var timer := get_tree().create_timer(timeout)
	timer.timeout.connect(func():
		timed_out = true
		_http_request.cancel_request()
	)
	
	var response: Array = await _http_request.request_completed
	
	if timed_out:
		return ""
	
	if response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200:
		var ip: String = response[3].get_string_from_utf8().strip_edges()
		if _is_valid_ipv4(ip):
			return ip
	
	return ""

func _cancel_request() -> void:
	_is_requesting = false
	if is_instance_valid(_http_request) and _http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_http_request.cancel_request()

func _is_valid_ipv4(ip: String) -> bool:
	if ip.is_empty():
		return false
	var parts := ip.split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if not part.is_valid_int():
			return false
		var num := part.to_int()
		if num < 0 or num > 255:
			return false
	return true

func is_requesting() -> bool:
	return _is_requesting

func _exit_tree() -> void:
	_cancel_request()

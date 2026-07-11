class_name MDNSGetDNSIPv4
extends Node

signal on_ipv4_address_found(ipv4_address: String)
signal on_ipv4_address_found_with_mdns(mdns_not_found:String, ipv4_address: String)
signal on_ipv4_address_not_found()
signal on_ipv4_address_not_found_with_mdns(mdns_not_found:String)

@export var mdns_service_name: String = "https://apint.ddns.net"
@export var found_ipv4_address: String = ""

@export var fetch_at_ready: bool = true

func _ready() -> void:
	if fetch_at_ready:
		try_to_fetch_ipv4_address_in_inspector()


func try_to_fetch_ipv4_address_in_inspector() -> void:
	var hostname := mdns_service_name.trim_prefix("https://").trim_prefix("http://")
	var resolved := IP.resolve_hostname(hostname, IP.TYPE_IPV4)
	var response := {}
	if resolved != "" and resolved != "0.0.0.0":
		response["address"] = resolved
	_on_mdns_response(response)

func _on_mdns_response(response: Dictionary) -> void:
	if response.is_empty():
		push_warning("mDNS: No response received for service: " + mdns_service_name)
		return
	var ipv4: String = ""
	if response.has("addresses") and not response["addresses"].is_empty():
		for address in response["addresses"]:
			if typeof(address) == TYPE_STRING and address.is_valid_ip_address():
				# Check it's IPv4 (not IPv6)
				if not ":" in address:
					ipv4 = address
					break

	if ipv4.is_empty() and response.has("address"):
		var address = response["address"]
		if typeof(address) == TYPE_STRING and address.is_valid_ip_address() and not ":" in address:
			ipv4 = address

	if not ipv4.is_empty():
		found_ipv4_address = ipv4
		on_ipv4_address_found.emit(found_ipv4_address)
		on_ipv4_address_found_with_mdns.emit(mdns_service_name, found_ipv4_address)
	else:
		on_ipv4_address_not_found.emit()
		on_ipv4_address_not_found_with_mdns.emit(mdns_service_name)
		
func set_mdns_address(mdns_address: String) -> void:
	mdns_service_name = mdns_address

func set_mdns_address_and_fetch(mdns_address: String) -> void:
	mdns_service_name = mdns_address
	try_to_fetch_ipv4_address_in_inspector()

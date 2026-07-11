class_name MDNSGetLocalIPv4
extends Node


signal on_found_local_ipv4(ipv4:String)
signal on_found_local_ipv4_join(ipv4:String)
signal on_not_found_local_ipv4()

@export var ivp4_found:String
@export var ivp4_list:Array[String] = [	]
@export var splitter:String = ","
@export var ivp4_list_join:String = ""
@export var refresh_at_ready:bool=true
@export var remove_localhost:bool=true

func _ready() -> void:
	if refresh_at_ready:
		refresh_ipv4()

func refresh_ipv4():
	ivp4_list.clear()
	var addresses = IP.get_local_addresses()
	if remove_localhost:
		var filtered: Array[String] = []
		for addr in addresses:
			if not addr.begins_with("127.") and not addr.contains("localhost"):
				filtered.append(addr)
		addresses = filtered
	for address in addresses:
		if address.contains(".") and not address.begins_with("127."):
			ivp4_list.append(address)
			on_found_local_ipv4.emit(address)
	if ivp4_list.size() > 0:
		ivp4_found = ivp4_list[0]
	else:
		ivp4_found = ""
		on_not_found_local_ipv4.emit()	
	ivp4_list_join = ",".join(ivp4_list)
	on_found_local_ipv4_join.emit(ivp4_list_join)
	

##Resource that functions as a customizable Preset for the [FileManager]. Handles all data management.
##
##A simple way to organize all your loading and saving into Resources.
##The goal was to minimize the lines of code you need to write in your project to set up your files.
##Can optionally handle session info, when saving and loading becomes conditional.
##
##Also compresses data into a single string, going from bytes into GZIP into base64 (and decompressing).
##Supports multiple copies of an object saving and loading their properties.

extends Files

class_name FilePreset

##Name of the preset. Is referred to by all other methods.
@export var name: String
##List of properties that need to be saved from the connected objects.
@export var properties: PackedStringArray

@export_group("extra")
##Make this preset part of a group. Can then be referenced by group name.
@export var in_group: bool = false
##Name of the group. Is referred to by all other methods.
@export var group_name: String
##Save the data to a different file name. Leave empty to use the preset name.
@export var custom_path_name: String
##Abort the load when the saved session was still open.
##Mainly used to prevent cheating by force-closing the game without saving.
@export var fail_on_session_open: bool = true


var save_data: Array[Array] #[var_string,var_type]
var save_nodes: Array[Object]
var session: SESSION = SESSION.CLOSED


##Setup called by the FileManager.
func _setup(origin: Object) -> RESPONSE:
	if !is_instance_valid(origin):
		push_error("origin ", origin, " is not valid.")
		return RESPONSE.ORIGIN_NOT_FOUND
	for var_string: String in properties:
		if not var_string in origin:
			push_error("could not connect variable ", var_string, " from object ",origin)
			return RESPONSE.VAR_NOT_FOUND
		var the_var = origin.get(var_string)
		save_data.append( [ var_string, typeof(the_var) ] )
		save_nodes.append(origin)
	
	return RESPONSE.OK


##Save called by the FileManager. Returns the property data from connected objects as a compressed string.
func SAVE() -> String:
	var save_array: Array[Array] #holds [var_name, var_value, var_type]
	for node in save_nodes:
		if !is_instance_valid(node):
			push_error("origin ", node, " is not valid.")
			return ""
		for sub_array in save_data:
			if not sub_array[0] in node:
				push_error("could not retrieve variable ", sub_array[0], " from object ",node)
				return ""
			save_array.append([
				sub_array[0],
				node.get(sub_array[0]),
				sub_array[1]]
			)
	var compressed_data: String = _compress(save_array)
	return compressed_data
	
	
##Called by the FileManager. Handles the saved session and decompressed the data.
##Then loads the properties back into the connected Objects.
func LOAD(load_data: Array, force_load: bool) -> RESPONSE:
	session = load_data[1] as SESSION
	if session == SESSION.LOCKED and not force_load:
		return RESPONSE.LOAD_FAILED
	elif session == SESSION.OPEN and fail_on_session_open and not force_load:
		return RESPONSE.LOAD_FAILED
	var compressed_data: String = load_data[0]
	var load_array: Array[Array] = _decompress(compressed_data)
	for node in save_nodes:
		if !is_instance_valid(node):
			push_error("origin ", node, " is not valid.")
			return RESPONSE.ORIGIN_NOT_FOUND
		for sub_array in load_array:
			if not sub_array[0] in node:
				push_error("could not retrieve variable ", sub_array[0], " from object ", node)
				return RESPONSE.VAR_NOT_FOUND
			var load_var = type_convert(sub_array[1],sub_array[2])
			node.set(sub_array[0],load_var)
	return RESPONSE.OK


func _compress(data: Array[Array]) -> String:
	var raw: PackedByteArray = var_to_bytes(data)
	var raw_compressed: PackedByteArray = raw.compress(FileAccess.CompressionMode.COMPRESSION_GZIP)
	var base64: String = Marshalls.raw_to_base64(raw_compressed)
	return base64
	
	
func _decompress(compressed_data: String) -> Array[Array]:
	var raw_compressed: PackedByteArray = Marshalls.base64_to_raw(compressed_data)
	var raw: PackedByteArray = raw_compressed.decompress_dynamic(-1,FileAccess.CompressionMode.COMPRESSION_GZIP)
	var load_array: Array[Array] = bytes_to_var(raw)
	return load_array

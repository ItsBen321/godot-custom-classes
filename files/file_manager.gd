##Resource to manage a custom File system, works with [FilePreset].
##
##Best practice is to keep a reference to this in an autoload. Easily setup up flexible FilePresets and plug them in.
##Call [method FileManager.setup] from your objects that need saving/loading. Then simply use [method FileManager.SAVE] and [method FileManager.LOAD] with the preset name.
##You can connect multiple instances with the same variables to a single preset, or set up multiple saves with the same settings.
##Every file gets saved with a session status, call [method FileManager.open_session], [method FileManager.close_session] or [method FileManager.lock_session] before saving.
##Sessions status gets loaded in after calling [method FileManager.LOAD], you can handle things accordingly.
##
##Saving files is done atomically using a temporary file. Should catch any issues that can pop up and prevent crashes.
##Essentially stores a JSON string, holding the name of the preset, compressed data and session info.
##In case of a group, bundles the JSON strings into 1 file and reads from that file.
##[codeblock]
##var manager: FileManager = preload("resource_uid")
##
##func _ready() -> void:
##    manager.setup("game",self)
##    manager.open_session("game")
##    manager.SAVE("game")
##[/codeblock]

extends Files

class_name FileManager

##Name of the folder where everything gets saved. Leave blank to save in "user://".
##(Can be changed by accessing the file_path variable property.)
@export var file_dir: String = "data"
##Custom file extension.
@export var custom_ext: String = "log"
##All FilePresets handled by this FileManager.
@export var presets: Array[FilePreset]:
	set(value):
		presets = value
		_presets_setup()

var file_path: String = "user://"
var all_presets: Dictionary[String, FilePreset]
var groups: Dictionary[String, Array]


##Used to connect a node to a FilePreset.
##[codeblock]FileManager.setup("preset_name",self)[/codeblock]
func setup(preset_name: String, origin: Object) -> RESPONSE:
	if not preset_name in all_presets.keys():
		push_error("preset with name ", preset_name ," not found in FileManager.")
		return RESPONSE.PRESET_NOT_FOUND
	var file_preset: FilePreset = all_presets[preset_name]
	if file_preset == null:
		push_error("preset with name ", preset_name ," returns Null.")
		return RESPONSE.PRESET_INVALID
	var response: RESPONSE = file_preset._setup(origin)
	return response
	

##Save according to the selected preset or group of presets and its connected nodes.
##Typically called right after a session update so it can be used on the next load.
##You can specify a save to create extra copies that are saved independently.
##Leave at 0 for default save.
##[codeblock]
##FileManager.open_session("main")
##FileManager.SAVE("main", 1)
###Writes a file to disk based on the "main" preset with an open session, for save 1.
##[/codeblock]
func SAVE(preset_or_group: String, save: int = 0) -> RESPONSE:
	var save_dict: Dictionary[String,Array]
	var file_name: String
	if preset_or_group in groups.keys():
		file_name = preset_or_group
		for preset: FilePreset in groups[preset_or_group]:
			var save_string: String = preset.SAVE()
			if save_string.is_empty():
				return RESPONSE.SAVE_FAILED
			save_dict[preset.name] = [save_string,preset.session]
	elif preset_or_group in all_presets.keys():
		if !all_presets[preset_or_group].custom_path_name.is_empty():
			file_name = all_presets[preset_or_group].custom_path_name
		else: file_name = preset_or_group
		var save_string: String = all_presets[preset_or_group].SAVE()
		if save_string.is_empty():
			return RESPONSE.SAVE_FAILED
		save_dict[preset_or_group] = [save_string,all_presets[preset_or_group].session]
	else:
		push_error("preset or group with name ", preset_or_group ," not found in FileManager.")
		return RESPONSE.PRESET_NOT_FOUND
	if save != 0: file_name += "_%d" % save
	
	var json_string: String = JSON.stringify(save_dict)
	var dir_path: String = file_path.path_join(file_dir)
	var final_path: String = dir_path.path_join(file_name) + ".%s" % custom_ext
	var temp_path: String = final_path + ".tmp"
	if !DirAccess.dir_exists_absolute(dir_path):
		var dir_error := DirAccess.make_dir_absolute(dir_path)
		if dir_error != OK:
			push_error("could not create new dir: ", dir_error)
			return RESPONSE.SAVE_FAILED
	var temp_save := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_save == null:
		var error := FileAccess.get_open_error()
		push_error("could not initiate temp file: ", error)
		return RESPONSE.SAVE_FAILED
	temp_save.store_string(json_string)
	temp_save.flush()
	temp_save.close()
	var rename_error := DirAccess.rename_absolute(temp_path,final_path)
	if rename_error != OK:
		push_error("could not rename temp file: ", rename_error)
		DirAccess.remove_absolute(temp_path)
		return RESPONSE.SAVE_FAILED
	return RESPONSE.OK
	
	
##Load according to the selected preset or group of presets and its connected nodes.
##Enabling force_load will not respect the saved session (in case of being locked or open).
##You can specify a save to load extra copies that were saved independently.
##Leave at 0 for default load.
func LOAD(preset_or_group: String, save: int = 0, force_load: bool = false) -> RESPONSE:
	var file_name: String
	if preset_or_group in groups.keys():
		file_name = preset_or_group
	elif preset_or_group in all_presets.keys():
		if !all_presets[preset_or_group].custom_path_name.is_empty():
			file_name = all_presets[preset_or_group].custom_path_name
		else: file_name = preset_or_group
	else:
		push_error("preset or group with name ", preset_or_group ," not found in FileManager.")
		return RESPONSE.PRESET_NOT_FOUND
	if save != 0: file_name += "_%d" % save
		
	var dir_path: String = file_path.path_join(file_dir)
	var final_path: String = dir_path.path_join(file_name) + ".%s" % custom_ext
	if !FileAccess.file_exists(final_path):
		push_error("could not find file to load")
		return RESPONSE.LOAD_FAILED
	var load_file := FileAccess.open(final_path,FileAccess.READ)
	if load_file == null:
		var load_error := FileAccess.get_open_error()
		push_error("could not load file: ", load_error)
		return RESPONSE.LOAD_FAILED
	var json_string: String = load_file.get_as_text()
	load_file.close()
	var json := JSON.new()
	var json_error = json.parse(json_string)
	if json_error != OK:
		push_error("could not read file data: ", json.get_error_message())
		return RESPONSE.LOAD_FAILED
	var load_data: Dictionary = json.data
	
	for preset in load_data.keys():
		if not preset in all_presets:
			push_error("preset or group with name ", preset_or_group ," not found in FileManager.")
			return RESPONSE.PRESET_NOT_FOUND
		var response = all_presets[preset].LOAD(load_data[preset], force_load)
		
		if response != RESPONSE.OK:
			return RESPONSE.LOAD_FAILED
		
	return RESPONSE.OK
	
	
##Returns the session of a selected file or group.
func session(preset_or_group: String) -> SESSION:
	if preset_or_group in groups.keys():
		for preset: FilePreset in groups[preset_or_group]:
			return preset.session
	elif preset_or_group in all_presets.keys():
		return all_presets[preset_or_group].session
	else:
		push_error("preset or group with name ", preset_or_group ," not found in FileManager.")
		return SESSION.ERROR
	return SESSION.ERROR


##Opens the session of a selected file or group.
##Primarily done while data is being actively used and updated.
func open_session(preset_or_group: String) -> RESPONSE:
	if preset_or_group in groups.keys():
		for preset: FilePreset in groups[preset_or_group]:
			if preset.session == SESSION.OPEN:
				push_warning("session already open for ", preset.name)
				continue
			preset.session = SESSION.OPEN
	elif preset_or_group in all_presets.keys():
		if all_presets[preset_or_group].session == SESSION.OPEN:
			push_warning("session already open for ", preset_or_group)
			return RESPONSE.SESSION_ALREADY_OPEN
		all_presets[preset_or_group].session = SESSION.OPEN
	else:
		push_error("preset or group with name ", preset_or_group ," not found in FileManager.")
		return RESPONSE.PRESET_NOT_FOUND
	return RESPONSE.OK
	
	
##Closes the session of a selected file or group.
##Primarily done while data is no longer being used and updated.
func close_session(preset_or_group: String) -> RESPONSE:
	if preset_or_group in groups.keys():
		for preset: FilePreset in groups[preset_or_group]:
			if preset.session == SESSION.CLOSED:
				push_warning("session already closed for ", preset.name)
				continue
			preset.session = SESSION.CLOSED
	elif preset_or_group in all_presets.keys():
		if all_presets[preset_or_group].session == SESSION.CLOSED:
			push_warning("session already open for ", preset_or_group)
			return RESPONSE.SESSION_ALREADY_CLOSED
		all_presets[preset_or_group].session = SESSION.CLOSED
	else:
		push_error("preset or group with name ", preset_or_group ," not found in FileManager.")
		return RESPONSE.PRESET_NOT_FOUND
	return RESPONSE.OK
	
	
##Locks the session of a selected file or group.
##Primarily done while data should no longer be loaded in anymore.
func lock_session(preset_or_group: String) -> RESPONSE:
	if preset_or_group in groups.keys():
		for preset: FilePreset in groups[preset_or_group]:
			if preset.session == SESSION.LOCKED:
				push_warning("session already locked for ", preset.name)
				continue
			preset.session = SESSION.LOCKED
	elif preset_or_group in all_presets.keys():
		if all_presets[preset_or_group].session == SESSION.LOCKED:
			push_warning("session already locked for ", preset_or_group)
			return RESPONSE.SESSION_ALREADY_LOCKED
		all_presets[preset_or_group].session = SESSION.LOCKED
	else:
		push_error("preset or group with name ", preset_or_group ," not found in FileManager.")
		return RESPONSE.PRESET_NOT_FOUND
	return RESPONSE.OK
	
	
func _presets_setup() -> void:
	for preset in presets:
		all_presets[preset.name] = preset
		if preset.in_group and !preset.group_name.is_empty():
			if not preset.group_name in groups.keys():
				groups[preset.group_name] = [preset]
			else: groups[preset.group_name].append(preset)

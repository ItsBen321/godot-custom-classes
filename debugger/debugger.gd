##Custom debugger to log any sort of data, stats or text you want. Has simple instructions
##to get, find, save and load data. Can be created as a custom resource or instantiated at runtime!
##
##To access from anywhere it's recommended to either create a Debugger autoload or instantiate one
##in an existing autoload file. From there you can call add_line() with any info you want.
##It's possible to put everything in a single Debugger or create multiple custom ones with
##different utilities. There is no set format or limit for what you can store, except the log number and
##optional timestamp as index 0 and 1 on the Array. Added logs send a [code]log_added[/code] signal.
##There is a normal debug_log with all the variables, and a text-converted string_log.
##Below is an example of how to set up a Debugger.
##
##@tutorial(Short overview): https://youtu.be/3JpCy9vs880
##[codeblock]
##var DB: Debugger = Debugger.new()
##
##func _ready() -> void:
##	DB.max_lines = 2000
##	DB.print_lines = true
##	DB.string_log_separation_length = 3
##	DB.save_path = "C:/Users/Me"
##[/codeblock]
##Some useful functions include:
##[codeblock]
##DB.add_line(name, age, height) #adds a line to the log
##var indices: PackedInt32Array = DB.find_lines("Bob") #finds the index of all lines containing that Variant
##var first_Bob: Array = DB.get_line(indices[0]) #returns the line at index number
##DB.save_debug_log() #saves the log to a *.txt file at specified location, can also save as *.csv

extends Resource

class_name Debugger

##Emits both the normal log_array and the log_string when a new line gets added.
signal log_added(log_array: Array, log_string: String)

var debug_log: Array = []
var string_log: PackedStringArray = []
##Total amount of lines added to the debug_log, will overflow past the max_lines.
var total_lines: int = 1
var can_update: bool = true

@export var max_lines: int = 1000
##If true, will print every new entry to the terminal.
@export var print_lines: bool = false
@export var string_log_separator: String = "|"
@export var string_log_separation_length: int = 1
@export var include_timestamp: bool = true
@export_global_dir var save_path: String = ""

##Allows the Debugger to process inputs. Is on by default.
func start():
	can_update = true

##Stops the Debugger from processing inputs.
func stop():
	can_update = false

##Returns the line in the debug_log at the specified index.
func get_line(index: int = -1) -> Array:
	if index < debug_log.size():
		return debug_log[index]
	push_error("requested line ",index," not in log of size ",debug_log.size())
	return []

##Returns the line in the string_log at the specified index.
func get_string_line(index: int = -1) -> String:
	if index < string_log.size():
		return string_log[index]
	push_error("requested line ",index," not in string_log of size ",string_log.size())
	return ""

##Returns the size of the debug_log.
func size() -> int:
	return debug_log.size()

##Find every line index in the debug_log for the specified Variant.
func find_lines(looking_for: Variant) -> PackedInt32Array:
	var indices: PackedInt32Array = []
	for line_number in debug_log.size():
		if looking_for in debug_log[line_number]:
			indices.append(line_number)
	return indices

##Add a line to the Debugger. Can consist of any variables you want, adds an entry to both
##the normal debug_log as well as the string_log. Trims the oldest entries when exceeding
##the max_lines.
func add_line(...line_array: Array):
	if !can_update:
		return
	
	var prefix_array: Array = [total_lines]
	if include_timestamp: prefix_array.append(Time.get_datetime_string_from_system(false, true))
	var full_array: Array = prefix_array + line_array
	
	var full_text_array: PackedStringArray = PackedStringArray(full_array)
	var separator: String = ""
	var whitespace: String = " ".repeat(string_log_separation_length)
	separator = whitespace + string_log_separator + whitespace
	var full_string: String = separator.join(full_text_array)
	
	total_lines += 1
	if print_lines: print(full_string)
	log_added.emit(full_array, full_string)
	
	debug_log.append(full_array)
	string_log.append(full_string)
	while debug_log.size() > max_lines:
		debug_log.remove_at(0)
	while string_log.size() > max_lines:
		string_log.remove_at(0)
		string_log.remove_at(0)
		string_log.remove_at(0)


##Saves the full log to a text file. Make sure you have a valid path set at Debugger.save_path.
##File name will automatically include Project name, timestamp and the *.txt extention.
##You can disable timestamp to overwrite the same log every time, unless you dynamically change
##the save_path.
func save_debug_log(add_timestamp_to_path: bool = true) -> Error:
	var new_save_path: String = "%s/%s_Log" % [save_path,ProjectSettings.get_setting("application/config/name")]
	if add_timestamp_to_path: new_save_path = "%s_%s" % [
		new_save_path,Time.get_datetime_string_from_system(false,true).replace(":","-")]
	print(new_save_path)
	var file := FileAccess.open("%s.txt" % new_save_path,FileAccess.WRITE)
	
	if file == null:
		var error_message := FileAccess.get_open_error()
		push_error("Could not save the debug log: ",error_message)
		return ERR_CANT_OPEN
	
	for text_line in string_log:
		file.seek_end()
		file.store_line(text_line)
		
	file.close()
	return OK

##Saves the full log to a csv file. Make sure you have a valid path set at Debugger.save_path.
##File name will automatically include Project name, timestamp and the *.csv extention.
##You can disable timestamp to overwrite the same log every time, unless you dynamically change
##the save_path.
func save_debug_log_csv(add_timestamp_to_path: bool = true, delimiter: String = ",") -> Error:
	var new_save_path: String = "%s/%s_Log" % [save_path,ProjectSettings.get_setting("application/config/name")]
	if add_timestamp_to_path: new_save_path = "%s_%s" % [
		new_save_path,Time.get_datetime_string_from_system(false,true).replace(":","-")]
	var file := FileAccess.open("%s.csv" % new_save_path,FileAccess.WRITE)
	
	if file == null:
		var error_message := FileAccess.get_open_error()
		push_error("Could not save the debug log: ",error_message)
		return ERR_CANT_OPEN
	
	for line in debug_log:
		var string_line: PackedStringArray = PackedStringArray(line)
		file.seek_end() 
		file.store_csv_line(string_line,delimiter)
		
	file.close()
	return OK

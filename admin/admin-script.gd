## Simple helper class for logging and debugging
##
## Create a new script that extends *Admin*, then add it as an autoload. This will automatically
## instantiate and set up your admin window when running in the editor.
## Connect to the *admin_message* signal to wire any logs and text into the display window.
## This class is meant to be changed for every project. Write custom functions
## in your *Admin* autoload to create buttons.
## There is no need to interact with the admin-window.tscn scene.
## It is recommended to turn off Project Settings > Display > Window > Embed Subwindows.
##
## @tutorial(Short overview): https://youtu.be/UBlf3dE3sQ8
extends Node
class_name Admin

const ADMIN_WINDOW = preload("uid://c172pjqj7c68t")
var admin_window: Window

signal admin_message(text: String)

func _ready() -> void:
	if not OS.has_feature("editor"):
		return
	var method_names: Array[StringName] = []
	for method_info: Dictionary in get_script().get_script_method_list():
		var method_name: StringName = method_info.get("name", &"")
		if method_name != &"":
			method_names.append(method_name)
	method_names.erase(&"_ready")
	method_names.erase(&"_message_received")
	admin_window = ADMIN_WINDOW.instantiate()
	get_tree().root.add_child.call_deferred(admin_window)
	await admin_window.ready
	for method: StringName in method_names:
		var new_button := Button.new()
		new_button.text = str(method)
		new_button.pressed.connect(Callable(self,method))
		admin_window.get_child(0).get_child(0).get_child(0).add_child(new_button) # adding button to vbox in splitcontainer
	admin_message.connect(_message_received)


func _message_received(text: String):
	var code_edit: CodeEdit = admin_window.get_child(0).get_child(0).get_child(1)
	if not code_edit.text.ends_with("\n") and not code_edit.text.is_empty():
		code_edit.text += "\n"
	code_edit.text += text

	var last_line: int = max(code_edit.get_line_count() - 1, 0)
	code_edit.set_caret_line(last_line)
	code_edit.set_caret_column(code_edit.get_line(last_line).length())

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

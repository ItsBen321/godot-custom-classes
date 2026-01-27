##Abstract Class, can't instantiate.
##
##Used for debugging and understanding complex Dictionaries / Arrays.
##Simply call [code]Deconstruct.go(my_var)[/code] in your script at runtime, output is in the terminal.
##Or get a visual popup window by calling [code]Deconstruct.go(my_var, get_tree())[/code] in your script.
##Better result if embedded subwindows is turned off in Project Settings.
##
##@tutorial(Short overview): https://youtu.be/l1Eq7W2A0IA
@abstract
class_name Deconstruct

static var offset: int = -1
static var popup: bool = false
static var window: Window

##Currently accepts Array and Dictionary. Use the Layers argument to specify how deep the deconstruct goes.
##This is simply to minimize the output when things are very nested.
static func go(input: Variant, layers: int = 10):
	popup = false
	var the_type: int = _check_array(input)
	match the_type:
		TYPE_DICTIONARY:
			_init_deconstruct()
			_deconstruct_dict(input, layers+1)
			print_rich("[hr]")
		TYPE_ARRAY:
			_init_deconstruct()
			_deconstruct_array(input, layers+1)
			print_rich("[hr]")
		_:
			push_error("Cannot deconstruct ",input," of type ",type_string(typeof(input)))

##Creates a Popup window with nested Labels and FoldableContainers to represent the input Variable.
##Currently accepts Array and Dictionary. Use the Layers argument to specify how deep the deconstruct goes.
##This is simply to minimize the output when things are very nested.
##Needs get_tree() as argument to instantiate the window.
static func go_popup(input: Variant, tree: SceneTree, layers: int = 10):
	popup = true
	var root: Window = tree.root
	var the_type: int = _check_array(input)
	match the_type:
		TYPE_DICTIONARY:
			var parent: Node = _init_popup_deconstruct(root)
			_deconstruct_dict(input, layers+1, parent)
			print_rich("[hr]")
		TYPE_ARRAY:
			var parent: Node = _init_popup_deconstruct(root)
			_deconstruct_array(input, layers+1, parent)
			print_rich("[hr]")
		_:
			push_error("Cannot deconstruct ",input," of type ",type_string(typeof(input)))

static func _init_popup_deconstruct(root: Window) -> VBoxContainer:
	offset = -1
	window = Window.new()
	window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	window.size = Vector2i(400,600)
	window.title = "Deconstruct"
	window.close_requested.connect(func(): window.queue_free())
	
	var scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	window.add_child(scroll_container)
	var vbox: VBoxContainer = _add_vbox(scroll_container)
	
	root.add_child.call_deferred(window)
	return vbox

static func _add_vbox(parent: Node) -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(vbox)
	return vbox

static func _add_foldable(parent: Node, title: String) -> FoldableContainer:
	var foldable: FoldableContainer = FoldableContainer.new()
	foldable.fold()
	foldable.title = title
	parent.add_child(foldable)
	return foldable

static func _add_label(parent: Node, text: String):
	var label: Label = Label.new()
	label.text = text
	parent.add_child(label)

static func _init_deconstruct():
	offset = -1
	print_rich("[hr]")
	print_rich("[color=SKY_BLUE]■ : Dictionary Key[/color]")
	print_rich("[color=GREEN_YELLOW]■ : Array Value[/color]")
	print_rich("[color=CORNSILK]■ : Dictionary Value[/color]")
	print_rich("[hr]")

static func _deconstruct_dict(dict, layers, parent: Node = null):
	if layers <= 0: return
	offset += 1
	layers -= 1
	
	for item in dict.keys():
		var the_type: int = _check_array(dict[item])
		match the_type:
			TYPE_DICTIONARY:
				var new_parent: Node = null
				if popup:
					new_parent = _add_foldable(parent, "Dict: %s (%s)" % [str(item),type_string(typeof(item))])
					new_parent = _add_vbox(new_parent)
				else:
					print_rich("[color=SKY_BLUE]%s﹂▶ [b]%s[/b] (%s)[/color]"%["\t".repeat(offset),str(item),type_string(typeof(item))])
				_deconstruct_dict(dict[item], layers, new_parent)
			TYPE_ARRAY:
				var new_parent: Node = null
				if popup:
					new_parent = _add_foldable(parent, "Array: %s (%s)" % [str(item),type_string(typeof(item))])
					new_parent = _add_vbox(new_parent)
				else:
					print_rich("[color=SKY_BLUE]%s﹂▶ [b]%s[/b] (%s)[/color]"%["\t".repeat(offset),str(item),type_string(typeof(item))])
				_deconstruct_array(dict[item], layers, new_parent)
			_:
				if layers <= 0: continue
				if popup:
					_add_label(parent,("%s (%s) : "%[str(item),type_string(typeof(item))] +
						"%s (%s)"%[str(dict[item]),type_string(typeof(dict[item]))]))
				else:
					print_rich("[color=SKY_BLUE]%s﹂▶ [b]%s[/b] (%s) : [/color]"%["\t".repeat(offset),str(item),type_string(typeof(item))] +
						"[color=CORNSILK][i]%s[/i] (%s)[/color]"%[str(dict[item]),type_string(typeof(dict[item]))])
	offset -= 1
	layers += 1

static func _deconstruct_array(array, layers, parent: Node = null):
	if layers <= 0: return
	offset += 1
	layers -= 1
	
	for item in array:
		var the_type: int = _check_array(item)
		match the_type:
			TYPE_DICTIONARY:
				var new_parent: Node = null
				if popup:
					new_parent = _add_foldable(parent, "Dict in Array")
					new_parent = _add_vbox(new_parent)
				_deconstruct_dict(item, layers, new_parent)
			TYPE_ARRAY:
				var new_parent: Node = null
				if popup:
					new_parent = _add_foldable(parent, "Array in Array")
					new_parent = _add_vbox(new_parent)
				_deconstruct_array(item, layers, new_parent)
			_:
				if layers <= 0: continue
				if popup:
					_add_label(parent,"%s (%s)"%[str(item),type_string(typeof(item))])
				else:
					print_rich("[color=GREEN_YELLOW]%s﹂▶ [i]%s[/i] (%s)[/color]"%["\t".repeat(offset),str(item),type_string(typeof(item))])
	offset -= 1
	layers += 1

static func _check_array(type: Variant) -> int:
	if typeof(type) in [TYPE_ARRAY,TYPE_PACKED_BYTE_ARRAY,TYPE_PACKED_COLOR_ARRAY,
	TYPE_PACKED_INT32_ARRAY,TYPE_PACKED_INT64_ARRAY,TYPE_PACKED_STRING_ARRAY,
	TYPE_PACKED_FLOAT32_ARRAY,TYPE_PACKED_FLOAT64_ARRAY,TYPE_PACKED_VECTOR2_ARRAY,
	TYPE_PACKED_VECTOR3_ARRAY,TYPE_PACKED_VECTOR4_ARRAY]:
		return TYPE_ARRAY
	return typeof(type)

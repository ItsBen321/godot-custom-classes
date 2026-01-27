##Simple way to turn a RichTextLabel into a Dialogue box,
##introducing some handy functions and signals.
##
##Easy to use RichTextEdit made to process dialogue.
##
##Create a Dialogue box, design it and sets its properties. Then you can load in
##any text you want or store a text buffer. Using the [code]update[/code] and
##[code]end[/code] signals you can monitor its behavior and add extra functionality.
##Supports formatting and custom Callables!
##
##@tutorial(Short overview): https://youtu.be/SkvXWE56ngQ

extends RichTextLabel

class_name Dialogue

##Emits an update whenever the [code]error_code[/code] gets updated. Relevant if you need to track
##the status of the dialogue text.
signal update(code: error_code)
##Emits when the end of the dialogue buffer is reached. Can be used to close the Dialogue box.
signal end

##Possible error codes while processing dialogue text.
enum error_code {
	DONE, ##Full dialogue cycle finished.
	IN_ANIMATION, ##Currently in an animation cycle for the dialogue text.
	START, ##Starting the dialogue cycle.
	ERROR, ##Something went wrong.
	END ##End of dialogue buffer is reached
}

var current_code: error_code:
	set(value):
		current_code = value
		update.emit(current_code)
		if current_code == error_code.END:
			end.emit()

##Can take any Dictionary to format the Dialogue strings.
var format_dictionary: Dictionary = {}

##By defaults tries to execute custom callables on itself, but can be directed to
##a different Node to handle the callables. Allows for more flexibility.
var custom_callables_target: Node = self

##Array of text that gets loaded into the Dialogue. Use func [code]Buffer(new_dialogue_buffer)[/code]
##instead of accessing this directly (unless you need to read data from it).
var dialogue_buffer: PackedStringArray = []

@export var animated_text: bool = false
@export_range(0.1,3.0,0.1,"or_greater") var animation_speed: float = 0.5
##Should the next dialogue text wait for the current animation to finish.
@export var await_animation: bool = false
##When a line of Dialogue starts with this Prefix, it'll instead try to execute the following Callable.
##Use this Prefix twice in order to also jump to the next line of Dialogue.
##[codeblock]
##var my_text: PackedStringArray = ["one","//call_me","two","////call_me","three"]
##func call_me():
##	print("called")
##Buffer(my_text)
##
##Next() #Displays "one"
##Next() #Prints "called"
##Next() #Displays "two"
##Next() #Prints "called" and Displays "three"
##[/codeblock]
@export var custom_callable: String = "//"

##Pass in a string of text to display in the Dialogue.
##[codeblock]
##Display("Hello World")
###Loads "Hello World" in the Dialogue using the current settings.
##[/codeblock]
func Display(new_dialogue_text: String) -> error_code:
	if await_animation and current_code == error_code.IN_ANIMATION:
		return current_code
	
	if new_dialogue_text.left(custom_callable.length()*2) == custom_callable + custom_callable:
		var callable_string: String = new_dialogue_text.lstrip(custom_callable + custom_callable)
		if custom_callables_target.has_method(callable_string):
			custom_callables_target.call(callable_string)
			call_deferred("Next")
			return current_code
		call_deferred("Next")
		push_error("Callable ",callable_string, " not found in ", custom_callables_target)
		return error_code.ERROR
	
	elif new_dialogue_text.left(custom_callable.length()) == custom_callable:
		var callable_string: String = new_dialogue_text.lstrip(custom_callable)
		if custom_callables_target.has_method(callable_string):
			custom_callables_target.call(callable_string)
			return current_code
		push_error("Callable ",callable_string, " not found in ", custom_callables_target)
		return error_code.ERROR
	
	clear()
	current_code = error_code.START
	new_dialogue_text.format(format_dictionary)
	
	if !animated_text:
		text = new_dialogue_text
	else:
		visible_ratio = 0.0
		text = new_dialogue_text
		current_code = error_code.IN_ANIMATION
		for characters_progress in 101:
			visible_ratio = float(characters_progress)/100
			await get_tree().create_timer(animation_speed/100,false).timeout
	
	current_code = error_code.DONE
	return current_code

##Loads in a buffer of text for the Dialogue, gets triggered using Next().
##Accepts PackedStringArray, Array, String. A normal String gets separated by every new line.
##Can choose to override the existing buffer or append to it.
##[codeblock]
##var new_buffer: PackedStringArray = ["Hello world!","How are you?"]
##var new_buffer: Array = ["Hello world!","How are you?"]
##var new_buffer: String = "Hello world!\nHow are you?"
##
##Buffer(new_buffer)
##[/codeblock]
func Buffer(new_dialogue_buffer: Variant, append_to_existing: bool = true) -> error_code:
	if !append_to_existing: dialogue_buffer.clear()
	match typeof(new_dialogue_buffer):
		
		TYPE_PACKED_STRING_ARRAY:
			dialogue_buffer += new_dialogue_buffer.duplicate()
		
		TYPE_ARRAY:
			for item in new_dialogue_buffer:
				dialogue_buffer.append(str(item))
		
		TYPE_STRING:
			var split_buffer: PackedStringArray = new_dialogue_buffer.split("\n",false)
			dialogue_buffer += split_buffer
		
		_: 
			push_error("No valid variable gives for the dialogue buffer. Recieved: ",
				type_string(typeof(new_dialogue_buffer)),": ",new_dialogue_buffer)
			return error_code.ERROR
		
	return error_code.DONE

##Displays the next line of dialogue in the buffer.
func Next() -> error_code:
	if await_animation and current_code == error_code.IN_ANIMATION:
		return current_code
	if dialogue_buffer.is_empty():
		current_code = error_code.END
		return current_code
	
	var next_dialogue_string: String = dialogue_buffer[0]
	dialogue_buffer.remove_at(0)
	Display(next_dialogue_string)
		
	return error_code.DONE

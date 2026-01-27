@abstract

## The simplest way to add custom animations.
##
## Create a custom animation and give it a proper [code]class_name[/code] (for example [code]Wobble[/code]).
## Just write a [method TweenAnimation.play] function using the template with Tweens.
##
## [codeblock]
###Play a simple animation on node.
##Wobble.new(self)
##
###Use its timing.
##await Wobble.new(my_node).finished
##
###Set its custom variables.
##Wobble.new(my_name, {
##    "time": 1.0,
##    "scale": Vector2(1.2,1.2)
##} )
##[/codeblock]

extends RefCounted

class_name TweenAnimation

## Emitted when the animation has finished
signal finished

func _init(animation_node: Node, options: Dictionary = {}) -> void:
	for option in options.keys():
		if !get(StringName(option)):
			push_warning("property \"%s\" was not found in animation [ %s | %s ]" % [option, get_script().get_global_name(), self])
			continue
		set(StringName(option), options[option])
	_init_play(animation_node)

func _init_play(animation_node):
	await play(animation_node)
	finished.emit()

@abstract
func play(node: Node)

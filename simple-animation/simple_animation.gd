@tool
extends Node

##Add this node to any object you want to animate!
##
##Has default templates and simple settings.
##Can test the animations in the editor. Just emit the set outro signal on parent node for the outro.
##In theory doesn't need any reference in your scripts, unless you want to call things manually.
##You can also sonnect the custom_callable signal to set up a custom animation.
##
##@tutorial(Short Overview): https://youtu.be/zw1sAL_B5Rc
class_name SimpleAnimation

enum ANIMATION {
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	ZOOM_IN,
	ZOOM_OUT,
	FADE,
	CUSTOM
}

##Called when the animation is finished.
signal finished

##Called when trying to play a custom animation. Takes a bool as argument: intro = true / false.
signal custom_animation

var parent: Node

##Play animation as soon as object is instantiated.
@export var play_on_instantiate: bool = true
##Play animation as soon as this signal is emitted by parent node. Leave empty to not connect.
@export var play_outro_signal: StringName = "outro"
##Call queue_free() after the animation finished.
@export var remove_after_outro: bool = true
##Selected animation for the intro.
@export var intro_animation: ANIMATION = ANIMATION.FADE
##Selected animation for the outro.
@export var outro_animation: ANIMATION = ANIMATION.FADE
@export_group("extra properties")
##Duration of the animation in seconds.
@export_range(0.1,3.0,0.05,"or_greater") var duration: float = 1.0
##Scale of the zoom animations.
@export_range(0.01,0.4,0.01,"or_greater") var zoom: float = 0.1
##Global distance of the slide animations.
@export_range(1,100,1,"or_greater") var distance: float = 10.0
@export_subgroup("intro")
@export var animation_easing_intro: Tween.EaseType = Tween.EaseType.EASE_IN_OUT
@export var animation_transition_intro: Tween.TransitionType = Tween.TransitionType.TRANS_SINE
@export_subgroup("outro")
@export var animation_easing_outro: Tween.EaseType = Tween.EaseType.EASE_IN_OUT
@export var animation_transition_outro: Tween.TransitionType = Tween.TransitionType.TRANS_SINE
@export_group("test")
@export_tool_button("Test Intro","Play") var test_intro = play
@export_tool_button("Test Outro","Play") var test_outro = play.bind(false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint(): return
	_get_parent()
	
	if play_on_instantiate:
		play(true)

func _get_parent():
	if parent: return
	if !is_instance_valid(get_parent()):
		push_error("Animation node ", self," could not find a valid parent node.")
		return
	parent = get_parent()
	if play_outro_signal.is_empty(): return
	if not parent.has_signal(play_outro_signal):
		push_warning("Animation node ", self," could not find signal [",play_outro_signal, "] in parent node ", parent)
		return
	parent.connect(play_outro_signal,play.bind(false))
	

##Gets automatically called, but can also get called manually.
func play(intro: bool = true) -> void:
	if Engine.is_editor_hint():
		notify_property_list_changed()
		_get_parent()
	
	var original_position: Vector2 = parent.global_position
	var original_modulate: Color = parent.modulate
	var original_scale: Vector2 = parent.scale
	var the_animation: ANIMATION
	if intro: the_animation = intro_animation
	else: the_animation = outro_animation
	
	match the_animation:
		ANIMATION.SLIDE_LEFT: _play_left(intro)
		ANIMATION.SLIDE_RIGHT: _play_right(intro)
		ANIMATION.SLIDE_UP: _play_up(intro)
		ANIMATION.SLIDE_DOWN: _play_down(intro)
		ANIMATION.ZOOM_IN: _play_zoom_in(intro)
		ANIMATION.ZOOM_OUT: _play_zoom_out(intro)
		ANIMATION.CUSTOM: custom_animation.emit(intro)
	if the_animation != ANIMATION.CUSTOM:
		await _play_fade(intro)
		
	if Engine.is_editor_hint() and not intro:
		parent.global_position = original_position
		parent.modulate = original_modulate
		parent.scale = original_scale
		return
		
	finished.emit(intro)
	if not intro and remove_after_outro:
		parent.queue_free()


func _play_fade(intro: bool) -> void:
	if intro:
		var original_modulate: Color = parent.modulate
		parent.modulate = Color.TRANSPARENT
		var tween := create_tween()
		tween.tween_property(parent, "modulate", original_modulate,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished
	else:
		var tween := create_tween()
		tween.tween_property(parent, "modulate", Color.TRANSPARENT,duration).set_ease(animation_easing_outro).set_trans(animation_transition_outro)
		await tween.finished

func _play_left(intro: bool) -> void:
	if intro:
		var original_position: Vector2 = parent.global_position
		parent.global_position.x += distance
		var tween := create_tween()
		tween.tween_property(parent, "global_position", original_position,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished
	else:
		var final_position: Vector2 = parent.global_position
		final_position.x -= distance
		var tween := create_tween()
		tween.tween_property(parent, "global_position", final_position,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished

func _play_right(intro: bool) -> void:
	if intro:
		var original_position: Vector2 = parent.global_position
		parent.global_position.x -= distance
		var tween := create_tween()
		tween.tween_property(parent, "global_position", original_position,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished
	else:
		var final_position: Vector2 = parent.global_position
		final_position.x += distance
		var tween := create_tween()
		tween.tween_property(parent, "global_position", final_position,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished
		
func _play_up(intro: bool) -> void:
	if intro:
		var original_position: Vector2 = parent.global_position
		parent.global_position.y += distance
		var tween := create_tween()
		tween.tween_property(parent, "global_position", original_position,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished
	else:
		var final_position: Vector2 = parent.global_position
		final_position.y -= distance
		var tween := create_tween()
		tween.tween_property(parent, "global_position", final_position,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished
		
func _play_down(intro: bool) -> void:
	if intro:
		var original_position: Vector2 = parent.global_position
		parent.global_position.y -= distance
		var tween := create_tween()
		tween.tween_property(parent, "global_position", original_position,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished
	else:
		var final_position: Vector2 = parent.global_position
		final_position.y += distance
		var tween := create_tween()
		tween.tween_property(parent, "global_position", final_position,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished

func _play_zoom_in(intro: bool) -> void:
	if intro:
		var original_scale: Vector2 = parent.scale
		parent.scale -= Vector2(zoom,zoom)
		var tween := create_tween()
		tween.tween_property(parent, "scale", original_scale,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished
	else:
		var final_scale: Vector2 = parent.scale
		final_scale += Vector2(zoom,zoom)
		var tween := create_tween()
		tween.tween_property(parent, "scale", final_scale,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished
		
func _play_zoom_out(intro: bool) -> void:
	if intro:
		var original_scale: Vector2 = parent.scale
		parent.scale += Vector2(zoom,zoom)
		var tween := create_tween()
		tween.tween_property(parent, "scale", original_scale,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished
	else:
		var final_scale: Vector2 = parent.scale
		final_scale -= Vector2(zoom,zoom)
		var tween := create_tween()
		tween.tween_property(parent, "scale", final_scale,duration).set_ease(animation_easing_intro).set_trans(animation_transition_intro)
		await tween.finished

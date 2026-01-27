##Nodes that function as a data container for a [PackedScene] to create a structure with [SceneManager].
##
##Don't require any code, signals or instantiating. Simply put these in the right spots as children of a [SceneManager].
##The name of this name is treated as its scene name, and is what's referenced by the [method SceneManager.switch] method.
##Children of this node can't be open at the same time, they will be switched between.
##Always opens its parents first before opening its own scene, respects the tree structure.
##Can be initiated on startup, or when first called. Also offers to get hidden instead of freed.
##Option to define and call custom methods when scene is switched to and switched away from.

extends Scenes

class_name SceneNode

##The packed scene that you're instantiating on the parent.
@export var scene: PackedScene
##Instantiate this scene right away and hide it until called.
@export var init_on_startup: bool = false
##How this scene is entered and exited. Custom doesn't perform an action and relies on setting your own exit method.
@export var display_type: DISPLAY = DISPLAY.INIT_FREE
@export_group("extra")
##Method on the PackedScene that gets triggered when this scene is loaded.
@export var start_method: String = "start"
##Method on the PackedScene that gets triggered when this scene is removed.
@export var exit_method: String = "exit"

var TYPE := MAIN_SCENE
var parent: Node
var manager: SceneManager:
	set(value):
		manager = value
		_setup()
var scene_object: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not scene: return
	if not scene.can_instantiate():
		push_error("can not instantiate scene ", scene)
		queue_free()
	
	
func _setup() -> void:
	parent = get_parent()
	if not init_on_startup: return
	if parent == manager:
		scene_object = scene.instantiate()
		parent.main_node.add_child.call_deferred(scene_object)
		scene_object.hide()
	if parent is SceneNode and is_instance_valid(parent.scene_object):
		scene_object = scene.instantiate()
		parent.scene_object.add_child.call_deferred(scene_object)
		scene_object.hide()
	
	
func start() -> void:
	if display_type in [DISPLAY.INIT_FREE,DISPLAY.INIT_CUSTOM]:
		if is_instance_valid(scene_object): scene_object.queue_free()
		scene_object = scene.instantiate()
		if TYPE == MAIN_SCENE: manager.main_node.add_child(scene_object)
		else: parent.scene_object.add_child(scene_object)
	elif display_type in [DISPLAY.SHOW_HIDE,DISPLAY.SHOW_CUSTOM]:
		if not is_instance_valid(scene_object):
			scene_object = scene.instantiate()
			if MAIN_SCENE: manager.main_node.add_child(scene_object)
			else: parent.scene_object.add_child(scene_object)
		scene_object.set_process(true)
		scene_object.set_process_input(true)
		scene_object.set_physics_process(true)
		scene_object.show()
	manager.active_scene = self
	if not start_method.is_empty() and scene_object.has_method(start_method):
		scene_object.call(start_method)
	
	
func exit() -> void:
	if not exit_method.is_empty() and scene_object.has_method(exit_method):
		scene_object.call(exit_method)
	if display_type == DISPLAY.INIT_FREE:
		if is_instance_valid(scene_object):
			if TYPE == MAIN_SCENE: manager.main_node.remove_child(scene_object)
			else: parent.scene_object.remove_child(scene_object)
			scene_object.queue_free()
	elif display_type == DISPLAY.SHOW_HIDE:
		if is_instance_valid(scene_object):
			scene_object.hide()
			scene_object.set_process(false)
			scene_object.set_process_input(false)
			scene_object.set_physics_process(false)

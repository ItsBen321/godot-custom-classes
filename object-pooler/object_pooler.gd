##To prevent the instantiating and removing of scenes at runtime, which can lead to stutters.
##Instead pools them all into a buffer, then dynamically takes and returns the scenes.
##
##Primarily made to pool lots of repetitive scenes (for example: visual effects). Not great at
##storing more complex scenes that need a big *reset*, which is usually done by instantiating
##a new version. But the ObjectPooler does support calling _ready and _exit automatically.
##
##Can be created as a custom resource or instantiated at runtime! When preloading as a custom
##resource, you can set auto_start and an object as PackedScene.
##
##@tutorial(Short overview): https://youtu.be/o_nSrP_DHVk
##[codeblock]
##var MyPool: ObjectPooler = ObjectPooler.new()
##
##func _ready() -> void:
##	MyPool.size = 50
##	MyPool.always_call_ready = true
##	MyPool.start(my_scene)
##	var first_scene: Node = MyPool.take()
##	add_child(first_scene)
##
##func return_scecne():
##	MyPool.put(first_scene)
##	print(MyPool.status())
##[/codeblock]

extends Resource

class_name ObjectPooler

enum error_code {
	INVALID_OBJECT,
	IN_USE,
	CANT_INSTANTIATE,
	DONE
}

var enabled: bool = false
var object_pool: Array[Node] = []

##The PackedScene object used to fill the object_pool.
@export var object: PackedScene = null
##The size of the object_pool.
@export_range(1,100,1) var size: int = 10
##Enable and start filling the pool with instances of the object.
@export var auto_start: bool = false
##Does nothing when trying to take from an empty pool.
@export var disable_when_empty: bool = false
@export_group("Object settings")
##Calls the [code]_ready()[/code] function every time it gets taken from the pool.
@export var always_call_ready: bool = false
##Calls the [code]_exit()[/code] function every time it gets returned to the pool.
@export var always_call_exit: bool = false

func _init() -> void:
	call_deferred("_check_auto_start")

func _check_auto_start():
	if auto_start:
		call_deferred("start")

##Returns the status as a Dictionary. Mainly for troubleshooting.
##[codeblock]
##{"is_active" : bool,
##"has_object" : PackedScene,
##"objects_in_pool": int}
##[/codeblock]
func status() -> Dictionary:
	var status_dict: Dictionary = {
		"is_active:" : enabled,
		"has_object" : object,
		"objects_in_pool" : object_pool.size(),
	}
	return status_dict

##Disables the ObjectPooler and clears its data. Call start(PackedScene) to restart again.
func reset():
	enabled = false
	object_pool.clear()
	object.free()

##Enabled the ObjectPooler and fills its pool with instances of PackedScene.
##When no PackedScene is added in this function, it tries to takes the default object set
##in the inspector (or through code). Returns an error code for troubleshooting.
func start(the_object: PackedScene = object) -> error_code:
	if the_object == null:
		push_error("No valid object (",the_object,") given for ObjectPooler: ",self)
		return error_code.INVALID_OBJECT
	if enabled or !object_pool.is_empty():
		push_error("ObjectPooler: ",self, " - is already in use.")
		return error_code.IN_USE
	if !the_object.can_instantiate():
		push_error("Can't instantiate object (",the_object,") given for ObjectPooler: ",self)
		return error_code.CANT_INSTANTIATE
		
	object = the_object.duplicate()
	for amount in size:
		var new_object := object.instantiate()
		new_object.set_process(false)
		new_object.set_physics_process(false)
		new_object.set_process_input(false)
		object_pool.append(new_object)
	enabled = true
		
	return error_code.DONE

##Returns a scene from the pool. Returns null when an error occurs (or when the pool is empty
##and disable_when_empty is true.). If the pool is empty and disable_when_empty is false,
##instantiate a new scene and return that. Don't forget to [code]add_child()[/code].
func take() -> Node:
	var return_object: Node = null
	if !enabled:
		push_error("ObjectPooler: ",self, " - is not active.")
		return null
	if object_pool.is_empty() and !disable_when_empty:
		return_object = object.instantiate()
	elif object_pool.is_empty() and disable_when_empty:
		return null
	elif !object_pool.is_empty():
		return_object = object_pool.pop_back()
	if !is_instance_valid(return_object):
		push_error("Returned object (",return_object,") from ObjectPooler (",self,") is not valid.")
		return null
	else:
		return_object.set_process(true)
		return_object.set_physics_process(true)
		return_object.set_process_input(true)
	
	if always_call_ready:
		return_object.request_ready()
	return return_object

##Returns a scene to the pool and removes it as a child. Calls [code]queue_free()[/code] if the
##pool is full.
func put(put_object: Node):
	if !enabled:
		push_error("ObjectPooler: ",self, " - is not active.")
		return
	if !is_instance_valid(put_object):
		push_error("Put object (",put_object,") from ObjectPooler (",self,") is not valid.")
		return
	if always_call_exit and put_object.has_method("_exit"):
		put_object.call("_exit")
	if object_pool.size() >= size:
		put_object.queue_free()
		return
	if is_instance_valid(put_object.get_parent()):
		put_object.get_parent().remove_child(put_object)
	put_object.set_process(false)
	put_object.set_physics_process(false)
	put_object.set_process_input(false)
	object_pool.push_back(put_object)

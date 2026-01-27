##Manages the Scene Tree.
##
##Add this node to your main node on which the scenes need to be instantiated.
##Simply add [SceneNode]s to this node in the desired structure, respects their order.
##Labels the direct child scenes to this as main scenes, and all others as sub scenes.
##
##You can move from anywhere in the tree to any other position by calling [method SceneManager.switch]
##Will always close existing branches in order and open new ones in order.
##Has the option to link other [SceneManager]s so you only need to reference this 1 to switch multiple layers.
##Mainly useful to split up UI from the main scene and background.
##Child scenes will always get instantiated on top on their parent scenes, they won't replace them.
##Connect the scene_switched signal for more utility. Emits both scene name and scene instance.

extends Scenes

class_name SceneManager

##Link other [SceneManager] nodes from this scene, they will all get called when this manager receives a [method SceneManager.switch]
@export var linked_managers: Array[SceneManager]

var active_scene: SceneNode
var main_node: Node
var scene_list: Dictionary[String,SceneNode]

##Emits after a successful [method SceneManager.switch] call. Arguments are (scene_name: String, scene_instance: Node).
signal scene_switched

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_node = get_parent()
	for child in get_children():
		if child is SceneNode:
			scene_list[child.name] = child
			child.TYPE = MAIN_SCENE
			child.manager = self
			_init_sub_scenes(child)
			
func _init_sub_scenes(child: SceneNode) -> void:
	for sub_child in child.get_children():
		if sub_child is SceneNode:
			scene_list[sub_child.name] = sub_child
			sub_child.TYPE = SUB_SCENE
			sub_child.manager = self
			_init_sub_scenes(sub_child)

##Go to a different scene. Will detect if it's a nearby child, parent or different branch completely.
##Will automatically get called on linked [SceneManager]s. Emits [signal SceneManager.scene_switched] when complete.
func switch(scene_name: String) -> void:
	for manager in linked_managers:
		manager.switch(scene_name)
	if not scene_name in scene_list.keys():
		push_error(scene_name, " not found in the SceneManager.")
		return
	var new_scene: SceneNode = scene_list[scene_name]
	var relation: RELATION
	var new_parents: Array[SceneNode] = []
	var old_parents: Array[SceneNode] = []
	if active_scene == null:
		new_parents = _get_parents(new_scene, new_parents)
		new_parents.reverse()
		for parent in new_parents:
			parent.start()
		new_scene.start()
		return
	new_parents = _get_parents(new_scene, new_parents)
	old_parents = _get_parents(active_scene, old_parents)
	if new_scene.TYPE == MAIN_SCENE: relation = RELATION.MAIN
	elif new_scene.TYPE == SUB_SCENE:
		relation = _get_relation(new_parents, old_parents)
		
	match relation:
		RELATION.MAIN:
			if active_scene: active_scene.exit()
			for parent in old_parents:
				parent.exit()
			new_scene.start()
		RELATION.SIBLING:
			if active_scene: active_scene.exit()
			new_scene.start()
		RELATION.PARENT:
			var remove_scenes: Array[SceneNode]
			for parent in old_parents:
				if parent not in new_parents and parent != new_scene:
					remove_scenes.append(parent)
			if active_scene: active_scene.exit()
			for parent in remove_scenes:
				parent.exit()
		RELATION.CHILD:
			var add_scenes: Array[SceneNode]
			for parent in new_parents:
				if parent not in old_parents and parent != active_scene:
					add_scenes.append(parent)
			add_scenes.reverse()
			for parent in add_scenes:
				parent.start()
			new_scene.start()
		RELATION.DISTANT:
			var remove_scenes: Array[SceneNode]
			for parent in old_parents:
				if parent not in new_parents:
					remove_scenes.append(parent)
			if active_scene: active_scene.exit()
			for parent in remove_scenes:
				parent.exit()
			var add_scenes: Array[SceneNode]
			for parent in new_parents:
				if parent not in old_parents:
					add_scenes.append(parent)
			add_scenes.reverse()
			for parent in add_scenes:
				parent.start()
			new_scene.start()
	scene_switched.emit(scene_name, new_scene)
	
func _get_relation(new_parents: Array[SceneNode], old_parents: Array[SceneNode]) -> RELATION:
	if not old_parents.is_empty():
		if new_parents[0] == old_parents[0]: return RELATION.SIBLING
	for parent in new_parents:
		if parent == active_scene: return RELATION.CHILD
	for parent in old_parents:
		if parent == active_scene: return RELATION.PARENT
	return RELATION.DISTANT
	
	
func _get_parents(scene: SceneNode, all_parents: Array[SceneNode]) -> Array[SceneNode]:
	if scene.get_parent() is SceneNode:
		all_parents.append(scene.get_parent())
		all_parents = _get_parents(scene.get_parent(), all_parents)
	return all_parents

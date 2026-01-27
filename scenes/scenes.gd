@abstract
##Handling scenes in a node-based structure.
##
##Start with a [SceneManager] on the base and add [SceneNode]s.
##
##@tutorial(Short overview): https://youtu.be/COHsEbzNF08

extends Node

class_name Scenes

enum {
	MAIN_SCENE,
	SUB_SCENE
}

enum DISPLAY {
	INIT_FREE,
	SHOW_HIDE,
	INIT_CUSTOM,
	SHOW_CUSTOM
}

enum RELATION {
	SIBLING,
	CHILD,
	PARENT,
	DISTANT,
	MAIN
}

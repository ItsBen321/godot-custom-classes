extends TweenAnimation

# class_name MyAnimation

var time: float = 1.0

func play(node: Node):
	var tween := node.create_tween()
	await tween.finished

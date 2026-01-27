extends TweenAnimation

class_name WobbleZoom

var time: float = 0.3

func play(node: Node):
	var tween_scale := node.create_tween()
	var tween_rotate := node.create_tween()
	tween_scale.tween_property(node, "scale", Vector2(1.2,1.2), time/2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	tween_scale.tween_property(node, "scale", Vector2(1,1), time/2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	tween_rotate.tween_property(node, "rotation", -0.1, time/3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	tween_rotate.tween_property(node, "rotation", 0.1, time/3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	tween_rotate.tween_property(node, "rotation", 0, time/3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	await tween_rotate.finished

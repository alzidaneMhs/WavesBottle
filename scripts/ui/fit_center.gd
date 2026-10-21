class_name FitCenter
extends CenterContainer

const MARGIN := 24.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_fit()


func _fit() -> void:
	for child in get_children():
		var c := child as Control
		if c == null or not c.visible:
			continue
		var need := c.get_combined_minimum_size()
		if need.x <= 0.0 or need.y <= 0.0:
			continue
		var avail := size - Vector2(MARGIN, MARGIN) * 2.0
		var s := minf(1.0, minf(avail.x / need.x, avail.y / need.y))
		s = maxf(s, 0.4)
		c.pivot_offset = c.size * 0.5
		c.scale = Vector2(s, s)

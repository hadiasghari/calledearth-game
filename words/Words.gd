extends RigidBody2D


func init(pos, text):
	$Label.text = text
	#var sz = $Label.get_size()
	#$Rect.set_size(sz)
	var sz = Vector2(len(text) * 16, 32)
	var sz2 = sz/2
	$Rect.set_size(sz)
	$Collision.shape.extents = sz2
	$Collision.transform[2] = sz2  #)  # ((1, 0), (-0, 1), (52, 16))
	print(typeof($Collision.transform))  # 8
	#$Collision.Shape.  set_size(sz)
	# - TODO: can I make the label centered?
	# - shall we insert line breaks after certain characters? J=> no
	# - font-size the same for now 
	position = pos


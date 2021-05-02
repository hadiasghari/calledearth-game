extends RigidBody2D


func init(pos, text, ecode):
	text = char(ecode) + text
	$Label.text = text	# print(ord(text[0]))
	var sz = Vector2(len(text) * 16 + 20, 32)
	var sz2 = sz/2
	$Rect.set_size(sz)
	$Collision.shape.extents = sz2
	$Collision.transform[2] = sz2  # ((1, 0), (-0, 1), (52, 16))
	# - TODO: can I make the label centered?
	# - shall we insert line breaks after certain characters? J=> no
	# - font-size the same for now 
	position = pos


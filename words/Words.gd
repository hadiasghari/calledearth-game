extends RigidBody2D


func init(pos, text, ecode, textlen):
	text = char(ecode) + text
	$Label.text = text	# print(ord(text[0]))
	var sz = Vector2(textlen, 60)  # len(text) * 16 + 20 , 32
	var sz2 = sz/2
	$Rect.set_size(sz)
	$Collision.shape.extents = sz2
	$Collision.transform[2] = sz2  # ((1, 0), (-0, 1), (52, 16))
	# note: shall we insert line breaks after certain characters? J=> no
	# note: font-size the same for now 
	# TODO... center label
	position = pos
	$Audio.stream.set_loop(false)
	$Audio.play()
	# TODO... two types of words, jumpable (sticky), moveable

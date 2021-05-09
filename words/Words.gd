extends RigidBody2D

var BoxColors = ["#FFA7A7", "#00F6F6", "#A7FF63", "#FFE160"]

func init(pos, text, ecode, maxlen, boxcolor_ix=-1):
	if len(text) > 140:
		text = text
	
	text = char(ecode) + text

	
	# TEMP LETS NOT RESIZE RE FONT QUALITY
	var textlen = len(text)*16 + 100  # estimate
	var boxl = min(textlen, maxlen)
	var lines = (textlen / maxlen) + 1
	text = str(lines) + " " + text
	lines = min(lines, 8)  # for now limit
	var boxh = lines * 40 + 15
		
	$Label.text = text		
		
	var sz = Vector2(boxl, boxh)  # len(text) * 16 + 20 , 32
	$Rect.set_size(sz)
	$Label.set_size(sz)  # resizing this with center makes it nice
	var sz2 = Vector2(boxl, min(boxh, 110))/2		
	$Collision.shape.extents = sz2
	$Collision.transform[2] = sz2  # ((1, 0), (-0, 1), (52, 16))
	
	# TODO: but now the box should be moved a bit to keep the overall center
	
	# note: shall we insert line breaks after certain characters? J=> no
	# note: font-size the same for now 	
	pos[1] -= boxh - 60
	# TODO ALSO POS0
	position = pos
	
	$Audio.stream.set_loop(false)
	$Audio.play()
	# TODO... two types of words, jumpable (sticky), moveable

	# set bg color
	if boxcolor_ix != -1: 
		$Rect.color = BoxColors[boxcolor_ix % 4]

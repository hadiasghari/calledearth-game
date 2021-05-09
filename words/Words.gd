extends RigidBody2D

var BoxColors = ["#FFA7A7", "#00F6F6", "#A7FF63", "#FFE160"]

func init(pos, text, ecode, maxlen, boxcolor_ix=-1):
	# we use the same font-size so the box adjusts
	# we thus set a limit of 140 characters to make sizing easier
	if len(text) > 140:
		text = text.left(140) + "..."	
	text = char(ecode) + " " + text
	$Label.text = text		
	
	# estimate box size
	var textlen = len(text)*16 + 100  # estimate with margin
	var lines = min((textlen / maxlen) + 1, 4)  # 4 lines limit
	var boxl = min(textlen, maxlen-100)
	var boxh = lines * 50 + 20  # add margin		
	var sz = Vector2(boxl, boxh)  # len(text) * 16 + 20 , 32
	# resize all elements 
	$Rect.set_size(sz)
	$Label.set_size(sz)  # resizing this with center makes it nice
	$Collision.shape = RectangleShape2D.new()  # we need a new one!
	$Collision.shape.set_extents(sz/2)	
	$Collision.transform[2] = sz/2  # centers it	
	# position box at center 
	if boxcolor_ix % 2 == 1:
		position = pos + Vector2(0, -30)
	else: 
		position = pos + Vector2(maxlen-boxl, -30)
		# -boxh/2 + 30
	# set bg color
	if boxcolor_ix != -1: 
		$Rect.color = BoxColors[boxcolor_ix % 4]
	
	# finally, some sound	
	$Audio.stream.set_loop(false)
	$Audio.play()

	# (NOTE/TODO: two types of words, jumpable (sticky/groove), moveable..)	

extends Node2D

signal player_dead(why)
signal player_energy(value)  # to update energy
signal player_switched(offset)  # this is simply for HUD
signal milestone(what)

export var bag_speed  = 350
var Collectible = preload('res://items/Collectible.tscn')
var Energy = preload('res://items/Energy.tscn')

var bag_hit_freeze = false
onready var _bag_paths = [$Bags/PathMinor, $Bags/PathMajor, $Bags/PathFinal]


func _ready():	
	spawn_pickups()		
	var _err
	_err = $Player.connect("dead", self, "_on_player_dead")
	_err = $Player.connect("switched", self, "_on_player_switched")
	_err = $Player.connect("energy", self, "_on_player_energychange")	
	for p in _bag_paths:
		for fp in p.get_children():
			if fp.get_child_count() >= 1:	
				var bag = fp.get_child(0)
				_err = bag.connect("hit", self, "_on_plasticbag_hit")
	#
	$MusicLevel.play()

func reposition(loc):
	#print_debug("reposition:", loc)	
	bag_hit_freeze = false  # unfreeze bags (if necessary)
		
	# Note: we don't respawn collectibles, or reset limbs, which turned out well during prototype testing
	match loc:
		'-': pass  # don't respoition (for testing start wherever player is)
		'': $Player.position = Vector2(300, -400)  # start
		'0': $Player.position = Vector2(300, -400)
		'btn1': $Player.position = $WriteButton1.position + Vector2($WriteButton1.platform_length*2, -400)
		'sav1': $Player.position = $Save1.position + Vector2(0, -100)
		# TESTING ONLY (not possible in game play):
		'btn1-': $Player.position = $WriteButton1.position + Vector2(-150, 0)
		'btn2-': $Player.position = $WriteButton2.position + Vector2(-150, 0)
		'btn2': $Player.position = $WriteButton2.position + Vector2($WriteButton2.platform_length*2, -400)	 # cannot really die after btn2		
		var unknown:
			print_debug('Unknown location for reposition requested: ' + str(unknown))
			

func _process(delta):	
	if not bag_hit_freeze:
		for p in _bag_paths:
			for fp in p.get_children():
				fp.set_offset(fp.get_offset() + bag_speed * delta)


# NOTE: following functions are shared between L1 & L2, suggesting a good inheritence possibility
#      (once we add more functions in the future)

func spawn_pickups():
	$Tilemap_pickups.hide()
	var pickups = $Tilemap_pickups 
	for cell in pickups.get_used_cells():
		var id = pickups.get_cellv(cell)
		var type = pickups.tile_set.tile_get_name(id)
		var pos = pickups.map_to_world(cell)
		var c = Collectible.instance()
		# FUTURE: cell sizes between layers should (probably) be the same 
		#        (and related to the collectible also) to avoid placement problems
		type = c.init(type, pos + pickups.cell_size)  
		if type:
			add_child(c)
			c.connect('pickup', self, '_on_pickup_' + type) 

func _on_pickup_switch():
	$Player.limb_switch()
	
func _on_plasticbag_hit():
	$MusicLevel.stop()	
	$Player.freeze_player(true)
	bag_hit_freeze = true  # freeze all bags temporarily. (alt add func param identifying bag)
	emit_signal("player_dead", "hit_bag")

func _on_player_dead(why):
	$MusicLevel.stop()
	emit_signal("player_dead", why)
	
func _on_player_switched(offset):
	emit_signal("player_switched", offset)

func _on_player_energychange(value):
	emit_signal("player_energy", value)		
		
func _on_pickup_victory():
	$MusicLevel.stop()
	emit_signal('milestone', 'dance')  
	
func freeze_player(pause_state):
	print_debug("L1 freeze_player: ", pause_state)
	if pause_state:
		$MusicLevel.stream_paused = true 
		$Player.freeze_player(true)
	else:
		$MusicLevel.stream_paused = false
		if not $MusicLevel.playing:  
			$MusicLevel.play()
		$Player.freeze_player(false)

func spawn_energy_item(etype):
	var ei = Energy.instance()  				
	var pos = Vector2(-300+randi()%600, -50-randi()%100)  # above player
	ei.init(etype, "?", $Player.position + pos)
	add_child(ei)				

func _on_Buttons_activated():
	$MusicLevel.stop()	
	$MusicWriting.play()  # TODO: maybe fade tween
	$Player.set_physics_process(false)

func _on_Buttons_deactivated(num):
	#print_debug("DEACTIVATE: " + str(num))	
	$Player/Camera2D.current = true  # return camera!
	if $MusicWriting.playing:  # necessary check if we get called twice
		$MusicWriting.stop()
		$MusicLevel.play()
	$Player.set_physics_process(true)
	emit_signal('milestone', 'btn' + str(num))  

## end shared functions

func _on_Save1_body_exited(_body):
	# save location! (collision triggers only for player) 
	# print_debug(body)
	emit_signal('milestone', 'sav1')   

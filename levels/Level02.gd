extends Node2D

signal player_dead(why)
signal player_energy(value)  # to update energy
signal player_switched(offset)  # this is simply for HUD
signal milestone(what)

export var bag_speed  = 350

var Collectible = preload('res://items/Collectible.tscn')
var Energy = preload('res://items/Energy.tscn')

func _ready():
	$Player/Camera2D.zoom = Vector2(2, 2)	
	var _err
	_err = $Player.connect("dead", self, "_on_player_dead")
	_err = $Player.connect("switched", self, "_on_player_switched")
	_err = $Player.connect("energy", self, "_on_player_energychange")	
	spawn_pickups()	
	# TODO:	reposition("B-")  
	$MusicLevel.play()

func reposition(loc):
	# In case we stopped Music or physics on last death:	
	# Note: we don't respawn collectibles, or reset limbs, which turned out well during prototype test
	# reposition player
	match loc:
		'0':  $Player.position = Vector2(300, -400)			
		#'A': $Player.position = Vector2(300, -400) # TODO: set some in that craze :)
		'B-': $Player.position = $PlatformButton.position + Vector2(-150, 0)
		'B+': $Player.position = $PlatformButton.position + $Button2/ExitArea.position + Vector2(300, 0)
		'B+': $Player.position = $PlatformButton.position + $Button2/ExitArea.position + Vector2(300, 0)
		var unknown:
			print_debug('Unknown location for reposition requested: ' + str(unknown))


func _process(delta):	
	var bag_follows = [$Bags/PathMinor/Follow1, 
						$Bags/PathMajor/Follow2, 
						$Bags/PathMajor/Follow3]	
	for f in bag_follows:
		f.set_offset(f.get_offset() + bag_speed * delta)


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
		type = c.init(type, pos + pickups.cell_size/2)
		if type:
			add_child(c)
			c.connect('pickup', self, '_on_pickup_' + type) 

func _on_pickup_switch():
	$Player.limb_switch()

func _on_player_dead(why):
	print_debug(why) 
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
	if pause_state:
		$MusicLevel.stop()
		$Player.freeze_player(true)
	else:
		$MusicLevel.play()
		$Player.freeze_player(false)

func spawn_energy_item(etype):
	var ei = Energy.instance()  				
	var pos = Vector2(-300+randi()%600, -50-randi()%100)  # above player
	ei.init(etype, "?", $Player.position + pos)
	add_child(ei)				

func _on_ButtonPlatform_activated():
	$MusicLevel.stop()	
	if not $MusicSegue.playing:
		$MusicSegue.play()  # set db in object
	$Player.set_physics_process(false)

func _on_ButtonPlatform_deactivated():
	$Player/Camera2D.current = true  # return camera!
	$MusicSegue.stop()
	$MusicLevel.play()
	$Player.set_physics_process(true)
	emit_signal('milestone', 'btn1')  

## end shared functions

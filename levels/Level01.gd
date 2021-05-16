extends Node2D

signal player_dead
signal player_energy(value)  # to update energy
signal player_switched(offset)  # this is simply for HUD
signal dance_next

var Collectible = preload('res://items/Collectible.tscn')
var Energy = preload('res://items/Energy.tscn')


func reposition(loc):
	# In case we stopped Music or physics on last death:	
	# Note: we don't respawn collectibles, or reset limbs, which turned out well during prototype test
	$MusicLevel.play()
	$Player.freeze_player(false) 
	# reposition player
	match loc:
		'0': 
			$Player.position = Vector2(300, -400)			
		'A-': 
			$Player.position = $Button1.position + Vector2(-150, 0)
		'A+': 
			$Player.position = $Button1.position + $Button1/ExitArea.position + Vector2(300, -400)
		'B-':
			$Player.position = $Button2.position + Vector2(-150, 0)
		'B+':
			$Player.position = $Button2.position + $Button2/ExitArea.position + Vector2(300, 0)
		var unknown:
			print_debug('Unknown location for reposition requested: ' + str(unknown))

	

func _ready():
	spawn_pickups()
	var _err
	_err = $Player.connect("dead", self, "_on_player_dead")
	_err = $Player.connect("switched", self, "_on_player_switched")
	_err = $Player.connect("energy", self, "_on_player_energychange")
	_err = $Spikes.connect("hit", self, "_on_player_dead")
	
	reposition("0")  # TODO: SET REPOSITION somewhere  -- from input

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
	# Q from a design perspective could the pickup directly call the player, etc? do we need to go through level?
	$Player.limb_switch()

func _on_player_dead():
	$MusicLevel.stop()
	emit_signal("player_dead")
	
func _on_player_switched(offset):
	emit_signal("player_switched", offset)

func _on_player_energychange(value):
	emit_signal("player_energy", value)		
		
func _on_pickup_victory():
	$MusicLevel.stop()
	emit_signal('dance_next')  
			
func _on_Buttons_deactivated():
	$Player/Camera2D.current = true  # return camera!
	$MusicSegue.stop()
	$MusicLevel.play()
	$Player.set_physics_process(true)	# TODO however now sth needs to activate this

func _on_Buttons_activated():
	# volume already set to $MusicSegue.volume_db = -15
	$MusicLevel.stop()	
	if not $MusicSegue.playing:
		$MusicSegue.play()
	$Player.set_physics_process(false)
	
func spawn_energy_item(etype):
	var ei = Energy.instance()  				
	# position above player	
	var pos = $Player.position + Vector2(-300+randi()%600, -50-randi()%100)
	ei.init(etype, "?", pos)
	add_child(ei)				
	
func freeze_player(pause_state):
	if pause_state:
		$Player.freeze_player(true)
	else:
		$Player.freeze_player(false)


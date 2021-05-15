extends Node2D

var Collectible = preload('res://items/Collectible.tscn')
#var Energy = preload('res://items/Energy.tscn')
#onready var GLOBAL = get_node("/root/Global")

signal player_dead
signal dance_next
signal limb_switched(offset)  # this is simply for HUD

func reposition(loc):
	# in case we stopped these on death:	
	$MusicLevel.play()
	$Player.set_physics_process(true)  
	# note, we don't respawn collectibles, or reset limbs, which turned out better during the prototype test
	# finally, set player location
	match loc:
		'A': 
			$Player.position = Vector2(300, -400)			
		'B': 
			$Player.position = $Button1.position + $Button1/AreaExit.position + Vector2(300, -400)
		var unknown:
			# also e.g. write before these buttons $Player.position = $Button1.position - Vector2(100, 0) 				
			# one could add position 'C' is write before/after dancing...
			print_debug('Unknown location for reposition requested')
	
	

func _ready():
	spawn_pickups()
	$Player.connect("dead", self, "_on_gameover")
	$Player.connect("limbswitched", self, "_on_player_limbswitched")
	$Spikes.connect("hit", self, "_on_gameover")
	# TODO: SET REPOSITION somewhere


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


func _on_gameover():
	$MusicLevel.stop()
	emit_signal("player_dead")
	

func _on_player_limbswitched(offset):
	# This should probably be moved into the player itself, if we can connect their signals
	# Q: from a design perspective where should this HUD be best set?
	# (for now we just pass it to Main that is calling us)
	emit_signal("limb_switched", offset)
		
		
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
	

extends Node2D

signal player_dead(why)
signal player_energy(value)  
signal player_switched(offset) 
signal milestone(what)
signal powerup

var Collectible = preload('res://items/Collectible.tscn')
var Energy = preload('res://items/Energy.tscn')


func reposition(loc):
	# In case we stopped Music or physics on last death:	
	# Note: we don't respawn collectibles, or reset limbs, which turned out well during prototype test
	# reposition player:
	#print_debug("L1 reposition:", loc)
	match loc:
		'-': pass  # don't respoition (for testing start wherever player is)
		'': $Player.position = Vector2(300, -400)  # level start
		'0': $Player.position = Vector2(300, -400)  
		'btn1': $Player.position = $WriteButton1.position + Vector2($WriteButton1.platform_length*2, -400)
		# TESTING ONLY (not possible in game play):
		'btn1-': $Player.position = $WriteButton1.position + Vector2(-150, 0)
		'btn2-': $Player.position = $WriteButton2.position + Vector2(-150, 0)
		'btn2': $Player.position = $WriteButton2.position + Vector2($WriteButton2.platform_length*2, 0)	 # cannot really die after btn2		
		var unknown:
			print_debug('Unknown location for reposition requested: ' + str(unknown))

	
func _ready():
	spawn_pickups()
	var _err
	_err = $Player.connect("dead", self, "_on_player_dead")
	_err = $Player.connect("switched", self, "_on_player_switched")
	_err = $Player.connect("energy", self, "_on_player_energychange")
	_err = $Spikes1.connect("hit", self, "_on_spikes_hit")
	_err = $Spikes2.connect("hit", self, "_on_spikes_hit")
	$MusicLevel.play()

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

func _on_spikes_hit():
	$MusicLevel.stop()	
	$Player.freeze_player(true)
	emit_signal("player_dead", "hit_spikes_l1")

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
	
func _on_pickup_yellow():
	emit_signal('powerup')
	
func freeze_player(pause_state):
	#print_debug("L1 freeze_player: ", pause_state)
	if pause_state:
		$MusicLevel.stream_paused = true  # to continue music
		$Player.freeze_player(true)
		# note (.get_tree().paused=true pauses *everything* hence not...)
	else:
		$MusicLevel.stream_paused = false
		if not $MusicLevel.playing:  
			$MusicLevel.play()
		$Player.freeze_player(false)

func spawn_energy_item(etype):
	var ei = Energy.instance()  				
	# position items above player	
	var pos = $Player.position + Vector2(-300+randi()%600, -50-randi()%100)
	ei.init(etype, "?", pos)
	add_child(ei)				
			
func _on_Buttons_deactivated(num):
	#print_debug("DEACTIVATE: " + str(num))
	$Player/Camera2D.current = true  # return camera!
	if $MusicWriting.playing:  # necessary check if we get called twice
		$MusicWriting.stop()
		$MusicLevel.play()
	$Player.set_physics_process(true)
	emit_signal('milestone', 'btn' + str(num))  

func _on_Buttons_activated():
	# note, signal emitted to django server re prompt in the writing-button scene
	$MusicLevel.stop()	
	$MusicWriting.play()  # Future: perhaps fade start this with tween
	$Player.set_physics_process(false)
	$Player.stop_animations()

	

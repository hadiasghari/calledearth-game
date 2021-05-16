extends Control

onready var GLOBAL = get_node("/root/Global")

export var critical_level = 10
#signal energy_critical

func _process(_delta):
	if Input.is_action_just_pressed("test_recharge"):
		print_debug("CHARGE!")
		update_energy(100)	

func update_energy(value):	
	GLOBAL.energy += value
	GLOBAL.energy = min(max(0, GLOBAL.energy), 100)  # 0 to 100
	$Number.text = str(GLOBAL.energy)
	$TextureProgress.value = GLOBAL.energy
	if GLOBAL.energy < critical_level:
		$TimerBlink.start()
		#emit_signal("energy_critical")
	else: 
		$TimerBlink.stop()
	$TextureProgress.show()  # restore state to visible
	

func _on_TimerBlink_timeout():
	match $TextureProgress.visible:
		false: $TextureProgress.show()
		true: $TextureProgress.hide()
		var wtf: print_debug("WTF ebar: " + str(wtf))


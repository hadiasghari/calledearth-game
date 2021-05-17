extends Control

onready var GLOBAL = get_node("/root/Global")

export var critical_level = 10

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
	else: 
		$TimerBlink.stop()
	# to be sure we're not stuck in wierd timer state: restore to visible		
	$TextureProgress.show()
	$Number.show()
	
func _on_TimerBlink_timeout():
	match $TextureProgress.visible:
		false: 
			$TextureProgress.show()
			$Number.show()
		true: 
			$TextureProgress.hide()
			$Number.hide()
		var wtf: print_debug("WTF ebar: " + str(wtf))


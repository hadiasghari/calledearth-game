# PROJECT TODO
*UPDATE October 2021*
- We have added a websocket backend to the Django part to make webuser gameflow faster/smoother.
  This still requires some further work (esp re issues leading to websocket disconnects).
- Also, the Godot engine link with the Django part could also use this websocket mechanism for effiency
  Note, I decided to keep the Heroku part as the design works :)
- For game restart, we added a menu at the start to allow it. 
  (State isn't kept but that's okay for now; it's manual but that's also okay)
- The game-level logic is getting a bit complicated in Main.gd, which might suggest refactoring
  maybe helpful. The same for refactoring the HUDs (which are also a bit in Main and a bit in contq.) 
- A gamelog might still be useful for debugging purposes, but not necessary
- The `defer` error is still being pushed hard to the Godot console, to look into... 
  (re button multipress, although not an issue now)
- (See Hadi's other notes from this period)




----

As of June 2021, for future versions.


## PRIORITY, 1
- some terrible murphy concurrency made it possible to trigger `WriteButton`s twice when gamepad keys are smashed  quickly under pressure :) (hence freezing the player immediately after finishing writing)
  moving the _is_activated place allows manual deactivation again; to test.
- however, this is probably related to the `defer` error by godot. that should be fixed (in `WritingButton.gd`, `Collectibe.gd`, `Player.gd`)
  i.e. `area_set_shape_disabled: Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.`
 - (I am unsure how to fix this, so probably somethin gto ask godot discord/forums).
 


## PRIORITY, 2
- Redesign and replace the current centralized Django messaging/database. This is necessary for scalability with >10 active participants, especially if the network firewall might block too many connections. (See story below)
- The Django part could be fully removed, in which case a local webserver is necessary... or at least the connections could be turned into websockets/async calls so they can remain open; 
(Note that if it is fully remvoed, the mobile clients will still need some external proxy/tunnel to find the server, since it will be running on a dynamic IP and might also not be accessible on the public web due to firewalls and NATs).
- The web-server connection changes are in `Main.gd` and `WriteButton.gd`
- All across the code, replace `set_web_state('event', ...)`  with a file-based (unique) gamelog. (the FYI calls ones are currently commented out with TODO so as to lower web server calls; once the game log is implemented, additional information like return values of request.requests can be logged too)


*Story of Run 20210521*
There was a hang up in all HTTP requests in one game today (1370) where 26 participants
connected and went bonkers (by sending in a lot of texts!). 
the laptop was also running OBS/zoom. on a fast LAN connection
godot stopped updating heroku. and even after a manual heroku change (in case one http packet was lost)
people's powerups nor promprts were not pickedup/shown anymore...!
things were fixed after restarting the server, closing zoom/obs, and asking only half to logon.
given the logic of the code here it seems ALL subsequent http requests were blocked by something.
(maybe all the http timers stopped? is that possible? or the some machine/godot/eduroam/heroku limit?)
note that godot continued to play/run quite okay during this time
in any case, the inbound from clients to godot is also done via these outbound links, so they all fail together :)
(i.e. these heroku requests are unnecesssarily expensive compared to simpler requests that could be sent from the
 mobile to godot). note that in this case a 'retry' wouldn't have helped. 
some 'keep alive' and a graceful restart (i.e. saving state of the world/words)  would have. :).
(heroku only has two gamelogs from that run, so problem couldn't have been from that choking. it is possible that users were sending too many things?)


## OTHER
- general: perhaps add a button to restart/recover the game (even load from state?) -- esp for performances with participants
- general: perhaps add automated tests (for game controllers and the web-users)
- general: read up, or ask in godot discord, some design question regarding chaining signals in case of nested scenes. 

- Player.gd or main: perhaps add a state-machine or something similar for the player freeze/unfreeze and also wing/jump/pushes etc in player.gd
- Level02.gd: perhaps make level 2 a bit easier 
- Levelxx.gd: if more levels are to be added, perhaps use inheritance for some of the level01/level02 code
- Level02.gd: the cell sizes should be made the same (or some other common design pattern)  (similarly: and collision shape texture in collectible.gd)
- MovingPlatform.gd: perhaps fix moving platform up-down 
- HUD.gd, Main.gd: possibly add a margin for the HUD when the projector is a bit out of bounds; possibly show a +1 when energy is added, or rethink that mechanism/dynamic
- HUD.gd, Collective.gd, ...: possibly add TWEENS (animations) to smoothen effects like HUD texts etc

- the git history could be squashed re some large files
- (more TODOs possibly in Hadi's May 2021 notes)





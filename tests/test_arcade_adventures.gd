extends SceneTree
var failures := 0
var checks := 0
var game
var arcade: BalloonArcade
func expect(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 create_timer(90).timeout.connect(func(): quit(1))
 run.call_deferred()
func reset() -> void:
 arcade.round_index = 0
 arcade.coop = false
 arcade.begin_round()
 arcade.set_physics_process(false)
 arcade.mechanic = "stone"
 arcade.freeze = 30
 arcade.invincible = 30
 arcade.accept_drops = true
func capture(name: String) -> void:
 if DisplayServer.get_name() == "headless": return
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/arcade-adventure-"+name+".png")
func run() -> void:
 game = load("res://scenes/game.tscn").instantiate()
 game.save_path = "user://arcade-adventures-test.json"
 for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(game.save_path + suffix)
 root.add_child(game)
 await process_frame
 root.size = Vector2i(844,390)
 game.profile.home_country = "AF"
 game.profile.settings.music = 0.0
 game.profile.settings.sound = 0.0
 game.audio.apply_settings(game.profile.settings)
 game.start_arcade("world")
 arcade = game.arcade
 reset()
 for kind in BalloonArcade.WEAPONS:
  reset()
  arcade.collect(kind)
  arcade.collect(kind)
  expect(arcade.weapon_level == 2, "Repeated weapon upgrades "+kind)
  arcade.collect(kind)
  arcade.collect(kind)
  expect(arcade.weapon_level == 3, "Upgrade cap is three")
  expect(arcade.fire(), "Upgraded weapon can fire")
 reset()
 arcade.collect("sticky")
 arcade.collect("gun")
 expect(arcade.weapon_trait == "sticky" and arcade.fire(), "Sticky blaster combination")
 expect(arcade.wires[0].sticky, "Combination carries ceiling attachment")
 arcade.simulate(2)
 expect(arcade.wires[0].stuck, "Combination attaches at ceiling")
 await capture("combo")
 reset()
 arcade.collect("rocket")
 arcade.collect("double")
 arcade.fire()
 expect(arcade.wires.size()==2 and arcade.wires[0].blast, "Explosive double arrows")
 reset()
 arcade.collect("double")
 arcade.collect("gun")
 arcade.fire()
 expect(arcade.wires.size()==2, "Double blaster combination")
 reset()
 arcade.accept_drops = false
 arcade.pickups.assign([{"position":Vector2(arcade.player_x,arcade.floor_y-20),"kind":"speed","age":0.0}])
 arcade.simulate(0.01)
 expect(not arcade.effects.has("speed") and arcade.pickups.size()==1, "Avoid mode refuses hidden reward or curse")
 arcade.accept_drops = true
 arcade.simulate(0.01)
 expect(arcade.effects.has("speed") and arcade.pickups.is_empty(), "Collect mode reveals and applies mystery curse")
 arcade.effects.clear()
 var old_score := arcade.score
 for index in 3:
  arcade.pickups.assign([{"position":Vector2(arcade.player_x,arcade.floor_y-20),"kind":"shield","age":0.0}])
  arcade.simulate(0.01)
 expect(arcade.score == old_score+500, "Three lucky mysteries award a risk bonus")
 reset()
 arcade.mechanic = "ice"
 arcade.set_control("▶",true)
 arcade.simulate(0.1)
 arcade.set_control("▶",false)
 var x := arcade.player_x
 arcade.simulate(0.02)
 expect(arcade.player_x > x, "Ice keeps sliding after release")
 for theme in ["stone","space","ocean"]:
  reset()
  arcade.mechanic = theme
  arcade.freeze = 0
  arcade.balls.assign([arcade.make_ball(Vector2(100,100),0,1)])
  arcade.balls[0].velocity = Vector2.ZERO
  arcade.simulate(0.1)
  expect(arcade.balls[0].velocity.y == (60.0 if theme=="stone" else 16.0 if theme=="space" else 23.0), "Theme changes gravity: "+theme)
 reset()
 arcade.mechanic = "sand"
 arcade.clock = 1
 x = arcade.player_x
 arcade.simulate(0.1)
 expect(arcade.player_x != x, "Desert gusts push the explorer")
 for rule in ["swarm","no_fire","flood"]:
  reset()
  arcade.challenge = rule
  arcade.remaining = 1
  expect(not arcade.fire() if rule=="no_fire" else arcade.fire(), "Challenge firing rule "+rule)
  arcade.wires.clear()
  arcade.simulate(1.1)
  expect(arcade.phase == (BalloonArcade.Phase.FAILED if rule=="flood" else BalloonArcade.Phase.CLEAR), "Correct win/loss at challenge deadline: "+rule)
 reset()
 arcade.round_index = 1
 arcade.begin_round()
 expect(arcade.challenge != "" and arcade.remaining==25, "Second round selects a challenge")
 arcade.freeze = 30
 arcade.wave_clock = 4
 var count := arcade.balls.size()
 arcade.simulate(0.01)
 expect(arcade.balls.size()==count+1, "Survival challenge adds a bounded wave")
 await capture("challenge")
 reset()
 arcade.round_index = 2
 arcade.begin_round()
 arcade.freeze = 30
 expect(arcade.balls[0].get("boss",false) and arcade.balls[0].radius > 48, "Third round spawns an armored giant")
 expect("AF" not in game.profile.discoveries, "Unfinished boss country has no passport stamp")
 var boss: Dictionary = arcade.balls[0]
 var hp: int = boss.hp
 arcade.pop_ball(0)
 expect(boss.hp==hp-1 and arcade.balls.size()==1, "Boss absorbs hits without splitting")
 arcade.pop_ball(0)
 expect(arcade.balls.size()>1, "Boss sheds armor and spawns minions")
 await capture("boss")
 for index in hp-2: arcade.pop_ball(0)
 expect(not arcade.balls.any(func(ball): return ball.get("boss",false)), "Boss defeated after its health is exhausted")
 while not arcade.balls.is_empty(): arcade.pop_ball(0)
 arcade.simulate(0.01)
 expect(arcade.phase==BalloonArcade.Phase.CLEAR and "AF" in game.profile.discoveries, "Boss and minions must clear before passport stamp")
 reset()
 arcade.coop = true
 arcade.layout()
 arcade.begin_round()
 arcade.set_physics_process(false)
 arcade.freeze = 30
 expect(arcade.partner_controls.visible and arcade.controls.position.y < arcade.partner_controls.position.y, "Co-op exposes two sets of touch controls")
 arcade.set_control("P2 ▶",true)
 x = arcade.partner_x
 arcade.simulate(0.1)
 expect(arcade.partner_x > x, "P2 independently moves")
 arcade.set_control("P2 ▶",false)
 arcade.set_control("P2 FIRE",true)
 arcade.simulate(0.1)
 expect(not arcade.wires.is_empty() and absf(arcade.wires[0].x-arcade.partner_x)<1, "P2 fires from their own character")
 arcade.set_control("P2 FIRE",false)
 arcade.partner_down = true
 arcade.collect("heart")
 expect(not arcade.partner_down and arcade.partner_grace > 0, "Shared heart revives a fallen teammate")
 arcade.collect("heart")
 expect(arcade.shield, "Healthy team receives a shared shield from heart")
 arcade.shield = false
 arcade.invincible = 0
 arcade.hit()
 expect(arcade.phase == BalloonArcade.Phase.FAILED, "First co-op collision ends the run")
 arcade.begin_round()
 arcade.freeze = 0
 arcade.balls.assign([arcade.make_ball(Vector2(arcade.partner_x, arcade.floor_y - 35), 0, 1)])
 arcade.simulate(0.01)
 expect(arcade.phase == BalloonArcade.Phase.FAILED, "P2 collision ends the run even during starting grace")
 arcade.begin_round()
 arcade.freeze=30
 await capture("coop-landscape")
 root.size=Vector2i(390,844)
 await process_frame
 await capture("coop-portrait")
 expect(arcade.controls.get_global_rect().end.y < arcade.partner_controls.position.y+2, "Portrait co-op controls do not overlap")
 arcade.score = 987654
 game.return_to_menu()
 expect(game.profile.records.has("balloon-coop:"+game.profile.difficulty) and game.profile.records["balloon-coop:"+game.profile.difficulty] == 987654, "Co-op score persists in its own record on menu exit")
 game.queue_free()
 await process_frame
 print("Arcade adventure checks: ",checks,"; failures: ",failures)
 quit(1 if failures else 0)

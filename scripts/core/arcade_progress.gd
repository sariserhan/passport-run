class_name ArcadeProgress
extends RefCounted

const DROPS := {
 "double": ["Double harpoon", "Two upward harpoons. Collect again to upgrade your weapon."],
 "sticky": ["Sticky harpoon", "Harpoons stay attached to the ceiling for three seconds."],
 "gun": ["Rapid blaster", "Fast upward projectiles with a short firing cooldown."],
 "triple": ["Triple harpoon", "Three upward harpoons cover a wider area."],
 "spread": ["Spread shot", "Five projectiles fan out above the explorer."],
 "laser": ["Piercing laser", "A beam pierces balloons for half a second."],
 "rocket": ["Splash rocket", "An impact hits balloons within its blast radius."],
 "rapid": ["Rapid fire", "Eight seconds of shorter weapon cooldowns."],
 "freeze": ["Frozen balloons", "Balloons stop for four seconds. Touching one is still fatal."],
 "slow": ["Slow motion", "Balloons move more slowly for ten seconds."],
 "boots": ["Quick boots", "Move faster for ten seconds."],
 "upgrade": ["Weapon upgrade", "Upgrade your equipped weapon, up to level three."],
 "time": ["Time boost", "Adds twelve seconds to a clear round or shortens a survival round."],
 "coin": ["Travel coins", "Fifteen tour coins and 750 bonus points."],
 "bomb": ["Burst bomb", "Splits large and medium balloons; bosses keep their armor."],
 "magnet": ["Mystery magnet", "Nearby mystery drops drift toward you for ten seconds."],
 "speed": ["Fast balloons", "Hazard: balloons move faster for eight seconds."],
 "multiply": ["Balloon multiplication", "Hazard: ordinary balloons duplicate, up to the wave limit."],
 "heavy": ["Heavy boots", "Hazard: slower movement for eight seconds."],
 "reverse": ["Reversed controls", "Hazard: left and right swap for eight seconds."],
 "jam": ["Weapon jam", "Hazard: firing stops for three seconds."],
 "shrink_time": ["Time pressure", "Hazard: removes twelve seconds from a clear round or extends survival."],
}
const DAILY := {"pops": ["Pop 30 balloons", 30], "bosses": ["Defeat a boss", 1], "no_drops": ["Clear a destination without drops", 1]}
const MEDALS := ["Unstamped", "Bronze", "Silver", "Gold"]

static func medal(seconds: float, retries: int, combo: int) -> int:
 if seconds >= 0 and retries == 0 and seconds <= 150 and combo >= 5: return 3
 if seconds >= 0 and retries <= 2 and seconds <= 210 and combo >= 3: return 2
 return 1

static func mastery_key(id: String, difficulty: String, coop: bool) -> String:
 return id + ":" + difficulty + (":coop" if coop else "")

static func valid_mastery_key(key: String) -> bool:
 var parts := key.split(":")
 return parts.size() in [2, 3] and parts[0] in GameCatalog.DESTINATIONS and parts[1] in GameCatalog.DIFFICULTIES and (parts.size() == 2 or parts[2] == "coop")

static func clean_daily(data: Variant, day: String) -> Dictionary:
 var result := {"date": day, "pops": 0, "bosses": 0, "no_drops": 0}
 if data is Dictionary and data.get("date") == day:
  for key in DAILY:
   if data.get(key) is int or data.get(key) is float: result[key] = clampi(int(data[key]), 0, DAILY[key][1])
 return result

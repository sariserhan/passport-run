class_name BuddyPersonality
extends RefCounted
const FRIENDS := {
 "bird": {"name": "Pip", "description": "A curious bird who flutters, chirps and spins with joy.", "idle": "Chirp!", "cheer": "Tweet!", "worry": "Eep!", "color": "ffc85c"},
 "robot": {"name": "Orbit", "description": "A patient robot who scans the path and celebrates with a victory orbit.", "idle": "Scanning…", "cheer": "Beep!", "worry": "Alert!", "color": "86d7ed"},
 "dragon": {"name": "Ember", "description": "A sleepy baby dragon who stretches, hops and breathes tiny sparks.", "idle": "Zzz…", "cheer": "Roar!", "worry": "Oh!", "color": "8ed599"},
}

static func message(kind: String, state: String, clock: float, pressure: float = 0) -> String:
 if kind not in FRIENDS: return ""
 if state == "fall" or pressure > 0.65: return FRIENDS[kind].worry
 if state in ["celebrate", "stamp"]: return "♥"
 if state == "jump": return {"bird": "Whee!", "robot": "Boost!", "dragon": "Hop!"}[kind]
 return FRIENDS[kind].idle if fmod(clock, 8) > 5 else "• •"

static func offset(kind: String, state: String, clock: float) -> Vector3:
 var cheer := state in ["celebrate", "stamp"]
 if kind == "bird": return Vector3(sin(clock * 4) * (0.22 if cheer else 0.06), sin(clock * 8) * 0.13, 0)
 if kind == "robot": return Vector3(cos(clock * 3) * (0.3 if cheer else 0.05), sin(clock * 3) * 0.12, sin(clock * 3) * 0.08)
 return Vector3(0, absf(sin(clock * (7 if cheer else 1.4))) * (0.28 if cheer else 0.06), 0)

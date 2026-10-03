class_name PassportBackup
extends RefCounted
const FORMAT := "passport-run-backup-v1"
const FILENAME := "passport-run-backup.json"

static func export_text(profile: PlayerProfile) -> String:
 if not profile.save(): return ""
 var data := profile.read_valid(profile.file_path)
 data.erase("anonymous_id")
 return JSON.stringify({"format": FORMAT, "created": GameCatalog.today_utc(), "profile": data})

static func inspect(value: String) -> Dictionary:
 if value.to_utf8_buffer().size() > PlayerProfile.MAX_PROFILE_BYTES + 1024: return {}
 var parsed: Variant = JSON.parse_string(value)
 if not parsed is Dictionary or parsed.get("format") != FORMAT or not parsed.get("profile") is Dictionary: return {}
 var data: Dictionary = parsed.profile
 if JSON.stringify(data).to_utf8_buffer().size() > PlayerProfile.MAX_PROFILE_BYTES: return {}
 if data.get("version") != PlayerProfile.SCHEMA_VERSION or not data.get("discoveries") is Array or data.discoveries.size() > GameCatalog.DESTINATIONS.size(): return {}
 if not data.discoveries.all(func(id): return id is String and id in GameCatalog.DESTINATIONS): return {}
 # A temporary profile applies the same validation as normal loading, before replacement.
 return data

static func restore(profile: PlayerProfile, value: String) -> bool:
 var data := inspect(value)
 if data.is_empty(): return false
 var temporary := profile.file_path + ".restore"
 var file := FileAccess.open(temporary, FileAccess.WRITE)
 if not file: return false
 file.store_string(JSON.stringify(data))
 file.close()
 var candidate := PlayerProfile.new(temporary)
 candidate.anonymous_id = profile.anonymous_id
 candidate.character_pack_unlocked = profile.character_pack_unlocked
 candidate.file_path = profile.file_path
 if not profile.read_valid(profile.file_path).is_empty():
  if DirAccess.copy_absolute(profile.file_path, profile.file_path + ".before-restore") != OK:
   DirAccess.remove_absolute(temporary)
   return false
 var result := candidate.save()
 DirAccess.remove_absolute(temporary)
 return result

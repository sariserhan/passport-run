class_name NativePictureShare
extends RefCounted
const REQUEST := "user://passport-share-request.json"
const RESULT := "user://passport-share-result.json"
const FILENAMES := ["passport-run-room.png", "passport-run-album.png", "passport-run-journal.png", "passport-run-photo.png", "passport-run-scrapbook.png"]

static func request(owner: Node, filename: String) -> String:
 if OS.get_name() != "iOS": return "unavailable"
 if filename not in FILENAMES or not FileAccess.file_exists("user://" + filename): return "error"
 var token := Crypto.new().generate_random_bytes(12).hex_encode()
 DirAccess.remove_absolute(RESULT)
 var file := FileAccess.open(REQUEST + ".tmp", FileAccess.WRITE)
 if not file: return "error"
 file.store_string(JSON.stringify({"id": token, "filename": filename, "expires": Time.get_unix_time_from_system() + 10}))
 file.close()
 if DirAccess.rename_absolute(REQUEST + ".tmp", REQUEST) != OK: return "error"
 var deadline := Time.get_ticks_msec() + 8000
 while Time.get_ticks_msec() < deadline:
  await owner.get_tree().create_timer(0.2).timeout
  if FileAccess.file_exists(RESULT):
   var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(RESULT))
   if result is Dictionary and result.get("id") == token:
    DirAccess.remove_absolute(RESULT)
    var state: Variant = result.get("state", "error")
    return state if state in ["opened", "shared", "cancelled", "error"] else "error"
 DirAccess.remove_absolute(REQUEST)
 return "unavailable"

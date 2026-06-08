class_name PlayerData

static var current_level : int   = 1
static var best_level    : int   = 1   # highest level ever reached
static var shirt_color   : Color = Color(0.22, 0.44, 0.90)
static var hair_color    : Color = Color(0.28, 0.14, 0.04)
static var skin_color    : Color = Color(1.00, 0.82, 0.65)

const SAVE_PATH : String = "user://savegame.dat"

# Call this after reaching a new best level
static func save() -> void:
	var f : FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_32(best_level)

# Call this when the game starts to restore progress
static func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f : FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		best_level = clampi(int(f.get_32()), 1, 100)

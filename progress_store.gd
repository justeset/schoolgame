extends RefCounted

const SAVE_PATH := "user://progress.cfg"
const SECTION := "tasks"

static func set_leaders_completed(completed: bool) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SECTION, "leaders_completed", completed)
	config.save(SAVE_PATH)

static func is_leaders_completed() -> bool:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return false
	return bool(config.get_value(SECTION, "leaders_completed", false))

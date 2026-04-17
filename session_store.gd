extends Node

const SAVE_PATH := "user://session.cfg"
const SECTION := "auth"


func save_session(token: String, user: Dictionary) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(SECTION, "token", token)
	config.set_value(SECTION, "user_id", int(user.get("id", 0)))
	config.set_value(SECTION, "email", str(user.get("email", "")))
	config.set_value(SECTION, "name", str(user.get("name", "")))
	config.save(SAVE_PATH)


func clear_session() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.erase_section(SECTION)
	config.save(SAVE_PATH)


func is_logged_in() -> bool:
	return get_token() != ""


func get_token() -> String:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return ""
	return str(config.get_value(SECTION, "token", ""))


func get_user() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return {}
	return {
		"id": int(config.get_value(SECTION, "user_id", 0)),
		"email": str(config.get_value(SECTION, "email", "")),
		"name": str(config.get_value(SECTION, "name", "")),
	}


func update_user(user: Dictionary) -> void:
	var token := get_token()
	save_session(token, user)

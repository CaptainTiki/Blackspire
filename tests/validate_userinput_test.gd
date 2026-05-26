extends SceneTree

## Headless validation script for Blackspire
## Run with:
##   godot --headless --script res://tests/validate_userinput_test.gd
##
## This acts as a lightweight smoke test / pre-handoff validation.

const TEST_LEVEL_PATH := "res://world/levels/test_level.tscn"
const PLAYER_SCENE_PATH := "res://world/actors/player/Player.tscn"

var passed := 0
var failed := 0

func _init() -> void:
	print("\n=== Blackspire Headless Validation ===\n")
	
	run_validation()
	
	print("\n=== Validation Complete ===")
	print("Passed: %d  |  Failed: %d\n" % [passed, failed])
	
	# Exit with proper code for CI / automation
	var exit_code := 0 if failed == 0 else 1
	quit(exit_code)


func run_validation() -> void:
	validate_project_loads()
	validate_test_level_loads()
	validate_player_can_spawn()
	validate_player_controller_structure()
	# Future ideas:
	# validate_input_actions_exist()
	# validate_no_critical_resource_errors()


func validate_project_loads() -> void:
	print("• Checking if project can load TestLevel...")
	var level_scene := load(TEST_LEVEL_PATH)
	if level_scene == null:
		fail("Could not load TestLevel at %s" % TEST_LEVEL_PATH)
	else:
		pass_test("TestLevel scene loads successfully")


func validate_test_level_loads() -> void:
	print("• Instantiating TestLevel...")
	var level_scene := load(TEST_LEVEL_PATH)
	var level := level_scene.instantiate() as Node
	
	if level == null:
		fail("Failed to instantiate TestLevel")
		return
	
	get_root().add_child(level)
	
	if not level.has_method("get_player_spawns"):
		fail("TestLevel does not have get_player_spawns() method (missing BaseLevel inheritance?)")
	else:
		pass_test("TestLevel instantiated and has expected interface")
	
	# Clean up
	level.queue_free()


func validate_player_can_spawn() -> void:
	print("• Checking player spawn points in TestLevel...")
	var level_scene := load(TEST_LEVEL_PATH)
	var level := level_scene.instantiate() as Node
	get_root().add_child(level)
	
	if not level.has_method("get_player_spawns"):
		fail("Cannot check spawns - missing get_player_spawns()")
		level.queue_free()
		return
	
	var spawns: Array = level.get_player_spawns()
	
	if spawns.is_empty():
		fail("No player spawn points found in TestLevel")
	else:
		pass_test("Found %d player spawn point(s) in TestLevel" % spawns.size())
	
	level.queue_free()


func validate_player_controller_structure() -> void:
	print("• Validating Player controller scene...")
	var player_packed := load(PLAYER_SCENE_PATH)
	if player_packed == null:
		fail("Could not load Player scene at %s" % PLAYER_SCENE_PATH)
		return
	
	var player := player_packed.instantiate() as Node
	
	var has_camera: bool = player.has_node("Camera3D")
	var has_collision: bool = player.has_node("CollisionShape3D")
	
	if not has_camera:
		fail("Player scene is missing Camera3D child")
	else:
		pass_test("Player has Camera3D child")
	
	if not has_collision:
		fail("Player scene is missing CollisionShape3D child")
	else:
		pass_test("Player has CollisionShape3D child")
	
	player.queue_free()


func pass_test(message: String) -> void:
	print("  [PASS] ", message)
	passed += 1


func fail(message: String) -> void:
	print("  [FAIL] ", message)
	failed += 1

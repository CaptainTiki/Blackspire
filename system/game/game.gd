class_name Game
extends Node

## The central "session" container.
## Main creates one of these and tells it what kind of game to run.
##
## Game is responsible for:
## - Loading the appropriate starting scene (Hub or directly into a level)
## - Owning the PlayerSlotManager
## - Managing transitions between Hub <-> Dungeon runs
## - Owning the current world content

@onready var player_slot_manager: PlayerSlotManager = $PlayerSlotManager

## Temporary stand-in until we have a real Hub scene.
@export var test_level_scene: PackedScene = preload("res://world/levels/test_level.tscn")
@export var player_scene: PackedScene = preload("res://world/actors/player/Player.tscn")

var current_session: GameSessionConfig
var current_world: Node = null   # Will hold Hub or Level later
var split_screen_layer: CanvasLayer
var split_screen_root: Control


func start_session(config: GameSessionConfig) -> void:
	current_session = config
	print("Game: Starting session of type ", GameSessionConfig.SessionType.keys()[config.session_type])

	# Create player slots (even if we don't fully use them yet)
	player_slot_manager.create_local_slots(config.local_player_count)

	_load_starting_world()

func _load_starting_world() -> void:
	if not test_level_scene:
		push_error("Game: No test_level_scene assigned!")
		return

	var level := test_level_scene.instantiate() as Level
	if not level:
		push_error("Game: test_level_scene must instantiate a Level.")
		return

	current_world = level
	add_child(current_world)

	print("Game: Loaded test level as temporary world for session type: ", 
		GameSessionConfig.SessionType.keys()[current_session.session_type])

	level.level_ready.connect(_on_level_ready, CONNECT_ONE_SHOT)


func _on_level_ready() -> void:
	var level := current_world as Level
	var players := player_slot_manager.spawn_local_players(level, player_scene)
	if players.is_empty():
		push_error("Game: PlayerSlotManager did not spawn any local players.")
		return

	if current_session.session_type == GameSessionConfig.SessionType.LOCAL_COOP:
		_create_local_coop_viewports()

	print("Game: Spawned %d local player(s)." % players.size())


func _process(_delta: float) -> void:
	_sync_split_screen_cameras()


func _create_local_coop_viewports() -> void:
	if player_slot_manager.get_local_player_count() != 2:
		push_error("Game: First local co-op viewport pass requires exactly 2 local players.")
		return

	if split_screen_layer:
		split_screen_layer.queue_free()

	split_screen_layer = CanvasLayer.new()
	split_screen_layer.name = "LocalCoopSplitScreen"
	split_screen_layer.layer = 0
	add_child(split_screen_layer)

	var backdrop := ColorRect.new()
	backdrop.name = "SplitScreenBackdrop"
	backdrop.color = Color.BLACK
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split_screen_layer.add_child(backdrop)

	split_screen_root = VBoxContainer.new()
	split_screen_root.name = "SplitScreenRoot"
	split_screen_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	split_screen_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split_screen_root.add_theme_constant_override("separation", 4)
	split_screen_layer.add_child(split_screen_root)

	var shared_world := get_viewport().world_3d
	for slot in player_slot_manager.slots:
		_create_slot_viewport(slot, shared_world)

	print("Game: Created 2-player local co-op split-screen viewports.")


func _create_slot_viewport(slot: PlayerSlot, shared_world: World3D) -> void:
	var slot_root := Control.new()
	slot_root.name = "Player%dSplitScreenPane" % (slot.slot_index + 1)
	slot_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_screen_root.add_child(slot_root)

	var container := SubViewportContainer.new()
	container.name = "Player%dViewportContainer" % (slot.slot_index + 1)
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_root.add_child(container)

	var viewport := SubViewport.new()
	viewport.name = "Player%dViewport" % (slot.slot_index + 1)
	viewport.world_3d = shared_world
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)

	var camera := Camera3D.new()
	camera.name = "Player%dViewportCamera" % (slot.slot_index + 1)
	camera.current = true
	viewport.add_child(camera)

	slot.viewport = viewport
	slot.viewport_camera = camera
	_bind_slot_canvas_layers(slot)
	_create_slot_hud(slot, slot_root)


func _sync_split_screen_cameras() -> void:
	if not split_screen_layer:
		return

	for slot in player_slot_manager.slots:
		if not slot.camera or not slot.viewport_camera:
			continue

		slot.viewport_camera.global_transform = slot.camera.global_transform
		slot.viewport_camera.fov = slot.camera.fov
		slot.viewport_camera.near = slot.camera.near
		slot.viewport_camera.far = slot.camera.far


func _bind_slot_canvas_layers(slot: PlayerSlot) -> void:
	if not slot.player:
		push_error("Game: Cannot bind UI without a slot player.")
		return
	if not slot.viewport:
		push_error("Game: Cannot bind UI without a slot viewport.")
		return

	for child in slot.player.get_children():
		if child is CanvasLayer:
			var canvas_layer := child as CanvasLayer
			if canvas_layer is PlayerHUD:
				canvas_layer.visible = false
			canvas_layer.custom_viewport = slot.viewport
			if canvas_layer.has_method("configure_for_split_screen"):
				canvas_layer.configure_for_split_screen()


func _create_slot_hud(slot: PlayerSlot, slot_root: Control) -> void:
	var label := Label.new()
	label.name = "Player%dHPLabel" % (slot.slot_index + 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	label.offset_left = 12.0
	label.offset_top = -34.0
	label.offset_right = 170.0
	label.offset_bottom = -8.0
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82, 1.0))
	slot_root.add_child(label)
	slot.split_screen_hud_label = label

	var health := slot.player.health as HealthComponent
	_update_slot_hud(health.current_health, health.max_health, slot)
	health.health_changed.connect(_update_slot_hud.bind(slot))


func _update_slot_hud(current_health: int, max_health: int, slot: PlayerSlot) -> void:
	if not slot.split_screen_hud_label:
		return

	slot.split_screen_hud_label.text = "P%d HP %d/%d" % [slot.slot_index + 1, current_health, max_health]

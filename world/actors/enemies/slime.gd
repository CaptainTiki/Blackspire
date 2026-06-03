extends "res://world/actors/enemies/enemy.gd"
class_name Slime

## First state-machine enemy for the Multiplayer Playthrough Slice.
## Melee pressure slime. Uses the shared Enemy base + StateChart + mirrored states.
## Visuals and behavior are still prototype (capsule + tweens + contract animations).

@export var slime_color: Color = Color(0.2, 0.65, 0.25, 1.0)

func _ready() -> void:
	super()
	# Apply slime look
	if mesh and _mesh_material:
		_mesh_material.albedo_color = slime_color
		_base_albedo_color = slime_color
	# Slightly different defaults for "slime" feel (can be tuned per instance via exports too)
	# move_speed etc inherited; override here if desired for this type.
	# e.g. move_speed = 2.8
	print("Slime spawned (state machine): ", name)

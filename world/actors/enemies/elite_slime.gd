extends "res://world/actors/enemies/slime.gd"
class_name EliteSlime

## Elite variant of the melee Slime — the arena centerpiece.
## Pure stat/visual overrides on top of Slime: tankier, harder-hitting, and a
## little slower with a longer, more readable windup so the lunge cycle is easy
## to react to and punish around the arena pillars.
##
## NOTE: physical size lives in the SCENE root transform (elite_slime.tscn), not
## here. Level captures the authored scale before spawning and restores it after
## placing the enemy, so setting `scale` in _ready would be clobbered.

@export var elite_health: int = 90
@export var elite_color: Color = Color(0.55, 0.12, 0.42, 1.0)


func _ready() -> void:
	# Tougher and harder-hitting than a basic slime, slower with a clearer tell.
	move_speed = 2.0
	attack_damage = 18
	attack_range = 3.5
	attack_cooldown = 1.2
	attack_windup = 0.5
	attack_lunge_distance = 4.5
	attack_lunge_duration = 0.4
	attack_hit_range = 2.2
	attack_hit_cone_degrees = 80.0
	aggro_range = 12.0
	slime_color = elite_color

	# Slime._ready applies slime_color to the material; Enemy._ready wires the rest.
	super()

	# HealthComponent._ready already ran (children ready before parent), so bump
	# the pool now and refresh listeners (health bar, etc.).
	if health:
		health.max_health = elite_health
		health.current_health = elite_health
		health.health_changed.emit(elite_health, elite_health)

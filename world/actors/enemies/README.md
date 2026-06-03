# Enemy Architecture (State Machine)

This directory contains the new state-machine-driven enemy foundation for the Multiplayer Playthrough Slice.

Current temporary implementation (`basic_enemy.gd` + `enemy_behavior.gd` enum brain + `basic_enemy.tscn`) is **left as-is** for now. New enemies (starting with Slime) use the clean `Enemy` + `StateChart` + mirrored `EnemyStateMachine` pattern, modeled directly after the player controller.

## Core Files

- `enemy.gd` — `class_name Enemy` (extends CharacterBody3D). New base for all future enemies. Owns common API, network replication surface, health/hurtbox wiring, visual feedback tweens (proto), motor helpers, target perception, animation contract enforcement, authority checks, die/decompose, snapshots.
- `enemy_base_state.gd` — `class_name EnemyState`. Base that state logic nodes extend (by path string to avoid load-order issues).
- `enemy_state_machine.gd` — `class_name EnemyStateMachine`. The mirror node that lives next to the `StateChart`. Owns debug label, pushes expression properties (distance, has target, authority) every frame, provides active state text for the label.
- `slime.gd` — `class_name Slime extends Enemy`. First concrete implementation. Sets slime-specific visuals/defaults.
- `slime.tscn` — The scene using the above. Includes `StateChart`, `StateMachine` mirror, `AnimationPlayer`, `Components/HealthComponent` + `Hurtbox`, health bar, debug label, death timer, mesh + collision.
- `states/` — Mirrored logic:
  - `enemy_idle_state.gd`
  - `enemy_chase_state.gd`
  - `enemy_windup_state.gd`
  - `enemy_lunge_state.gd`
  - `enemy_recover_state.gd`
  - `enemy_hurt_state.gd`
  - `enemy_dead_state.gd`

## State Chart Shape (in slime.tscn and future enemies)

```
StateChart
└─ Root (compound)
   └─ Behavior (compound, initial=Idle)
      ├─ Idle
      ├─ Chase
      ├─ Windup
      ├─ Lunge
      ├─ Recover
      ├─ Hurt   (interruptible)
      └─ Dead
```

Transitions are mostly event-driven (`onChase`, `onWindup`, `onLunge`, `onRecover`, `onHurt`, `onIdle`, `onDead`).

States in the mirror tree (`StateMachine/Root/BehaviorState/XXXState`) receive `state_entered` and `state_physics_processing` signals from the corresponding chart nodes and implement the matching `_on_xxx_state_...` methods.

## Contracts (All State-Machine Enemies)

1. **AnimationPlayer**
   - Must have a direct child `AnimationPlayer` at `$AnimationPlayer`.
   - Use the base helper: `enemy.play_animation(&"idle")` (or direct).
   - **Standard clip names** (required for consistency):
     - `"idle"`
     - `"move"`
     - `"windup"`
     - `"lunge"`
     - `"hurt"`
     - `"death"`
   - `play_animation` will warn (but not crash) on missing clips during proto. Real art passes must provide these clips.
   - Example in states:
     ```gdscript
     enemy.play_animation(&"idle")
     ```

2. **Scene Structure (minimum)**
   - Root: CharacterBody3D with `script = slime.gd` (or subclass of Enemy)
   - `CollisionShape3D` (capsule etc.)
   - `MeshInstance3D` (for proto feedback tweens + material)
   - `$AnimationPlayer`
   - `Components/HealthComponent`
   - `Components/Hurtbox` (Area3D with script + collision, damage_target pointing to root)
   - `DebugStateLabel` (Label3D)
   - `DeathTimer` (Timer)
   - Optional: HealthBar (WorldHealthBar3D), AttackRangeDebug, etc.
   - `%StateChart` (unique name) + tree
   - `StateMachine` node (with `enemy` and `debug_label` exports wired) + mirror tree of state nodes

3. **Network / Authority**
   - Implement (or inherit) the surface used by Level:
     - `network_enemy_id`, `is_dead`, `is_network_authority`
     - `set_network_enemy_id(id)`
     - `set_network_authority_enabled(bool)` — clients set false; AI logic in states must early-return if `not enemy.is_network_authority`
     - `get_network_state() -> Dictionary`
     - `apply_network_state(pos, yaw, is_dead)`
     - `apply_network_death()`
   - Authority enemies run full state logic + chart.
   - Remote/presentation copies receive snapshots and death; they can still play hurt/death anims via the methods.

4. **Target / Combat**
   - Use `enemy.update_target()`, `enemy.has_valid_target()`, `enemy.distance_to_target()`.
   - `alert_to_player(p)` forces target and should send `onChase` (or equivalent).
   - Damage goes through `apply_damage(damage_request)` which respects authority then forwards to HealthComponent.
   - On hit: health signal → Enemy plays hurt reaction + floating number + `play_animation(&"hurt")` + sends `onHurt` event.

5. **Motor Verbs (preferred over direct velocity edits)**
   - `face_target()`
   - `apply_horizontal_velocity(dir, speed)`
   - `stop_horizontal_movement()`
   - `move_with_gravity(delta)`
   - States set velocity via these then call move.

6. **Debug**
   - `set_debug_state("CHASE")` updates the Label3D.
   - StateMachine pushes expression props and renders the multi-line active states when its `debug` export is true (wired in scene).

## How States Work (example)

```gdscript
# enemy_chase_state.gd
func _on_chase_state_physics_processing(delta: float) -> void:
	if not enemy or not enemy.is_network_authority: return
	enemy.update_target()
	if not enemy.has_valid_target():
		enemy.state_chart.send_event(&"onIdle")
		return
	if enemy.distance_to_target() <= enemy.attack_range:
		enemy.state_chart.send_event(&"onWindup")
		return
	enemy.face_target()
	enemy.apply_horizontal_velocity(dir, enemy.move_speed)
	enemy.move_with_gravity(delta)
```

One-shot or timer-driven states (windup, hurt) often do work in `_entered` and either defer or use a small timer var + physics check to send the next event.

## Adding a New Enemy Type

1. Create `new_enemy.gd` : `extends "res://world/actors/enemies/enemy.gd"; class_name NewEnemy`
2. (Optional) Override defaults, colors, play different sounds, etc. in `_ready` after super.
3. Create `new_enemy.tscn` (duplicate slime.tscn, change script + material + any unique nodes, keep the StateChart + StateMachine trees + connections).
4. If the behavior tree differs significantly, you may need extra states or a different chart layout under Behavior — keep the same event names where possible for shared systems.
5. Add to `trenchbroom/entities/` a new .tres FGD point class pointing at the .tscn (or reuse info_enemy_spawn with a property).
6. Update Level.gd exports + spawn helpers + any `as BasicEnemy` / return types to be polymorphic (prefer `has_method` or `is Enemy` checks).
7. Document new states in this README and the enemy’s own notes if complex.

## Multiplayer Notes

- State transitions and semantic events (`onLunge`, health changes, death) are the future replication hooks.
- Do **not** bind replication to node paths, temp animation names, or one-off tweens.
- For this slice: new slime works in SP and local co-op. Online: host runs AI, clients receive snapshots + play presentation (hurt/death anims still fire via apply_network_* and health signals).

## Current Limitations / Next

- No patrol/idle wander yet (pure wait in Idle until aggro).
- No per-enemy blackboard or perception component (target finding is simple in base; can be extracted later).
- Visuals are still capsule + squash tweens + contract anims (real slime mesh + particles come with VFX pass).
- Range debug visuals omitted in slime.tscn for cleanliness (re-add if tuning needs them).
- Elite will likely be a heavier Slime variant or separate with more states/phases.

See `docs/multiplayer_playthrough_slice_plan.md` for the overall enemy plan (melee slime → spitter → elite) and `docs/project_blackspire_architecture.md` (EnemyActor example, state chart split, components).

Re-read the player README and architecture before changing the chart shape significantly.

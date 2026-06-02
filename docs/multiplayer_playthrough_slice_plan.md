# Multiplayer Playthrough Slice Plan

**Last Updated:** 2026-06-02

## Purpose

Build the first five-minute Blackspire playthrough that is fun enough to sit real players in front of.

This is **not** a demo and not production polish. It is still allowed to be janky. The goal is to answer:

```text
Is the core co-op dungeon loop fun with another person?
```

Networking and local co-op have been proven enough to stop chasing temporary sync hooks. The next work should improve the actual feel of the game while preserving the session architecture we just validated.

## Proven Foundation

The project now has a working session spine:

- Single Player, Local Co-op, Host, and Client sessions use the same `Game` flow.
- `PlayerSlot` represents session participants rather than only local input devices.
- Hub -> run -> hub works locally and in a two-instance host/client session.
- Remote player presence, movement, rotation, jumping, and primary-action presentation replicate.
- Enemy authority can live on the host.
- Client combat intent can be forwarded to the host and resolved there.

The remaining online bugs are known authority gaps and are tracked in `docs/network_known_issues.md`.

## Slice Goal

Create a compact multiplayer-ready dungeon experience:

```text
spawn room -> cramped fight -> lock-in panic fight -> elite arena -> locked exit
```

The run should be short, readable, and replayable enough to judge:

- player movement feel
- melee timing and impact
- enemy attack readability
- room pacing
- co-op pressure
- revive/downed tension
- basic audio/visual feedback

## Non-Goals

- no production art
- no final networking authority pass
- no matchmaking or internet polish
- no full inventory/stash replication
- no complete animation set
- no procedural room library expansion beyond what this slice needs
- no public-demo polish pass

## Design Pillars

- **Readable combat first.** Players should understand why they got hit and when they have an opening.
- **Small rooms, real pressure.** Combat should happen in shaped spaces, not empty boxes.
- **Co-op naturally matters.** One player can kite, revive, distract, or cover while another attacks.
- **State-machine hooks from day one.** Gameplay state transitions should be obvious places for VFX, SFX, UI, and future network replication.
- **Prototype speed.** Tune quickly, verify quickly, and avoid building permanent-looking systems before the feel is proven.

## Player Rebuild

Replace the temporary player/combat controller with a new state-machine-driven player foundation.

### Requirements

- visible player mesh
- first pass animation states:
  - idle
  - move
  - attack
  - hurt
  - downed
  - revive or get-up, if cheap
- tunable controller values for fast iteration:
  - walk speed
  - sprint speed
  - acceleration/deceleration
  - turn/look feel
  - jump, if we keep jump for the slice
  - attack windup/active/recovery timing
- clear semantic events:
  - attack started
  - attack active
  - attack hit confirmed
  - hurt
  - downed
  - revived
  - died

### Multiplayer Shape

Do not wire deep networking first. Do design the player so the hooks are obvious:

- local input produces player intent
- state machine produces state facts and semantic events
- host can own health/downed/combat results later
- clients can play presentation from replicated state/events later

## Enemy Rebuild

Replace the current single basic enemy with three prototype enemies using state machines/state charts.

### Slime

Melee pressure enemy.

- idle / patrol or wait
- aggro
- chase
- windup
- lunge or bite
- recover
- hurt
- death

Purpose: prove basic spacing, melee tells, and swarm readability.

### Ranged Spitter

Ranged harassment enemy.

- idle
- aggro
- reposition
- aim/windup
- spit projectile
- recover
- hurt
- death

Purpose: force movement, dodging, line-of-sight awareness, and co-op target prioritization.

### Elite Slime

Arena-style mini-boss.

- melee attack
- ranged spit
- heavier health pool
- longer readable tells
- phase-like pressure through attack selection, even if simple

Purpose: create a one-minute-plus fight where players trade turns attacking, dodging, reviving, and repositioning.

## Room Set

Author five silver-standard rooms.

Silver-standard means:

- still placeholder textures
- not production set dressing
- real layout composition
- readable paths and combat spaces
- clear mapper-authored spawn/door/lever/extraction intent

### Rooms

1. **Spawn Room**
   - safe entry
   - gives players a moment to orient

2. **Cramped Combat Room**
   - small, close, uncomfortable
   - proves melee spacing and collision feel

3. **Lock-In Panic Room**
   - door closes or locks behind players
   - several small enemies
   - "oh crap" moment
   - introduces multiplayer pressure without an elite

4. **Elite Arena**
   - one elite slime
   - enough space to dodge and rotate
   - fight should last roughly one minute or more in prototype tuning

5. **Locked Exit Room**
   - exit is behind a door/lever or simple encounter gate
   - reintroduces doors/levers into the playable session
   - sets up future network sync for interactable world state

## VFX Pass

Add lightweight prototype effects for:

- player swing trail or impact flash
- enemy hit burst
- enemy death pop
- projectile impact
- downed/revive cue if cheap

These should be cheap and replaceable. Their job is to prove timing and readability.

## SFX Pass

Add rough sound cues, even if they are placeholder or mouth-noise quality:

- player swing
- weapon hit
- player hurt
- slime aggro/attack/hurt/death
- spitter windup/fire/impact
- door/lever
- pickup or reward cue if still present

The goal is to prove that actions have audio timing, not to create final sound design.

## Networking Guidance For This Slice

Keep the session spine intact, but avoid chasing every new temporary gameplay detail into netcode immediately.

When adding systems, ask:

- What is the eventual host-owned truth?
- What is local input intent?
- What is presentation-only?
- What event/state should future replication listen to?

Good hook shapes:

- `state_changed(previous, next)`
- `attack_started(attack_id)`
- `attack_active(attack_id)`
- `attack_hit_confirmed(target_id, hit_position, damage)`
- `health_changed(current, max)`
- `life_state_changed(state)`
- `door_state_changed(open/closed/locked)`

Avoid hooks that depend on temporary node paths, animation-player names, or one-off presentation scripts.

## Suggested Implementation Order

1. New player controller/state machine prototype.
2. Slime enemy state machine.
3. Cramped combat room.
4. Hit VFX/SFX for player vs slime.
5. Ranged spitter.
6. Lock-in panic room.
7. Elite slime.
8. Elite arena room.
9. Locked exit room with door/lever/extraction path.
10. First full five-minute playthrough tuning pass.

## Done For This Slice

- A player can complete the five-room run in single-player.
- Two local players can complete the five-room run.
- Host/client can still connect, deploy, move, and complete at least a rough version of the run, even if some new gameplay details remain host/local only.
- Combat has visible and audible feedback.
- Rooms feel shaped enough to judge pacing.
- The player/enemy code now has clean state/event hooks for the future networking pass.

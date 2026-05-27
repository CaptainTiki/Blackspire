extends MoveableProp
class_name UrnDebris

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var time_to_live: float = 15.0

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = time_to_live
	timer.one_shot = true
	add_child(timer)
	timer.start()

	timer.timeout.connect(_play_shrink_animation)

func _play_shrink_animation() -> void:
	animation_player.play("shrink")
	animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func _on_animation_finished(_anim_name: StringName) -> void:
	queue_free()

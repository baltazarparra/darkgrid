class_name FeedbackSystem
extends Node

@export var shake_intensity: float = 8.0
@export var shake_duration: float = 0.3

func trigger_screenshake(intensity: float = shake_intensity, duration: float = shake_duration) -> void:
    var camera := get_viewport().get_camera_2d()
    if camera == null:
        return
    var original_offset := camera.offset
    var tween := create_tween()
    tween.tween_method(_shake_camera.bind(camera), intensity, 0.0, duration)
    tween.tween_callback(func(): camera.offset = original_offset)

func _shake_camera(amount: float, camera: Camera2D) -> void:
    camera.offset = Vector2(
        randf_range(-amount, amount),
        randf_range(-amount, amount)
    )

func spawn_impact_particles(position: Vector2) -> void:
    var particles := preload("res://scenes/shared/impact_particles.tscn").instantiate()
    particles.position = position
    get_tree().current_scene.add_child(particles)
    particles.restart()
    await get_tree().create_timer(particles.lifetime + 0.1).timeout
    particles.queue_free()

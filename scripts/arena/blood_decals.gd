class_name BloodDecals
extends Node2D

## Sangue persistente no chão da arena: cada golpe/morte projeta manchas que
## ACUMULAM a luta inteira e secam com o tempo (fresco → seco escuro). O chão
## conta a história do combate. Escuta FeedbackSystem.blood_spilled — não
## conhece atores nem timing.
##
## Custo: redesenho só ao ganhar splat novo e a cada DRY_REDRAW_S (secagem).

const MAX_SPLATS: int = 250
# Projeta o respingo do centro do ator para o chão sob os pés.
const GROUND_OFFSET: float = 26.0
const DRY_TIME_S: float = 14.0
const DRY_REDRAW_S: float = 2.0

var _splats: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	# Entre o chão do backdrop (-20) e os atores (0).
	z_index = -10
	var dry_timer := Timer.new()
	dry_timer.wait_time = DRY_REDRAW_S
	dry_timer.autostart = true
	dry_timer.timeout.connect(queue_redraw)
	add_child(dry_timer)

## intensity: 1.0 golpe comum, ~1.6 crítico, ~2.6 morte (poça grande).
func add_splat(at: Vector2, intensity: float) -> void:
	var ground := Vector2(at.x, at.y + GROUND_OFFSET)
	var count: int = 2 + int(intensity * 2.0)
	var now: float = Time.get_ticks_msec() / 1000.0
	for i: int in count:
		var off := Vector2(
			_rng.randf_range(-26.0, 26.0) * intensity,
			_rng.randf_range(-9.0, 9.0) * intensity)
		var r: float = _rng.randf_range(2.5, 6.5) * (0.7 + intensity * 0.45)
		# Satélites pré-computados: a forma da mancha é fixa, só a cor seca.
		var blobs: Array[Vector3] = [Vector3(0.0, 0.0, r)]
		for j: int in 2:
			blobs.append(Vector3(
				_rng.randf_range(-r, r) * 1.4,
				_rng.randf_range(-r, r) * 0.5,
				r * _rng.randf_range(0.35, 0.65)))
		_splats.append({"pos": ground + off, "blobs": blobs, "born": now})
	while _splats.size() > MAX_SPLATS:
		_splats.pop_front()
	queue_redraw()

func _draw() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	for splat: Dictionary in _splats:
		var age: float = clampf((now - splat["born"]) / DRY_TIME_S, 0.0, 1.0)
		var color: Color = Constants.COLOR_BLOOD_POOL.lerp(
			Constants.COLOR_BLOOD_POOL_DARK, age)
		var pos: Vector2 = splat["pos"]
		for blob: Vector3 in splat["blobs"]:
			draw_circle(pos + Vector2(blob.x, blob.y), blob.z, color)

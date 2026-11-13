
extends TileMapLayer

const LADDER_SOURCE_ID: int = 0
const LADDER_ATLAS_COORDS: Vector2i = Vector2i(1, 1)
const TILE_SIZE: int = 16
const LADDER_DETECTOR_SCRIPT = preload("res://scripts/ladder_detector.gd")

func _ready() -> void:
	create_ladder_detectors()

func create_ladder_detectors() -> void:
	var ladder_columns: Dictionary = {}

	for cell in get_used_cells():
		var source_id: int = get_cell_source_id(cell)
		var atlas_coords: Vector2i = get_cell_atlas_coords(cell)

		if source_id == LADDER_SOURCE_ID and atlas_coords == LADDER_ATLAS_COORDS:
			if not ladder_columns.has(cell.x):
				ladder_columns[cell.x] = []

			ladder_columns[cell.x].append(cell.y)

	for column_x in ladder_columns:
		var rows: Array = ladder_columns[column_x]
		rows.sort()

		var start_y: int = rows[0]
		var previous_y: int = rows[0]

		for i in range(1, rows.size()):
			var current_y: int = rows[i]

			if current_y != previous_y + 1:
				create_detector(column_x, start_y, previous_y)
				start_y = current_y

			previous_y = current_y

		create_detector(column_x, start_y, previous_y)


func create_detector(column_x: int, start_y: int, end_y: int) -> void:
	var detector := Area2D.new()
	detector.name = "LadderDetector_%d_%d" % [column_x, start_y]
	detector.set_script(LADDER_DETECTOR_SCRIPT)
	detector.body_entered.connect(Callable(detector, "_on_body_entered"))
	detector.body_exited.connect(Callable(detector, "_on_body_exited"))
	
	# NEW PROPERTY: Tell the detector where its topmost pixel edge sits globally
	# We map the tile coordinate to its local/global coordinate and subtract half a tile to get the crisp top edge line
	var top_local_pos = map_to_local(Vector2i(column_x, start_y))
	detector.set_meta("ladder_top_y", to_global(top_local_pos).y - (TILE_SIZE / 2.0))

	var shape_node := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()

	rectangle.size = Vector2(TILE_SIZE, (end_y - start_y + 1) * TILE_SIZE)
	shape_node.shape = rectangle

	var bottom_right := map_to_local(Vector2i(column_x, end_y))
	detector.position = (top_local_pos + bottom_right) / 2.0

	detector.add_child(shape_node)
	add_child(detector)

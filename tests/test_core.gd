extends SceneTree

var checks: int = 0
var failures: int = 0

func expect(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
	checks += 1

func _initialize() -> void:
	var config: DifficultyConfig = load("res://resources/easy.tres")
	var path := PathGenerator.generate(817294, 3, 10)
	expect(path == PathGenerator.generate(817294, 3, 10), "Paths must repeat for a fixed seed")
	expect(path != PathGenerator.generate(817295, 3, 10), "Different seeds should vary this fixture")
	expect(path == [2, 2, 2, 2, 0, 0, 2, 1, 2, 0], "Version 1 golden path must never silently change")
	for seed_value in range(100):
		var generated := PathGenerator.generate(seed_value, config.lane_count, config.row_count)
		expect(generated.size() == 10, "Exactly ten rows")
		for lane in generated:
			expect(lane >= 0 and lane < 3, "Lane must be in range")
	var run := RunState.new()
	run.reset(817294, config)
	expect(not run.select(0, 0, 3), "No input before preview")
	expect(run.begin_preview(), "Preview starts")
	expect(not run.select(0, 0, 3), "No input during preview")
	run.finish_preview()
	expect(not run.select(1, 0, 3), "Cannot skip rows")
	expect(not run.select(0, -1, 3), "Cannot select invalid lane")
	for row in 10:
		expect(run.select(row, run.path[row], 3), "Correct row accepted")
		expect(not run.select(row, run.path[row], 3), "Multi-tap rejected")
		expect(run.land(), "Correct tile survives")
	expect(run.phase == RunState.Phase.COMPLETE, "Last row completes path")
	expect(not run.select(10, 0, 3), "No input after completion")
	run.reset(817294, config)
	run.begin_preview()
	run.finish_preview()
	run.select(0, (run.path[0] + 1) % 3, 3)
	expect(not run.land(), "Wrong tile falls")
	expect(run.completed_rows == 0, "Failure does not inflate score")
	expect(not run.select(0, run.path[0], 3), "Input during falling rejected")
	print("Core checks: ", checks)
	quit(1 if failures else 0)

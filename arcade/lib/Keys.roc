# Keys -- the keys a game can ask about.
#
# Hand-written, and named as roc-ray names it: `Keys.Key` is the enum,
# `Devices.Snapshot` is what a tick is handed. Keeping both names means a
# game's `read_controls` ports with its import line changed and nothing else.

Keys :: [].{
	# The keys a game here can ask about. A tick sends two bit sets, so the
	# list is short on purpose: adding one is a bit and a line in game_runner.js.
	Key := [KeyUp, KeyDown, KeyLeft, KeyRight, KeyW, KeyA, KeyS, KeyD, KeySpace, KeyEscape, KeyEnter, KeyF, KeyP, KeyR].{
		is_eq : _
	}

	bit : Keys.Key -> U32
	bit = |key|
		match key {
			KeyUp => 1
			KeyDown => 2
			KeyLeft => 4
			KeyRight => 8
			KeyW => 16
			KeyA => 32
			KeyS => 64
			KeyD => 128
			KeySpace => 256
			KeyEscape => 512
			KeyEnter => 1024
			KeyF => 2048
			KeyP => 4096
			KeyR => 8192
		}
}

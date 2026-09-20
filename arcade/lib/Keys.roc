# Keys -- the keys a game can ask about.
#
# Hand-written, and named as roc-ray names it: `Keys.Key` is the enum,
# `Input.Snapshot` is what a tick is handed, shaped like roc-ray's
# `Devices.Snapshot`. Keeping the key names means a
# game's `read_controls` ports with its import line changed and nothing else.

Keys :: [].{
	# The keys a game here can ask about. A tick sends two bit sets, so the
	# list is short on purpose: adding one is a bit and a line in
	# game_runner.js.
	#
	# **ESCAPE AND F ARE NOT HERE.** They belong to the runners -- Escape
	# closes a native window and F shows its frame rate -- and a page can do
	# neither. A key a game could bind on one end and not the other is a key
	# that behaves differently on the two, so no game is given them at all.
	Key := [KeyUp, KeyDown, KeyLeft, KeyRight, KeyW, KeyA, KeyS, KeyD, KeySpace, KeyEnter, KeyP, KeyR, KeyQ, KeyE].{
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
			KeyEnter => 512
			KeyP => 1024
			KeyR => 2048
			KeyQ => 4096
			KeyE => 8192
		}
}

# Keys -- which keys are held and which were struck this tick.
#
# Hand-written, and shaped deliberately like roc-ray's `Devices.Snapshot`: a
# game's `read_controls` is the one function that touches the keyboard, and it
# takes a snapshot as a VALUE rather than performing an effect. Matching the
# shape means such a function ports between the two platforms with its import
# line changed and nothing else.
#
# **A SNAPSHOT IS DATA, SO A PAGE CAN MAKE ONE.** The browser's event loop owns
# the keyboard, keeps the set of keys currently down, and hands one of these to
# every tick. On roc-ray the player converts the host's snapshot into one.
#
# `pressed` is the edge -- struck since the last tick -- and implies `down`.
# Snake turns on the edge; Pong's paddle moves while a key is held.

Keys :: [].{
	# The keys a game here can ask about. A tick sends two bit sets, so the
	# list is short on purpose: adding one is a bit and a line in blitter.js.
	Key := [KeyUp, KeyDown, KeyLeft, KeyRight, KeyW, KeyA, KeyS, KeyD, KeySpace, KeyEscape, KeyEnter, KeyP, KeyR].{
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
			KeyP => 2048
			KeyR => 4096
		}

	Snapshot := { held : U32, struck : U32 }.{
		## Whether a key is held down now, however long it has been.
		key_down : Snapshot, Keys.Key -> Bool
		key_down = |snapshot, key| U32.bitwise_and(snapshot.held, bit(key)) != 0

		## Whether a key went down since the last tick.
		key_pressed : Snapshot, Keys.Key -> Bool
		key_pressed = |snapshot, key| U32.bitwise_and(snapshot.struck, bit(key)) != 0

		## Say that a key is held, as `Keys.none.with_key_down(KeyW)`.
		with_key_down : Snapshot, Keys.Key -> Snapshot
		with_key_down = |snapshot, key| Snapshot.{ held: U32.bitwise_or(snapshot.held, bit(key)), struck: snapshot.struck }

		## Say that a key was struck, which is also held.
		with_key_pressed : Snapshot, Keys.Key -> Snapshot
		with_key_pressed = |snapshot, key|
			Snapshot.{ held: U32.bitwise_or(snapshot.held, bit(key)), struck: U32.bitwise_or(snapshot.struck, bit(key)) }
	}

	## No key at all: what a movie that ignores the keyboard is handed, and
	## what a test starts from.
	none : Keys.Snapshot
	none = Snapshot.{ held: 0, struck: 0 }

	## The two bit sets as they arrive from a player.
	of : U32, U32 -> Keys.Snapshot
	of = |held, struck| Snapshot.{ held: U32.bitwise_or(held, struck), struck }
}

# Input -- what the keyboard and the mouse looked like at one tick.
#
# Hand-written, and shaped deliberately like roc-ray's `Devices.Snapshot`: a
# game's `read_controls` is the one function that touches input, and it takes a
# snapshot as a VALUE rather than performing an effect. Matching the shape --
# `key_down`, `mouse.button_pressed`, the lot -- means
# such a function ports between the two platforms with its import line changed
# and nothing else.
#
# **A SNAPSHOT IS DATA, SO A PAGE CAN MAKE ONE.** The browser's event loop owns
# the keyboard and the pointer, keeps what is down, and hands one of these to
# every tick. On roc-ray the runner converts the host's snapshot into one.
#
# `pressed` is the edge -- struck since the last tick -- and implies `down`.
# Snake turns on the edge; Pong's paddle moves while a key is held.
import Keys
import Mouse

Input :: [].{
	# `mouse` is a field rather than a method, so a game reaches the pointer
	# exactly as it does on roc-ray: `input.mouse.position()`.
	Snapshot := { held : U32, struck : U32, mouse : Mouse.Snapshot }.{
		## Whether a key is held down now, however long it has been.
		key_down : Snapshot, Keys.Key -> Bool
		key_down = |snapshot, key| U32.bitwise_and(snapshot.held, Keys.bit(key)) != 0

		## Whether a key went down since the last tick.
		key_pressed : Snapshot, Keys.Key -> Bool
		key_pressed = |snapshot, key| U32.bitwise_and(snapshot.struck, Keys.bit(key)) != 0

		## Say that a key is held, as `Input.none.with_key_down(KeyW)`.
		with_key_down : Snapshot, Keys.Key -> Snapshot
		with_key_down = |s, key| Snapshot.{ held: U32.bitwise_or(s.held, Keys.bit(key)), struck: s.struck, mouse: s.mouse }

		## Say that a key was struck, which is also held.
		with_key_pressed : Snapshot, Keys.Key -> Snapshot
		with_key_pressed = |s, key|
			Snapshot.{ held: U32.bitwise_or(s.held, Keys.bit(key)), struck: U32.bitwise_or(s.struck, Keys.bit(key)), mouse: s.mouse }

		## Give a snapshot its pointer, as roc-ray's `with_mouse_*` do.
		with_mouse : Snapshot, Mouse.Snapshot -> Snapshot
		with_mouse = |s, pointer| Snapshot.{ held: s.held, struck: s.struck, mouse: pointer }

	}

	## Nothing touched: what a test starts from.
	none : Input.Snapshot
	none = Snapshot.{ held: 0, struck: 0, mouse: Mouse.none }

	## What a runner packs a tick's input into.
	of : U32, U32, Mouse.Snapshot -> Input.Snapshot
	of = |held, struck, mouse| Snapshot.{ held: U32.bitwise_or(held, struck), struck, mouse }
}

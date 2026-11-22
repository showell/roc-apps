## Input is what the keyboard and the mouse looked like at one tick.
##
## It is shaped like roc-ray's `Devices.Snapshot` on purpose. A game's
## `read_controls` is the one function that touches input, and it takes a
## snapshot as a value rather than performing an effect, so with `key_down`,
## `mouse.button_pressed` and the rest named alike, a game that starts from one
## of roc-ray's examples keeps that function with its import line changed.
##
## A snapshot is data, so a page can make one. The browser's event loop owns
## the keyboard and the pointer, keeps what is down, and hands one of these to
## every tick.
##
## `pressed` is the edge, struck since the last tick, and implies `down`.
## Snake turns on the edge, and Pong's paddle moves while a key is held.
import Keys
import Mouse

Input :: [].{

	## `mouse` is a field rather than a method, so a game reaches the pointer
	## as roc-ray's examples do: `input.mouse.position()`.
	Snapshot := {
		held : U32,
		struck : U32,
		mouse : Mouse.Snapshot,
	}.{

		## Whether a key is held down now, however long it has been.
		key_down : Snapshot, Keys.Key -> Bool
		key_down = |snapshot, key| U32.bitwise_and(snapshot.held, Keys.bit(key)) != 0

		## Whether a key went down since the last tick.
		key_pressed : Snapshot, Keys.Key -> Bool
		key_pressed = |snapshot, key| U32.bitwise_and(snapshot.struck, Keys.bit(key)) != 0

		## Say that a key is held, as `Input.none.with_key_down(KeyW)`. Tests build
		## a tick's snapshot with this and `with_key_pressed`.
		with_key_down : Snapshot, Keys.Key -> Snapshot
		with_key_down = |snapshot, key| Snapshot.{
			held: U32.bitwise_or(snapshot.held, Keys.bit(key)),
			struck: snapshot.struck,
			mouse: snapshot.mouse,
		}

		## Say that a key was struck, which is also held.
		with_key_pressed : Snapshot, Keys.Key -> Snapshot
		with_key_pressed = |snapshot, key|
			Snapshot.{
				held: U32.bitwise_or(snapshot.held, Keys.bit(key)),
				struck: U32.bitwise_or(snapshot.struck, Keys.bit(key)),
				mouse: snapshot.mouse,
			}

		## Give a snapshot its pointer, as roc-ray's `with_mouse_*` do.
		with_mouse : Snapshot, Mouse.Snapshot -> Snapshot
		with_mouse = |snapshot, pointer| Snapshot.{
			held: snapshot.held,
			struck: snapshot.struck,
			mouse: pointer,
		}

	}

	## Nothing touched: where a test starts a tick's snapshot.
	none : Input.Snapshot
	none = Snapshot.{
		held: 0,
		struck: 0,
		mouse: Mouse.none,
	}

	## A tick's input from the keys held and struck, as bits, and the pointer,
	## which is how WasmApp packs what the page hands it.
	of : {
		held : U32,
		struck : U32,
		mouse : Mouse.Snapshot,
	} -> Input.Snapshot
	of = |{ held, struck, mouse }| Snapshot.{
		held: U32.bitwise_or(held, struck),
		struck,
		mouse,
	}
}

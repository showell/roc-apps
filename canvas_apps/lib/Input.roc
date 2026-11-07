## Input is what the keyboard and the mouse looked like at one tick.
##
## It mirrors roc-ray's Devices.Snapshot but is named for roc-ray's App.Input,
## a tick's whole input, which on roc-ray also carries the window, the time
## and messages. CanvasAppRunner imports both modules, and two nominal types
## with the same qualified name are ambiguous to the compiler, which still
## reports two `Devices.Snapshot`s when roc-ray's module is imported under
## another name. Mouse can share roc-ray's name because its type never has to
## be named on both sides of one signature.
##
## It is shaped like roc-ray's `Devices.Snapshot` on purpose. A game's
## `read_controls` is the one function that touches input, and it takes a
## snapshot as a value rather than performing an effect, so with `key_down`,
## `mouse.button_pressed` and the rest named alike, such a function ports
## between the two platforms with its import line changed and nothing else.
##
## A snapshot is data, so a page can make one. The browser's event loop owns
## the keyboard and the pointer, keeps what is down, and hands one of these to
## every tick. On roc-ray the runner converts the host's snapshot into one.
##
## `pressed` is the edge, struck since the last tick, and implies `down`.
## Snake turns on the edge, and Pong's paddle moves while a key is held.
import Keys
import Mouse

Input :: [].{

	## `mouse` is a field rather than a method, so a game reaches the pointer
	## exactly as it does on roc-ray: `input.mouse.position()`.
	Snapshot := { held : U32, struck : U32, mouse : Mouse.Snapshot }.{

		## Whether a key is held down now, however long it has been.
		key_down : Snapshot, Keys.Key -> Bool
		key_down = |snapshot, key| snapshot.held.bitwise_and(Keys.bit(key)) != 0

		## Whether a key went down since the last tick.
		key_pressed : Snapshot, Keys.Key -> Bool
		key_pressed = |snapshot, key| snapshot.struck.bitwise_and(Keys.bit(key)) != 0

		## Say that a key is held, as `Input.none.with_key_down(KeyW)`. The native
		## runner builds a tick's snapshot with this and `with_key_pressed`, and
		## tests build theirs the same way.
		with_key_down : Snapshot, Keys.Key -> Snapshot
		with_key_down = |s, key| Snapshot.{ held: s.held.bitwise_or(Keys.bit(key)), struck: s.struck, mouse: s.mouse }

		## Say that a key was struck, which is also held.
		with_key_pressed : Snapshot, Keys.Key -> Snapshot
		with_key_pressed = |s, key|
			Snapshot.{ held: s.held.bitwise_or(Keys.bit(key)), struck: s.struck.bitwise_or(Keys.bit(key)), mouse: s.mouse }

		## Give a snapshot its pointer, as roc-ray's `with_mouse_*` do.
		with_mouse : Snapshot, Mouse.Snapshot -> Snapshot
		with_mouse = |s, pointer| Snapshot.{ held: s.held, struck: s.struck, mouse: pointer }

	}

	## Nothing touched: where the native runner starts each tick's snapshot,
	## and where a test starts.
	none : Input.Snapshot
	none = Snapshot.{ held: 0, struck: 0, mouse: Mouse.none }

	## A tick's input from the keys held and struck, as bits, and the pointer,
	## which is how WasmApp packs what the page hands it. The native runner packs its input the other way, from
	## `none` with the `with_*` makers.
	of : { held : U32, struck : U32, mouse : Mouse.Snapshot } -> Input.Snapshot
	of = |{ held, struck, mouse }| Snapshot.{ held: held.bitwise_or(struck), struck, mouse }
}

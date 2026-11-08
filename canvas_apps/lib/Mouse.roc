## Mouse is where the pointer is and which buttons are down. It is shaped like
## roc-ray's Mouse.Snapshot, so a game reads it the same way on both ends:
## `input.mouse.button_down(Left)`, `input.mouse.position()`. Only the three
## buttons a browser reports are here, where roc-ray names seven.
##
## Position is in the game's own coordinates, so a game never learns how big the
## window is or how the page scaled the canvas.

import Math

Mouse :: [].{
	Button := [Left, Right, Middle].{
		is_eq : _
	}

	bit : Mouse.Button -> U32
	bit = |button|
		match button {
			Left => 1
			Right => 2
			Middle => 4
		}

	## `wheel` is a field rather than a method, so a game reads it exactly as it
	## does on roc-ray: `input.mouse.wheel`, positive away from the hand. It is
	## not called `wheel_delta`, because roc-ray's `wheel_delta` means both
	## axes, as a Vec2.
	Snapshot := { held : U32, struck : U32, at : Math.Vec2, wheel : F32 }.{

		## Whether a button is down now, however long it has been.
		button_down : Snapshot, Mouse.Button -> Bool
		button_down = |snapshot, button| snapshot.held.bitwise_and(bit(button)) != 0

		## Whether a button went down since the last tick.
		button_pressed : Snapshot, Mouse.Button -> Bool
		button_pressed = |snapshot, button| snapshot.struck.bitwise_and(bit(button)) != 0

		## Where the pointer is, in the game's coordinates.
		position : Snapshot -> Math.Vec2
		position = |snapshot| snapshot.at

		## Say that a button is held, as `Mouse.none.with_button_down(Left)`.
		with_button_down : Snapshot, Mouse.Button -> Snapshot
		with_button_down = |s, button| Snapshot.{ held: s.held.bitwise_or(bit(button)), struck: s.struck, at: s.at, wheel: s.wheel }

		## Say that a button was struck, which is also held.
		with_button_pressed : Snapshot, Mouse.Button -> Snapshot
		with_button_pressed = |s, button|
			Snapshot.{ held: s.held.bitwise_or(bit(button)), struck: s.struck.bitwise_or(bit(button)), at: s.at, wheel: s.wheel }
	}

	## No button down, the pointer at the origin and the wheel still: the
	## pointer in `Input.none`, and what a test starts from.
	none : Mouse.Snapshot
	none = Snapshot.{ held: 0, struck: 0, at: { x: 0, y: 0 }, wheel: 0 }

	## What a runner packs a tick's pointer into: the buttons held and struck
	## as bits, where the pointer is, and how far the wheel turned. A struck
	## button is held too.
	of : { held : U32, struck : U32, at : Math.Vec2, wheel : F32 } -> Mouse.Snapshot
	of = |{ held, struck, at, wheel }| Snapshot.{ held: held.bitwise_or(struck), struck, at, wheel }
}

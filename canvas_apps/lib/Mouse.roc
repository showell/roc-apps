# Mouse -- where the pointer is and which buttons are down.
#
# Hand-written, and shaped like roc-ray's Mouse.Snapshot so a game reads it the
# same way on both ends: `input.mouse.button_down(Left)`, `input.mouse.position()`.
# Only the three buttons a browser reports are here; roc-ray names seven.
#
# Position is in the game's own coordinates, so a game never learns how big the
# window is or how the page scaled the canvas.

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

	# `wheel` is a field rather than a method, so a game reads it exactly as it
	# does on roc-ray: `input.mouse.wheel`, positive away from the hand. **IT
	# IS NOT CALLED wheel_delta**, which roc-ray also has and which means
	# something else there -- both axes, as a Vec2. One name, one meaning.
	Snapshot := { held : U32, struck : U32, at : { x : F32, y : F32 }, wheel : F32 }.{
		## Whether a button is down now, however long it has been.
		button_down : Snapshot, Mouse.Button -> Bool
		button_down = |snapshot, button| U32.bitwise_and(snapshot.held, bit(button)) != 0

		## Whether a button went down since the last tick.
		button_pressed : Snapshot, Mouse.Button -> Bool
		button_pressed = |snapshot, button| U32.bitwise_and(snapshot.struck, bit(button)) != 0

		## Where the pointer is, in the game's coordinates.
		position : Snapshot -> { x : F32, y : F32 }
		position = |snapshot| snapshot.at
	}

	none : Mouse.Snapshot
	none = Snapshot.{ held: 0, struck: 0, at: { x: 0, y: 0 }, wheel: 0 }

	of : U32, U32, F32, F32, F32 -> Mouse.Snapshot
	of = |held, struck, x, y, wheel| Snapshot.{ held: U32.bitwise_or(held, struck), struck, at: { x, y }, wheel }
}

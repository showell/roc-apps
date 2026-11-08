## A widget that answers the pointer asks this module where a click landed and
## whether it landed in a part of the canvas. A click is a press of the left
## button this frame: a button held down from an earlier frame isn't one. For a
## widget's expects, it also makes a frame's snapshot with a click, or a held
## button, at a spot.
import lib.Input
import lib.Mouse
import lib.Point

Click :: [].{

	## A part of the canvas, in pixels. It holds its top left corner and stops
	## short of its far edges, so two areas side by side share no pixel.
	Area := {
		left : F64,
		top : F64,
		width : F64,
		height : F64,
	}.{

		## Whether `spot` is in the area.
		contains : Click.Area, Point.Point -> Bool
		contains = |area, spot|
			spot.x >= area.left and spot.x < area.left + area.width and spot.y >= area.top and spot.y < area.top + area.height
	}

	## Where this frame's click is, if there is one.
	click_point : Input.Snapshot -> Try(Point.Point, [NoClick])
	click_point = |input|
		if input.mouse.button_pressed(Left) {
			{ x, y } = input.mouse.position()
			Ok({ x: x.to_f64(), y: y.to_f64() })
		} else {
			Err(NoClick)
		}

	## A frame's snapshot with the left button pressed just now at `spot`.
	click_at : Point.Point -> Input.Snapshot
	click_at = |spot| Input.none.with_mouse(pointer_at(spot).with_button_pressed(Left))

	## A frame's snapshot with the left button held at `spot` since an earlier
	## frame.
	held_at : Point.Point -> Input.Snapshot
	held_at = |spot| Input.none.with_mouse(pointer_at(spot).with_button_down(Left))
}

## The pointer at `spot`, with no button down.
pointer_at : Point.Point -> Mouse.Snapshot
pointer_at = |{ x, y }| Mouse.of({ held: 0, struck: 0, at: { x: x.to_f32_wrap(), y: y.to_f32_wrap() }, wheel: 0.0 })

## An area whose edges a spot can be tried on.
sample_area : Click.Area
sample_area = {
	left: 10.0,
	top: 20.0,
	width: 30.0,
	height: 40.0,
}

# An area holds its top left corner and its last pixel, and stops short of its far
# edges on every side.
expect sample_area.contains({ x: 10.0, y: 20.0 })
expect sample_area.contains({ x: 39.0, y: 59.0 })
expect !sample_area.contains({ x: 40.0, y: 20.0 })
expect !sample_area.contains({ x: 10.0, y: 60.0 })
expect !sample_area.contains({ x: 9.0, y: 20.0 })
expect !sample_area.contains({ x: 10.0, y: 19.0 })

# A press of the left button is a click where it lands; a held button, a press
# of the right button and no button are none.
expect Click.click_point(Click.click_at({ x: 3.0, y: 4.0 })) == Ok({ x: 3.0, y: 4.0 })
expect Click.click_point(Click.held_at({ x: 3.0, y: 4.0 })) == Err(NoClick)
expect {
	right_press = Input.none.with_mouse(pointer_at({ x: 3.0, y: 4.0 }).with_button_pressed(Right))
	Click.click_point(right_press) == Err(NoClick)
}
expect Click.click_point(Input.none) == Err(NoClick)

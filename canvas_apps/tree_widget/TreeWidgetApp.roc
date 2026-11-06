## The widget for the Safari tutorial's chapter on the conifer. Video recorder
## buttons run how far one tree is from the camera, and two more buttons choose
## its crown, so flat triangles and cones can be compared at any distance. Each
## frame is worked out from those two alone. The picture is the ride's sky and
## grass with the tree on them, drawn by TreeDraw. Below it, lines of text read
## out the calls.
import game.Clock
import game.Conifer
import game.Detail
import game.Distance
import game.Geom
import game.Lens
import game.TreeDraw
import lib.Brush
import lib.CanvasApp
import lib.Input
import lib.Mouse
import lib.Shapes
import widget.ScrubWidget
import widget.VcrButtons

TreeWidgetApp :: [].{

	## The crown the reader has chosen.
	Crown : [Triangles, Cones]

	## The whole state of the widget: the buttons, which hold the distance to the
	## tree, and the crown.
	Model : { transport : VcrButtons.Transport(Distance), crown : TreeWidgetApp.Crown }

	canvas_app : CanvasApp.CanvasApp(TreeWidgetApp.Model)
	canvas_app = ScrubWidget.canvas_app({
		title: "A conifer up close",
		init: at_start,
		advance: next_model,
		frame: frame_at,
	})
}

## The widget as it opens.
at_start : TreeWidgetApp.Model
at_start = { transport: VcrButtons.transport_at(approach.first), crown: Cones }

## The farthest the tree stands, a little beyond where the ride stops giving it
## cones.
farthest : Distance
farthest = Detail.cone_reach.plus(Distance.metres(20.0))

## The nearest the tree comes: just short of the near plane, where the ride stops
## drawing it, and well inside the reach of its widest cones.
nearest : Distance
nearest = Geom.near_plane.plus(Distance.metres(0.1))

## The approach, in about ten seconds. A place along it runs from 0, and the
## distance left is the fourth power of what remains of 1, so the near end, where
## the crowns differ, takes half the time.
approach : VcrButtons.NumberRange(Distance)
approach = {
	first: farthest,
	last: nearest,
	place_of: |forward| 1.0 - forward.ratio_to(farthest).pow(0.25),
	number_at: forward_at,
	one_step: 0.01,
	playing: Plays(0.0013),
}

## The distance at a place along the approach.
forward_at : F64 -> Distance
forward_at = |place| farthest.times((1.0 - place).pow(4.0))

## The model after one frame: the buttons, then the crown's.
next_model : TreeWidgetApp.Model, Input.Snapshot -> TreeWidgetApp.Model
next_model = |model, input| {
	transport: VcrButtons.next_transport(model.transport, { input, range: approach }),
	crown: crown_after(model.crown, input),
}

## A button's place on the canvas.
Area : {
	left : F64,
	top : F64,
	width : F64,
	height : F64,
}

triangles_area : Area
triangles_area = {
	left: 432.0,
	top: 222.0,
	width: 88.0,
	height: 24.0,
}

cones_area : Area
cones_area = { ..triangles_area, left: 528.0 }

is_inside : Area, { x : F64, y : F64 } -> Bool
is_inside = |area, { x, y }|
	x >= area.left
		and x < area.left + area.width
		and y >= area.top
		and y < area.top + area.height

## `crown` after a frame: a press on a crown's button chooses it.
crown_after : TreeWidgetApp.Crown, Input.Snapshot -> TreeWidgetApp.Crown
crown_after = |crown, input|
	if input.mouse.button_pressed(Left) {
		position = input.mouse.position()
		spot = { x: position.x.to_f64(), y: position.y.to_f64() }
		if is_inside(triangles_area, spot) {
			Triangles
		} else if is_inside(cones_area, spot) {
			Cones
		} else {
			crown
		}
	} else {
		crown
	}

crown_name : TreeWidgetApp.Crown -> Str
crown_name = |crown|
	match crown {
		Triangles => "Triangles"
		Cones => "Cones"
	}

## A crown's button, lit if it's the one chosen.
crown_button : TreeWidgetApp.Crown, { area : Area, chosen : TreeWidgetApp.Crown } -> List(Shapes.Shape)
crown_button = |crown, { area, chosen }| {
	color =
		if crown == chosen {
			0xd0603a
		} else {
			0x303030
		}
	[
		Rect({
			x: area.left,
			y: area.top,
			w: area.width,
			h: area.height,
			fill: ScrubWidget.flat(color),
		}),
		Text({
			text: crown_name(crown),
			x: area.left + area.width / 2.0,
			y: area.top + 17.0,
			size: ScrubWidget.label_size,
			face: Prose,
			align: Center,
			color: Brush.opaque(0xf7f5f0),
		}),
	]
}

## Everything on the canvas.
frame_at : TreeWidgetApp.Model -> List(Shapes.Shape)
frame_at = |{ transport, crown }|
	[
		VcrButtons.frame_shapes(
			transport,
			{
				range: approach,
				picture: picture(transport.at, crown),
				status: status_lines(transport.at, crown),
			},
		),
		crown_button(Triangles, { area: triangles_area, chosen: crown }),
		crown_button(Cones, { area: cones_area, chosen: crown }),
	].join()

## The tree's kind. A big green tree's crown comes low enough to stay in the
## picture as the camera nears it.
conifer : Conifer
conifer = Conifer.BigGreen

## How far to the right of the rider the tree stands.
tree_right : Distance
tree_right = Distance.metres(2.0)

## The crown TreeDraw is told to draw. Cones past the reach of the shading are
## unshaded, as they are on the ride.
crown_drawn : TreeWidgetApp.Crown, Distance -> TreeDraw.Crown
crown_drawn = |crown, forward|
	match crown {
		Triangles => Triangles
		Cones => TreeDraw.crown_at(forward.min(Detail.crown_shade_reach))
	}

## The tree at `forward`, the nearest in the ride, so with a shaded trunk.
tree_shapes : Distance, TreeWidgetApp.Crown -> List(Shapes.Shape)
tree_shapes = |forward, crown|
	TreeDraw.draw_crowned(
		{ tree: { right: tree_right, forward, conifer }, nearer_trees: 0 },
		{ cam_focal: Lens.focal, crown: crown_drawn(crown, forward) },
	)

picture : Distance, TreeWidgetApp.Crown -> List(Shapes.Shape)
picture = |forward, crown|
	ScrubWidget.ride_picture(tree_shapes(forward, crown), { clock: Clock.start, sun: OutOfView })

## What the ride would do at `forward`, in a word.
ride_crown_name : Distance -> Str
ride_crown_name = |forward|
	match TreeDraw.crown_at(forward) {
		Cones(_) => "Cones"
		Triangles => "Triangles"
	}

## The calls this widget makes at `forward`, and the distance, a line each.
status_lines : Distance, TreeWidgetApp.Crown -> List(Str)
status_lines = |forward, crown|
	[
		"forward = ${ScrubWidget.tenths_text(forward.to_metres())} m",
		"TreeDraw.crown_at(forward) = ${ride_crown_name(forward)}",
		"TreeDraw.draw_crowned(tree, ${crown_name(crown)})",
	]

## The widget at `metres`, stopped, with `crown`.
stopped_at : F64, TreeWidgetApp.Crown -> TreeWidgetApp.Model
stopped_at = |metres, crown| {
	transport: VcrButtons.transport_at(Distance.metres(metres)),
	crown,
}

## What a press of `control` does, after that frame.
pressed_on : TreeWidgetApp.Model, VcrButtons.Control -> TreeWidgetApp.Model
pressed_on = |model, control| next_model(model, VcrButtons.click_on(control, approach.playing))

## A frame's snapshot with a press at (`x`, `y`).
press_at : F32, F32 -> Input.Snapshot
press_at = |x, y| Input.none.with_mouse(Mouse.of(1, 1, x, y, 0.0))

## The crown after a press at (`x`, `y`), from `crown`.
crown_clicked : TreeWidgetApp.Crown, F32, F32 -> TreeWidgetApp.Crown
crown_clicked = |crown, x, y| crown_after(crown, press_at(x, y))

## Whether `got` is within `slack` metres of `metres`.
is_about : Distance, { metres : F64, slack : F64 } -> Bool
is_about = |got, { metres, slack }| (got.to_metres() - metres).abs() <= slack

# The approach starts with triangles on the ride and ends past the widest cone,
# short of the near plane.
expect farthest.to_metres() == 220.0
expect nearest > Geom.near_plane
expect at_start.transport == { at: farthest, motion: Stopped }
expect at_start.crown == Cones

# A place along the approach and its distance are inverses, and the ends are in
# order.
expect (approach.place_of)(farthest) == 0.0
expect (approach.place_of)(nearest) > (approach.place_of)(Distance.metres(1.0))
expect
	is_about(
		(approach.number_at)((approach.place_of)(Distance.metres(10.0))),
		{ metres: 10.0, slack: 0.000000001 },
	)

# The buttons run the distance: a frame of play is a little nearer, a step nearer or
# farther is more, and the ends are the ends.
expect is_about(pressed_on(stopped_at(100.0, Cones), Play).transport.at, { metres: 99.37, slack: 0.01 })
expect pressed_on(stopped_at(100.0, Cones), Play).transport.motion == Forward
expect is_about(pressed_on(stopped_at(100.0, Cones), StepForward).transport.at, { metres: 95.2, slack: 0.1 })
expect is_about(pressed_on(stopped_at(100.0, Cones), StepBack).transport.at, { metres: 104.9, slack: 0.1 })
expect pressed_on(stopped_at(100.0, Cones), ToStart).transport.at == farthest
expect pressed_on(stopped_at(100.0, Cones), ToEnd).transport.at == nearest

# A step stays on the approach at both ends.
expect pressed_on(at_start, StepBack).transport.at == farthest
expect pressed_on(stopped_at(0.5, Cones), StepForward).transport.at == nearest

# A press on a crown's button chooses it, at the first and last pixel of the button.
expect crown_clicked(Cones, 476.0, 234.0) == Triangles
expect crown_clicked(Triangles, 572.0, 234.0) == Cones
expect crown_clicked(Cones, 432.0, 222.0) == Triangles
expect crown_clicked(Cones, 519.0, 245.0) == Triangles
expect crown_clicked(Triangles, 528.0, 222.0) == Cones
expect crown_clicked(Triangles, 615.0, 245.0) == Cones

# Pressing the crown already chosen keeps it.
expect crown_clicked(Triangles, 476.0, 234.0) == Triangles
expect crown_clicked(Cones, 572.0, 234.0) == Cones

# Off the buttons a press does nothing: just past each edge, between them, and on
# the picture, where page_check.mjs presses.
expect crown_clicked(Triangles, 431.0, 234.0) == Triangles
expect crown_clicked(Cones, 524.0, 234.0) == Cones
expect crown_clicked(Triangles, 616.0, 234.0) == Triangles
expect crown_clicked(Cones, 476.0, 221.0) == Cones
expect crown_clicked(Cones, 476.0, 246.0) == Cones
expect crown_clicked(Cones, 128.0, 144.0) == Cones

# A button held from an earlier frame isn't a press.
expect crown_after(Cones, Input.none.with_mouse(Mouse.of(1, 0, 476.0, 234.0, 0.0))) == Cones
expect crown_after(Cones, Input.none) == Cones

# The crown and the distance don't disturb each other.
expect pressed_on(stopped_at(100.0, Triangles), Play).crown == Triangles
expect pressed_on(stopped_at(100.0, Cones), ToEnd).crown == Cones
expect next_model(stopped_at(100.0, Cones), press_at(476.0, 234.0)).transport.at == Distance.metres(100.0)

# The lines read the distance, what the ride does there, and the crown chosen.
expect
	status_lines(Distance.metres(199.0), Triangles)
		== [
			"forward = 199.0 m",
			"TreeDraw.crown_at(forward) = Cones",
			"TreeDraw.draw_crowned(tree, Triangles)",
		]

expect
	status_lines(Distance.metres(200.0), Cones)
		== [
			"forward = 200.0 m",
			"TreeDraw.crown_at(forward) = Triangles",
			"TreeDraw.draw_crowned(tree, Cones)",
		]

# The chosen crown is what the ride draws, where the ride would choose it, whether
# the cones are shaded or not.
expect {
	ride_at = |metres|
		TreeDraw.draw(
			{
				tree: { right: tree_right, forward: Distance.metres(metres), conifer },
				nearer_trees: 0,
			},
			Lens.focal,
		)
	[
		ride_at(20.0) == tree_shapes(Distance.metres(20.0), Cones),
		ride_at(120.0) == tree_shapes(Distance.metres(120.0), Cones),
		ride_at(210.0) == tree_shapes(Distance.metres(210.0), Triangles),
		ride_at(20.0) != tree_shapes(Distance.metres(20.0), Triangles),
		ride_at(210.0) != tree_shapes(Distance.metres(210.0), Cones),
	].all(|held| held)
}

# The crowns differ all along the approach, until the camera would be inside every
# cone, where both are triangles.
expect picture(Distance.metres(20.0), Cones) != picture(Distance.metres(20.0), Triangles)
expect picture(farthest, Cones) != picture(farthest, Triangles)
expect picture(nearest, Cones) == picture(nearest, Triangles)

# The picture moves with the distance.
expect picture(Distance.metres(20.0), Cones) != picture(Distance.metres(21.0), Cones)

# The chosen button is lit, and the other isn't.
expect
	crown_button(Cones, { area: cones_area, chosen: Cones })
		!= crown_button(Cones, { area: cones_area, chosen: Triangles })

# The hint goes once the distance has moved, and the crown's buttons stay.
expect frame_at(at_start).len() == frame_at(stopped_at(100.0, Cones)).len() + 1

## The widget for the Safari tutorial's chapter on the conifer: a still picture of
## three trees of one kind at three distances, with no controls. TreeShapes draws
## each one and picks its crown, and under each tree are its distance and the
## crown `TreeShapes.crown_of` gives there.
import game.Across
import game.Along
import game.Clock
import game.Conifer
import game.Distance
import game.Fraction
import game.Lens
import game.Pixels
import game.Screen
import game.Sky
import game.Spot
import game.TreeShapes
import lib.CanvasApp
import lib.Shapes
import widget.ReadoutText
import widget.ScrubWidget

TreeWidgetApp :: [].{

	## A still picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(TreeWidgetApp.Model)
	canvas_app = ScrubWidget.still_app({ title: "Three conifers", shapes: still_shapes })
}

## A tree in the picture: how far off it stands, and the x on the canvas of the
## middle of its third.
Stand : { forward : Distance, canvas_x : F64 }

## Just past the reach of the cones, where the tree is still plain to see.
far_stand : Stand
far_stand = { forward: Distance.metres(210.0), canvas_x: 107.0 }

## Just past the reach of the shading, as near as unshaded cones come.
middle_stand : Stand
middle_stand = { forward: Distance.metres(85.0), canvas_x: 320.0 }

## Half shaded, and about as near as a tree comes with all of it in the picture.
near_stand : Stand
near_stand = { forward: Distance.metres(40.0), canvas_x: 533.0 }

stands : List(Stand)
stands = [far_stand, middle_stand, near_stand]

## The tallest kind, so the far tree still reads as a tree.
conifer : Conifer
conifer = Conifer.Gold

## How many canvas pixels the picture gives a pixel of the ride's screen.
canvas_per_screen : F64
canvas_per_screen = ScrubWidget.canvas_width / Screen.width.to_f64()

## How far right of the camera a stand's tree must be to land on its `canvas_x`.
right_of : Stand -> Distance
right_of = |{ forward, canvas_x }| {
	screen_x = Pixels.of(canvas_x / canvas_per_screen)
	forward.times(screen_x.minus(Screen.center_x).portion(Lens.resting_focal))
}

## The spot of a stand's tree, on the ground, if it is in front of the camera.
stand_spot : Stand -> Try(Spot, [BehindCamera])
stand_spot = |stand|
	Spot.straight_ahead({
		road_point: {
			along: Along.metres(stand.forward.to_metres()),
			across: Across.right_of_middle(right_of(stand)),
		},
		lift: Distance.zero,
		forward: stand.forward,
	})

tree_shapes : Stand -> List(Shapes.Shape)
tree_shapes = |stand|
	ScrubWidget.resting_lens_shapes(
		stand_spot(stand).map_ok(|spot| { spot, kind: conifer }),
		{ nearer_tree_count: 0 },
	)

## What `TreeShapes.crown_of` says at `forward`, as Roc would write it.
crown_text : Distance -> Str
crown_text = |forward|
	match TreeShapes.crown_of(forward) {
		Cones({ shade }) => "Cones({ shade: ${ReadoutText.tenths_text(shade.to_f64())} })"
		Triangles => "Triangles"
	}

## The two lines under a tree.
caption_lines : Distance -> List(Str)
caption_lines = |forward|
	["forward = ${ReadoutText.tenths_text(forward.to_metres())} m", crown_text(forward)]

## A line of a caption, centered under its tree, on row `row` of the panel.
caption_line : Stand, { text : Str, row : U64 } -> Shapes.Shape
caption_line = |stand, { text, row }|
	ScrubWidget.readout({
		text,
		color: ScrubWidget.ink_color,
		row,
		style: {
			x: stand.canvas_x,
			first_baseline: 276.0,
			row_spacing: 24.0,
			size: 13.0,
			align: Center,
		},
	})

caption_shapes : Stand -> List(Shapes.Shape)
caption_shapes = |stand|
	caption_lines(stand.forward).map_with_index(|text, row| caption_line(stand, { text, row }))

still_shapes : List(Shapes.Shape)
still_shapes = {
	trees = stands.join_map(tree_shapes)
	picture_shapes = ScrubWidget.picture_shapes({
		backdrop: { sky_colors: Sky.colors_at(Clock.start), sun_sighting: OutOfView },
		ride_shapes: trees,
	})
	ScrubWidget.frame_shapes({ picture_shapes, status_lines: [] }).concat(stands.join_map(caption_shapes))
}

## Whether a stand's tree is all in the picture, on its `canvas_x`, and at least
## 30 pixels tall on the canvas.
is_plain_to_see : Stand -> Bool
is_plain_to_see = |stand|
	match stand_spot(stand) {
		Ok(spot) => {
			outline = TreeShapes.tree_outline(
				spot,
				{ height: conifer.scenery_height(), cam_focal: Lens.resting_focal },
			)
			foot_y = outline.foot.y.to_f64() * canvas_per_screen
			tip_y = foot_y - outline.height_on_screen.to_f64() * canvas_per_screen
			x = outline.foot.x.to_f64() * canvas_per_screen
			tip_y >= 0.0
				and foot_y <= ScrubWidget.picture_bottom_y
				and foot_y - tip_y >= 30.0
				and (x - stand.canvas_x).abs() <= 0.000000001
		}
		Err(BehindCamera) => False
	}

# Each tree shows one of the three things `crown_of` can say.
expect TreeShapes.crown_of(far_stand.forward) == Triangles
expect TreeShapes.crown_of(middle_stand.forward) == Cones({ shade: Fraction.zero })
expect TreeShapes.crown_of(near_stand.forward) == Cones({ shade: Fraction.of(0.5) })

# All three trees can be seen. A tree too near loses its foot under the panel or
# its tip off the top, and one too far is a speck.
expect stands.all(is_plain_to_see)
expect !is_plain_to_see({ ..near_stand, forward: Distance.metres(30.0) })
expect !is_plain_to_see({ ..far_stand, forward: Distance.metres(300.0) })

# The captions go down last, so they show over the panel.
expect still_shapes.ends_with(stands.join_map(caption_shapes))

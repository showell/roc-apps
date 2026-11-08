## WidgetExpects reaches every widget's expects in one run of `roc test`. Each
## widget imports the game, and `roc test` runs the expects of every module a
## root reaches, so a run per widget would run the game's expects once for each
## widget. Here the game's run once, beside all of the widgets'. Each widget's
## package.roc exposes its app module for this root.
app [main!] {
	beacon: "../../beacon_widget/package.roc",
	bends: "../../bends_widget/package.roc",
	bird: "../../bird_widget/package.roc",
	cat: "../../cat_widget/package.roc",
	frame: "../../frame_widget/package.roc",
	game: "../game.roc",
	gaze: "../../gaze_widget/package.roc",
	lib: "../../lib/main.roc",
	rehearsal: "../../rehearsal_widget/package.roc",
	route: "../../route_widget/package.roc",
	shapes: "../../shapes_widget/package.roc",
	sky: "../../sky_widget/package.roc",
	step: "../../step_widget/package.roc",
	stills: "../../stills_widget/package.roc",
	tree: "../../tree_widget/package.roc",
	truck: "../../truck_widget/package.roc",
	widget: "../../widget_kit/main.roc",
}

import beacon.BeaconWidgetApp
import bends.BendsWidgetApp
import bird.BirdWidgetApp
import cat.CatWidgetApp
import frame.FrameWidgetApp
import gaze.GazeWidgetApp
import rehearsal.RehearsalWidgetApp
import route.RouteWidgetApp
import shapes.ShapesWidgetApp
import sky.SkyWidgetApp
import step.StepWidgetApp
import stills.StillsWidgetApp
import tree.TreeWidgetApp
import truck.TruckWidgetApp
import game.Steps
import lib.CanvasApp
import lib.Font
import lib.Input
import lib.Point
import lib.Shapes
import widget.Click
import widget.ReadoutText
import widget.WidgetPage

main! = |_args| Ok({})

## Each line of type in a frame.
lines_of_type : List(Shapes.Shape) -> List(Shapes.TextLine)
lines_of_type = |shapes|
	shapes.keep_oks(
		|shape|
			match shape {
				Text(line) => Ok(line)
				Poly(_) | Disc(_) | Rect(_) | Blend(_) | View(_) | Image(_) => Err(NotText)
			},
	)

## The words of each line of type in a frame.
words_in : List(Shapes.Shape) -> List(Str)
words_in = |shapes| lines_of_type(shapes).map(|line| line.text)

## The words of a canvas app's first frame, and of the frame after each of
## `inputs`, one step each.
words_shown : CanvasApp.CanvasApp(model), List(Input.Snapshot) -> List(Str)
words_shown = |canvas_app, inputs| {
	frame_of = canvas_app.frame_shapes
	model_at_next_step = canvas_app.model_at_next_step
	var $model = canvas_app.init
	var $words = words_in(frame_of($model))
	for input in inputs {
		$model = model_at_next_step($model, input, CanvasApp.seconds_a_step(canvas_app))
		$words = $words.concat(words_in(frame_of($model)))
	}
	$words
}

# The native runner plots every line of type with Font, which crashes on a
# byte it has no glyph for, so each word a widget shows must have one. Every
# widget's first frame is read, and the frame widget's with each layer added.
# The two lines named are there to show the words were found at all.
expect {
	# Nine presses open the frame widget's ten layers, its last one last.
	right_presses = List.repeat(Input.none.with_key_pressed(KeyRight), 9)
	words = [
		words_shown(BeaconWidgetApp.canvas_app, []),
		words_shown(BendsWidgetApp.canvas_app, []),
		words_shown(BirdWidgetApp.canvas_app, []),
		words_shown(CatWidgetApp.canvas_app, []),
		words_shown(FrameWidgetApp.canvas_app, right_presses),
		words_shown(GazeWidgetApp.canvas_app, []),
		words_shown(RehearsalWidgetApp.canvas_app, []),
		words_shown(RouteWidgetApp.canvas_app, []),
		words_shown(ShapesWidgetApp.canvas_app, []),
		words_shown(SkyWidgetApp.canvas_app, []),
		words_shown(StepWidgetApp.canvas_app, []),
		words_shown(StillsWidgetApp.canvas_app, []),
		words_shown(TreeWidgetApp.canvas_app, []),
		words_shown(TruckWidgetApp.canvas_app, []),
	].join()
	words.all(Font.can_plot)
		and words.contains("Added: The moving things")
		and words.contains("Cones({ shade: 0.5 })")
}

## Every line of the names under the stills widget's small stills, the only
## lines it centers. A long name takes two.
still_name_lines : List(Shapes.Shape) -> List(Shapes.TextLine)
still_name_lines = |shapes| lines_of_type(shapes).keep_if(|line| line.align == Center)

## The first line of each name under the stills widget's small stills: a line
## that doesn't go on from a line above it ending in a comma.
still_names : List(Shapes.Shape) -> List(Shapes.TextLine)
still_names = |shapes| {
	lines = still_name_lines(shapes)
	goes_on_from = |line, other|
		other.x == line.x and other.y < line.y and other.text.ends_with(",")
	lines.keep_if(|line| !lines.any(|other| goes_on_from(line, other)))
}

## Whether `text`, set as `name` is, fits the cell `name` stands under. The
## cells of a row are all one width, so a cell is as wide as its name is far
## from the nearest name in the row.
fits_cell_of : List(Shapes.TextLine), { name : Shapes.TextLine, text : Str } -> Bool
fits_cell_of = |names, { name, text }| {
	row_neighbors = names.keep_if(|other| other.y == name.y and other.x != name.x)
	match row_neighbors.map(|other| (other.x - name.x).abs()).min() {
		Ok(cell_width) => Font.room_for(text, name.size) <= cell_width
		Err(ListWasEmpty) => crash "WidgetExpects.fits_cell_of: every row of stills has two or more"
	}
}

## The stills widget's frame for `model`.
stills_frame_shapes : StillsWidgetApp.Model -> List(Shapes.Shape)
stills_frame_shapes = |model| {
	frame_of = StillsWidgetApp.canvas_app.frame_shapes
	frame_of(model)
}

## The stills widget's first frame.
stills_first_frame_shapes : List(Shapes.Shape)
stills_first_frame_shapes = stills_frame_shapes(StillsWidgetApp.canvas_app.init)

## The stills widget after a click on each small still, which shows it large. A
## name's baseline is inside its still's cell.
stills_models : List(StillsWidgetApp.Model)
stills_models = {
	stills_app = StillsWidgetApp.canvas_app
	model_at_next_step = stills_app.model_at_next_step
	seconds = CanvasApp.seconds_a_step(stills_app)
	still_names(stills_first_frame_shapes).map(
		|name| {
			click = Click.click_at({ x: name.x, y: name.y })
			model_at_next_step(stills_app.init, click, seconds)
		},
	)
}

## The corners of a frame's polygons that lie wholly above the panel. A
## polygon's coordinates are its corners' x and y, two at a time.
picture_points : List(Shapes.Shape) -> List(Point.Point)
picture_points = |shapes| {
	corner_of = |pair|
		match pair {
			[x, y] => { x, y }
			_ => crash "WidgetExpects.picture_points: a polygon's coordinates come in pairs"
		}
	polygons = shapes.keep_oks(
		|shape|
			match shape {
				Poly({ coordinates, .. }) => Ok(coordinates.chunks_of(2).map(corner_of))
				Text(_) | Disc(_) | Rect(_) | Blend(_) | View(_) | Image(_) => Err(NotPoly)
			},
	)
	is_above_panel = |point| point.y < WidgetPage.picture_bottom_y
	polygons.keep_if(|corners| corners.all(is_above_panel)).join()
}

## Whether every line of type above the panel ends left of every polygon there,
## which in the stills widget is the large still.
is_type_left_of_still : List(Shapes.Shape) -> Bool
is_type_left_of_still = |shapes| {
	lines = lines_of_type(shapes).keep_if(|line| line.y < WidgetPage.picture_bottom_y)
	match picture_points(shapes).map(|point| point.x).min() {
		Ok(still_left) => {
			is_left_of_still = |line| {
				line_end = line.x + Font.room_for(line.text, line.size)
				line.align == Left and line_end <= still_left
			}
			!lines.is_empty() and lines.all(is_left_of_still)
		}
		Err(ListWasEmpty) => False
	}
}

# Each line of each name under a small still fits its cell, and one much
# longer would not.
expect {
	lines = still_name_lines(stills_first_frame_shapes)
	still_names(stills_first_frame_shapes).len()
		== 13
		and lines.all(|name| fits_cell_of(lines, { name, text: name.text }))
}
expect
	match still_names(stills_first_frame_shapes) {
		[first, ..] as names => !fits_cell_of(names, { name: first, text: "Collapse, and then some" })
		[] => False
	}

# The words above the panel end left of the large still, whichever still is
# shown large.
expect {
	poses = stills_models.map(|model| model.large_pose)
	is_each_pose_once = poses.all(|pose| poses.keep_if(|other| other == pose).len() == 1)
	frames = stills_models.map(stills_frame_shapes)
	is_each_pose_once and frames.all(is_type_left_of_still)
}

# A readout counts frames from one, though steps count from zero.
expect ReadoutText.stage_text(Playing(Steps.zero)) == "Playing: frame 1"
expect ReadoutText.stage_text(Playing(Steps.of(9))) == "Playing: frame 10"

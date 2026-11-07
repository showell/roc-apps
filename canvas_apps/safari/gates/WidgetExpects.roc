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
	gaze: "../../gaze_widget/package.roc",
	lib: "../../lib/main.roc",
	rehearsal: "../../rehearsal_widget/package.roc",
	route: "../../route_widget/package.roc",
	shapes: "../../shapes_widget/package.roc",
	sky: "../../sky_widget/package.roc",
	step: "../../step_widget/package.roc",
	stills: "../../stills_widget/package.roc",
	tree: "../../tree_widget/package.roc",
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
import lib.CanvasApp
import lib.Font
import lib.Input
import lib.Shapes

main! = |_args| Ok({})

## The words of each line of type in a frame.
words_in : List(Shapes.Shape) -> List(Str)
words_in = |shapes|
	shapes.keep_oks(
		|shape|
			match shape {
				Text(line) => Ok(line.text)
				Poly(_) | Disc(_) | Rect(_) | Blend(_) | View(_) | Image(_) => Err(NotText)
			},
	)

## The words of a canvas app's first frame, and of the frame after each of
## `inputs`, one step each.
words_shown : CanvasApp.CanvasApp(model), List(Input.Snapshot) -> List(Str)
words_shown = |canvas_app, inputs| {
	frame_of = canvas_app.frame_shapes
	model_at_next_step = canvas_app.model_at_next_step
	var $model = canvas_app.init
	var $words = words_in(frame_of($model))
	for input in inputs {
		$model = model_at_next_step($model, input, 1.0 / canvas_app.fps.to_f32())
		$words = $words.concat(words_in(frame_of($model)))
	}
	$words
}

# The native runner plots every line of type with Font, which crashes on a
# byte it has no glyph for, so each word a widget shows must have one. Every
# widget's first frame is read, and the frame widget's with each layer added.
# The two lines named are there to show the words were found at all.
expect {
	words = [
		words_shown(BeaconWidgetApp.canvas_app, []),
		words_shown(BendsWidgetApp.canvas_app, []),
		words_shown(BirdWidgetApp.canvas_app, []),
		words_shown(CatWidgetApp.canvas_app, []),
		words_shown(FrameWidgetApp.canvas_app, List.repeat(Input.none.with_key_pressed(KeyRight), 9)),
		words_shown(GazeWidgetApp.canvas_app, []),
		words_shown(RehearsalWidgetApp.canvas_app, []),
		words_shown(RouteWidgetApp.canvas_app, []),
		words_shown(ShapesWidgetApp.canvas_app, []),
		words_shown(SkyWidgetApp.canvas_app, []),
		words_shown(StepWidgetApp.canvas_app, []),
		words_shown(StillsWidgetApp.canvas_app, []),
		words_shown(TreeWidgetApp.canvas_app, []),
	].join()
	words.all(Font.can_plot)
		and words.contains("Added: The moving things")
		and words.contains("Cones({ shade: 0.5 })")
}

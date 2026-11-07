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

main! = |_args| Ok({})

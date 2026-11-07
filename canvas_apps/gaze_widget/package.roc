# This widget's app module as a package, so that the safari gate's
# gates/WidgetExpects.roc reaches its expects with every other widget's.
# web.roc is the widget's app, and its packages must match these.
package
	[GazeWidgetApp]
	{
		game: "../safari/game.roc",
		lib: "../lib/main.roc",
		widget: "../widget_kit/main.roc",
	}

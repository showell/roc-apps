# The game's modules that the gates read, as a package. The gate programs in
# gates/ reach this as `game: "../game.roc"` and say `import game.SafariRide`.
package
	[Angle, Rider, Safari, SafariRide, SafariShapes, Screen, Sky, World]
	{
		lib: "../lib/main.roc",
	}

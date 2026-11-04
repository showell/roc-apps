# The game's modules that the gates read, as a package. The gate programs in
# gates/ reach this as `game: "../game.roc"` and say `import game.SafariRide`.
package
	[SafariRide, Sky, SafariShapes, Screen, Paint, SafariBrush, World, Safari, Blit, Rider]
	{
		lib: "../lib/main.roc",
	}

# The game's modules that the gates and the tutorial's widgets read, as a
# package. The gate programs in gates/ reach this as `game: "../game.roc"` and
# say `import game.SafariRide`.
package
	[
		Angle,
		Animation,
		Cat,
		CatDraw,
		CatStills,
		CrossingReaction,
		Rider,
		Safari,
		SafariRide,
		SafariShapes,
		Scenery,
		Screen,
		Sky,
		Speed,
		World,
	]
	{
		lib: "../lib/main.roc",
	}

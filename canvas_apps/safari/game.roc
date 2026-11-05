# The game's modules that the gates and the tutorial's widgets read, as a
# package. The gate programs in gates/ reach this as `game: "../game.roc"` and
# say `import game.Tour`.
package
	[
		Angle,
		Animation,
		Cat,
		CatDraw,
		CatStills,
		CrossingReaction,
		RideInstant,
		Rider,
		SafariShapes,
		Scenery,
		Screen,
		Sky,
		Speed,
		Tour,
		World,
	]
	{
		lib: "../lib/main.roc",
	}

# The game's modules that the gates and the tutorial's widgets read, as a
# package. The gate programs in gates/ reach this as `game: "../game.roc"` and
# say `import game.Tour`.
package
	[
		Along,
		Angle,
		Animation,
		BirdFlight,
		Camera,
		Cat,
		CatDraw,
		CatStills,
		Clock,
		CrossingReaction,
		Distance,
		Fraction,
		ItemDraw,
		Lens,
		Paint,
		RideInstant,
		Rider,
		RocBird,
		SafariShapes,
		Scenery,
		Screen,
		Sky,
		Speed,
		Steps,
		Tour,
		Tower,
		TowerSighting,
		Tree,
		World,
	]
	{
		lib: "../lib/main.roc",
	}

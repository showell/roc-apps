# The expects that can't sit beside their code, one module a topic, with what
# two of them share in Fixtures. A road view needs a place along the road, a
# place across it and a turn, and most sightings import none of them; the scene
# and a ride that has finished need more again. No module of the game sees all
# of what these checks do, and the game shouldn't import a module for a test,
# so they sit here, where the gate reaches them as one package root:
# `roc test gates/expects/main.roc` runs them all, with the expects of every
# game and lib module the package reaches. A module left off this list runs
# none of its expects, silently.
package
	[
		EncounterExpects,
		Fixtures,
		RideExpects,
		RiderExpects,
		RoadExpects,
		SceneExpects,
		SightingExpects,
	]
	{ game: "../../game.roc", lib: "../../../lib/main.roc" }

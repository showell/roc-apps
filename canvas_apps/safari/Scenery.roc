## Scenery holds the words the world is built from: a segment's colour scheme,
## the animals, and how far from the road the herds keep.
import Distance
import Geom

Scenery :: [].{
	Scheme : [AllGreen, GoldGreen, RedGreen]
	Animal : [Elephant, Giraffe, Zebra, Rhino]
	BendLife : [Quiet, Animal(Scenery.Animal), DuckPond]

	## How far from the middle of the road the nearest row of a herd stands.
	herd_front_distance : Distance
	herd_front_distance = Geom.road_half_width.plus(Distance.metres(10.0))

	is_pond : Scenery.BendLife -> Bool
	is_pond = |c|
		match c {
			DuckPond => True
			Quiet | Animal(_) => False
		}
}

expect Scenery.is_pond(DuckPond)
expect !Scenery.is_pond(Quiet)
expect !Scenery.is_pond(Animal(Zebra))
expect !Scenery.is_pond(Animal(Elephant))
expect !Scenery.is_pond(Animal(Giraffe))
expect !Scenery.is_pond(Animal(Rhino))

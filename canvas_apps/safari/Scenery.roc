## Scenery holds the words the world is built from: a segment's colour scheme,
## the animals, and how far from the road the herds keep.
import Distance

Scenery :: [].{
	Scheme : [AllGreen, GoldGreen, RedGreen]
	Animal : [Elephant, Giraffe, Zebra, Rhino]
	BendLife : [Quiet, Animal(Scenery.Animal), DuckPond]

	herd_road_offset : Distance
	herd_road_offset = Distance.metres(10.0)

	is_pond : Scenery.BendLife -> Bool
	is_pond = |c|
		match c {
			DuckPond => True
			Quiet | Animal(_) => False
		}
}

expect Scenery.herd_road_offset.to_metres() == 10.0
expect Scenery.is_pond(DuckPond)
expect !Scenery.is_pond(Quiet)
expect !Scenery.is_pond(Animal(Zebra))
expect !Scenery.is_pond(Animal(Elephant))
expect !Scenery.is_pond(Animal(Giraffe))
expect !Scenery.is_pond(Animal(Rhino))

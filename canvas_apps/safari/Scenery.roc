## Scenery holds the words the world is built from: a segment's colour scheme,
## the animals, and how wide the road is.
import Across
import Distance

Scenery :: [].{
	Scheme : [AllGreen, GoldGreen, RedGreen]
	Animal : [Elephant, Giraffe, Zebra, Rhino]
	BendLife : [Quiet, Animal(Scenery.Animal), DuckPond]

	road_width : Distance
	road_width = Distance.metres(4.0)

	road_half_width : Distance
	road_half_width = road_width.divided_by(2.0)

	left_edge : Across
	left_edge = Across.left_of_middle(road_half_width)

	right_edge : Across
	right_edge = Across.right_of_middle(road_half_width)

	herd_road_offset : Distance
	herd_road_offset = Distance.metres(10.0)

	is_pond : Scenery.BendLife -> Bool
	is_pond = |c|
		match c {
			DuckPond => True
			Quiet | Animal(_) => False
		}
}

expect Scenery.road_width.to_metres() == 4.0
expect Scenery.road_half_width.to_metres() == 2.0
expect Scenery.herd_road_offset.to_metres() == 10.0
expect Scenery.left_edge.to_metres() == -2.0
expect Scenery.right_edge.to_metres() == 2.0
expect Across.middle.distance_from(Scenery.left_edge).to_metres() == 2.0
expect Across.metres(-2.0).distance_from(Scenery.left_edge).to_metres() == 0.0
expect Across.metres(2.0).distance_from(Scenery.left_edge).to_metres() == 4.0
expect Scenery.is_pond(DuckPond)
expect !Scenery.is_pond(Quiet)
expect !Scenery.is_pond(Animal(Zebra))
expect !Scenery.is_pond(Animal(Elephant))
expect !Scenery.is_pond(Animal(Giraffe))
expect !Scenery.is_pond(Animal(Rhino))

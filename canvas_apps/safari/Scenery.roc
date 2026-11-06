# Scenery -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Across
import Along
import Cutouts
import Distance

Scenery :: [].{
	Scheme : [AllGreen, YellowGreen, RedGreen]
	Animal : [Elephant, Giraffe, Zebra, Rhino]
	BendLife : [Quiet, Animal(Scenery.Animal), DuckPond]
	Tree : {
		along : Along,
		across : Across,
		color : I64,
		height : Distance,
	}
	Critter : {
		along : Along,
		across : Across,
		codepoint : I64,
		height : Distance,
		facing : Cutouts.Facing,
	}

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
expect !(Scenery.is_pond(Quiet))
expect !(Scenery.is_pond(Animal(Zebra)))
expect !(Scenery.is_pond(Animal(Elephant)))
expect !(Scenery.is_pond(Animal(Giraffe)))
expect !(Scenery.is_pond(Animal(Rhino)))

scheme_code : Scenery.Scheme -> I64
scheme_code = |s|
	match s {
		AllGreen => 0
		YellowGreen => 1
		RedGreen => 2
	}

life_code : Scenery.BendLife -> I64
life_code = |c|
	match c {
		Quiet => 0
		Animal(Elephant) => 1
		Animal(Giraffe) => 2
		Animal(Zebra) => 3
		Animal(Rhino) => 4
		DuckPond => 5
	}

expect scheme_code(AllGreen) == 0
expect scheme_code(YellowGreen) == 1
expect scheme_code(RedGreen) == 2
expect life_code(Quiet) == 0
expect life_code(Animal(Elephant)) == 1
expect life_code(Animal(Giraffe)) == 2
expect life_code(Animal(Zebra)) == 3
expect life_code(Animal(Rhino)) == 4
expect life_code(DuckPond) == 5

a_tree : Scenery.Tree
a_tree = {
	along: Along.metres(120.5),
	across: Across.metres(3.25),
	color: 9066271,
	height: Distance.metres(7.75),
}

a_critter : Scenery.Critter
a_critter = {
	along: Along.metres(250.5),
	across: Across.metres(-6.5),
	codepoint: 128004,
	height: Distance.metres(1.375),
	facing: FacesRight,
}

expect a_tree.along.to_metres() == 120.5
expect a_tree.across.to_metres() == 3.25
expect a_tree.height.to_metres() == 7.75
expect a_critter.along.to_metres() == 250.5
expect a_critter.across.to_metres() == -6.5
expect a_critter.height.to_metres() == 1.375
expect a_tree.color == 9066271
expect a_critter.codepoint == 128004
expect a_critter.facing == FacesRight

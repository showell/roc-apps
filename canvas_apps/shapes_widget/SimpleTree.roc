## The simplest tree there is: a triangle of foliage on a rectangle of trunk,
## as one picture. The trunk comes first, so the foliage paints over its top.
import game.Picture
import game.Polygon
import game.Screen
import lib.RgbColor
import lib.Shapes

SimpleTree :: [].{

	## The tree's foliage, one green triangle.
	foliage : Shapes.Shape
	foliage = Polygon.triangle(
		{
			first_corner: Screen.point(180.0, 240.0),
			second_corner: Screen.point(420.0, 240.0),
			third_corner: Screen.point(300.0, 40.0),
		},
		RgbColor.of(0x2e8b57),
	)

	## The tree's trunk, one brown rectangle.
	trunk : Shapes.Shape
	trunk = Polygon.rectangle(
		{ top_left: Screen.point(285.0, 200.0), bottom_right: Screen.point(315.0, 300.0) },
		RgbColor.of(0x8b5a2b),
	)

	## The whole tree, trunk first.
	tree : Picture
	tree = Picture.from_shapes([trunk, foliage])
}

expect SimpleTree.tree.to_shapes() == [SimpleTree.trunk, SimpleTree.foliage]

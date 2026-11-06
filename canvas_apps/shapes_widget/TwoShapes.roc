## A frame is a list of shapes, painted first to last. The rectangle comes second
## in the list, so where the two overlap it paints over the triangle.
import game.Paint
import game.Screen
import lib.Shapes

TwoShapes :: [].{

	shapes : List(Shapes.Shape)
	shapes = triangle.concat(rectangle)
}

triangle : List(Shapes.Shape)
triangle = Paint.polygon(0x2e8b57, triangle_corners)

rectangle : List(Shapes.Shape)
rectangle = Paint.polygon(0xe8a33d, rectangle_corners)

triangle_corners : List(Screen.Point)
triangle_corners = [
	Screen.point(120.0, 300.0),
	Screen.point(360.0, 300.0),
	Screen.point(240.0, 60.0),
]

rectangle_corners : List(Screen.Point)
rectangle_corners = [
	Screen.point(270.0, 120.0),
	Screen.point(520.0, 120.0),
	Screen.point(520.0, 250.0),
	Screen.point(270.0, 250.0),
]

expect TwoShapes.shapes.len() == 2
expect TwoShapes.shapes.drop_first(1) == rectangle

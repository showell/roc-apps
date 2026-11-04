## A screen of pixels seen through a camera rolled about the screen's centre.
## A point in the scene turns onto the screen by minus the roll, as a canvas
## turns one when it translates to the centre, rotates by minus the roll and
## translates back; a point on the screen turns back into the scene by the
## roll. The centre is the same point in both.
ScreenRoll :: {
	cos : F64,
	sin : F64,
	center : { x : F64, y : F64 },
	width_px : I64,
	height_px : I64,
}.{

	## A point in the scene, before the roll turns it onto the screen.
	ScenePoint := { x : F64, y : F64 }.{
		is_eq : _
	}

	## A point on the screen, where the roll has turned a scene point.
	ScreenPoint := { x : F64, y : F64 }.{
		is_eq : _
	}

	## A screen `width` by `height` pixels, and the camera's roll in radians.
	of : { roll : F64, width : I64, height : I64 } -> ScreenRoll
	of = |{ roll, width, height }|
		ScreenRoll.(
			{
				cos: F64.cos(roll),
				sin: F64.sin(roll),
				center: { x: I64.to_f64(width) / 2.0, y: I64.to_f64(height) / 2.0 },
				width_px: width,
				height_px: height,
			},
		)

	width_px : ScreenRoll -> I64
	width_px = |ScreenRoll.(screen)| screen.width_px

	height_px : ScreenRoll -> I64
	height_px = |ScreenRoll.(screen)| screen.height_px

	to_screen : ScreenRoll, ScreenRoll.ScenePoint -> ScreenRoll.ScreenPoint
	to_screen = |ScreenRoll.(screen), ScreenRoll.ScenePoint.({ x, y })| {
		center = screen.center
		dx = x - center.x
		dy = y - center.y
		ScreenRoll.ScreenPoint.(
			{
				x: center.x + dx * screen.cos + dy * screen.sin,
				y: center.y - dx * screen.sin + dy * screen.cos,
			},
		)
	}

	to_scene : ScreenRoll, ScreenRoll.ScreenPoint -> ScreenRoll.ScenePoint
	to_scene = |ScreenRoll.(screen), ScreenRoll.ScreenPoint.({ x, y })| {
		center = screen.center
		dx = x - center.x
		dy = y - center.y
		ScreenRoll.ScenePoint.(
			{
				x: center.x + dx * screen.cos - dy * screen.sin,
				y: center.y + dx * screen.sin + dy * screen.cos,
			},
		)
	}
}

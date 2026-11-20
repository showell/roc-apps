## Figure is how the movie's flat figures are drawn: a robot, the dancer, the
## drum major's drumstick. A figure is laid out in metres from its feet,
## across from its middle and up from the ground, and a Place says where its
## feet are on the screen and how many pixels a metre is there, so the same
## figure serves near and far.
import lib.Brush
import lib.CurvedShapes
import lib.Pixels
import lib.Point
import lib.Shapes

Figure :: [].{

	## Where the screen is for one figure: its feet, and pixels a metre.
	Place : {
		x : F64,
		y : F64,
		scale : F64,
	}

	## A spot on the figure, in metres from its feet.
	Spot : { across : F64, up : F64 }

	screen_point : Figure.Place, Figure.Spot -> Point
	screen_point = |place, spot| Point.at(
		place.x + spot.across * place.scale,
		place.y - spot.up * place.scale,
	)

	## A straight bar `width` metres wide.
	bar : Figure.Place,
	{
		from : Figure.Spot,
		to : Figure.Spot,
		width : F64,
		fill : Brush.Fill,
	} -> Shapes.Shape
	bar = |place, { from, to, width, fill }|
		Shapes.line(
			{
				from: screen_point(place, from),
				to: screen_point(place, to),
				width: Pixels.of(width * place.scale),
			},
			fill,
		)

	## A round dot `radius` metres across.
	dot : Figure.Place,
	{
		at : Figure.Spot,
		radius : F64,
		fill : Brush.Fill,
	} -> Shapes.Shape
	dot = |place, { at, radius, fill }| Disc({
		center: screen_point(place, at),
		radius: Pixels.of(radius * place.scale),
		fill,
	})

	## A rounded box, `left` and `bottom` its lower left corner in metres.
	box : Figure.Place,
	{
		left : F64,
		bottom : F64,
		width : F64,
		height : F64,
		corner : F64,
		fill : Brush.Fill,
	} -> Shapes.Shape
	box = |
		place,
		{
			left,
			bottom,
			width,
			height,
			corner,
			fill,
		},
	|
		CurvedShapes.rounded_rect(
			{
				top_left: screen_point(place, { across: left, up: bottom + height }),
				width: Pixels.of(width * place.scale),
				height: Pixels.of(height * place.scale),
				corner_radius: Pixels.of(corner * place.scale),
				corner_steps: 3,
			},
			fill,
		)

	## The far end of a bone `length` metres long from `start`, at `angle`
	## radians from straight down, positive to the screen's right.
	bone_end : Figure.Spot, { angle : F64, length : F64 } -> Figure.Spot
	bone_end = |start, { angle, length }| {
		across: start.across + angle.sin() * length,
		up: start.up - angle.cos() * length,
	}

	## Where the knee of a leg goes, from the hip and the ankle and the two
	## bones' lengths: the one of the two places the bones can meet that is
	## in front, toward the screen's right, as a knee bends. An ankle farther
	## off than the leg is long is out of reach: the leg goes straight toward
	## it, and `ankle` is where the foot really ends up.
	knee_between : {
		hip : Figure.Spot,
		ankle : Figure.Spot,
		thigh : F64,
		shin : F64,
	} -> { knee : Figure.Spot, ankle : Figure.Spot }
	knee_between = |{ hip, ankle, thigh, shin }| {
		leg = two_bones({
			root: hip,
			tip: ankle,
			first: thigh,
			second: shin,
			bend: TowardFront,
		})
		{ knee: leg.joint, ankle: leg.tip }
	}

	## Where the elbow of an arm goes, from the shoulder and the hand, as
	## `knee_between` finds a knee, except that an elbow bends down, toward the
	## ground. A hand out of reach is where the straight arm points.
	elbow_between : {
		shoulder : Figure.Spot,
		hand : Figure.Spot,
		upper : F64,
		fore : F64,
	} -> { elbow : Figure.Spot, hand : Figure.Spot }
	elbow_between = |{ shoulder, hand, upper, fore }| {
		arm = two_bones({
			root: shoulder,
			tip: hand,
			first: upper,
			second: fore,
			bend: TowardGround,
		})
		{ elbow: arm.joint, hand: arm.tip }
	}

	## The angle of a bone from `from` to `to`, from straight down, positive
	## to the screen's right, as `bone_end` takes it.
	angle_from_down : Figure.Spot, Figure.Spot -> F64
	angle_from_down = |from, to| F64.atan2({ x: from.up - to.up, y: to.across - from.across })
}

# Two bones from `root` toward `tip`, and the joint between them on the
# side `bend` asks for.
two_bones : {
	root : Figure.Spot,
	tip : Figure.Spot,
	first : F64,
	second : F64,
	bend : [TowardFront, TowardGround],
} -> { joint : Figure.Spot, tip : Figure.Spot }
two_bones = |{ root, tip, first, second, bend }| {
	dx = tip.across - root.across
	dy = tip.up - root.up
	wanted = (dx * dx + dy * dy).sqrt()
	reach = (first + second) * 0.999
	if wanted >= reach or wanted < 0.0001 {
		# Straight toward the tip, or straight down when it is at the root.
		unit =
			if wanted < 0.0001 {
				{ across: 0.0, up: -1.0 }
			} else {
				{ across: dx / wanted, up: dy / wanted }
			}
		{
			joint: { across: root.across + unit.across * first, up: root.up + unit.up * first },
			tip: { across: root.across + unit.across * reach, up: root.up + unit.up * reach },
		}
	} else {
		along = (first * first - second * second + wanted * wanted) / (2.0 * wanted)
		off = (first * first - along * along).max(0.0).sqrt()
		base = { across: root.across + dx * along / wanted, up: root.up + dy * along / wanted }
		# The two sides of the line from root to tip; the joint takes the one
		# `bend` asks for.
		side = { across: 0.0 - dy / wanted, up: dx / wanted }
		leaning =
			match bend {
				TowardFront => side.across
				TowardGround => 0.0 - side.up
			}
		sign = if leaning >= 0.0 {
			1.0
		} else {
			-1.0
		}
		{
			joint: {
				across: base.across + sign * off * side.across,
				up: base.up + sign * off * side.up,
			},
			tip,
		}
	}
}

# A knee bends forward, and its bones keep their lengths.
expect {
	leg = Figure.knee_between({
		hip: { across: 0.0, up: 0.8 },
		ankle: { across: 0.1, up: 0.0 },
		thigh: 0.43,
		shin: 0.43,
	})
	thigh = ((leg.knee.across * leg.knee.across) + (leg.knee.up - 0.8) * (leg.knee.up - 0.8)).sqrt()
	leg.knee.across > 0.1 and (thigh - 0.43).abs() < 0.0001
}

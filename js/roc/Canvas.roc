## This module holds what a JavaScript program can ask of the host it runs
## on: the effects it has (a line logged, a shape drawn), the input it reads
## (the pointer, a key), and the turtle that turns moves into lines.
##
## **AN EFFECT HAPPENS WHEN THE PROGRAM CALLS FOR IT.** The interpreter hands
## each one to the host (`Host.emit!`) at the moment the program makes it, in
## program order, so a draw, a log and another draw reach the host in that
## order, and a program that stops halfway has drawn what it drew before the
## stop. A read (`Host.pointer!`, `Host.key!`) is asked of the host when the
## program asks for it.
##
## Every effect has one written form, `Canvas.line_of`: the page's host reads
## it to paint, and the recording host (js-canvas) prints it, so a sample's
## golden log is the very text the page paints from.
import Heap
import NumberText

Canvas :: [].{
	Effect : [
		Log(Str),
		Background(Str),
		Fill(Str),
		NoFill,
		Stroke({ color : Str, width : F64 }),
		NoStroke,
		Line(
			{
				x1 : F64,
				y1 : F64,
				x2 : F64,
				y2 : F64,
			},
		),
		Rect(
			{
				x : F64,
				y : F64,
				w : F64,
				h : F64,
			},
		),
		Circle(
			{
				x : F64,
				y : F64,
				r : F64,
			},
		),
		Ellipse(
			{
				x : F64,
				y : F64,
				rx : F64,
				ry : F64,
			},
		),
		# The corners' coordinates, x then y, corner by corner.
		Polygon(List(F64)),
		Words(
			{
				text : Str,
				x : F64,
				y : F64,
				size : F64,
			},
		),
	]

	Axis : [X, Y]

	KeyState : [Down, Up]

	## The host's effects and reads, which the interpreter calls in program
	## order. A record, not a reference into the machine, so passing it costs
	## nothing and refers to no heap.
	## `collected!` is told of each collection once it has swept: the heap's
	## cells, the freed ones among them, and the cells its roots reached. It
	## is no effect of the program's, so no budget counts it.
	Host : {
		emit! : Canvas.Effect => {},
		pointer! : Canvas.Axis => F64,
		key! : Str => Canvas.KeyState,
		collected! : { cells : U64, live : U64 } => {},
	}

	## Where the turtle stands, the way it faces in degrees clockwise from up,
	## and whether its moves draw.
	Turtle : {
		x : F64,
		y : F64,
		heading : F64,
		pen : [Down, Up],
	}

	## The page's rails, which the recording host holds a program to as well:
	## the statements and effects of the run before the first frame, and of
	## each frame after.
	run_limits : { steps : U64, effects : U64 }
	run_limits = { steps: 3000000, effects: 20000 }

	frame_limits : { steps : U64, effects : U64 }
	frame_limits = { steps: 300000, effects: 20000 }

	## The frames the page calls in a second. The time a frame is called with
	## is its number over this, so a frame's `t` is the same on the page, at
	## any speed, and in the recording host.
	frames_per_second : U64
	frames_per_second = 30

	## The turtle at the start of a run: the canvas's middle, facing up, its
	## pen down.
	turtle_start : Canvas.Turtle
	turtle_start = {
		x: 200.0,
		y: 200.0,
		heading: 0.0,
		pen: Down,
	}

	# ---- the shapes ------------------------------------------------------------

	## The effect a drawing builtin's call makes, or why its arguments can't
	## make one.
	## A builtin's arguments, and the heap they may refer to.
	Given : { arguments : List(Heap.Value), cells : List(Heap.Cell) }

	effect_of : Heap.Paint, Canvas.Given -> Try(Canvas.Effect, [Unsupported(Str)])
	effect_of = |paint, { arguments, cells }|
		match paint {
			Background => Ok(
				Background(Canvas.color_at(arguments, { position: 0, name: "background" })?),
			)
			Fill => Ok(Fill(Canvas.color_at(arguments, { position: 0, name: "fill" })?))
			NoFill => Ok(NoFill)
			Stroke => Ok(
				Stroke({
					color: Canvas.color_at(arguments, { position: 0, name: "stroke" })?,
					width: Canvas.optional_number(
						arguments,
						{
							position: 1,
							default: 1.0,
							name: "stroke",
						},
					)?,
				}),
			)
			NoStroke => Ok(NoStroke)
			Line => {
				n = Canvas.numbers_given(arguments, { count: 4, call: "line(x1, y1, x2, y2)" })?
				Ok(
					Line({
						x1: Canvas.at(n, 0),
						y1: Canvas.at(n, 1),
						x2: Canvas.at(n, 2),
						y2: Canvas.at(n, 3),
					}),
				)
			}
			Rect => {
				n = Canvas.numbers_given(arguments, { count: 4, call: "rect(x, y, w, h)" })?
				Ok(
					Rect({
						x: Canvas.at(n, 0),
						y: Canvas.at(n, 1),
						w: Canvas.at(n, 2),
						h: Canvas.at(n, 3),
					}),
				)
			}
			Circle => {
				n = Canvas.numbers_given(arguments, { count: 3, call: "circle(x, y, r)" })?
				Ok(
					Circle({
						x: Canvas.at(n, 0),
						y: Canvas.at(n, 1),
						r: Canvas.at(n, 2),
					}),
				)
			}
			Ellipse => {
				n = Canvas.numbers_given(arguments, { count: 4, call: "ellipse(x, y, rx, ry)" })?
				Ok(
					Ellipse({
						x: Canvas.at(n, 0),
						y: Canvas.at(n, 1),
						rx: Canvas.at(n, 2),
						ry: Canvas.at(n, 3),
					}),
				)
			}
			Polygon => Ok(Polygon(Canvas.corners(cells, arguments)?))
			Words => {
				words = match arguments.first() {
					Ok(Text(text)) => text
					Ok(Number(number)) => NumberText.text_for(number)
					_ => return Err(Unsupported("unsupported: text(words, x, y, size) of words that are not a string or a number"))
				}
				n = Canvas.numbers_given(
					arguments.drop_first(1),
					{ count: 2, call: "text(words, x, y, size)" },
				)?
				Ok(
					Words({
						text: words,
						x: Canvas.at(n, 0),
						y: Canvas.at(n, 1),
						size: Canvas.optional_number(
							arguments,
							{
								position: 3,
								default: 16.0,
								name: "text",
							},
						)?,
					}),
				)
			}
		}

	# The first `count` arguments, each a number, or why not.
	numbers_given : List(Heap.Value),
	{ count : U64, call : Str } -> Try(
		List(F64),
		[Unsupported(Str)],
	)
	numbers_given = |arguments, { count, call }| {
		var $got = []
		var $i = 0
		var $ok = True
		while $i < count {
			match arguments.get($i) {
				Ok(Number(number)) => {
					$got = $got.append(number)
				}
				_ => {
					$ok = False
				}
			}
			$i = $i + 1
		}
		if $ok {
			Ok($got)
		} else {
			Err(Unsupported("unsupported: ${call} of anything but numbers"))
		}
	}

	at : List(F64), U64 -> F64
	at = |given, position| given.get(position) ?? crash "Canvas.at: Canvas.numbers_given answers as many as it is asked for"

	# The argument at `position`, a number, or `default` when the call leaves
	# it out.
	optional_number : List(Heap.Value),
	{
		position : U64,
		default : F64,
		name : Str,
	} -> Try(F64, [Unsupported(Str)])
	optional_number = |arguments, { position, default, name }|
		match arguments.get(position) {
			Ok(Number(number)) => Ok(number)
			Ok(Undefined) | Err(OutOfBounds) => Ok(default)
			Ok(_) => Err(Unsupported("unsupported: ${name} of anything but a number there"))
		}

	## A color the canvas is handed as it is written, a CSS color string
	## (`"tomato"`, `"#3a7"`, `"rgb(20, 120, 200)"`). It is checked for its
	## characters, not its sense: the page's canvas leaves its color as it was
	## for a string it doesn't know, as a browser's does.
	color_at : List(Heap.Value), { position : U64, name : Str } -> Try(Str, [Unsupported(Str)])
	color_at = |arguments, { position, name }|
		match arguments.get(position) {
			Ok(Text(color)) if Canvas.is_color_text(color) => Ok(color)
			_ => Err(Unsupported("unsupported: ${name} of anything but a CSS color string"))
		}

	is_color_text : Str -> Bool
	is_color_text = |color| {
		bytes = color.to_utf8()
		!bytes.is_empty() and bytes.len() <= 64 and bytes.all(Canvas.is_color_byte)
	}

	is_color_byte : U8 -> Bool
	is_color_byte = |byte|
		(byte >= 'a' and byte <= 'z')
			or (byte >= 'A' and byte <= 'Z')
			or (byte >= '0' and byte <= '9')
			or byte == '#'
			or byte == '('
			or byte == ')'
			or byte == ','
			or byte == '.'
			or byte == '%'
			or byte == ' '

	# A polygon's corners, from an array of `[x, y]` arrays, three or more.
	corners : List(Heap.Cell), List(Heap.Value) -> Try(List(F64), [Unsupported(Str)])
	corners = |cells, arguments| {
		refused = Unsupported("unsupported: polygon(points) of anything but an array of three or more [x, y] arrays")
		points = match arguments.first() {
			Ok(Reference(id)) => match Heap.cell_at(cells, id) {
				Array(items) => items
				_ => return Err(refused)
			}
			_ => return Err(refused)
		}
		if points.len() < 3 {
			return Err(refused)
		}
		var $coordinates = []
		for point in points {
			match point {
				Reference(id) => match Heap.cell_at(cells, id) {
					Array([Number(x), Number(y)]) => {
						$coordinates = $coordinates.append(x).append(y)
					}
					_ => return Err(refused)
				}
				_ => return Err(refused)
			}
		}
		Ok($coordinates)
	}

	# ---- the turtle ------------------------------------------------------------

	## The turtle after a move, and the line it drew, if it drew one.
	Moved : { turtle : Canvas.Turtle, drawn : [Drew(Canvas.Effect), Nothing] }

	moved : Canvas.Turtle,
	{
		move : Heap.Move,
		arguments : List(Heap.Value),
	} -> Try(Canvas.Moved, [Unsupported(Str)])
	moved = |turtle, { move, arguments }|
		match move {
			Forward => {
				n = Canvas.numbers_given(arguments, { count: 1, call: "forward(distance)" })?
				Ok(Canvas.walked(turtle, Canvas.at(n, 0)))
			}
			Back => {
				n = Canvas.numbers_given(arguments, { count: 1, call: "back(distance)" })?
				Ok(Canvas.walked(turtle, -Canvas.at(n, 0)))
			}
			Turn => {
				n = Canvas.numbers_given(arguments, { count: 1, call: "turn(degrees)" })?
				heading = Canvas.normal_heading(turtle.heading + Canvas.at(n, 0))
				Ok({ turtle: { ..turtle, heading: heading }, drawn: Nothing })
			}
			PenUp => Ok({ turtle: { ..turtle, pen: Up }, drawn: Nothing })
			PenDown => Ok({ turtle: { ..turtle, pen: Down }, drawn: Nothing })
			Goto => {
				n = Canvas.numbers_given(arguments, { count: 2, call: "goto(x, y)" })?
				Ok(Canvas.went(turtle, { x: Canvas.at(n, 0), y: Canvas.at(n, 1) }))
			}
		}

	walked : Canvas.Turtle, F64 -> Canvas.Moved
	walked = |turtle, distance| {
		{ sin, cos } = Canvas.direction(turtle.heading)
		Canvas.went(turtle, { x: turtle.x + distance * sin, y: turtle.y - distance * cos })
	}

	went : Canvas.Turtle, { x : F64, y : F64 } -> Canvas.Moved
	went = |turtle, to| {
		drawn = match turtle.pen {
			Down => Drew(
				Line({
					x1: turtle.x,
					y1: turtle.y,
					x2: to.x,
					y2: to.y,
				}),
			)
			Up => Nothing
		}
		{ turtle: { ..turtle, x: to.x, y: to.y }, drawn: drawn }
	}

	# A heading in [0, 360).
	normal_heading : F64 -> F64
	normal_heading = |degrees| degrees - 360.0 * degrees.div_floor_by(360.0)

	# The sine and cosine of a heading, exact on the four square ones, so a
	# turtle that walks a square ends where it began.
	direction : F64 -> { sin : F64, cos : F64 }
	direction = |heading|
		if heading == 0.0 {
			{ sin: 0.0, cos: 1.0 }
		} else if heading == 90.0 {
			{ sin: 1.0, cos: 0.0 }
		} else if heading == 180.0 {
			{ sin: 0.0, cos: -1.0 }
		} else if heading == 270.0 {
			{ sin: -1.0, cos: 0.0 }
		} else {
			radians = heading * 3.141592653589793 / 180.0
			{ sin: radians.sin(), cos: radians.cos() }
		}

	# ---- the written form ------------------------------------------------------

	## An effect as one line of text, named as the program calls it, its
	## numbers as JavaScript's `String(n)` writes them. A color is the line's
	## last word, and a log's or a text's words are the rest of the line, with
	## a line break written `\n` and a backslash `\\`.
	line_of : Canvas.Effect -> Str
	line_of = |effect|
		match effect {
			Log(text) => "log ${Canvas.escaped(text)}"
			Background(color) => "background ${color}"
			Fill(color) => "fill ${color}"
			NoFill => "noFill"
			Stroke({ color, width }) => "stroke ${Canvas.number_words([width])} ${color}"
			NoStroke => "noStroke"
			Line({ x1, y1, x2, y2 }) => "line ${Canvas.number_words([x1, y1, x2, y2])}"
			Rect({ x, y, w, h }) => "rect ${Canvas.number_words([x, y, w, h])}"
			Circle({ x, y, r }) => "circle ${Canvas.number_words([x, y, r])}"
			Ellipse({ x, y, rx, ry }) => "ellipse ${Canvas.number_words([x, y, rx, ry])}"
			Polygon(coordinates) => "polygon ${Canvas.number_words(coordinates)}"
			Words({ text, x, y, size }) => {
				place = Canvas.number_words([x, y, size])
				"text ${place} ${Canvas.escaped(text)}"
			}
		}

	number_words : List(F64) -> Str
	number_words = |values| Str.join_with(values.map(NumberText.text_for), " ")

	escaped : Str -> Str
	escaped = |text| {
		var $bytes = []
		for byte in text.to_utf8() {
			if byte == '\\' {
				$bytes = $bytes.append('\\').append('\\')
			} else if byte == '\n' {
				$bytes = $bytes.append('\\').append('n')
			} else {
				$bytes = $bytes.append(byte)
			}
		}
		Str.from_utf8($bytes) ?? crash "Canvas.escaped: a backslash and an n keep UTF-8 whole"
	}

	expect Canvas.line_of(
		Circle({
			x: 200.0,
			y: 150.5,
			r: 30.0,
		}),
	) == "circle 200 150.5 30"
	expect Canvas.line_of(Stroke({ color: "rgb(1, 2, 3)", width: 2.0 })) == "stroke 2 rgb(1, 2, 3)"
	expect Canvas.line_of(Log("a\\b\nc")) == "log a\\\\b\\nc"
	expect Canvas.line_of(
		Words({
			text: "hi there",
			x: 10.0,
			y: 20.0,
			size: 16.0,
		}),
	) == "text 10 20 16 hi there"
	expect Canvas.normal_heading(-90.0) == 270.0
	expect Canvas.normal_heading(450.0) == 90.0
	expect Canvas.is_color_text("#3a7") and Canvas.is_color_text("rgb(20, 120, 200)")
	expect !Canvas.is_color_text("") and !Canvas.is_color_text("red;\n")
}

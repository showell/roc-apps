## ChessBoard draws the board a chess toy shows, and says which square the
## pointer is over. The board is 68 pixels a square, rank 8 at the top and a1
## at the lower left, with each file's letter along rank 1 and each rank's
## number up file a. Over the squares go the two overlays, the glow on the
## newest piece, the hover marks and the pieces with their move numbers, in
## that order, so a later one paints over an earlier.
import lib.Brush
import lib.CurvedShapes
import lib.Math
import lib.Pixels
import lib.Point
import lib.Shapes

ChessBoard :: [].{

	## The board's top left corner on the page, and a square's side.
	left : F64
	left = 58.0

	top : F64
	top = 54.0

	square_side : F64
	square_side = 68.0

	## The square under `point`, or `OffBoard`.
	square_at : Math.Vec2 -> Try(U8, [OffBoard])
	square_at = |point| {
		column = ((point.x.to_f64() - ChessBoard.left) / ChessBoard.square_side).floor_to_i64_try() ?? crash "ChessBoard.square_at: the pointer is at no finite place"
		row_from_top = ((point.y.to_f64() - ChessBoard.top) / ChessBoard.square_side).floor_to_i64_try() ?? crash "ChessBoard.square_at: the pointer is at no finite place"
		if column < 0 or column > 7 or row_from_top < 0 or row_from_top > 7 {
			Err(OffBoard)
		} else {
			Ok(((7 - row_from_top) * 8 + column).to_u8_wrap())
		}
	}

	## What the board shows at one moment, beside how the toy draws it.
	View : {
		board : List(I8),
		pieces_shown : U64,
		dead_ends : List(Bool),
		impossible : List(Bool),
		hover : [Over(U8), Away],
		moves_from : List(List(U8)),
		piece : Str,
	}

	## The board's shapes.
	board_shapes : ChessBoard.View -> List(Shapes.Shape)
	board_shapes = |view| {
		newest = view.pieces_shown.to_i64_wrap() - 1
		List.join([
			List.from_iter(U64.until(0, 64)).map(square_shapes).join(),
			overlay_shapes(view),
			frontier_shapes(view.board, newest),
			hover_shapes(view),
			piece_shapes({ board: view.board, newest, piece: view.piece }),
		])
	}
}

## The two failure overlays. Indigo, a square no piece can live on right now,
## is the toy's, and the stronger fact, so it wins where both hold. Red, a
## dead end, is the tape's.
overlay_shapes : ChessBoard.View -> List(Shapes.Shape)
overlay_shapes = |view|
	List.map2(view.impossible, view.dead_ends, |impossible, dead_end| (impossible, dead_end))
		.map_with_index(
			|(impossible, dead_end), square|
				if impossible {
					[square_fill(square.to_u8_wrap(), indigo)]
				} else if dead_end {
					[square_fill(square.to_u8_wrap(), red)]
				} else {
					[]
				},
		)
		.join()

## The newest piece's square glows, so the search's frontier is easy to
## follow.
frontier_shapes : List(I8), I64 -> List(Shapes.Shape)
frontier_shapes = |board, newest|
	board.map_with_index(
		|number, square|
			if newest >= 0 and number.to_i64() == newest {
				[square_fill(square.to_u8_wrap(), glow)]
			} else {
				[]
			},
	).join()

## Over the hovered square: its outline, and a mark on each square its piece
## would reach, a dot where the square is open and a ring where a piece
## stands.
hover_shapes : ChessBoard.View -> List(Shapes.Shape)
hover_shapes = |view|
	match view.hover {
		Away => []
		Over(square) => {
			corner = square_corner(square)
			inset = 1.5
			outline = box_outline_shapes({
				x: corner.x + inset,
				y: corner.y + inset,
				side: ChessBoard.square_side - 2.0 * inset,
			})
			reached = view.moves_from.get(square.to_u64()) ?? crash "ChessBoard.hover_shapes: a square past the board"
			marks = reached.map(
				|target| {
					target_corner = square_corner(target)
					center = Point.at(target_corner.x + ChessBoard.square_side / 2.0, target_corner.y + ChessBoard.square_side / 2.0)
					open = (view.board.get(target.to_u64()) ?? crash "ChessBoard.hover_shapes: a square past the board") < 0
					if open {
						[Disc({ center, radius: Pixels.of(ChessBoard.square_side * 0.13), fill: Flat(open_dot) })]
					} else {
						CurvedShapes.ring_shapes(
							{
								center,
								radius: Pixels.of(ChessBoard.square_side * 0.3),
								line_width: Pixels.of(3.0),
								sides: 40,
							},
							Flat(taken_ring),
						)
					}
				},
			)
			List.concat(outline, marks.join())
		}
	}

## The four sides of a square box three pixels wide, as the stroke a canvas
## would draw centred on the box's edge.
box_outline_shapes : { x : F64, y : F64, side : F64 } -> List(Shapes.Shape)
box_outline_shapes = |{ x, y, side }| {
	half = 1.5
	edge = |left_x, top_y, width, height|
		Shapes.rectangle({
			top_left: Point.at(left_x, top_y),
			width: Pixels.of(width),
			height: Pixels.of(height),
			fill: Flat(hover_edge),
		})
	[
		edge(x - half, y - half, side + 2.0 * half, 2.0 * half),
		edge(x - half, y + side - half, side + 2.0 * half, 2.0 * half),
		edge(x - half, y + half, 2.0 * half, side - 2.0 * half),
		edge(x + side - half, y + half, 2.0 * half, side - 2.0 * half),
	]
}

## Each piece, with its move number counted from 1 in its top right corner.
## The newest is red.
piece_shapes : { board : List(I8), newest : I64, piece : Str } -> List(Shapes.Shape)
piece_shapes = |{ board, newest, piece }|
	board.map_with_index(
		|number, square|
			if number < 0 {
				[]
			} else {
				corner = square_corner(square.to_u8_wrap())
				color =
					if number.to_i64() == newest {
						newest_piece
					} else {
						older_piece
					}
				label = (number.to_i64() + 1).to_str()
				[
					Text({
						text: piece,
						x: corner.x + ChessBoard.square_side / 2.0,
						y: corner.y + ChessBoard.square_side / 2.0 + 20.0,
						size: piece_size,
						face: Code,
						align: Center,
						color,
					}),
					right_aligned_text({
						text: label,
						right: corner.x + ChessBoard.square_side - 3.0,
						baseline: corner.y + 11.0,
						size: 11.0,
						color: move_number_ink,
					}),
				]
			},
	).join()

## One square's fill, and its coordinate where the square is on rank 1 or
## file a.
square_shapes : U64 -> List(Shapes.Shape)
square_shapes = |index| {
	square = index.to_u8_wrap()
	corner = square_corner(square)
	rank = index // 8
	file = index % 8
	is_light = (rank + file) % 2 == 1
	(fill, ink) =
		if is_light {
			(light_square, dark_square)
		} else {
			(dark_square, light_square)
		}
	file_letter =
		if rank == 0 {
			letter = Str.from_utf8([97 + file.to_u8_wrap()]) ?? crash "ChessBoard.square_shapes: a file letter is ASCII"
			[
				right_aligned_text({
					text: letter,
					right: corner.x + ChessBoard.square_side - 3.0,
					baseline: corner.y + ChessBoard.square_side - 4.0,
					size: 10.0,
					color: ink,
				}),
			]
		} else {
			[]
		}
	rank_number =
		if file == 0 {
			[
				Text({
					text: (rank + 1).to_str(),
					x: corner.x + 3.0,
					y: corner.y + 10.0,
					size: 10.0,
					face: Code,
					align: Left,
					color: ink,
				}),
			]
		} else {
			[]
		}
	List.join([[square_fill(square, fill)], file_letter, rank_number])
}

## A line of monospace type whose right end is at `right`. A canvas sets the
## letters, so the line's width is the face's: six tenths of the size a
## letter.
right_aligned_text : {
	text : Str,
	right : F64,
	baseline : F64,
	size : F64,
	color : Brush.Rgba,
} -> Shapes.Shape
right_aligned_text = |{ text, right, baseline, size, color }| {
	width = text.count_utf8_bytes().to_f64() * size * 0.6
	Text({
		text,
		x: right - width / 2.0,
		y: baseline,
		size,
		face: Code,
		align: Center,
		color,
	})
}

## A square's top left corner on the page.
square_corner : U8 -> { x : F64, y : F64 }
square_corner = |square| {
	file = (square % 8).to_f64()
	rank = (square // 8).to_f64()
	{
		x: ChessBoard.left + file * ChessBoard.square_side,
		y: ChessBoard.top + (7.0 - rank) * ChessBoard.square_side,
	}
}

## A whole square in one colour.
square_fill : U8, Brush.Rgba -> Shapes.Shape
square_fill = |square, color| {
	corner = square_corner(square)
	Shapes.rectangle({
		top_left: Point.at(corner.x, corner.y),
		width: Pixels.of(ChessBoard.square_side),
		height: Pixels.of(ChessBoard.square_side),
		fill: Flat(color),
	})
}

## The size a piece is set at, 72 hundredths of a square, rounded.
piece_size : F64
piece_size = 49.0

light_square : Brush.Rgba
light_square = { r: 240.0, g: 217.0, b: 181.0, a: 1.0 }

dark_square : Brush.Rgba
dark_square = { r: 181.0, g: 136.0, b: 99.0, a: 1.0 }

indigo : Brush.Rgba
indigo = { r: 80.0, g: 70.0, b: 190.0, a: 0.45 }

red : Brush.Rgba
red = { r: 190.0, g: 40.0, b: 40.0, a: 0.5 }

glow : Brush.Rgba
glow = { r: 255.0, g: 214.0, b: 102.0, a: 0.5 }

hover_edge : Brush.Rgba
hover_edge = { r: 70.0, g: 140.0, b: 220.0, a: 0.9 }

open_dot : Brush.Rgba
open_dot = { r: 60.0, g: 160.0, b: 90.0, a: 0.9 }

taken_ring : Brush.Rgba
taken_ring = { r: 200.0, g: 60.0, b: 60.0, a: 0.85 }

newest_piece : Brush.Rgba
newest_piece = { r: 122.0, g: 31.0, b: 31.0, a: 1.0 }

older_piece : Brush.Rgba
older_piece = { r: 34.0, g: 35.0, b: 42.0, a: 1.0 }

move_number_ink : Brush.Rgba
move_number_ink = { r: 20.0, g: 20.0, b: 25.0, a: 0.65 }

# a1 is the lower left square and h8 the upper right; a point off the board
# on any side is on no square.
expect ChessBoard.square_at({ x: 60, y: 596 }) == Ok(0)
expect ChessBoard.square_at({ x: 600, y: 56 }) == Ok(63)
expect ChessBoard.square_at({ x: 58 + 68 * 3 + 1, y: 54 + 68 * 4 + 1 }) == Ok(27)
expect [{ x: 57, y: 300 }, { x: 603, y: 300 }, { x: 300, y: 53 }, { x: 300, y: 599 }].all(|point| ChessBoard.square_at(point) == Err(OffBoard))

# The board's squares alternate, a1 dark and h1 light, and only rank 1 and
# file a carry a coordinate.
expect square_shapes(0).len() == 3 and square_shapes(7).len() == 2 and square_shapes(56).len() == 2 and square_shapes(27).len() == 1
expect square_shapes(0).first() == Ok(square_fill(0, dark_square)) and square_shapes(7).first() == Ok(square_fill(7, light_square))

## A grid of pixels kept as a row-major list: which pixels a stretch of a row
## or a column covers, where a pixel's centre is, and where a pixel sits in
## the list. A pixel belongs to a shape when its centre is inside the shape.
##
## `blend` writes in place. Its fallbacks `crash` rather than name the list,
## which would copy the whole list on every store (docs/roc-notes.md, "Speed
## and copying").
import lib.Brush
import PixelColor

PixelGrid :: [].{

	## A pixel's place along a row or down a column, counted from 0 at the
	## grid's left or top edge. The length of a row or a column is one too:
	## the place just past its last pixel. Rows and columns share the type
	## because a range and a centre mean the same along either, and the one
	## call that takes both, `pixel_index`, names each in its record.
	Coordinate := U16.{
		is_eq : _

		## The first pixel of a row or a column.
		first : PixelGrid.Coordinate
		first = PixelGrid.Coordinate.(0)

		## A place worked out in a wider type, once it is on the grid. A
		## negative one, or one past 65535, would wrap, so it crashes.
		from_i64 : I64 -> PixelGrid.Coordinate
		from_i64 = |place| {
			coordinate = place.to_u16_try()
				?? crash "PixelGrid.Coordinate.from_i64: a place off any grid"
			PixelGrid.Coordinate.(coordinate)
		}

		## The places from `start` up to but not including `end`; none when
		## `end` is not past `start`.
		until : PixelGrid.Coordinate, PixelGrid.Coordinate -> Iter(PixelGrid.Coordinate)
		until = |PixelGrid.Coordinate.(start), PixelGrid.Coordinate.(end)|
			U16.until(start, end).map(|place| PixelGrid.Coordinate.(place))

		to_f64 : PixelGrid.Coordinate -> F64
		to_f64 = |PixelGrid.Coordinate.(place)| place.to_f64()

		to_u64 : PixelGrid.Coordinate -> U64
		to_u64 = |PixelGrid.Coordinate.(place)| place.to_u64()
	}

	## Pixels from `start` up to but not including `end`; none when `end` is not
	## past `start`.
	CoordinateRange : { start : PixelGrid.Coordinate, end : PixelGrid.Coordinate }

	## The centre of the pixel at `place` in its row or column.
	pixel_center : PixelGrid.Coordinate -> F64
	pixel_center = |place| place.to_f64() + 0.5

	## The pixels of a row or a column `count` long whose centres fall in
	## [from, to). Each end is held to 0..`count` in an I64 before it becomes a
	## coordinate, so a place far off the grid never wraps onto it.
	pixels_between : {
		from : F64,
		to : F64,
		extent : PixelGrid.Coordinate,
	} -> PixelGrid.CoordinateRange
	pixels_between = |{ from, to, extent: PixelGrid.Coordinate.(extent) }| {
		length = extent.to_i64()
		{
			start: nearest_coordinate({ place: first_pixel_past(from), length }),
			end: nearest_coordinate({ place: first_pixel_past(to), length }),
		}
	}

	## Where the pixel at `row` and `column` is in the list of a grid `width`
	## pixels wide. The product is a U64, which holds any grid's size.
	pixel_index : {
		row : PixelGrid.Coordinate,
		column : PixelGrid.Coordinate,
		width : PixelGrid.Coordinate,
	} -> U64
	pixel_index = |{ row, column, width }| row.to_u64() * width.to_u64() + column.to_u64()

	## `color` laid over the pixel at `at`.
	blend : List(U32), { at : U64, color : Brush.Rgba } -> List(U32)
	blend = |pixels, { at, color }| {
		pixel = pixels.get(at) ?? crash "PixelGrid.blend: a pixel off the grid"
		new_pixel = PixelColor.over(pixel, color)
		pixels.set(at, new_pixel) ?? crash "PixelGrid.blend: a pixel off the grid"
	}
}

## The coordinate on a row or a column `length` long nearest `place`.
nearest_coordinate : { place : I64, length : I64 } -> PixelGrid.Coordinate
nearest_coordinate = |{ place, length }| {
	on_or_after_first = place.max(0)
	PixelGrid.Coordinate.from_i64(length.min(on_or_after_first))
}

## The first pixel whose centre is at or past `x`. A coordinate far off the
## grid (a point projected from just beside a camera) is first clamped to
## ±100000, well past any screen but small enough that its conversion to an
## integer can't wrap round to a pixel on it.
first_pixel_past : F64 -> I64
first_pixel_past = |x| {
	bounded = if x < -100000.0 {
		-100000.0
	} else if x > 100000.0 {
		100000.0
	} else {
		x
	}
	ceiling(bounded - 0.5)
}

## The least whole number at or above `x`, which is within ±100001. The
## conversion to an integer truncates toward zero, so it is the ceiling
## already unless `x` is above it.
ceiling : F64 -> I64
ceiling = |x| {
	toward_zero = x.to_i64_wrap()
	if toward_zero.to_f64() < x {
		toward_zero + 1
	} else {
		toward_zero
	}
}

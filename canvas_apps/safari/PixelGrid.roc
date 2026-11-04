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

	## Pixels from `start` up to but not including `end`; none when `end` is not
	## past `start`.
	Range : { start : I64, end : I64 }

	## The centre of the pixel at `index` in its row or column.
	pixel_center : I64 -> F64
	pixel_center = |index| I64.to_f64(index) + 0.5

	## The pixels of a row or a column `count` long whose centres fall in
	## [from, to).
	pixels_between : { from : F64, to : F64, count : I64 } -> PixelGrid.Range
	pixels_between = |{ from, to, count }| {
		start: I64.max(0, first_pixel_past(from)),
		end: I64.min(count, first_pixel_past(to)),
	}

	## Where the pixel at `row` and `column` is in the list of a grid `width`
	## pixels wide.
	pixel_index : { row : I64, column : I64, width : I64 } -> U64
	pixel_index = |{ row, column, width }| I64.to_u64_wrap(row * width + column)

	## `color` laid over the pixel at `at`.
	blend : List(U32), { at : U64, color : Brush.Rgba } -> List(U32)
	blend = |pixels, { at, color }| {
		pixel = pixels.get(at) ?? crash "PixelGrid.blend: a pixel off the grid"
		new_pixel = PixelColor.over(pixel, color)
		pixels.set(at, new_pixel) ?? crash "PixelGrid.blend: a pixel off the grid"
	}
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
	toward_zero = F64.to_i64_wrap(x)
	if I64.to_f64(toward_zero) < x {
		toward_zero + 1
	} else {
		toward_zero
	}
}

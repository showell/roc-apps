## DepthSort orders the things in a frame from far to near, so each is
## painted over the ones behind it. Things about as far away as each other
## keep the order they came in.
import lib.DeviceMath

DepthSort :: [].{

	## Which thing in the frame a key stands for: its kind, and its place in
	## that kind's list. A frame has at most one truck, so the truck has no
	## place.
	Subject : [
		Tree(U64),
		Tower(U64),
		Critter(U64),
		Cat(U64),
		Truck,
		Rail(U64),
		Bird(U64),
	]

	## A thing to draw, as the sort sees it: how far ahead it is, and which
	## thing it is.
	DepthKey : { forward : F64, subject : DepthSort.Subject }

	## `items` from far to near, by `depth_of`: a stable merge sort.
	sort_by : List(item), (item -> F64) -> List(item)
	sort_by = |items, depth_of|
		if items.len() <= 1 {
			items
		} else {
			half = items.len() // 2
			merge({
				first: DepthSort.sort_by(items.take_first(half), depth_of),
				second: DepthSort.sort_by(items.drop_first(half), depth_of),
				depth_of,
			})
		}

	## Whether depth `this` is farther than `that` by more than a tie's
	## slack. The slack is relative to `that`, but never less than it is at
	## a depth of 1.
	is_farther : { this : F64, that : F64 } -> Bool
	is_farther = |{ this, that }| {
		slack = tie_slack * DeviceMath.real_max(DeviceMath.real_abs(that), 1.0)
		(this - that) > slack
	}
}

## About 6e-8, as its exact bits.
tie_slack : F64
tie_slack = F64.from_bits(4499125899939309867)

## Two lists, each far to near, merged into one. Of two items about as far
## away, the one from `first` goes first.
merge : {
	first : List(item),
	second : List(item),
	depth_of : (item -> F64),
} -> List(item)
merge = |{ first, second, depth_of }|
	merge_onto(
		[],
		{
			first,
			second,
			depth_of,
			at_first: 0,
			at_second: 0,
		},
	)

## The merge carried on from `merged`, with `first` taken up to `at_first`
## and `second` up to `at_second`.
merge_onto : List(item),
{
	first : List(item),
	second : List(item),
	depth_of : (item -> F64),
	at_first : U64,
	at_second : U64,
} -> List(item)
merge_onto = |merged, { first, second, depth_of, at_first, at_second }|
	match (first.get(at_first), second.get(at_second)) {
		(Ok(from_first), Ok(from_second)) =>
			if DepthSort.is_farther({ this: depth_of(from_second), that: depth_of(from_first) }) {
				merge_onto(
					merged.append(from_second),
					{
						first,
						second,
						depth_of,
						at_first,
						at_second: at_second + 1,
					},
				)
			} else {
				merge_onto(
					merged.append(from_first),
					{
						first,
						second,
						depth_of,
						at_first: at_first + 1,
						at_second,
					},
				)
			}
		(Ok(_), Err(OutOfBounds)) => merged.concat(first.drop_first(at_first))
		(Err(OutOfBounds), Ok(_)) => merged.concat(second.drop_first(at_second))
		(Err(OutOfBounds), Err(OutOfBounds)) => merged
	}

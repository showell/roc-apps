## DepthSort orders the things in a frame from far to near, so each is
## painted over the ones behind it. Things about as far away as each other
## keep the order they came in.
import Distance

DepthSort :: [].{

	## `items` from far to near, by `depth_of`: a stable merge sort.
	sort_by : List(item), (item -> Distance) -> List(item)
	sort_by = |items, depth_of|
		if items.len() <= 1 {
			items
		} else {
			half = items.len() // 2
			merge({
				first_items: DepthSort.sort_by(items.take_first(half), depth_of),
				second_items: DepthSort.sort_by(items.drop_first(half), depth_of),
				depth_of,
			})
		}
}

## Whether depth `this` is farther than `that` by more than a tie's
## slack. The slack is relative to `that`, but never less than it is at
## a depth of 1.
is_farther : { this : Distance, that : Distance } -> Bool
is_farther = |{ this, that }| {
	slack = tie_slack * that.to_metres().abs().max(1.0)
	this.minus(that).to_metres() > slack
}

## How near two depths are, as a share of the depth, to count as a tie: about
## 5.9e-8, one part in 17 million, a little under single precision's rounding
## step. Two things that stand at one place but whose depths were worked out
## by different sums can differ in their last bits; within this slack they keep
## the order they came in, so which is painted over the other is decided by
## that order, not by rounding. Held frames depend on every bit of it, so it is
## written as its exact bits.
tie_slack : F64
tie_slack = F64.from_bits(4499125899939309867)

## Two lists, each far to near, merged into one. Of two items about as far
## away, the one from `first_items` goes first.
merge : {
	first_items : List(item),
	second_items : List(item),
	depth_of : (item -> Distance),
} -> List(item)
merge = |{ first_items, second_items, depth_of }| {
	first_count = first_items.len()
	second_count = second_items.len()
	var $merged = List.with_capacity(first_count + second_count)
	var $at_first = 0
	var $at_second = 0
	while $at_first < first_count and $at_second < second_count {
		from_first = first_items.get($at_first) ?? crash "DepthSort.merge: past the first list's end"
		from_second = second_items.get($at_second) ?? crash "DepthSort.merge: past the second list's end"
		if is_farther({ this: depth_of(from_second), that: depth_of(from_first) }) {
			$merged = $merged.append(from_second)
			$at_second = $at_second + 1
		} else {
			$merged = $merged.append(from_first)
			$at_first = $at_first + 1
		}
	}
	$merged.concat(first_items.drop_first($at_first)).concat(second_items.drop_first($at_second))
}

# Ten keys, each with its own place, so the order they come out in shows
# whether ties kept theirs.
expect
	DepthSort.sort_by(
		[
			{ forward: Distance.metres(30.0), place: 0 },
			{ forward: Distance.metres(10.0), place: 1 },
			{ forward: Distance.metres(30.0), place: 2 },
			{ forward: Distance.metres(50.0), place: 3 },
			{ forward: Distance.metres(10.0), place: 4 },
			{ forward: Distance.metres(20.0), place: 5 },
			{ forward: Distance.metres(30.0), place: 6 },
			{ forward: Distance.metres(40.0), place: 7 },
			{ forward: Distance.metres(10.0), place: 8 },
			{ forward: Distance.metres(5.0), place: 9 },
		],
		|key| key.forward,
	)
		== [
			{ forward: Distance.metres(50.0), place: 3 },
			{ forward: Distance.metres(40.0), place: 7 },
			{ forward: Distance.metres(30.0), place: 0 },
			{ forward: Distance.metres(30.0), place: 2 },
			{ forward: Distance.metres(30.0), place: 6 },
			{ forward: Distance.metres(20.0), place: 5 },
			{ forward: Distance.metres(10.0), place: 1 },
			{ forward: Distance.metres(10.0), place: 4 },
			{ forward: Distance.metres(10.0), place: 8 },
			{ forward: Distance.metres(5.0), place: 9 },
		]

## A pair of things at these depths, first 0 and then 1, as the sort orders them.
sorted_places : { first : F64, second : F64 } -> List(U64)
sorted_places = |{ first, second }| {
	keys = [
		{ forward: Distance.metres(first), place: 0 },
		{ forward: Distance.metres(second), place: 1 },
	]
	DepthSort.sort_by(keys, |key| key.forward).map(|key| key.place)
}

# At each depth the first pair is within the tie's slack and keeps its order;
# the second is not, and its farther thing goes first.
expect sorted_places({ first: 100.0, second: 100.000004 }) == [0, 1]
expect sorted_places({ first: 100.0, second: 100.00001 }) == [1, 0]
expect sorted_places({ first: 0.5, second: 0.50000004 }) == [0, 1]
expect sorted_places({ first: 0.5, second: 0.5000001 }) == [1, 0]

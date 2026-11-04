## These are Billboards' checks: which critters are in view, behind the
## camera or too small to draw, and what a billboard carries.
app [main!] {
	lib: "../lib/main.roc",
}

import Billboards
import Grade

## A cow 2.5 m to the right, at each distance and height.
sightings : List(Billboards.Sighting)
sightings =
	[
		{ forward: (-5.0), height: 1.0 },
		{ forward: 0.3, height: 1.0 },
		{ forward: 0.4, height: 1.0 },
		{ forward: 0.5, height: 1.0 },
		{ forward: 300.0, height: 1.0 },
		{ forward: 342.0, height: 1.0 },
		{ forward: 343.0, height: 1.0 },
		{ forward: 400.0, height: 1.0 },
		{ forward: 10.0, height: 0.0 },
		{ forward: 50.0, height: 0.9 },
	].map(
		|{ forward, height }|
			Billboards.sighting({ at: { right: 2.5, forward }, height, codepoint: 128004, facing: FacesRight }),
	)

is_in_view : Billboards.Sighting -> Bool
is_in_view = |sighting|
	match sighting {
		InView(_) => True
		BehindCamera => False
		TooSmall => False
	}

is_too_small : Billboards.Sighting -> Bool
is_too_small = |sighting|
	match sighting {
		TooSmall => True
		InView(_) => False
		BehindCamera => False
	}

billboard_of : Billboards.Sighting -> Billboards.Billboard
billboard_of = |sighting|
	match sighting {
		InView(billboard) => billboard
		BehindCamera => crash "BillboardsSpec: this critter is in view"
		TooSmall => crash "BillboardsSpec: this critter is in view"
	}

near_cow : Billboards.Billboard
near_cow = billboard_of(sightings.get(3) ?? crash "BillboardsSpec: ten sightings")

left_bull : Billboards.Billboard
left_bull = billboard_of(Billboards.sighting({ at: { right: (-1.5), forward: 50.0 }, height: 1.6, codepoint: 128002, facing: FacesLeft }))

kept_got : List(Bool)
kept_got = sightings.map(is_in_view)

kept_want : List(Bool)
kept_want = [False, False, False, True, True, True, False, False, False, True]

culled_got : List(Bool)
culled_got = sightings.map(is_too_small)

culled_want : List(Bool)
culled_want = [False, False, False, False, False, False, True, True, True, False]

carried_real_got : List(F64)
carried_real_got = [near_cow.right, near_cow.forward, near_cow.height, left_bull.right, left_bull.forward, left_bull.height]

carried_real_want : List(F64)
carried_real_want = [2.5, 0.5, 1.0, (-1.5), 50.0, 1.6]

carried_int_got : List(I64)
carried_int_got = [near_cow.codepoint, left_bull.codepoint]

carried_int_want : List(I64)
carried_int_want = [128004, 128002]

carried_bool_got : List(Bool)
carried_bool_got = [near_cow.facing == FacesRight, left_bull.facing == FacesRight]

carried_bool_want : List(Bool)
carried_bool_want = [True, False]

harvest_got : List(I64)
harvest_got = [
	Billboards.billboards_in_view(sightings).len().to_i64_wrap(),
	Billboards.too_small_count(sightings),
	sightings.len().to_i64_wrap(),
]

harvest_want : List(I64)
harvest_want = [4, 3, 10]

floor_got : List(F64)
floor_got = [Billboards.min_critter_px]

floor_want : List(F64)
floor_want = [2.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.bools({
			name: "bb-kept ",
			got: kept_got,
			want: kept_want,
		}),
		Grade.bools({
			name: "bb-culled",
			got: culled_got,
			want: culled_want,
		}),
		Grade.reals({
			name: "bb-carry",
			got: carried_real_got,
			want: carried_real_want,
			tol: 0.0,
		}),
		Grade.ints({
			name: "bb-cp   ",
			got: carried_int_got,
			want: carried_int_want,
		}),
		Grade.bools({
			name: "bb-face ",
			got: carried_bool_got,
			want: carried_bool_want,
		}),
		Grade.ints({
			name: "bb-count",
			got: harvest_got,
			want: harvest_want,
		}),
		Grade.reals({
			name: "bb-floor",
			got: floor_got,
			want: floor_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}

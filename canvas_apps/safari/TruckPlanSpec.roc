## These are TruckPlan's checks: where on the chain the truck is found,
## whether it is in view, and the key the depth sort reads.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Frame
import Grade
import Truck
import TruckPlan
import World

segs : List(World.Segment)
segs = [
	World.route_segment(0),
	World.route_segment(1),
	World.route_segment(2),
]

here : Frame.Pose
here = {
	along: 0.0,
	across: 0.0,
	yaw: Angle.straight_ahead,
	half_width: 2.0,
}

lengths_got : List(F64)
lengths_got = segs.map(|seg| seg.length)

lengths_want : List(F64)
lengths_want = [500.0, 320.0, 400.0]

## What a truck `lead` metres ahead of a rider at the start of the chain is
## seen from, from `pose`, with its lights off.
truck_view : Frame.Pose, F64 -> TruckPlan.View
truck_view = |pose, lead| {
	road: {
		world: segs,
		chain: [0, 1, 2].map(World.SegmentIndex.number),
		pose,
	},
	lead,
	lights: { headlights: Off, brake_lights: Off },
}

truck_seen_from : Frame.Pose, F64 -> TruckPlan.TruckAt
truck_seen_from = |pose, lead| TruckPlan.in_view(truck_view(pose, lead))

lead_of : F64 -> TruckPlan.TruckAt
lead_of = |lead| truck_seen_from(here, lead)

## Whether the truck is in view.
is_ahead : TruckPlan.TruckAt -> Bool
is_ahead = |truck|
	match truck {
		Ahead(_) => True
		NoTruck => False
	}

## Where the truck is, for a lead that puts it in view.
ahead_of : F64 -> {
	position : Frame.ChainPosition,
	along : F64,
	across : F64,
	forward : F64,
	lights : Truck.Lights,
}
ahead_of = |lead|
	match lead_of(lead) {
		Ahead(truck) => truck
		NoTruck => crash "TruckPlanSpec: this lead puts the truck in view"
	}

present_got : List(Bool)
present_got = [
	100.0,
	499.0,
	600.0,
	900.0,
	2000.0,
	0.0,
	(0.0 - 50.0),
].map(|lead| is_ahead(lead_of(lead)))

present_want : List(Bool)
present_want = [True, True, True, True, False, False, False]

landed_got : List(I64)
landed_got = [100.0, 499.0, 600.0, 900.0].map(|lead| ahead_of(lead).position.to_i64())

landed_want : List(I64)
landed_want = [0, 0, 1, 2]

along_got : List(F64)
along_got = [100.0, 499.0, 600.0, 900.0].map(|lead| ahead_of(lead).along)

along_want : List(F64)
along_want = [100.0, 499.0, 100.0, 80.0]

across_got : List(F64)
across_got = [100.0, 499.0, 600.0, 900.0].map(|lead| ahead_of(lead).across)

across_want : List(F64)
across_want = [2.0, 2.0, 2.0, 2.0]

## The lights a truck in view shows, when it has `lights` on.
lights_shown : Truck.Lights -> Truck.Lights
lights_shown = |lights|
	match TruckPlan.in_view({ ..truck_view(here, 100.0), lights }) {
		Ahead(truck) => truck.lights
		NoTruck => crash "TruckPlanSpec: this lead puts the truck in view"
	}

lights_got : List(Bool)
lights_got = [
	{ headlights: Off, brake_lights: Off },
	{ headlights: Off, brake_lights: On },
	{ headlights: On, brake_lights: Off },
	{ headlights: On, brake_lights: On },
].map(|lights| lights_shown(lights) == lights)

lights_want : List(Bool)
lights_want = [True, True, True, True]

fwd_got : List(F64)
fwd_got = [ahead_of(100.0).forward, ahead_of(499.0).forward]

fwd_want : List(F64)
fwd_want = [100.0, 499.0]

none_flag_got : List(Bool)
none_flag_got = [is_ahead(NoTruck), is_ahead(lead_of(2000.0))]

none_flag_want : List(Bool)
none_flag_want = [False, False]

behind_got : List(Bool)
behind_got = [
	is_ahead(
		truck_seen_from(
			{
				along: 100.0,
				across: 0.0,
				yaw: Angle.straight_ahead,
				half_width: 2.0,
			},
			0.25,
		),
	),
	is_ahead(
		truck_seen_from(
			{
				along: 100.0,
				across: 0.0,
				yaw: Angle.straight_ahead,
				half_width: 2.0,
			},
			1.0,
		),
	),
]

behind_want : List(Bool)
behind_want = [False, True]

## The depth key of a truck in view.
key_of : F64 -> { forward : F64 }
key_of = |lead| {
	key = TruckPlan.depth_keys(lead_of(lead)).first()
		?? crash "TruckPlanSpec: a truck in view has a depth key"
	{ forward: key.forward }
}

items_got : List(I64)
items_got = [
	TruckPlan.depth_keys(lead_of(100.0)).len().to_i64_wrap(),
	TruckPlan.depth_keys(lead_of(2000.0)).len().to_i64_wrap(),
	TruckPlan.depth_keys(NoTruck).len().to_i64_wrap(),
	TruckPlan.depth_keys(lead_of(100.0)).count_if(|key| key.subject == Truck).to_i64_wrap(),
]

items_want : List(I64)
items_want = [1, 0, 0, 1]

item_fwd_got : List(F64)
item_fwd_got = [key_of(499.0).forward]

item_fwd_want : List(F64)
item_fwd_want = [499.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "tp-length",
			got: lengths_got,
			want: lengths_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "tp-presnt",
			got: present_got,
			want: present_want,
		}),
		Grade.ints({
			name: "tp-landed",
			got: landed_got,
			want: landed_want,
		}),
		Grade.reals({
			name: "tp-along ",
			got: along_got,
			want: along_want,
			tol: 0.0,
		}),
		Grade.reals({
			name: "tp-across",
			got: across_got,
			want: across_want,
			tol: 0.0,
		}),
		Grade.bools({
			name: "tp-lights",
			got: lights_got,
			want: lights_want,
		}),
		Grade.reals({
			name: "tp-fwd   ",
			got: fwd_got,
			want: fwd_want,
			tol: 0.0001,
		}),
		Grade.bools({
			name: "tp-nflag ",
			got: none_flag_got,
			want: none_flag_want,
		}),
		Grade.bools({
			name: "tp-behind",
			got: behind_got,
			want: behind_want,
		}),
		Grade.ints({
			name: "tp-items ",
			got: items_got,
			want: items_want,
		}),
		Grade.reals({
			name: "tp-ifwd  ",
			got: item_fwd_got,
			want: item_fwd_want,
			tol: 0.0001,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}

## The plan as the page reads it (main.ts's `Plan`): each truck's route with
## its stops, load and display minutes, the plan's totals, and the replay's
## frames, the start, one a move, and the end. Key order is the order
## solver.ts writes, which the judges compare as text.

import JsonOut
import Replay
import Route
import Seattle
import Solve
import Stop

PlanJson :: [].{

	plan_json_of : Solve.PagePlan -> JsonOut
	plan_json_of = |plan| {
		routes = plan.slot_routes.map_with_index(
			|r, i| {
				m = plan.minutes.get(i) ?? crash "PlanJson.plan_json_of: a route's minutes"
				time = plan.route_times.get(i) ?? crash "PlanJson.plan_json_of: a route's time"
				JsonOut.object([
					("stops", stops_json(r)),
					("orders", JsonOut.int(Route.load(r).to_i64_wrap())),
					("travel", JsonOut.int(m.travel)),
					("time", JsonOut.float(time)),
				])
			},
		)
		start = frame_json({
			routes: plan.trace.start_routes,
			touched: [],
			label: "start · ${plan.trace.start_routes.len().to_str()} clusters seeded",
		})
		moves = plan.trace.moves.map(
			|m| frame_json({
				routes: m.frame_routes,
				touched: m.touched,
				label: Replay.caption(m),
			}),
		)
		done = frame_json({
			routes: plan.slot_routes,
			touched: [],
			label: "done · trucks assigned to their lanes",
		})
		JsonOut.object([
			("routes", JsonOut.array(routes)),
			("totalTime", JsonOut.float(plan.time)),
			("travel", JsonOut.int(plan.travel)),
			("local", JsonOut.float(plan.local)),
			("service", JsonOut.int(plan.service)),
			("spread", JsonOut.float(plan.spread)),
			("log", JsonOut.array([])),
			("frames", JsonOut.array([start].concat(moves).append(done))),
			("unrouted", stops_json(plan.unrouted)),
		])
	}
}

stops_json : List(Stop) -> JsonOut
stops_json = |stops| JsonOut.array(stops.map(stop_json))

stop_json : Stop -> JsonOut
stop_json = |stop| {
	members = [
		("nbhd", JsonOut.string(Seattle.name_of(stop.nbhd))),
		("orders", JsonOut.int(stop.load().to_i64_wrap())),
		("houses", JsonOut.array(stop.houses.to_list().map(|h| JsonOut.int(h.to_i64())))),
	]
	match stop.pin {
		Free => JsonOut.object(members)
		Pinned(slot) => JsonOut.object(members.append(("pin", JsonOut.int(slot.to_i64_wrap()))))
	}
}

frame_json : {
	routes : List(List(Stop)),
	touched : List(Replay.HouseKey),
	label : Str,
} -> JsonOut
frame_json = |{ routes, touched, label }|
	JsonOut.object([
		("routes", JsonOut.array(routes.map(|r| JsonOut.object([("stops", stops_json(r))])))),
		("touched", JsonOut.array(touched.map(|k| JsonOut.string(Replay.key_name(k))))),
		("label", JsonOut.string(label)),
	])

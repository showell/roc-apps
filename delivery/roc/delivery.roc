## Seattle Delivery's solver, the app its Zig host links (roc/platform/).
## Each answer is a shift's, by its seed: the page's plan, or the facts the
## gold corpus pins.
app [gold_json, plan_json] { pf: platform "./platform/main.roc" }

import Gold
import JsonOut
import Orders
import PlanJson
import Solve

plan_json : U32 -> List(U8)
plan_json = |seed| {
	day = Solve.seattle_day(Orders.day_orders(seed))
	PlanJson.plan_json_of(Solve.page_plan(Solve.routes_traced(day))).to_bytes()
}

gold_json : U32 -> List(U8)
gold_json = |seed| Gold.gold_of(seed).to_bytes()

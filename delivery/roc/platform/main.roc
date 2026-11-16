## The platform the delivery solver runs on. Its host is the Zig in
## `delivery/src/`: `roc_seam.zig` declares these two functions and supplies the
## allocator, and `wasm.zig` (the page's `solver.wasm`) and `gold_check.zig`
## (the native judge) call them. Each takes a shift's seed and answers JSON as
## bytes: `roc_plan` the plan the page draws, `roc_gold` the facts the gold
## corpus pins. The Roc is built into an archive for each target, which the
## Zig links (`delivery/build.zig`).
platform ""
	requires {
		gold_json : U32 -> List(U8),
		plan_json : U32 -> List(U8)
	}
	exposes []
	packages {}
	provides { "roc_gold": gold_for_host, "roc_plan": plan_for_host }
	targets: {
		x64musl: {
			inputs: [app],
			output: Archive,
		},
		wasm32: {
			inputs: [app],
			output: Archive,
		},
	}

plan_for_host : U32 -> List(U8)
plan_for_host = |seed| plan_json(seed)

gold_for_host : U32 -> List(U8)
gold_for_host = |seed| gold_json(seed)

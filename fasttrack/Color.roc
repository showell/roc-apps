# Color -- the zones' colors and their order around the board, from
# Color.elm.
Color :: [].{
	get_zone_colors : U64 -> List(Str)
	get_zone_colors = |num_players| List.take_first(["red", "blue", "green", "purple", "aqua", "brown"], num_players)

	rotate_list : U64, List(a) -> List(a)
	rotate_list = |idx, lst| List.concat(List.drop_first(lst, idx), List.take_first(lst, idx))

	## The color `step` places after this one. A color that is not there
	## counts as index -1 going forward and 1 going back, as in Elm.
	shifted : Str, List(Str), I64, I64 -> Str
	shifted = |color, zone_colors, missing, step| {
		idx = match List.find_first_index(zone_colors, |c| c == color) {
			Ok(i) => U64.to_i64_wrap(i)
			Err(_) => missing
		}
		len = U64.to_i64_wrap(List.len(zone_colors))
		List.get(zone_colors, I64.to_u64_wrap(I64.mod_by(idx + step, len))) ?? "bogus"
	}

	next_zone_color : Str, List(Str) -> Str
	next_zone_color = |color, zone_colors| shifted(color, zone_colors, -1, 1)

	prev_zone_color : Str, List(Str) -> Str
	prev_zone_color = |color, zone_colors| shifted(color, zone_colors, 1, -1)
}

# tests/Example.elm, testZoneColors, plus the wrap the other way.
expect Color.prev_zone_color("green", ["red", "blue", "green"]) == "blue"
expect Color.next_zone_color("green", ["red", "blue", "green"]) == "red"
expect Color.prev_zone_color("red", ["red", "blue", "green"]) == "green"
expect Color.rotate_list(1, ["red", "blue", "green", "purple"]) == ["blue", "green", "purple", "red"]

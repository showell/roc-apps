# Color -- the zones' colors and their order around the board, from
# Color.elm.
Color :: [].{

	## The colors of a game's zones, in their order round the board (Color.elm's getZoneColors).
	get_zone_colors : U64 -> List(Str)
	get_zone_colors = |num_players| [
		"red",
		"blue",
		"green",
		"purple",
		"aqua",
		"brown",
	].take_first(num_players)

	rotate_list : U64, List(a) -> List(a)
	rotate_list = |idx, colors| colors.drop_first(idx).concat(colors.take_first(idx))

	## The color `step` places after this one. A color that is not there
	## counts as index -1 going forward and 1 going back, as in Elm.
	shifted_color : Str, List(Str), I64, I64 -> Str
	shifted_color = |color, zone_colors, missing, step| {
		idx = match zone_colors.find_first_index(|c| c == color) {
			Ok(i) => i.to_i64_wrap()
			Err(_) => missing
		}
		len = zone_colors.len().to_i64_wrap()
		zone_colors.get((idx + step).mod_by(len).to_u64_wrap()) ?? crash "Color.shifted_color: an index mod the colors' count is one of them"
	}

	next_zone_color : Str, List(Str) -> Str
	next_zone_color = |color, zone_colors| shifted_color(color, zone_colors, -1, 1)

	prev_zone_color : Str, List(Str) -> Str
	prev_zone_color = |color, zone_colors| shifted_color(color, zone_colors, 1, -1)
}

# tests/Example.elm, testZoneColors, plus the wrap the other way.
expect Color.prev_zone_color("green", ["red", "blue", "green"]) == "blue"
expect Color.next_zone_color("green", ["red", "blue", "green"]) == "red"
expect Color.prev_zone_color("red", ["red", "blue", "green"]) == "green"
expect Color.rotate_list(
	1,
	["red", "blue", "green", "purple"],
) == ["blue", "green", "purple", "red"]

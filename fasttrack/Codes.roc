# Codes -- a message as the number a click sends back.
#
# The page never builds a message: every clickable thing carries the code the
# view gave it, and a click hands that code to `update`. A location is its
# zone's place in the game's own (unrotated) color order and its place in
# Config.config_locations.
#
#     1              rotate the board ("done")
#     2              undo ("oops")
#     3              the computer's next click (the page's tick)
#     100 + i        play card i
#     200 + i        discard card i
#     300 + i        cover card i
#     10000 + loc    a piece's starting square
#     20000 + loc    a piece's end square
#
# where loc is 32 * zone + square, and the bullseye is 999.
import Config
import Type

Codes :: [].{
	rotate_board : U32
	rotate_board = 1

	undo : U32
	undo = 2

	## Not a message: FastTrack answers it with the computer's choice.
	agent_step : U32
	agent_step = 3


	activate_card : U64 -> U32
	activate_card = |idx| 100 + U64.to_u32_wrap(idx)

	discard_card : U64 -> U32
	discard_card = |idx| 200 + U64.to_u32_wrap(idx)

	cover_card : U64 -> U32
	cover_card = |idx| 300 + U64.to_u32_wrap(idx)

	bulls_eye : U32
	bulls_eye = 999

	location : List(Str), Type.PieceLocation -> U32
	location = |zone_colors, loc|
		match loc.zone {
			BullsEyeZone => bulls_eye
			NormalColor(color) => {
				zone = List.find_first_index(zone_colors, |c| c == color) ?? crash("Codes.location: no such zone")
				square = List.find_first_index(Config.config_locations, |l| l.id == loc.id) ?? crash("Codes.location: no such square")
				U64.to_u32_wrap(32 * zone + square)
			}
		}

	start_location : List(Str), Type.PieceLocation -> U32
	start_location = |zone_colors, loc| 10000 + location(zone_colors, loc)

	end_location : List(Str), Type.PieceLocation -> U32
	end_location = |zone_colors, loc| 20000 + location(zone_colors, loc)

	to_location : List(Str), U32 -> Try(Type.PieceLocation, [BadCode])
	to_location = |zone_colors, code|
		if code == bulls_eye {
			Ok({ zone: BullsEyeZone, id: "bullseye" })
		} else {
			match (List.get(zone_colors, U32.to_u64(code // 32)), List.get(Config.config_locations, U32.to_u64(code % 32))) {
				(Ok(color), Ok(square)) => Ok({ zone: NormalColor(color), id: square.id })
				_ => Err(BadCode)
			}
		}

	## A code no view hands out is a bug, and says so.
	decode : List(Str), U32 -> Try(Type.GameMsg, [BadCode])
	decode = |zone_colors, code|
		if code == rotate_board {
			Ok(RotateBoard)
		} else if code == undo {
			Ok(UndoAction)
		} else if code >= 20000 {
			Try.map_ok(to_location(zone_colors, code - 20000), |loc| SetEndLocation(loc))
		} else if code >= 10000 {
			Try.map_ok(to_location(zone_colors, code - 10000), |loc| SetStartLocation(loc))
		} else if code >= 300 and code < 400 {
			Ok(CoverCard(U32.to_u64(code - 300)))
		} else if code >= 200 and code < 300 {
			Ok(DiscardCard(U32.to_u64(code - 200)))
		} else if code >= 100 and code < 200 {
			Ok(ActivateCard(U32.to_u64(code - 100)))
		} else {
			Err(BadCode)
		}
}

expect {
	colors = ["red", "blue", "green", "purple"]
	loc = { zone: NormalColor("green"), id: "R4" }
	Codes.decode(colors, Codes.end_location(colors, loc)) == Ok(SetEndLocation(loc))
}
expect {
	colors = ["red", "blue", "green", "purple"]
	loc = { zone: BullsEyeZone, id: "bullseye" }
	Codes.decode(colors, Codes.start_location(colors, loc)) == Ok(SetStartLocation(loc))
}
expect Codes.decode(["red"], Codes.discard_card(3)) == Ok(DiscardCard(3))
expect Codes.decode(["red"], 7) == Err(BadCode)

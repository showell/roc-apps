# Codes -- a message as the number a click sends back.
#
# The page never builds a message: every clickable thing carries the code the
# view gave it, and a click hands that code to `update`. A square (Board.roc)
# is sent as its zone's place in the game's own (unrotated) color order and
# its place in Config.config_locations.
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
import Board
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
	activate_card = |idx| 100 + idx.to_u32_wrap()

	discard_card : U64 -> U32
	discard_card = |idx| 200 + idx.to_u32_wrap()

	cover_card : U64 -> U32
	cover_card = |idx| 300 + idx.to_u32_wrap()

	bulls_eye : U32
	bulls_eye = 999

	location : U64 -> U32
	location = |s| if s == Board.bullseye {
		bulls_eye
	} else {
		(32 * Board.zone(s) + Board.local(s)).to_u32_wrap()
	}

	start_location : U64 -> U32
	start_location = |s| 10000 + location(s)

	end_location : U64 -> U32
	end_location = |s| 20000 + location(s)

	to_location : List(Str), U32 -> Try(U64, [BadCode])
	to_location = |zone_colors, code|
		if code == bulls_eye {
			Ok(Board.bullseye)
		} else {
			zone = (code // 32).to_u64()
			local = (code % 32).to_u64()
			if zone < zone_colors.len() and local < Board.per_zone {
				Ok(Board.at(zone, local))
			} else {
				Err(BadCode)
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
			to_location(zone_colors, code - 20000).map_ok(|loc| SetEndLocation(loc))
		} else if code >= 10000 {
			to_location(zone_colors, code - 10000).map_ok(|loc| SetStartLocation(loc))
		} else if code >= 300 and code < 400 {
			Ok(CoverCard((code - 300).to_u64()))
		} else if code >= 200 and code < 300 {
			Ok(DiscardCard((code - 200).to_u64()))
		} else if code >= 100 and code < 200 {
			Ok(ActivateCard((code - 100).to_u64()))
		} else {
			Err(BadCode)
		}
}

expect {
	colors = ["red", "blue", "green", "purple"]
	s = Board.at(2, Board.r4)
	Codes.decode(colors, Codes.end_location(s)) == Ok(SetEndLocation(s)) and Codes.location(s) == 32 * 2 + 21
}
expect Codes.decode(["red", "blue", "green", "purple"], Codes.start_location(Board.bullseye)) == Ok(SetStartLocation(Board.bullseye))
expect Codes.decode(["red"], Codes.discard_card(3)) == Ok(DiscardCard(3))
expect Codes.decode(["red"], 7) == Err(BadCode)

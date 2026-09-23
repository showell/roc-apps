# Setup -- where pieces start and what hand a player starts with, from
# Setup.elm.
#
# Elm had a constant developer's switch here. Every setup but Normal lays the
# board out for one scenario (splitting sevens, trading jacks, a forced
# reverse); a game is begun with one, so a check can start from any of them.
import Config

Setup :: [].{
	InitSetup : [Normal, ForcedToReverse, Discard, Cover, BullsEye, SevenSplit]

	## Square ids in the color's own zone.
	starting_locations : Setup.InitSetup -> List(Str)
	starting_locations = |init_setup| {
		match init_setup {
			ForcedToReverse => ["HP1", "B1", "B3", "R0"]
			SevenSplit => ["L0", "L2", "R2", "B2"]
			Cover => ["HP1", "HP2", "HP3", "B2"]
			_ => Config.holding_pen_locations
		}
	}

	starting_hand : Setup.InitSetup, Str -> List(Str)
	starting_hand = |init_setup, color|
		match init_setup {
			ForcedToReverse => ["7", "8", "10", "9", "9"]
			Cover => ["K", "Q", "Q", "Q", "2"]
			Discard => if color == "blue" { ["K", "Q", "Q", "Q", "Q"] } else { ["K", "Q", "Q", "2", "3"] }
			BullsEye => ["A", "6", "Q", "8", "9"]
			SevenSplit => ["7", "7", "2", "Q", "K"]
			_ => []
		}
}

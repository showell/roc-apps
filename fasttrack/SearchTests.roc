# SearchTests -- the champion's choice in fixed positions, frozen: the line
# it plays (the messages), whether the search was cut, and the position the
# line ends in (Search.position_key: every piece's square and color, the hand
# kept, the discard credits, whether it drew). Taken from the code on
# 2026-11-01, before a cleanup that must not change a decision; an answer
# moves only for a change meant to change how the computer plays.
#
#   roc test SearchTests.roc
import Arena
import Game
import Search
import Strategy
import Type

## The champion's best line from `game`: its messages, cut, and end position.
choice : Type.Game -> Try((List(Type.GameMsg), Bool, List(U64)), [NoPlay])
choice = |game| Search.best_line(Strategy.champion, game).map_ok(|best| (best.line.msgs, best.cut, Search.position_key(best.line)))

# Setup.roc's scenarios, red to play: a split seven, a forced reverse, a
# discard, a cover, the bullseye.
expect choice(Game.begin_game(9, SevenSplit, Solo)) == Ok(([ActivateCard(3), SetStartLocation(19), ActivateCard(3), SetStartLocation(18), ActivateCard(0), SetStartLocation(5), SetEndLocation(7), SetStartLocation(17)], Bool.False, [60, 70, 110, 130, 271, 331, 351, 411, 492, 552, 572, 632, 713, 773, 793, 853, 999, 2, 7, 999, 0, 0]))
expect choice(Game.begin_game(9, ForcedToReverse, Solo)) == Ok(([ActivateCard(0), SetStartLocation(17)], Bool.False, [0, 40, 60, 221, 261, 281, 391, 442, 482, 502, 612, 663, 703, 723, 800, 833, 999, 8, 9, 9, 10, 999, 0, 0]))
expect choice(Game.begin_game(9, Discard, Solo)) == Ok(([DiscardCard(0), DiscardCard(0), DiscardCard(0), DiscardCard(1)], Bool.False, [0, 10, 20, 110, 221, 231, 241, 251, 442, 452, 462, 472, 663, 673, 683, 693, 999, 2, 999, 0, 0]))
expect choice(Game.begin_game(9, Cover, Solo)) == Ok(([ActivateCard(0), SetStartLocation(5), ActivateCard(0), SetStartLocation(6), CoverCard(0), CoverCard(0), CoverCard(0)], Bool.False, [0, 10, 20, 70, 221, 231, 241, 271, 442, 452, 462, 492, 663, 673, 683, 713, 999, 2, 5, 6, 10, 10, 999, 0, 1]))
expect choice(Game.begin_game(9, BullsEye, Solo)) == Ok(([ActivateCard(0), SetStartLocation(3), ActivateCard(0), SetStartLocation(11), SetEndLocation(88), ActivateCard(0), SetStartLocation(88), ActivateCard(1), SetStartLocation(82)], Bool.False, [0, 10, 20, 50, 221, 231, 241, 251, 442, 452, 462, 472, 663, 673, 683, 693, 999, 8, 999, 0, 0]))

# A first turn with no way out of the pen: a discard.
expect choice(Game.begin_game(0, Normal, Solo)) == Ok(([DiscardCard(0)], Bool.False, [0, 10, 20, 30, 221, 231, 241, 251, 442, 452, 462, 472, 663, 673, 683, 693, 999, 5, 5, 11, 11, 999, 1, 0]))

# Red's turn in games four champions play (Arena.position): seed, turn.
expect choice(Arena.position(3, 6)) == Ok(([ActivateCard(3), SetStartLocation(9)], Bool.False, [0, 10, 60, 170, 221, 231, 281, 291, 442, 452, 502, 663, 673, 683, 763, 822, 999, 2, 9, 10, 10, 999, 0, 0]))
expect choice(Arena.position(7, 4)) == Ok(([ActivateCard(3), SetStartLocation(10), ActivateCard(2), SetStartLocation(9)], Bool.False, [0, 10, 20, 50, 221, 261, 281, 331, 442, 452, 462, 512, 663, 733, 773, 823, 999, 4, 8, 10, 999, 0, 0]))
expect choice(Arena.position(5, 10)) == Ok(([ActivateCard(3), SetStartLocation(0), ActivateCard(1), SetStartLocation(11)], Bool.False, [60, 70, 140, 221, 271, 281, 291, 342, 502, 512, 542, 663, 703, 723, 733, 880, 999, 2, 7, 10, 999, 0, 0]))
expect choice(Arena.position(1, 15)) == Ok(([ActivateCard(4), SetStartLocation(80)], Bool.False, [40, 50, 60, 70, 221, 271, 281, 291, 442, 452, 512, 602, 703, 713, 723, 733, 999, 5, 5, 5, 9, 999, 0, 0]))

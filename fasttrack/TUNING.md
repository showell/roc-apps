# Tuning the computer

**Today's computer is `Strategy.champion`** (Strategy.roc): the square values
of Steve's ranking (SquareValues.roc), a base bonus of 1000 a step, and the A,
joker and J hoarded at 1500, 1000, 500 and 0 by pieces home, opponents
ignored, with a whole-turn search
(Search.roc). Experiments run through Arena.roc (`exp_*.roc`). The first two
sections below tuned an earlier computer -- a distance heuristic with a
limited search -- that has since been removed; they are kept for what they
found about the game.

The computer's weights (`Agent.Weights`) were chosen by racing computers
against each other: `web/tune.sh` over `web/race.mjs`, on the LLVM build of
`4a9f3b7`. A race is 100 deals, each played twice (abab and baba, so seats do
not decide it), four computers, solo; the number is A's share of the 200
games, with its standard error. A candidate replaced the champion only when it
won by more than one standard error.

**The result: `home = 10` and `back4 = 6`**, everything else off (danger 0,
out of the pen 0, hop 1, pen 4). `home = 10` won 55.0% ± 3.5 against the
untuned computer on 100 deals no stage had seen; `back4 = 6` added a smaller
gain, 54% ± 2.5 over 400 games (below).

## The races, 2026-09-22

Every candidate against the champion of the stage before it, on deals 1–100.

| factor | value | A won |
|---|---|---|
| hop | 4 | 48.5% ± 3.5 |
| hop | 8 | 45.5% ± 3.5 |
| hop | 14 | 38.0% ± 3.4 |
| danger | 10 | 53.0% ± 3.5 |
| danger | 20 | 52.5% ± 3.5 |
| danger | 40 | 44.5% ± 3.5 |
| danger | 80 | 33.0% ± 3.3 |
| out of the pen | 10 | 50.0% ± 3.5 |
| out of the pen | 20 | 45.0% ± 3.5 |
| out of the pen | 40 | 44.5% ± 3.5 |
| out of the pen | 80 | 42.5% ± 3.5 |
| home | 10 | **56.0% ± 3.5** |
| home | 20 | 49.0% ± 3.5 |
| home | 40 | 51.0% ± 3.5 |
| home | 80 | 52.0% ± 3.5 |

Then, on deals no stage had seen:

| A | B | deals | A won |
|---|---|---|---|
| home 10 | untuned | 1001–1100 | **55.0% ± 3.5** |
| home 10, danger 10 | home 10 | 2001–2100 | 49.0% ± 3.5 |
| home 10, danger 5 | home 10 | 2001–2100 | 46.5% ± 3.5 |

## What it says

- **Pricing the fast track made the computer worse**, more the dearer. The
  optimistic distance (a hop costs one step) at least tells it that landing
  exactly on a fast-track square is worth a great deal. The distance's
  weakness is real — every move past a piece's own fast-track square looks
  like a step backwards — but a price on the hop is not the fix. A distance
  that knows what landing exactly is worth probably is.
- **Danger, beyond a little, makes it timid**, and even a little adds nothing
  once home is rewarded.
- **Out of the pen is already paid for** by the pen's wait in the distance;
  more reward spends cards getting out too eagerly.
- **Home 10**: a piece in the base is safe, and the distance alone does not
  know that.

## The pen and the 4 played backwards, 2026-09-23

Steve: the pen was worth less than the worst square out of it (24 against
26), and the commonest good move in the game is to come out of the pen and
play a 4 backwards, which makes L0, L1 and L2 good squares to park on
(`:9100/notes/fasttrack-distance-table.md` has every square's formula). Both
became weights, raced against `home = 10`.

| A | B | deals | A won |
|---|---|---|---|
| pen 7 | pen 4 | 1–100 | 50.0% ± 3.5 |
| pen 11 | pen 4 | 1–100 | 48.0% ± 3.5 |
| pen 15 | pen 4 | 1–100 | 43.0% ± 3.5 |
| pen 23 | pen 4 | 1–100 | 39.0% ± 3.4 |
| back4 1 | none | 1–100 | 47.5% ± 3.5 |
| back4 3 | none | 1–100 | 48.5% ± 3.5 |
| back4 6 | none | 1–100 | **56.5% ± 3.5** |
| back4 9 | none | 1–100 | 54.5% ± 3.5 |
| back4 12 | none | 1–100 | 55.5% ± 3.5 |
| back4 6 | none | 3001–3100 | 51.5% ± 3.5 |
| back4 6, pen 8 | back4 6 | 1–100 | 48.5% ± 3.5 |
| back4 6, pen 12 | back4 6 | 1–100 | 49.5% ± 3.5 |

A 4 played backwards counts only where it lands a piece in its own home
stretch; left free, the shortest route chained ten of them round the board.
Priced at one step the computer parks too eagerly; priced for the wait for a
4 (6 and up) it helps. Pooled, back4 6 won 216 of 400. A bigger pen wait
never helped, on either table.

## The greedy player: hoarding A and jokers, 2026-09-23

A different player from the races above: `greedy_race.roc` (GreedyRace.roc).
Each square is worth 100 points a place in Steve's ranking to B1, every
player adds 1000 a step down its own base, and each turn every seat tries
every line of play to the turn's end and keeps the best board for its own
pieces. Each player's deck is shuffled once before the game; four discards
bring a piece out. Red alone also counts each A or joker it keeps in hand at
the end of its turn. 100 games per setting, seeds 1-100, binary `d21c400`;
an idle turn is one red begins with a discard. No turn was skipped with a
legal play and no search was cut short.

| A/joker kept worth | red's turns | fastest | slowest | idle turns a game | red captured |
|---|---|---|---|---|---|
| 0 | 15.9 | 7 | 23 | 3.6 | 72 |
| 200 | 15.8 | 7 | 25 | 3.5 | 71 |
| 500 | 15.9 | 7 | 25 | 3.5 | 71 |
| 1000 | 15.9 | 7 | 25 | 3.5 | 71 |
| 2000 | 15.6 | 7 | 25 | 3.0 | 70 |
| 4000 | 16.2 | 10 | 25 | 2.8 | 71 |

Up to 1000 the hoard barely changes a choice. At 2000 idle turns fall by a
sixth and the turns by 0.3; at 4000 idle turns fall further but the game gets
slower, as holding the cards starts to cost moves. The spread of a game is
about 3.5 turns, so a difference of 0.3 over 100 games is within the noise.

### Tapering the hoard, 2026-09-23

Steve: hoarding late in the game is dumb. Each A or joker kept is worth 2100
with no piece in the base, 1400 with one, 700 with two and 0 with three,
against no hoarding at all; 200 games each (seeds 1-200), binary `d49e62b`.

| hoard | red's turns | idle turns a game | red captured |
|---|---|---|---|
| none | 15.7 | 3.6 | 155 |
| 2100 / 1400 / 700 / 0 | 15.4 | 3.1 | 152 |

Paired game by game: 67 of the 200 games differ; red is faster in 40 and
slower in 27, by 0.23 turns on average (standard error 0.16). Idle turns fall
by a seventh. A small gain, likely real, not yet certain.

### Hoarding the J, 2026-09-23

30 games per variant, seeds 1-30; red is the variant, the other seats Strategy.champion.

| variant | red won | red's turns home | idle turns a game | red captured | skipped / cut |
|---|---|---|---|---|---|
| J up to 0 | 6 of 30 | 15.7 ± 0.6 | 4.0 | 22 | 0 / 0 |
| J up to 300 | 6 of 30 | 15.7 ± 0.6 | 4.0 | 22 | 0 / 0 |
| J up to 900 | 6 of 30 | 15.6 ± 0.6 | 4.0 | 22 | 0 / 0 |
| J up to 1500 | 7 of 30 | 15.2 ± 0.6 | 4.0 | 19 | 0 / 0 |
| J up to 3000 | 4 of 30 | 15.7 ± 0.6 | 3.9 | 20 | 0 / 0 |

Red hoards the J on top of the champion's A and joker, the J's worth
tapering like theirs (full, 2/3, 1/3, 0 by pieces home); the other seats play
Strategy.champion. `exp_jack_hoard.roc` at `42b9113`. Nothing here stands out
of the noise: 30 games is a win rate to within about 8 points and turns to
within 0.6. Up to 900 the J hoard changes almost nothing; 1500 is slightly
better on every count and 3000 slightly worse on wins. Not adopted.

### Playing to win, 2026-09-23

80 games per variant, seeds 1-80; red is the variant, the other seats Strategy.champion.

| variant | red won | red's turns home | idle turns a game | captures by red | red captured | skipped / cut |
|---|---|---|---|---|---|---|
| own pieces only | 21 of 80 | 15.5 ± 0.4 | 3.5 | 40 | 52 | 0 / 0 |
| own less the leader | 17 of 80 | 16.6 ± 0.4 | 3.7 | 101 | 68 | 0 / 0 |

Game by game: red won 5 games only as own less the leader (seeds 23, 41, 58,
61, 80) and 9 only as own pieces only (seeds 21, 22, 43, 55, 60, 69, 74, 76,
79); the other 66 came out the same.

Red scores its own pieces less the leading opponent's at the end of its turn
(`opponents: Leader`); the other seats count only their own. `exp_win_focus.roc`
at `62459a1`. Playing against the leader lost: fewer wins, a turn slower home,
and red was captured more. It captured two and a half times as often, so the
chase itself is what it bought. 5 games against 9 is not beyond chance (a sign
test gives about 0.4), but nothing here points the other way. Not adopted.

### Playing to win only when behind, 2026-09-23

80 games per variant, seeds 1-80; red is the variant, the other seats Strategy.champion.

| variant | red won | red's turns home | idle turns a game | captures by red | red captured | skipped / cut |
|---|---|---|---|---|---|---|
| own pieces only | 21 of 80 | 15.5 ± 0.4 | 3.5 | 40 | 52 | 0 / 0 |
| less the leader when behind | 17 of 80 | 16.3 ± 0.4 | 3.7 | 86 | 68 | 0 / 0 |

Game by game: red won 5 games only as less the leader when behind (seeds 41,
58, 61, 77, 80) and 9 only as own pieces only (seeds 21, 22, 40, 43, 55, 60,
69, 76, 79); the other 66 came out the same.

`opponents: LeaderWhenBehind`: red plays against the leader only when the
leader's board is ahead of its own as the search starts. `exp_win_focus.roc`
at the commit that adds it. It came out almost exactly like always chasing,
because red is almost always behind by that test: at 283 of red's 332
searches in 20 all-champion games (`exp_leader_shadow.roc`), and at 11 of the
14 where the chaser chose differently. The best of three opponents is
usually ahead of any one player. Not adopted.

## Before these races

Every race and arena number before `4a9f3b7` came from a build whose
distance tables were all "far" (`findings/llvm-closure-loop-alias/`), and is
void. The danger race run on it (64.5% for danger 10) measured a different
computer.

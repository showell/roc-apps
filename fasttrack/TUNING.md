# Tuning the computer

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

## Before these races

Every race and arena number before `4a9f3b7` came from a build whose
distance tables were all "far" (`findings/llvm-closure-loop-alias/`), and is
void. The danger race run on it (64.5% for danger 10) measured a different
computer.

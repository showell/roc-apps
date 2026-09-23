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

## Before these races

Every race and arena number before `4a9f3b7` came from a build whose
distance tables were all "far" (`findings/llvm-closure-loop-alias/`), and is
void. The danger race run on it (64.5% for danger 10) measured a different
computer.

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

### What the winner does, 2026-09-23

80 games, seeds 1-80; red, blue and purple play Strategy.champion, green the
first legal move it finds (`FirstLegal`). Each game stops at the first player
home. `exp_table.roc`.

Wins: red 31, blue 24, green 0, purple 25.

| | winner | champions who lost | green, when it lost | winner vs losers: above / equal / below |
|---|---|---|---|---|
| turns | 12.88 | 12.34 | 12.19 | 55 / 25 / 0 |
| cards played | 20.89 | 16.66 | 18.21 | 65 / 3 / 12 |
| idle turns | 1.99 | 3.23 | 1.81 | 13 / 10 / 57 |
| fast-track landings | 3.08 | 2.45 | 1.19 | 48 / 8 / 24 |
| fast-track hops | 1.78 | 1.33 | 0.00 | 44 / 12 / 24 |
| captures made | 0.84 | 0.48 | 0.44 | 40 / 19 / 21 |
| times captured | 0.31 | 0.70 | 0.51 | 10 / 23 / 47 |

Means per player per game; the last column compares the winner with the mean
of the champions who lost that game. Every stat leans the way Steve expected:
winners play more cards, sit idle less, use the fast track more, capture
more and are captured less. Cards played and idle turns separate them most.
The turns row is an artifact: the game stops at the winner's turn, so the
winner has always had its turn and some losers have not.

Green plays the first legal move and never won. It is idle less than the
champions, because its pieces rarely reach the base and nearly any card moves
one. Red's 31 wins against about 27 expected for each of three seats is
within noise (about ± 4).

### Which cards win, 2026-09-23

80 games, seeds 1-80, four champions, each game to the first player home.
`exp_cards.roc`. A card the winner played scores +3, a card a loser played
-1.

| rank | card | score | played by the winner | played by losers | winner's share | discarded by the winner | discarded by losers |
|---|---|---|---|---|---|---|---|
| 1 | J | 156 | 150 | 294 | .338 | 19 | 73 |
| 2 | Q | 131 | 139 | 286 | .327 | 21 | 81 |
| 3 | A | 125 | 168 | 379 | .307 | 0 | 0 |
| 4 | K | 118 | 138 | 296 | .318 | 23 | 72 |
| 5 | 6 | 110 | 162 | 376 | .301 | 0 | 0 |
| 6 | 7 | 102 | 107 | 219 | .328 | 26 | 99 |
| 7 | 4 | 88 | 126 | 290 | .303 | 10 | 86 |
| 8 | 8 | 85 | 84 | 167 | .335 | 21 | 115 |
| 9 | 2 | 67 | 99 | 230 | .301 | 20 | 93 |
| 10 | 10 | 57 | 91 | 216 | .296 | 16 | 98 |
| 11 | joker | 38 | 78 | 196 | .285 | 0 | 0 |
| 12 | 3 | 30 | 94 | 252 | .272 | 18 | 83 |
| 13 | 9 | 30 | 79 | 207 | .276 | 15 | 99 |
| 14 | 5 | -44 | 93 | 323 | .224 | 12 | 62 |

The score mixes a card's worth with how often it is played (the deck has two
jokers, four of the rest). The winner's share of a card's plays is fairer;
over all cards it is .301, since winners play more. Only the 5 stands out
(.224, about three standard errors low). A, 6 and joker sit at the average
because anyone with a piece in the pen must play them, and they were never
discarded. Steve's guess at the order of worth: 6, A, joker, J, K, Q, 7, 4,
10, 2, 9, 8, 3.

### Which cards were dealt to the winner, 2026-09-23

The same 80 games, every card each player drew: played, discarded, or in
hand when the game was won. `exp_cards.roc`.

| card | drawn: winner / losers | winner's share of draws | played + discarded: winner / losers | score, +3 / -1 |
|---|---|---|---|---|
| A | 179 / 385 | .317 | 168 / 379 | 125 |
| J | 175 / 380 | .315 | 169 / 367 | 140 |
| Q | 170 / 375 | .311 | 160 / 367 | 113 |
| 6 | 174 / 388 | .309 | 162 / 376 | 110 |
| joker | 87 / 202 | .301 | 78 / 196 | 38 |
| K | 166 / 387 | .300 | 161 / 368 | 115 |
| 7 | 159 / 399 | .284 | 133 / 318 | 81 |
| 4 | 155 / 437 | .261 | 136 / 376 | 32 |
| 2 | 139 / 420 | .248 | 119 / 323 | 34 |
| 8 | 134 / 412 | .245 | 105 / 282 | 33 |
| 10 | 137 / 429 | .242 | 107 / 314 | 7 |
| 5 | 142 / 453 | .238 | 105 / 385 | -70 |
| 3 | 131 / 421 | .237 | 112 / 335 | 1 |
| 9 | 127 / 408 | .237 | 94 / 306 | -24 |

Winners draw more (26 cards a game against 23), so the neutral share is .274.
Every move-again card (A, 6, J, Q, K, joker) is above it and every plain
number but the 7 and 4 below: move-again cards were 45.8% of the winners'
draws, 38.5% of the losers', 40.7% of the deck -- about six standard errors
apart. The winner is largely the player whose shuffled deck put move-again
cards on top. Counting a discard as a use (a credit toward getting out), the
score ranks J, A, K, Q, 6, 7, then the joker (76 for four copies), with the
plain numbers behind and the 5 last.

### Which cards were dealt to the winner, 200 games, 2026-09-23

200 games, seeds 1-200, four champions, each game to the first player home.
`exp_cards.roc`. Ranked by the winner's share of a card's draws (played +
discarded + in hand at the end); over every card it is .272, since winners
draw more. ± one standard error, counting draws as independent.

| rank | card | winner's share of draws | drawn: winner / losers | played | discarded | in hand at the end |
|---|---|---|---|---|---|---|
| 1 | joker | .314 ± .017 | 227 / 495 | 213 / 481 | 0 / 0 | 14 / 14 |
| 2 | A | .314 ± .012 | 463 / 1012 | 439 / 997 | 0 / 0 | 24 / 15 |
| 3 | 6 | .310 ± .012 | 437 / 973 | 404 / 951 | 0 / 0 | 33 / 22 |
| 4 | J | .309 ± .012 | 433 / 967 | 380 / 763 | 38 / 173 | 15 / 31 |
| 5 | Q | .285 ± .012 | 399 / 1001 | 322 / 771 | 50 / 202 | 27 / 28 |
| 6 | K | .285 ± .012 | 397 / 996 | 342 / 756 | 42 / 197 | 13 / 43 |
| 7 | 4 | .279 ± .012 | 394 / 1018 | 315 / 694 | 31 / 171 | 48 / 153 |
| 8 | 7 | .273 ± .012 | 385 / 1024 | 268 / 592 | 46 / 215 | 71 / 217 |
| 9 | 3 | .250 ± .012 | 346 / 1039 | 240 / 636 | 39 / 202 | 67 / 201 |
| 10 | 2 | .246 ± .011 | 352 / 1078 | 240 / 588 | 50 / 254 | 62 / 236 |
| 11 | 5 | .244 ± .011 | 354 / 1096 | 251 / 745 | 31 / 177 | 72 / 174 |
| 12 | 8 | .243 ± .012 | 335 / 1043 | 201 / 415 | 46 / 276 | 88 / 352 |
| 13 | 9 | .237 ± .012 | 322 / 1039 | 217 / 537 | 37 / 250 | 68 / 252 |
| 14 | 10 | .235 ± .011 | 328 / 1067 | 218 / 557 | 42 / 234 | 68 / 276 |

Steve's guess (6, A, joker, J, K, Q, 7, 4, 10, 2, 9, 8, 3) holds: the three
cards that get a piece out and the J lead at about .31, Q and K follow, 4
and 7 sit at the average, and the plain numbers trail together, within noise
of each other. The 5 of the 80-game run was noise. The 8, 9 and 10 are the
cards left rotting in a loser's hand.

### What the winner does, four champions, 200 games, 2026-09-23

The 200 games of the card ranking above, every seat Strategy.champion, each
to the first player home. `exp_cards.roc` (Tables.winner_table).

Wins: red 54, blue 47, green 62, purple 37 (50 each ± about 6 if the seats
are equal; a chi-square over the four gives p ≈ 0.08).

| | winner | players who lost | winner vs losers: above / equal / below |
|---|---|---|---|
| turns | 11.85 | 11.32 | 163 / 37 / 0 |
| cards played | 20.25 | 15.81 | 169 / 5 / 26 |
| idle turns | 1.61 | 2.97 | 37 / 9 / 154 |
| fast-track landings | 2.85 | 2.38 | 111 / 12 / 77 |
| fast-track hops | 1.76 | 1.32 | 109 / 17 / 74 |
| captures made | 0.81 | 0.51 | 96 / 39 / 65 |
| times captured | 0.30 | 0.68 | 27 / 41 / 132 |

### Hoarding the 7, 2026-09-23

200 games per variant, seeds 1-200; red is the variant, the other seats Strategy.champion. Each game stops at the first player home.

| variant | red won | the game's length, red's turns | idle turns a game | captures by red | red captured | skipped / cut |
|---|---|---|---|---|---|---|
| the champion | 50 of 200 | 11.8 ± 0.2 | 2.8 | 104 | 125 | 0 / 0 |
| hoards the 7 too | 55 of 200 | 11.8 ± 0.2 | 2.7 | 106 | 133 | 0 / 0 |

Game by game: red won 9 games only as hoards the 7 too (seeds 7, 34, 43, 44,
68, 82, 117, 158, 168) and 4 only as the champion (seeds 59, 73, 127, 196);
the other 187 came out the same.

Red hoards the 7 at 1500, 1000, 500, 0 by pieces home, beside the champion's
A, joker and J. `exp_seven_hoard.roc`. Leans better (9 games to 4) but within
chance (p ≈ 0.27). The taper is the point: a 7 kept early is a 7 in hand for
the end game, when a split packs pieces into the base and the hoard's worth
has fallen to nothing.

### Hoarding the 7, 1000 games, 2026-09-23

1000 games per variant, seeds 1-1000; red is the variant, the other seats Strategy.champion. Each game stops at the first player home.

| variant | red won | the game's length, red's turns | idle turns a game | captures by red | red captured | skipped / cut |
|---|---|---|---|---|---|---|
| the champion | 250 of 1000 | 11.8 ± 0.1 | 2.8 | 526 | 633 | 0 / 0 |
| 7s worth less as pieces come home | 258 of 1000 | 11.8 ± 0.1 | 2.8 | 555 | 655 | 0 / 0 |
| 7s worth more as pieces come home | 233 of 1000 | 11.8 ± 0.1 | 2.8 | 533 | 650 | 0 / 0 |

Game by game against the champion: 7s worth less as pieces come home (1500,
1000, 500, 0) won 46 games the champion lost and lost 38 it won; 7s worth
more (0, 500, 1000, 1500) won 23 and lost 40. `exp_seven_hoard.roc`.

Steve's falling taper -- keep 7s early so they are there for the end game --
changes nothing that shows (p ≈ 0.4; the 200-game run's 9 to 4 was noise).
The rising taper, which values a 7 most when it should be spent, hurts (p ≈
0.04). Not adopted.

### Hoarding the 7 at 900/600/300/0, dealt as duplicate, 2026-09-23

1000 seeds, each dealt four times with the decks turned a seat
(Game.begin_dealt), so red plays every player's deck: 4000 games per
variant. `exp_seven_duplicate.roc` at `82f3dd9` (now `exp_duplicate.roc`).

| red plays as | red won | win rate | wins with the decks turned 0 / 1 / 2 / 3 seats |
|---|---|---|---|
| the champion | 1087 of 4000 | 0.272 | 250 / 281 / 289 / 267 |
| hoarding 7s | 1061 of 4000 | 0.265 | 250 / 272 / 283 / 256 |

Deals only hoarding won: 124; only the champion won: 150. The difference,
-0.007 a game, judged three ways:

| judged as | standard error of the difference | the difference in standard errors |
|---|---|---|
| unrelated games | 0.010 | -0.66 |
| paired, deal by deal | 0.004 | -1.57 |
| by seed, four turned deals together | 0.004 | -1.53 |

A milder 7 hoard does not help either. **Duplicate dealing buys nothing over
pairing**: pairing (both variants on the same deal) already cuts the error
2.5 times, and turning the decks adds nothing on top, at four times the
games. A/B experiments stay paired by seed. Red, moving first, wins 27.2%
± 0.7 with every deck through its seat: a first-move edge of about 2 points.

### No J hoard, dealt as duplicate, 2026-09-23

1000 seeds, each dealt four times with the decks turned a seat: 4000 games
per variant. Red hoards only the A and joker (1500/1000/500/0) against the
champion, which hoards the J too. `exp_duplicate.roc` at `90fb257`.

| red plays as | red won | win rate | wins with the decks turned 0 / 1 / 2 / 3 seats |
|---|---|---|---|
| the champion | 1087 of 4000 | 0.272 | 250 / 281 / 289 / 267 |
| no J hoard | 1059 of 4000 | 0.265 | 246 / 270 / 289 / 254 |

Deals only no J hoard won: 143; only the champion won: 171. The difference,
-0.007 a game, is -1.58 standard errors paired (0.004): the J hoard helps,
as Steve expected (one-sided p ≈ 0.06), but not by much. The champion keeps
it.

### Against a leader three home, a first look, 2026-09-23

40 seeds, each dealt four times with the decks turned a seat: 160 games per
variant. Red scores its board less the board, at the end of its turn, of the
opponent worth most among those with three pieces home as the turn starts
(`opponents: LeaderNearHome`); nobody counts otherwise. `exp_duplicate.roc`.

| red plays as | red won | win rate | wins with the decks turned 0 / 1 / 2 / 3 seats |
|---|---|---|---|
| the champion | 43 of 160 | 0.269 | 6 / 13 / 12 / 12 |
| against a leader three home | 51 of 160 | 0.319 | 9 / 14 / 15 / 13 |

Deals only the variant won: 9; only the champion won: 1 (2.6 paired standard
errors). Promising, and to be scaled up.

### Against a leader three home, 2163 seeds, 2026-09-23

The dinner run of the first look above: 2500 seeds planned, each dealt four
times with the decks turned a seat. It stopped at seed 2164, on a turn the
search could not finish (blue holding J J joker J J; see below), so the
result is seeds 1-2163, read from the per-seed log lines: 8652 deals per
variant. `exp_duplicate.roc` at `8e52179`.

| red plays as | red won | win rate |
|---|---|---|
| the champion | 2390 of 8652 | 0.276 |
| against a leader three home | 2351 of 8652 | 0.272 |

By seed (four deals): the variant won more deals than the champion in 193
seeds and fewer in 220; 1750 came out the same. The difference, -0.0045 a
game, is -1.8 standard errors. The first look's 9 deals to 1 (seeds 1-40,
inside this run) was noise. Not adopted.

The turn that stopped it: four jacks and a joker are five plays that each
go again, and a jack trades with any of a dozen pieces, so the lines ran to
hundreds of thousands and the search's merge compared every pair. Search
now merges by sorted keys (no decision changes: 200 games identical) and
keeps at most 20000 lines a level, counting a search that hits the cap as
cut; that hand's search now takes 17 s and is cut.

### Rollouts at seed 69's pivot, 2026-09-23

Seed 69 with four champions, to red's first turn where the champion and the
leader-chaser choose differently: now red's turn 7, hand 4 9 2 Q A (the
essay's turn 6 predates the tie-break by position). Each line played out
1000 times from the end of red's turn, every player a champion, every
player's undrawn cards shuffled afresh -- the same 1000 shuffles for every
line. `exp_rollout.roc`.

| red's line | champion's score | red won | vs the champion's pick, paired |
|---|---|---|---|
| champion's pick: DS to B1; out with the A, back 4 to R0 | 26500 | 39.7% ± 1.5 | -- |
| DS to B3; out to L0 | 26000 | 53.2% ± 1.6 | +13.5 ± 1.3 |
| DS to B2; out to L1 | 25000 | 40.7% ± 1.6 | +1.0 ± 1.4 |
| DS to B2; out to L0 | 24900 | 52.0% ± 1.6 | +12.3 ± 1.4 |
| DS to B3 | 24200 | 50.9% ± 1.6 | +11.2 ± 1.3 |
| the capture: out to L0; bullseye onto purple's FT | 23400 | 40.7% ± 1.6 | +1.0 ± 1.9 |

The capture is no better than the champion's move here. The champion's move
is itself wrong by 13 points of red's chance to win: tucking the DS piece
deep beats leaving it on B1 and backing the new piece to R0, which the
square values prefer by 500 points. A piece on B1 blocks the base; the back
4 to R0 looks overvalued. One decision is worth more than any capture
experiment has found -- the next thing is to audit the champion's choices
by rollouts.

### Base bonus 2500, dealt as duplicate, 2026-09-23

500 seeds, each dealt four times with the decks turned a seat: 2000 games
per variant. Red's base worth 2500 a step (B1 2500 .. B4 10000) against the
champion's 1000, Steve's theory being that tucked positions are worth more
than the champion thinks (the rollouts at seed 69 above). `exp_duplicate.roc`
at `66727d0`.

| red plays as | red won | win rate | wins with the decks turned 0 / 1 / 2 / 3 seats |
|---|---|---|---|
| the champion | 550 of 2000 | 0.275 | 124 / 147 / 153 / 126 |
| base bonus 2500 | 581 of 2000 | 0.291 | 132 / 150 / 167 / 132 |

Deals only base bonus 2500 won: 126; only the champion won: 95. The
difference, +0.015 a game, is +2.1 paired standard errors (0.007): the first
change to beat the champion by more than noise. To confirm on fresh seeds,
with other values of the ramp, before it becomes the champion's.

### The base bonus swept on fresh seeds, 2026-09-24

Seeds 501-1000, each dealt four times with the decks turned a seat: 2000
games per strategy. `exp_duplicate.roc` at `ae9c5d7`.

| red plays as | red won | win rate | wins with the decks turned 0 / 1 / 2 / 3 seats |
|---|---|---|---|
| the champion | 537 of 2000 | 0.269 | 126 / 134 / 136 / 141 |
| base bonus 1500 | 529 of 2000 | 0.265 | 135 / 123 / 134 / 137 |
| base bonus 2500 | 547 of 2000 | 0.274 | 133 / 135 / 137 / 142 |
| base bonus 4000 | 527 of 2000 | 0.264 | 128 / 131 / 126 / 142 |

| red plays as | difference a game | deals only it won / only the champion won | paired, in standard errors |
|---|---|---|---|
| base bonus 1500 | -0.004 | 89 / 97 | -0.59 |
| base bonus 2500 | +0.005 | 130 / 120 | +0.63 |
| base bonus 4000 | -0.005 | 148 / 158 | -0.57 |

2500's +2.1 standard errors on seeds 1-500 shrank to +0.6 here. Pooled over
4000 deals it won 256 the champion lost and lost 215 it won: about +1 point
a game, 1.9 standard errors. The ramp is a plateau from 1000 to 4000, as the
first base bonus tuning found; it is not what cost the champion 13 points at
seed 69, where leaving a piece on B1 and backing one to R0 lost to tucking
deep.

## Before these races

Every race and arena number before `4a9f3b7` came from a build whose
distance tables were all "far" (`findings/llvm-closure-loop-alias/`), and is
void. The danger race run on it (64.5% for danger 10) measured a different
computer.

// elm/random 1.0.0's seed arithmetic, as Elm compiles it to JavaScript, so
// node computes exactly what the Elm build computes. `Bitwise.xor` is `^`,
// `shiftRightZfBy` is `>>>`, and `*` is a double multiply -- which is why
// `peel` loses low bits a 64-bit integer multiply would keep.
//
//   node fasttrack/web/elm_random_oracle.mjs
//
// prints the draws ElmRandom.roc's expects pin.

const next = ([state0, incr]) => [((state0 * 1664525) + incr) >>> 0, incr];

const peel = ([state]) => {
  const word = (state ^ (state >>> ((state >>> 28) + 4))) * 277803737;
  return ((word >>> 22) ^ word) >>> 0;
};

const initialSeed = (x) => {
  const [state1, incr] = next([0, 1013904223]);
  const state2 = (state1 + x) >>> 0;
  return next([state2, incr]);
};

const int = (a, b, seed0) => {
  const [lo, hi] = a < b ? [a, b] : [b, a];
  const range = hi - lo + 1;
  if (((range - 1) & range) === 0) {
    return [(((range - 1) & peel(seed0)) >>> 0) + lo, next(seed0)];
  }
  const threshhold = ((-range >>> 0) % range) >>> 0;
  let seed = seed0;
  for (;;) {
    const x = peel(seed);
    const seedN = next(seed);
    if (x < threshhold) { seed = seedN; continue; }
    return [(x % range) + lo, seedN];
  }
};

// Each case: a seed, then twelve draws from a shrinking deck, the way
// Player.replenishHand draws (0 .. deckCount-1, one card gone each time).
for (const millis of [0, 42, 1700000000000, 1758570000123]) {
  let seed = initialSeed(millis);
  const draws = [];
  for (let deck = 54; deck > 42; deck--) {
    const [v, s] = int(0, deck - 1, seed);
    draws.push(v);
    seed = s;
  }
  console.log(`${millis}: seed ${JSON.stringify(initialSeed(millis))} draws ${JSON.stringify(draws)} final ${JSON.stringify(seed)}`);
}

// all features: a day in a little simulated city, in stages. Each stage
// prints a checksum, so any engine that runs it can be held to node's answer.
// SIZE scales the work: the residents, the street map, the sieve and the
// newsletter all grow with it.
const SIZE = 5;

// ── Two tools every stage uses: a seeded random source and a checksum ──

// The same seed gives the same city on every run, in every engine.
function makeRandom(seed) {
  let state = seed;
  return (n) => {
    state = (state * 75 + 74) % 65537;
    return state % n;
  };
}

// A running hash of everything a stage adds to it, kept in a closure.
function makeChecksum(seed = 7) {
  let sum = seed;
  return {
    add(...values) {
      for (const value of values) {
        for (const ch of String(value)) sum = (sum * 31 + ch.charCodeAt(0)) % 1000003;
      }
    },
    value: () => sum,
  };
}

const random = makeRandom(2026);
const checksum = makeChecksum();

// ── Stage 1: the census, written as text and read back ──

const FIRST = ["ada", "bo", "cy", "dee", "eli", "fay", "gus", "hal", "ivy", "jo"];
const LAST = ["stone", "brook", "hill", "marsh", "wood"];
const DISTRICTS = ["harbor", "market", "old town", "uplands"];
const JOBS = ["baker", "nurse", "doctor", "teacher", "smith", "clerk", "none"];

let censusText = "";
for (let i = 0; i < SIZE * 20; i++) {
  const name = `${FIRST[random(FIRST.length)]} ${LAST[random(LAST.length)]}`;
  const district = DISTRICTS[random(DISTRICTS.length)];
  const job = JOBS[random(JOBS.length)];
  // A resident with no job leaves the last field out.
  const fields = [name, district, 18 + random(70), 1 + random(SIZE * 300)];
  if (job !== "none") fields.push(job);
  censusText += `  ${fields.join(" ; ")}\n`;
}

// The subset has no parseInt, so digits are read one at a time.
function parseNumber(text) {
  let n = 0;
  for (const digit of text) n = n * 10 + (digit.charCodeAt(0) - 48);
  return n;
}

const residents = [];
for (const line of censusText.split("\n")) {
  if (line.trim() === "") continue;
  const [name, district, ageText, houseText, job = "retired"] = line.split(";").map((field) => field.trim());
  residents.push({ id: residents.length, name, district, age: parseNumber(ageText), house: parseNumber(houseText), job });
}

// Called here, declared below: function declarations are hoisted.
const sectors = new Map();
for (const { job } of residents) {
  const sector = sectorOf(job);
  sectors.set(sector, (sectors.get(sector) ?? 0) + 1);
}

function sectorOf(job) {
  switch (job) {
    case "nurse":
    case "doctor":
      return "health";
    case "baker":
    case "smith":
      return "trade";
    default:
      return "other";
    case "teacher":
      return "schools";
  }
}

// Health workers get both perks, teachers the second: a fall-through.
function perksOf(sector) {
  let perks = 0;
  switch (sector) {
    case "health":
      perks += 2;
    case "schools":
      perks += 1;
      break;
    default:
      perks = 0;
  }
  return perks;
}

const byDistrict = new Map();
const stats = { oldest: null, anyDoctor: false, allAdults: true, perks: 0 };
for (const person of residents) {
  const { district, age, ...rest } = person;
  const entry = byDistrict.get(district) ?? { people: 0, totalAge: 0 };
  entry.people++;
  entry.totalAge += age;
  byDistrict.set(district, entry);

  stats.oldest ??= person;
  if (age > stats.oldest.age) stats.oldest = person;
  stats.anyDoctor ||= rest.job === "doctor";
  stats.allAdults &&= age >= 18;
  stats.perks += perksOf(sectorOf(rest.job));
}

for (const [district, { people, totalAge }] of byDistrict) checksum.add(district, people, totalAge);
for (const [sector, count] of sectors.entries()) checksum.add(sector, count);
console.log(`census: ${residents.length} residents in ${byDistrict.size} districts, checksum ${checksum.value()}`);
console.log({
  oldest: { ...stats.oldest, sector: sectorOf(stats.oldest.job) },
  sectors,
  flags: [stats.anyDoctor, stats.allAdults, stats.perks],
});

// ── Stage 2: the clerk's office, where lookups can fail ──

const registry = new Map(residents.map((r) => [r.id, r]));

function lookUp(id) {
  const person = registry.get(id) ?? null;
  return person.name;
}

function checkAge(age) {
  if (age < 0 || age > 130) throw new RangeError(`no one is ${age}`);
  return age;
}

let lookups = 0;
let missing = 0;
let lastMessage = "";
for (const id of [3, -1, residents.length, 7]) {
  try {
    checksum.add(lookUp(id));
  } catch (e) {
    if (e.name !== "TypeError") throw e;
    missing++;
    lastMessage = e.message;
  } finally {
    lookups++;
  }
}
let refused = "";
try {
  checkAge(stats.oldest.age + 100);
} catch ({ name, message }) {
  refused = `${name}: ${message}`;
}
checksum.add(lookups, missing, refused);
console.log(`clerk: ${lookups} lookups, ${missing} missing ("${lastMessage}"), ${refused}, checksum ${checksum.value()}`);

// ── Stage 3: the residents in order, by merge sort, checked by sort ──

function byDistrictThenAge(a, b) {
  if (a.district !== b.district) return a.district < b.district ? -1 : 1;
  if (a.age !== b.age) return b.age - a.age;
  return a.id - b.id;
}

function mergeSort(items, compare) {
  if (items.length <= 1) return items;
  const middle = Math.floor(items.length / 2);
  const left = mergeSort(items.slice(0, middle), compare);
  const right = mergeSort(items.slice(middle), compare);
  const merged = [];
  let i = 0;
  let j = 0;
  while (i < left.length && j < right.length) {
    if (compare(left[i], right[j]) <= 0) merged.push(left[i++]);
    else merged.push(right[j++]);
  }
  return [...merged, ...left.slice(i), ...right.slice(j)];
}

const ordered = mergeSort(residents, byDistrictThenAge);
const expected = [...residents].sort(byDistrictThenAge);
const agrees = ordered.every((r, k) => r === expected[k]);
for (const [k, r] of ordered.entries()) if (k % 25 === 0) checksum.add(r.id);
const eldest = DISTRICTS.map((d) => ordered.find((r) => r.district === d)?.name ?? "nobody");
console.log(`sort: ${ordered.length} sorted, agrees with sort: ${agrees}, checksum ${checksum.value()}`);
console.log("eldest by district:", eldest);

// ── Stage 4: the shortest walk from city hall to each district ──

const WIDTH = 4 + Math.floor(SIZE / 2);
const corner = (x, y) => `${x},${y}`;
const streets = new Map();
const closed = new Set();
for (let y = 0; y < WIDTH; y++) {
  for (let x = 0; x < WIDTH; x++) {
    if ((x + y) % 2 === 1 && random(9) === 0) closed.add(corner(x, y));
  }
}
closed.delete(corner(0, 0));

function connect(a, b, length) {
  if (closed.has(a) || closed.has(b)) return;
  for (const [from, to] of [[a, b], [b, a]]) {
    if (!streets.has(from)) streets.set(from, []);
    streets.get(from).push({ to, length });
  }
}

for (let y = 0; y < WIDTH; y++) {
  for (let x = 0; x < WIDTH; x++) {
    if (x + 1 < WIDTH) connect(corner(x, y), corner(x + 1, y), 1 + random(5));
    if (y + 1 < WIDTH) connect(corner(x, y), corner(x, y + 1), 1 + random(5));
  }
}

// Dijkstra's algorithm, picking the nearest open corner by a scan.
function shortestWalks(start) {
  const distance = new Map([[start, 0]]);
  const previous = new Map();
  const done = new Set();
  while (true) {
    let nearest = null;
    for (const [place, d] of distance) {
      if (!done.has(place) && (nearest === null || d < distance.get(nearest))) nearest = place;
    }
    if (nearest === null) break;
    done.add(nearest);
    for (const { to, length } of streets.get(nearest) ?? []) {
      const through = distance.get(nearest) + length;
      if (!distance.has(to) || through < distance.get(to)) {
        distance.set(to, through);
        previous.set(to, nearest);
      }
    }
  }
  return { distance, previous };
}

const { distance, previous } = shortestWalks(corner(0, 0));

// The first closed corner, in reading order.
let firstClosed = "none";
search: for (let y = 0; y < WIDTH; y++) {
  for (let x = 0; x < WIDTH; x++) {
    if (closed.has(corner(x, y))) {
      firstClosed = corner(x, y);
      break search;
    }
  }
}

const far = corner(WIDTH - 1, WIDTH - 1);
const walk = [];
let at = distance.has(far) ? far : undefined;
do {
  if (at === undefined) break;
  walk.unshift(at);
  at = previous.get(at);
} while (at !== undefined);

let totalDistance = 0;
for (const d of distance.values()) totalDistance += d;
const straight = Math.sqrt((WIDTH - 1) ** 2 * 2);
checksum.add(distance.size, totalDistance, walk.length, firstClosed);
console.log(`streets: ${WIDTH}x${WIDTH} corners, ${closed.size} closed (first ${firstClosed}), ${distance.size} reachable`);
console.log(`  the far corner is ${distance.get(far) ?? "unreachable"} blocks away, ${Math.round(straight * 100) / 100} as the crow flies, ${walk.length} corners on the way`);
console.log(`  checksum ${checksum.value()}`);

// ── Stage 5: which house numbers are prime, by the sieve of Eratosthenes ──

const LIMIT = SIZE * 300;
const isPrime = Array.from({ length: LIMIT + 1 }, (_, n) => n >= 2);
for (let p = 2; p * p <= LIMIT; p++) {
  if (!isPrime[p]) continue;
  for (let multiple = p * p; multiple <= LIMIT; multiple += p) isPrime[multiple] = false;
}
let primeCount = 0;
for (let n = 0; n <= LIMIT; n++) if (isPrime[n]) primeCount++;
const lucky = residents.filter(({ house }) => isPrime[house]);
const largest = isPrime.lastIndexOf(true);
checksum.add(primeCount, lucky.length, largest);
console.log(`sieve: ${primeCount} primes up to ${LIMIT}, the largest ${largest}; ${lucky.length} residents live at a prime, checksum ${checksum.value()}`);

// ── Stage 6: the newsletter, and its words counted ──

const NEWS = [
  "The market opens early, and the bakers sell bread by the harbor.",
  "A doctor and a nurse walk the uplands; the old town sleeps.",
  "Teachers say the smith fixed the bell, and the bell rings again!",
];
let newsletter = "";
for (let issue = 1; issue <= SIZE * 4; issue++) {
  const { name, district } = residents[random(residents.length)];
  newsletter += `${NEWS[issue % NEWS.length]} ${name.toUpperCase()} of ${district} writes in. `;
}

const counts = new Map();
for (const raw of newsletter.split(" ")) {
  let word = raw.toLowerCase();
  for (const mark of [",", ".", ";", "!"]) word = word.replaceAll(mark, "");
  if (word === "") continue;
  counts.set(word, (counts.get(word) ?? 0) + 1);
}
const ranked = [...counts].sort(([a, m], [b, n]) => n - m || (a < b ? -1 : 1));
const longest = [...new Set(counts.keys())].reduce((best, w) => (w.length > best.length ? w : best), "");
for (const [word, n] of ranked.slice(0, 10)) checksum.add(word, n);
console.log(`words: ${counts.size} distinct, the longest "${longest}", checksum ${checksum.value()}`);
console.log("most used:", ranked.slice(0, 4));
console.log(`${"headline:".padEnd(12)}${newsletter.slice(0, newsletter.indexOf(".") + 1)}`);

// ── The finale: evening falls, on the timers ──

// Each home turns its lights on at an hour of its own, from 18:00 to 23:00.
const lit = (hour) => residents.filter((r) => 18 + (r.house % 6) <= hour).length;
const forgotten = setTimeout(() => console.log("never: this timer is cleared"), 50);
clearTimeout(forgotten);

let hour = 18;
const clock = setInterval(() => {
  hour++;
  checksum.add(hour, lit(hour));
  console.log(`${hour}:00, lights on in ${lit(hour)} homes`);
  if (hour === 22) clearInterval(clock);
}, 250);
setTimeout(() => {
  const report = { hour, done: typeof checksum.value === "function", final: checksum.value() };
  console.log("midnight:", report);
}, 1500);
console.log("the city waits for evening");

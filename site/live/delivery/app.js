"use strict";
(() => {
  // geography.ts
  var FLEET = { trucks: 8, orders: 100 };
  var TRUCK_CAPS = [14, 14, 14, 14, 14, 12, 12, 12];
  var TOTAL_CAP = TRUCK_CAPS.reduce((a, b) => a + b, 0);
  var MAX_CAP = Math.max(...TRUCK_CAPS);
  var MIN_CAP = Math.min(...TRUCK_CAPS);
  var MAP_W = 1200;
  var MAP_H = 720;
  var WEST_SHORE = [
    { x: 488, y: 0 },
    { x: 480, y: 105 },
    { x: 524, y: 175 },
    // bulge east — U-District sits on land, lake narrows by the Montlake cut
    { x: 500, y: 250 },
    { x: 466, y: 350 },
    { x: 492, y: 470 },
    { x: 474, y: 590 },
    { x: 496, y: 720 }
  ];
  var EAST_SHORE = [
    { x: 590, y: 0 },
    { x: 606, y: 130 },
    { x: 582, y: 260 },
    { x: 616, y: 380 },
    { x: 588, y: 500 },
    { x: 612, y: 620 },
    { x: 594, y: 720 }
  ];
  var MERCER_ISLAND = [
    { x: 548, y: 440 },
    { x: 590, y: 482 },
    { x: 598, y: 560 },
    { x: 588, y: 640 },
    { x: 548, y: 698 },
    { x: 508, y: 640 },
    { x: 498, y: 560 },
    { x: 506, y: 482 }
  ];
  var PUGET_SOUND = [
    { x: 0, y: 0 },
    { x: 118, y: 0 },
    { x: 100, y: 140 },
    { x: 138, y: 225 },
    { x: 116, y: 330 },
    { x: 158, y: 405 },
    { x: 250, y: 445 },
    // Elliott Bay reaches in toward downtown
    { x: 238, y: 505 },
    { x: 150, y: 520 },
    { x: 182, y: 600 },
    { x: 138, y: 690 },
    { x: 0, y: 720 }
  ];
  var LAKE_UNION = [
    // 10% skinnier on the E-W (short) axis, long N-S axis held in place (x scaled 0.9
    // about the centerline ≈358) to make room for the I-5 corridor. The canals still
    // meet the outline: the east cut endpoint lands on the new E edge, the west within ~1px.
    { x: 340, y: 292 },
    { x: 374, y: 286 },
    { x: 390, y: 322 },
    { x: 374, y: 360 },
    { x: 344, y: 366 },
    { x: 327, y: 330 }
  ];
  var CANAL_WEST = [
    { x: 135, y: 232 },
    { x: 215, y: 240 },
    { x: 300, y: 250 },
    { x: 340, y: 296 }
  ];
  var CANAL_EAST = [
    { x: 378, y: 296 },
    { x: 432, y: 250 },
    { x: 486, y: 214 }
  ];
  var UNION_BAY = [
    { x: 484, y: 200 },
    { x: 512, y: 196 },
    { x: 540, y: 210 },
    { x: 544, y: 232 },
    { x: 516, y: 242 },
    { x: 488, y: 228 }
  ];
  var WAREHOUSE = { x: 802, y: 396 };
  var NEIGHBORHOODS = [
    // --- Westside (Seattle) — the city, heavier traffic ---
    { name: "Ballard", center: { x: 224, y: 146 }, side: "west", ringRadius: 32, houses: 12 },
    { name: "Green Lake", center: { x: 360, y: 62 }, side: "west", ringRadius: 34, houses: 12, lake: 16 },
    { name: "Fremont", center: { x: 340, y: 212 }, side: "west", ringRadius: 30, houses: 12, note: "Center of the Universe" },
    { name: "U-District", center: { x: 460, y: 169 }, side: "west", ringRadius: 30, houses: 12 },
    { name: "Magnolia", center: { x: 170, y: 291 }, side: "west", ringRadius: 26, houses: 12, note: "out on the bluff" },
    { name: "Queen Anne", center: { x: 286, y: 316 }, side: "west", ringRadius: 32, houses: 12 },
    { name: "Capitol Hill", center: { x: 434, y: 443 }, side: "west", ringRadius: 29, houses: 12 },
    // Eastlake sits in the spot Capitol Hill vacated (a hair NNE), wired only to
    // Capitol Hill and U-District — houseboats on Lake Union, so houses may overlap
    // water, but the ring road stays on land.
    { name: "Eastlake", center: { x: 441, y: 311 }, side: "west", ringRadius: 24, houses: 12 },
    { name: "Downtown", center: { x: 300, y: 430 }, side: "west", ringRadius: 30, houses: 12 },
    { name: "Beacon Hill", center: { x: 432, y: 555 }, side: "west", ringRadius: 30, houses: 12 },
    { name: "West Seattle", center: { x: 211, y: 589 }, side: "west", ringRadius: 30, houses: 12 },
    // --- Mercer Island — I-90 lands at the interchange right above the homes; a cheap
    //     off-ramp drops onto Mercer N (≈1 time unit), and the necks chain SOUTH to
    //     Mercer S at residential pace. "Mercer Island" itself is just the interchange
    //     (no homes) — a routing waypoint, never a delivery stop. ---
    { name: "Mercer Island", center: { x: 548, y: 500 }, side: "island", ringRadius: 10, houses: 0, note: "the Rock" },
    { name: "Mercer N", center: { x: 548, y: 552 }, side: "island", ringRadius: 19, houses: 12 },
    { name: "Mercer S", center: { x: 548, y: 635 }, side: "island", ringRadius: 19, houses: 12 },
    // --- Eastside — tech money, more room ---
    { name: "Medina", center: { x: 638, y: 228 }, side: "east", ringRadius: 28, houses: 12, note: "you-know-who lives here" },
    { name: "Kirkland", center: { x: 650, y: 60 }, side: "east", ringRadius: 30, houses: 12 },
    { name: "Redmond", center: { x: 868, y: 200 }, side: "east", ringRadius: 32, houses: 12 },
    { name: "Bellevue", center: { x: 740, y: 330 }, side: "east", ringRadius: 34, houses: 12 },
    { name: "Factoria", center: { x: 672, y: 508 }, side: "east", ringRadius: 30, houses: 12 },
    { name: "Issaquah", center: { x: 858, y: 612 }, side: "east", ringRadius: 30, houses: 12 },
    // --- I-5 exits — junctions (no homes) on the freeway spine, just west of the
    //     BH/CH/EL/UD corridor. The eight central cities reach each other ONLY via these
    //     exits now (the cross-corridor surface streets are severed). An artery that runs
    //     ~20% quicker than the surface streets (no lights) AND skips the slow neighborhood
    //     rings — the combination is what tips routes into hopping an exit to grab the
    //     stragglers. The spine is NOT a straight cardinal line (that reads un-Seattle): it
    //     runs vertical down from Eastlake to the bottom of Lake Union (a kink in the I-5
    //     `waters`), then bends gently SSW toward Downtown/West Seattle — leaving Capitol
    //     Hill & Beacon Hill more breathing room — while the middle tilts a couple degrees
    //     and the north leans east to thread the Fremont/U-District gap and pass EAST of
    //     Green Lake (pushed west to suit). S→N: 1) WSea/BH  2) Downtown/CH  3) Eastlake
    //     4) Fremont  5) U-Dist  6) Green Lake. ---
    { name: "Exit 1", center: { x: 328, y: 570 }, side: "west", ringRadius: 6, houses: 0, note: "I-5" },
    { name: "Exit 2", center: { x: 377, y: 436 }, side: "west", ringRadius: 6, houses: 0, note: "I-5" },
    { name: "Exit 3", center: { x: 397, y: 311 }, side: "west", ringRadius: 6, houses: 0, note: "I-5" },
    { name: "Exit 4", center: { x: 401, y: 212 }, side: "west", ringRadius: 6, houses: 0, note: "I-5" },
    { name: "Exit 5", center: { x: 405, y: 169 }, side: "west", ringRadius: 6, houses: 0, note: "I-5" },
    { name: "Exit 6", center: { x: 414, y: 84 }, side: "west", ringRadius: 6, houses: 0, note: "I-5" },
    // The 5/520 interchange — a junction (no homes) on the I-5 spine, exactly midway
    // between the Eastlake (Exit 3) and Fremont (Exit 4) exits, where SR 520 ties into I-5.
    { name: "5/520", center: { x: 399, y: 262 }, side: "west", ringRadius: 6, houses: 0, note: "I-5 / SR 520" },
    // Montlake — the SR 520 junction NE of Eastlake. The 520-to-Eastlake exit ramp meets
    // the highway here, so it can land on Eastlake's NE corner at a gentle angle.
    { name: "Montlake", center: { x: 490, y: 256 }, side: "west", ringRadius: 6, houses: 0, note: "SR 520" }
  ];
  var I5_EXITS = /* @__PURE__ */ new Set(["Exit 1", "Exit 2", "Exit 3", "Exit 4", "Exit 5", "Exit 6", "5/520"]);
  var ROADS = [
    // Westside arterials. The cross-corridor links (Downtown↔Cap Hill, Downtown↔Beacon,
    // Beacon↔West Seattle, Green Lake↔U-Dist, Fremont↔U-Dist) are SEVERED — they crossed
    // the I-5 line, so those trips now route via the freeway and its exits (below).
    ["Ballard", "Green Lake"],
    ["Ballard", "Fremont"],
    ["Magnolia", "Ballard"],
    // an artery over the ship canal (no bridge styling)
    ["Magnolia", "Queen Anne"],
    ["Green Lake", "Fremont"],
    ["Fremont", "Queen Anne"],
    ["Queen Anne", "Downtown"],
    ["Capitol Hill", "Eastlake"],
    // corridor-internal (parallel to I-5, not across it) — kept
    // (Eastlake↔U-District is GONE: it was a drawbridge — perilous and unpredictable for
    //  delivery, so drivers avoid it. U-District now reaches the network only via Exit 5.)
    ["Capitol Hill", "Beacon Hill"],
    ["Downtown", "West Seattle"],
    // west-internal (both west of I-5) — kept
    // I-5 exit ramps — each central city onto its freeway exit (paired cities share one).
    ["Exit 1", "West Seattle"],
    ["Exit 1", "Beacon Hill"],
    ["Exit 2", "Downtown"],
    ["Exit 2", "Capitol Hill"],
    ["Exit 3", "Eastlake"],
    ["Exit 4", "Fremont"],
    ["Exit 5", "U-District"],
    ["Exit 6", "Green Lake"],
    ["Eastlake", "Montlake"],
    // the SR 520 exit ramp into Eastlake's NE corner
    // Eastside arterials
    ["Medina", "Kirkland"],
    ["Medina", "Bellevue"],
    ["Kirkland", "Redmond"],
    ["Bellevue", "Redmond"],
    ["Bellevue", "Factoria"],
    ["Bellevue", "FC"],
    ["FC", "Factoria"],
    ["Factoria", "Issaquah"],
    ["Issaquah", "Redmond"],
    // the far-east "fast" bypass (I-405 / Sammamish)
    // The two Mercer Island cul-de-sacs branch off the I-90 interchange.
    ["Mercer Island", "Mercer N"],
    ["Mercer N", "Mercer S"]
    // the necks chain: slog through Mercer N to reach Mercer S
  ];
  var BRIDGES = [
    {
      // North crossing: the 5/520 interchange on I-5 -> Montlake -> Medina. The first
      // segment is the short freeway run from I-5 east to the Montlake junction; the second
      // is the long, slow lake crossing (SPEED.bridge520). Eastlake hangs off Montlake by a
      // surface ramp (below), landing on its NE corner.
      name: "SR 520",
      nodes: ["5/520", "Montlake", "Medina"],
      waters: [[], []]
    },
    {
      // South crossing: Beacon Hill -> Mercer Island -> Factoria.
      name: "I-90",
      nodes: ["Beacon Hill", "Mercer Island", "Factoria"],
      waters: [[{ x: 482, y: 522 }], [{ x: 610, y: 489 }]]
    },
    {
      // I-5 — the central freeway spine, south to north through its six exits. Kept in
      // BRIDGES only because it's a multi-node chain with mid-span waypoints; it's drawn
      // like a surface artery (map_view special-cases it) and runs ~20% quicker. The kink
      // in waters[1] (Exit 2↔Exit 3) holds the spine vertical down past the bottom of
      // Lake Union before it bends SSW — so the bend reads as a real freeway curve, not a
      // straight diagonal off Eastlake.
      name: "I-5",
      nodes: ["Exit 1", "Exit 2", "Exit 3", "5/520", "Exit 4", "Exit 5", "Exit 6"],
      waters: [[], [{ x: 399, y: 373 }], [], [], [], []]
    }
  ];
  function namePhase(name) {
    let h = 0;
    for (let i = 0; i < name.length; i++) h = h * 31 + name.charCodeAt(i) >>> 0;
    return h % 360 * (Math.PI / 180);
  }
  var HOUSE_GAP = 9;
  function housesOf(n) {
    const phase = namePhase(n.name);
    const r = n.ringRadius + HOUSE_GAP;
    const pts = [];
    for (let i = 0; i < n.houses; i++) {
      const a = phase + i / n.houses * Math.PI * 2;
      pts.push({ x: n.center.x + Math.cos(a) * r, y: n.center.y + Math.sin(a) * r });
    }
    return pts;
  }
  function neighborhood(name) {
    if (name === "FC") return null;
    const n = NEIGHBORHOODS.find((m) => m.name === name);
    if (!n) throw new Error(`unknown road node: ${name}`);
    return n;
  }
  function nodeAt(name) {
    return neighborhood(name)?.center ?? WAREHOUSE;
  }
  function gateOf(name, toward) {
    const n = neighborhood(name);
    if (!n) return WAREHOUSE;
    const a = Math.atan2(toward.y - n.center.y, toward.x - n.center.x);
    return { x: n.center.x + Math.cos(a) * n.ringRadius, y: n.center.y + Math.sin(a) * n.ringRadius };
  }
  function roadGates(road) {
    const [a, b] = road;
    return [gateOf(a, nodeAt(b)), gateOf(b, nodeAt(a))];
  }
  function bridgeSegments(b) {
    const segs = [];
    for (let i = 0; i < b.nodes.length - 1; i++) {
      const a = b.nodes[i];
      const c = b.nodes[i + 1];
      const w = b.waters[i] ?? [];
      const pts = [gateOf(a, w[0] ?? nodeAt(c)), ...w, gateOf(c, w[w.length - 1] ?? nodeAt(a))];
      segs.push({ edge: [a, c], pts });
    }
    return segs;
  }
  function bridgeDeck(b) {
    return bridgeSegments(b).flatMap((s) => s.pts);
  }
  function allGates() {
    const gates = [];
    for (const r of ROADS) {
      const [g1, g2] = roadGates(r);
      gates.push(g1, g2);
    }
    for (const b of BRIDGES) {
      for (const seg of bridgeSegments(b)) {
        gates.push(seg.pts[0], seg.pts[seg.pts.length - 1]);
      }
    }
    return gates;
  }
  function edgePolyline(a, b) {
    for (const r of ROADS) {
      if (r[0] === a && r[1] === b) return roadGates(r);
      if (r[0] === b && r[1] === a) {
        const [g1, g2] = roadGates(r);
        return [g2, g1];
      }
    }
    for (const br of BRIDGES) {
      for (const seg of bridgeSegments(br)) {
        const [x, y] = seg.edge;
        if (x === a && y === b) return seg.pts;
        if (x === b && y === a) return [...seg.pts].reverse();
      }
    }
    throw new Error(`no edge between adjacent nodes: ${a} -> ${b}`);
  }
  var TAU = Math.PI * 2;
  var norm = (a) => (a % TAU + TAU) % TAU;
  function gateAngle(name, toward) {
    const n = neighborhood(name);
    if (!n) return 0;
    return Math.atan2(toward.y - n.center.y, toward.x - n.center.x);
  }
  function houseAngles(name, indices) {
    const n = neighborhood(name);
    if (!n) return [];
    const phase = namePhase(name);
    return indices.map((i) => phase + i / n.houses * TAU);
  }
  function walkPlan(name, entryA, exitA, hAngles) {
    const n = neighborhood(name);
    if (!n) return { arcPx: 0, r: 0, startA: 0, coveredRad: 0, pe: 0, px: 0, loop: false };
    const r = n.ringRadius;
    const pts = [entryA, exitA, ...hAngles].map(norm).sort((a, b) => a - b);
    let maxGap = -1;
    let gapAt = 0;
    for (let i = 0; i < pts.length; i++) {
      const next = i + 1 < pts.length ? pts[i + 1] : pts[0] + TAU;
      if (next - pts[i] > maxGap) {
        maxGap = next - pts[i];
        gapAt = i;
      }
    }
    const startA = pts[(gapAt + 1) % pts.length];
    const coveredRad = TAU - maxGap;
    const arcOffset = (a) => {
      const o = norm(a - startA);
      if (o <= coveredRad) return o;
      return TAU - o < o - coveredRad ? 0 : coveredRad;
    };
    const pe = arcOffset(entryA);
    const px = arcOffset(exitA);
    const sameGate = norm(entryA - exitA) < 1e-9;
    let arcRad = 2 * coveredRad - Math.abs(pe - px);
    let loop = false;
    if (sameGate && 2 * coveredRad > TAU) {
      arcRad = TAU;
      loop = true;
    }
    return { arcPx: arcRad * r, r, startA, coveredRad, pe, px, loop };
  }
  function ringWalkArcPx(name, entryA, exitA, hAngles) {
    return walkPlan(name, entryA, exitA, hAngles).arcPx;
  }
  function sampleSeg(c, r, startA, from, to, out) {
    const span = to - from;
    const steps = Math.max(1, Math.ceil(Math.abs(span) / 0.2));
    for (let k = out.length ? 1 : 0; k <= steps; k++) {
      const a = startA + from + span * k / steps;
      out.push({ x: c.x + Math.cos(a) * r, y: c.y + Math.sin(a) * r });
    }
  }
  function ringWalkPath(name, entryA, exitA, hAngles) {
    const n = neighborhood(name);
    if (!n) return [];
    const pl = walkPlan(name, entryA, exitA, hAngles);
    const out = [];
    if (pl.loop) {
      sampleSeg(n.center, pl.r, pl.startA, pl.pe, pl.pe + TAU, out);
      return out;
    }
    const seq = pl.pe <= pl.px ? [pl.pe, 0, pl.coveredRad, pl.px] : [pl.pe, pl.coveredRad, 0, pl.px];
    for (let i = 1; i < seq.length; i++) sampleSeg(n.center, pl.r, pl.startA, seq[i - 1], seq[i], out);
    return out;
  }

  // orders.ts
  function allHouses() {
    const out = [];
    for (const n of NEIGHBORHOODS) {
      housesOf(n).forEach((at2, i) => out.push({ id: `${n.name}#${i}`, nbhd: n.name, index: i, at: at2 }));
    }
    return out;
  }
  function mulberry32(seed2) {
    let s = seed2 >>> 0;
    return () => {
      s = s + 1831565813 >>> 0;
      let t = s;
      t = Math.imul(t ^ t >>> 15, t | 1);
      t ^= t + Math.imul(t ^ t >>> 7, t | 61);
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }
  function chooseOrders(seed2, count) {
    const houses = allHouses();
    const idx = houses.map((_, i) => i);
    const rng = mulberry32(seed2);
    const n = Math.min(count, idx.length);
    for (let i = 0; i < n; i++) {
      const j = i + Math.floor(rng() * (idx.length - i));
      const tmp = idx[i];
      idx[i] = idx[j];
      idx[j] = tmp;
    }
    const chosen = /* @__PURE__ */ new Set();
    for (let k = 0; k < n; k++) chosen.add(houses[idx[k]].id);
    return chosen;
  }

  // roadgraph.ts
  var MIN_PER_PX = 0.0225;
  var SPEED = { city: 1.6, suburb: 1, bridge: 1.2, bridge520: 1.5, fast: 0.6, i5: 0.8 };
  var NEIGHBORHOOD_SLOWDOWN = 2.1;
  var SERVICE = 2;
  function safelyRound(x) {
    const r = Math.round(x);
    if (0.5 - Math.abs(x - r) < 1e-9) {
      throw new Error(`safelyRound(${x}) lands on a .5 boundary \u2014 cross-engine rounding could flip. Nudge a neighborhood a pixel.`);
    }
    if (r < 1) {
      throw new Error(`safelyRound(${x}) rounded to ${r} (< 1) \u2014 a zero-length segment would divide by zero in playback. Move the neighborhoods apart.`);
    }
    return r;
  }
  function roundExit(x) {
    const r = Math.round(x);
    if (r >= 1 && 0.5 - Math.abs(x - r) < 1e-9) {
      throw new Error(`roundExit(${x}) lands on a .5 boundary \u2014 cross-engine rounding could flip. Nudge a neighborhood a pixel.`);
    }
    return Math.max(1, r);
  }
  var NODES = [...NEIGHBORHOODS.map((n) => n.name), "FC"];
  function len(pts) {
    let d = 0;
    for (let i = 1; i < pts.length; i++) d += Math.hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y);
    return d;
  }
  function isWest(name) {
    return NEIGHBORHOODS.some((n) => n.name === name && n.side === "west");
  }
  function factor(a, b, bridge) {
    if (a === "Montlake" && b === "Medina" || a === "Medina" && b === "Montlake") return SPEED.bridge520;
    if (a === "Montlake" || b === "Montlake") return SPEED.i5;
    if (I5_EXITS.has(a) || I5_EXITS.has(b)) return SPEED.i5;
    if (a === "Issaquah" && b === "Redmond" || a === "Redmond" && b === "Issaquah") return SPEED.fast;
    if (bridge) return SPEED.bridge;
    if (isWest(a) || isWest(b)) return SPEED.city;
    return SPEED.suburb;
  }
  function localMinutes(name, entryA, exitA, houseAngles2) {
    const arterial = isWest(name) ? SPEED.city : SPEED.suburb;
    return ringWalkArcPx(name, entryA, exitA, houseAngles2) * arterial * NEIGHBORHOOD_SLOWDOWN * MIN_PER_PX;
  }
  function edges() {
    const out = [];
    const onI5 = (a, b) => I5_EXITS.has(a) || I5_EXITS.has(b);
    for (const r of ROADS) {
      const round = onI5(r[0], r[1]) ? roundExit : safelyRound;
      out.push({ a: r[0], b: r[1], minutes: round(len(roadGates(r)) * factor(r[0], r[1], false) * MIN_PER_PX) });
    }
    for (const b of BRIDGES) {
      for (const seg of bridgeSegments(b)) {
        const [x, y] = seg.edge;
        const round = onI5(x, y) ? roundExit : safelyRound;
        out.push({ a: x, b: y, minutes: round(len(seg.pts) * factor(x, y, true) * MIN_PER_PX) });
      }
    }
    return out;
  }
  function buildSubstrate() {
    const nodes = NODES;
    const index = new Map(nodes.map((n, i) => [n, i]));
    const N = nodes.length;
    const adj = nodes.map(() => []);
    for (const e of edges()) {
      const i = index.get(e.a);
      const j = index.get(e.b);
      if (i === void 0 || j === void 0) throw new Error(`edge names off the node list: ${e.a}-${e.b}`);
      adj[i].push({ to: j, w: e.minutes });
      adj[j].push({ to: i, w: e.minutes });
    }
    const matrix = nodes.map(() => new Array(N).fill(Infinity));
    const prev = nodes.map(() => new Array(N).fill(-1));
    for (let s = 0; s < N; s++) {
      const dist = matrix[s];
      const back = prev[s];
      dist[s] = 0;
      const done = new Array(N).fill(false);
      for (let it = 0; it < N; it++) {
        let u = -1;
        let best = Infinity;
        for (let k = 0; k < N; k++) if (!done[k] && dist[k] < best) {
          best = dist[k];
          u = k;
        }
        if (u === -1) break;
        done[u] = true;
        for (const { to, w } of adj[u]) if (dist[u] + w < dist[to]) {
          dist[to] = dist[u] + w;
          back[to] = u;
        }
      }
    }
    const idOf = (name) => {
      const i = index.get(name);
      if (i === void 0) throw new Error(`unknown node: ${name}`);
      return i;
    };
    const time = (a, b) => matrix[idOf(a)][idOf(b)];
    const path = (a, b) => {
      const s = idOf(a);
      let v = idOf(b);
      if (!Number.isFinite(matrix[s][v])) throw new Error(`no path: ${a} -> ${b}`);
      const rev = [];
      while (v !== s) {
        rev.push(v);
        v = prev[s][v];
        if (v === -1) throw new Error(`broken path chain: ${a} -> ${b}`);
      }
      rev.push(s);
      return rev.reverse().map((i) => nodes[i]);
    };
    return { nodes, index, matrix, time, path };
  }

  // timeline.ts
  function len2(pts) {
    const cum = [0];
    for (let i = 1; i < pts.length; i++) cum.push(cum[i - 1] + Math.hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y));
    return cum;
  }
  function at(pts, cum, pos) {
    if (pos <= 0) return pts[0];
    const total = cum[cum.length - 1];
    if (pos >= total) return pts[pts.length - 1];
    let k = 1;
    while (k < cum.length && cum[k] < pos) k++;
    const seg = cum[k] - cum[k - 1];
    const t = seg > 0 ? (pos - cum[k - 1]) / seg : 0;
    return { x: pts[k - 1].x + (pts[k].x - pts[k - 1].x) * t, y: pts[k - 1].y + (pts[k].y - pts[k - 1].y) * t };
  }
  function slice(pts, cum, a, b) {
    const out = [at(pts, cum, a)];
    for (let k = 0; k < cum.length; k++) if (cum[k] > a && cum[k] < b) out.push(pts[k]);
    out.push(at(pts, cum, b));
    return out;
  }
  function firstPassPos(pts, cum, target) {
    const TOL = 1;
    const approaches = [];
    let best = Infinity;
    for (let k = 1; k < pts.length; k++) {
      const ax = pts[k - 1].x;
      const ay = pts[k - 1].y;
      const dx = pts[k].x - ax;
      const dy = pts[k].y - ay;
      const l2 = dx * dx + dy * dy;
      const t = l2 > 0 ? Math.max(0, Math.min(1, ((target.x - ax) * dx + (target.y - ay) * dy) / l2)) : 0;
      const d = Math.hypot(target.x - (ax + dx * t), target.y - (ay + dy * t));
      if (d < best) best = d;
      approaches.push({ pos: cum[k - 1] + t * (cum[k] - cum[k - 1]), d });
    }
    let pos = 0;
    let earliest = Infinity;
    for (const a of approaches) {
      if (a.d <= best + TOL && a.pos < earliest) {
        earliest = a.pos;
        pos = a.pos;
      }
    }
    return pos;
  }
  function ringLegs(name, pts, arcMin, houses) {
    const cum = len2(pts);
    const total = cum[cum.length - 1] || 1;
    const n = NEIGHBORHOODS.find((m) => m.name === name);
    const angles = houseAngles(name, houses);
    const stops = houses.map((h, i) => {
      const ring = { x: n.center.x + Math.cos(angles[i]) * n.ringRadius, y: n.center.y + Math.sin(angles[i]) * n.ringRadius };
      return { house: `${name}#${h}`, pos: firstPassPos(pts, cum, ring) };
    }).sort((a, b) => a.pos - b.pos);
    const legs = [];
    let cursor = 0;
    const arcLeg = (a, b) => {
      const piece = slice(pts, cum, a, b);
      if (piece.length >= 2) legs.push({ kind: "arc", pts: piece, dur: arcMin * ((b - a) / total) });
    };
    for (const s of stops) {
      arcLeg(cursor, s.pos);
      legs.push({ kind: "service", at: at(pts, cum, s.pos), dur: SERVICE, house: s.house });
      cursor = s.pos;
    }
    arcLeg(cursor, total);
    return legs;
  }
  function buildItinerary(sub, route) {
    const waypoints = ["FC", ...route.stops.map((s) => s.nbhd), "FC"];
    const nodes = [];
    for (let i = 1; i < waypoints.length; i++) {
      for (const node of sub.path(waypoints[i - 1], waypoints[i])) if (nodes[nodes.length - 1] !== node) nodes.push(node);
    }
    const housesAt = /* @__PURE__ */ new Map();
    for (const s of route.stops) housesAt.set(s.nbhd, (housesAt.get(s.nbhd) ?? []).concat(s.houses));
    const delivered = /* @__PURE__ */ new Set();
    const legs = [];
    for (let i = 1; i < nodes.length; i++) {
      const prev = nodes[i - 1];
      const node = nodes[i];
      legs.push({ kind: "drive", pts: edgePolyline(prev, node), dur: sub.time(prev, node) });
      if (node !== "FC" && i < nodes.length - 1) {
        const entry = gateAngle(node, nodeAt(prev));
        const exit = gateAngle(node, nodeAt(nodes[i + 1]));
        const full = housesAt.get(node);
        const delivering = !!(full && full.length && !delivered.has(node));
        const houses = delivering ? full : [];
        if (delivering) delivered.add(node);
        const hAngles = houseAngles(node, houses);
        const pts = ringWalkPath(node, entry, exit, hAngles);
        const arcMin = localMinutes(node, entry, exit, hAngles);
        if (delivering) {
          for (const leg of ringLegs(node, pts, arcMin, houses)) legs.push(leg);
        } else if (pts.length >= 2) {
          legs.push({ kind: "arc", pts, dur: arcMin });
        }
      }
    }
    const total = legs.reduce((s, l) => s + l.dur, 0);
    return { legs, total };
  }

  // map_view.ts
  var SUB = buildSubstrate();
  var TRUCK_COLORS = [
    "#1c6fd6",
    // blue
    "#e8590c",
    // orange
    "#2f9e44",
    // green
    "#d6336c",
    // magenta
    "#a0521d",
    // saddle brown — warm/light enough to part from T8 charcoal, still redder than T7 gold
    "#7048e8",
    // violet
    "#b8860b",
    // dark gold
    "#343a40"
    // charcoal
  ];
  var ORDER_SIZE = 9.9;
  var HOME_SIZE = 5;
  var PANEL_X = MAP_W - 250;
  var PANEL_W = 240;
  var PANEL_TOP = 148;
  var PANEL_ROW0 = PANEL_TOP + 37;
  var PANEL_ROW_H = 18;
  var COLOR = {
    westLand: "#e7e3ea",
    eastLand: "#e7eede",
    water: "#9fcfe6",
    waterEdge: "#6fb2d2",
    island: "#eef3df",
    road: "#cfc7bb",
    roadCasing: "#b3aa9c",
    gate: "#7d7464",
    ring: "#a89f90",
    ringHot: "#2a2e34",
    home: "#cdc6b8",
    homeEdge: "#a9a094",
    order: "#e8732e",
    depot: "#c0392b",
    text: "#2a2e34",
    note: "#7b8088",
    faint: "#b9b3bf",
    link: "#2a6db0"
  };
  function trace(ctx2, pts, close) {
    ctx2.beginPath();
    ctx2.moveTo(pts[0].x, pts[0].y);
    for (let i = 1; i < pts.length; i++) ctx2.lineTo(pts[i].x, pts[i].y);
    if (close) ctx2.closePath();
  }
  function fillPoly(ctx2, pts, fill, edge) {
    trace(ctx2, pts, true);
    ctx2.fillStyle = fill;
    ctx2.fill();
    if (edge) {
      ctx2.lineWidth = 2;
      ctx2.strokeStyle = edge;
      ctx2.stroke();
    }
  }
  function drawLand(ctx2) {
    ctx2.fillStyle = COLOR.westLand;
    ctx2.fillRect(0, 0, MAP_W, MAP_H);
    ctx2.fillStyle = COLOR.eastLand;
    ctx2.fillRect(540, 0, MAP_W - 540, MAP_H);
  }
  function lakeWashington(ctx2) {
    ctx2.beginPath();
    ctx2.moveTo(WEST_SHORE[0].x, WEST_SHORE[0].y);
    for (const p of WEST_SHORE) ctx2.lineTo(p.x, p.y);
    for (let i = EAST_SHORE.length - 1; i >= 0; i--) ctx2.lineTo(EAST_SHORE[i].x, EAST_SHORE[i].y);
    ctx2.closePath();
    ctx2.fillStyle = COLOR.water;
    ctx2.fill();
    ctx2.lineWidth = 2;
    ctx2.strokeStyle = COLOR.waterEdge;
    ctx2.stroke();
  }
  function channel(ctx2, pts) {
    ctx2.lineCap = "round";
    ctx2.lineJoin = "round";
    trace(ctx2, pts, false);
    ctx2.lineWidth = 14;
    ctx2.strokeStyle = COLOR.waterEdge;
    ctx2.stroke();
    trace(ctx2, pts, false);
    ctx2.lineWidth = 10;
    ctx2.strokeStyle = COLOR.water;
    ctx2.stroke();
  }
  function drawWater(ctx2) {
    lakeWashington(ctx2);
    fillPoly(ctx2, PUGET_SOUND, COLOR.water, COLOR.waterEdge);
    channel(ctx2, CANAL_WEST);
    channel(ctx2, CANAL_EAST);
    fillPoly(ctx2, UNION_BAY, COLOR.water, COLOR.waterEdge);
    fillPoly(ctx2, LAKE_UNION, COLOR.water, COLOR.waterEdge);
    fillPoly(ctx2, MERCER_ISLAND, COLOR.island, COLOR.waterEdge);
  }
  function stroke(ctx2, pts, width, color) {
    trace(ctx2, pts, false);
    ctx2.lineCap = "round";
    ctx2.lineJoin = "round";
    ctx2.lineWidth = width;
    ctx2.strokeStyle = color;
    ctx2.stroke();
  }
  function drawRoads(ctx2) {
    for (const r of ROADS) {
      const gates = roadGates(r);
      stroke(ctx2, gates, 6, COLOR.roadCasing);
      stroke(ctx2, gates, 3.5, COLOR.road);
    }
  }
  function freewayStub(from, prev, edgeY) {
    const vx = from.x - prev.x;
    const vy = from.y - prev.y;
    const t = (edgeY - from.y) / vy;
    return { x: from.x + vx * t, y: edgeY };
  }
  function drawBridges(ctx2) {
    for (const b of BRIDGES) {
      let deck = bridgeDeck(b);
      if (b.name === "I-5") {
        const south = freewayStub(nodeAt("Exit 1"), nodeAt("Exit 2"), MAP_H);
        const north = freewayStub(nodeAt("Exit 6"), nodeAt("Exit 5"), 0);
        deck = [south, ...deck, north];
      }
      stroke(ctx2, deck, 6, COLOR.roadCasing);
      stroke(ctx2, deck, 3.5, COLOR.road);
    }
  }
  function drawGates(ctx2) {
    ctx2.fillStyle = COLOR.gate;
    for (const g of allGates()) {
      ctx2.beginPath();
      ctx2.arc(g.x, g.y, 2.4, 0, Math.PI * 2);
      ctx2.fill();
    }
  }
  function drawNeighborhood(ctx2, n, orders2, houseColor, highlight, delivered, popped = null) {
    if (n.houses === 0) {
      ctx2.beginPath();
      ctx2.arc(n.center.x, n.center.y, n.ringRadius, 0, Math.PI * 2);
      ctx2.fillStyle = COLOR.gate;
      ctx2.fill();
      return;
    }
    if (n.lake) {
      ctx2.beginPath();
      ctx2.arc(n.center.x, n.center.y, n.lake, 0, Math.PI * 2);
      ctx2.fillStyle = COLOR.water;
      ctx2.fill();
      ctx2.lineWidth = 1.5;
      ctx2.strokeStyle = COLOR.waterEdge;
      ctx2.stroke();
    }
    ctx2.beginPath();
    ctx2.arc(n.center.x, n.center.y, n.ringRadius, 0, Math.PI * 2);
    ctx2.lineWidth = 3;
    ctx2.strokeStyle = COLOR.ring;
    ctx2.stroke();
    const focusMode = highlight !== null;
    housesOf(n).forEach((h, i) => {
      const key = `${n.name}#${i}`;
      const isOrder = orders2.has(key);
      if (isOrder) {
        const isPopped = popped !== null && popped.has(key);
        const focused = isPopped || focusMode && highlight.has(key);
        const muted = focusMode && !focused;
        const color = houseColor.get(key) ?? COLOR.order;
        if (delivered && delivered.has(key)) {
          drawCheck(ctx2, h.x, h.y, ORDER_SIZE * 1.5, color);
          return;
        }
        if (isPopped) {
          ctx2.globalAlpha = 0.3;
          ctx2.fillStyle = color;
          ctx2.beginPath();
          ctx2.arc(h.x, h.y, 15, 0, Math.PI * 2);
          ctx2.fill();
          ctx2.globalAlpha = 1;
        }
        const s = isPopped ? 16 : focused ? 13 : ORDER_SIZE;
        ctx2.globalAlpha = muted ? 0.5 : 1;
        ctx2.fillStyle = color;
        ctx2.strokeStyle = isPopped ? "#16202b" : "#ffffff";
        ctx2.lineWidth = isPopped ? 2.5 : focused ? 2 : 1.5;
        ctx2.beginPath();
        ctx2.rect(h.x - s / 2, h.y - s / 2, s, s);
        ctx2.fill();
        ctx2.stroke();
        ctx2.globalAlpha = 1;
      } else {
        const s = HOME_SIZE;
        ctx2.fillStyle = COLOR.home;
        ctx2.strokeStyle = COLOR.homeEdge;
        ctx2.lineWidth = 1;
        ctx2.beginPath();
        ctx2.rect(h.x - s / 2, h.y - s / 2, s, s);
        ctx2.fill();
        ctx2.stroke();
      }
    });
  }
  function drawDetail(ctx2, plan2, orders2, hoverNbhd2, activeTruck) {
    if (hoverNbhd2 === null && activeTruck === null) return;
    const x = PANEL_X;
    let y = PANEL_ROW0 + plan2.routes.length * PANEL_ROW_H + (plan2.unrouted.length ? 18 : 0) + 20;
    ctx2.strokeStyle = "rgba(0, 0, 0, 0.12)";
    ctx2.lineWidth = 1;
    ctx2.beginPath();
    ctx2.moveTo(x, y - 14);
    ctx2.lineTo(x + PANEL_W, y - 14);
    ctx2.stroke();
    ctx2.textAlign = "left";
    const n = hoverNbhd2 ? NEIGHBORHOODS.find((m) => m.name === hoverNbhd2) : void 0;
    if (n) {
      let count = 0;
      for (let i = 0; i < n.houses; i++) if (orders2.has(`${n.name}#${i}`)) count++;
      ctx2.fillStyle = COLOR.text;
      ctx2.font = "bold 14px system-ui, sans-serif";
      ctx2.fillText(n.name, x, y);
      y += 18;
      if (n.note) {
        ctx2.fillStyle = COLOR.note;
        ctx2.font = "italic 12px system-ui, sans-serif";
        ctx2.fillText(n.note, x, y);
        y += 17;
      }
      ctx2.fillStyle = COLOR.note;
      ctx2.font = "12px system-ui, sans-serif";
      ctx2.fillText(`${count} order${count === 1 ? "" : "s"}  \xB7  \u2248${Math.round(SUB.time("FC", n.name))} min from FC`, x, y);
      y += 24;
    }
    if (activeTruck === null || !plan2.routes[activeTruck]) return;
    const r = plan2.routes[activeTruck];
    const color = TRUCK_COLORS[activeTruck % TRUCK_COLORS.length];
    ctx2.fillStyle = COLOR.text;
    ctx2.font = "bold 13px system-ui, sans-serif";
    ctx2.fillText(`Truck ${activeTruck + 1} \u2014 ${r.orders} totes \xB7 ${Math.round(r.time)} min`, x, y);
    y += 19;
    r.stops.forEach((s, k) => {
      const here = s.nbhd === hoverNbhd2;
      ctx2.fillStyle = color;
      ctx2.beginPath();
      ctx2.arc(x + 4, y - 4, here ? 4.5 : 3.5, 0, Math.PI * 2);
      ctx2.fill();
      ctx2.fillStyle = COLOR.text;
      ctx2.font = `${here ? "bold " : ""}12px system-ui, sans-serif`;
      ctx2.fillText(`${k + 1}. ${s.nbhd}`, x + 14, y);
      ctx2.fillStyle = COLOR.note;
      ctx2.textAlign = "right";
      ctx2.fillText(`${s.orders} tote${s.orders === 1 ? "" : "s"}`, x + PANEL_W, y);
      ctx2.textAlign = "left";
      y += 17;
    });
  }
  function drawWarehouse(ctx2) {
    const { x, y } = WAREHOUSE;
    ctx2.fillStyle = COLOR.depot;
    ctx2.strokeStyle = "#7d241a";
    ctx2.lineWidth = 2;
    ctx2.beginPath();
    ctx2.rect(x - 13, y - 8, 26, 18);
    ctx2.fill();
    ctx2.stroke();
    ctx2.beginPath();
    ctx2.moveTo(x - 16, y - 8);
    ctx2.lineTo(x, y - 20);
    ctx2.lineTo(x + 16, y - 8);
    ctx2.closePath();
    ctx2.fill();
    ctx2.stroke();
    ctx2.fillStyle = COLOR.text;
    ctx2.font = "bold 13px system-ui, sans-serif";
    ctx2.textAlign = "center";
    ctx2.fillText("Warehouse", x, y + 26);
    ctx2.fillStyle = COLOR.note;
    ctx2.font = "italic 11px system-ui, sans-serif";
    ctx2.fillText("AmazonFresh FC", x, y + 39);
  }
  function drawRegionLabels(ctx2) {
    ctx2.textAlign = "center";
    ctx2.save();
    ctx2.translate(545, 320);
    ctx2.rotate(Math.PI / 2);
    ctx2.fillStyle = COLOR.waterEdge;
    ctx2.font = "italic 16px system-ui, sans-serif";
    ctx2.fillText("Lake Washington", 0, 0);
    ctx2.restore();
    ctx2.fillStyle = COLOR.waterEdge;
    ctx2.font = "italic 11px system-ui, sans-serif";
    ctx2.textAlign = "center";
    ctx2.fillText("Lake Union", 358, 400);
    ctx2.save();
    ctx2.translate(48, 360);
    ctx2.rotate(-Math.PI / 2);
    ctx2.fillStyle = COLOR.waterEdge;
    ctx2.font = "italic 13px system-ui, sans-serif";
    ctx2.fillText("Puget Sound", 0, 0);
    ctx2.restore();
  }
  var HUD_TOOLTIPS = [
    { x: 24, y: 64, w: 110, h: 18, text: "Use S to shuffle up a new shift" },
    // over "Shift Sn"
    { x: 24, y: 86, w: 100, h: 18, text: "randomly selected from 228 homes" }
    // over "100 orders"
  ];
  var HUD_LINKS = [
    { label: "Home", href: "/", x: 24, y: 108, w: 46, h: 18 }
  ];
  function drawHud(ctx2, shift2) {
    ctx2.textAlign = "left";
    ctx2.fillStyle = COLOR.text;
    ctx2.font = "bold 18px system-ui, sans-serif";
    ctx2.fillText("Seattle Delivery Network", 24, 34);
    ctx2.fillStyle = COLOR.note;
    ctx2.font = "italic 12px system-ui, sans-serif";
    ctx2.fillText("totally not to scale", 24, 53);
    ctx2.fillStyle = COLOR.text;
    ctx2.font = "bold 15px system-ui, sans-serif";
    ctx2.fillText(`Shift S${shift2}`, 24, 77);
    ctx2.font = "14px system-ui, sans-serif";
    ctx2.fillText(`${FLEET.orders} orders`, 24, 99);
    ctx2.fillStyle = COLOR.link;
    ctx2.font = "13px system-ui, sans-serif";
    for (const l of HUD_LINKS) {
      const baseline = l.y + 13;
      ctx2.fillText(l.label, l.x, baseline);
      ctx2.fillRect(l.x, baseline + 2, ctx2.measureText(l.label).width, 1);
    }
    ctx2.font = "13px system-ui, sans-serif";
    const hints = [
      { key: "", rest: "hover a neighborhood or a truck" },
      { key: "Space", rest: " \u2014 run the day" },
      { key: "A", rest: " \u2014 step the solve" },
      { key: "\u2190/\u2192", rest: " \u2014 step (paused)" },
      { key: "S", rest: " \u2014 new shift" },
      { key: "B", rest: " \u2014 back" }
    ];
    hints.forEach((h, i) => {
      const y = 24 + i * 19;
      ctx2.fillStyle = COLOR.text;
      if (h.key) {
        ctx2.font = "bold 13px system-ui, sans-serif";
        ctx2.fillText(h.key, PANEL_X, y);
        const kw = ctx2.measureText(h.key).width;
        ctx2.font = "13px system-ui, sans-serif";
        ctx2.fillText(h.rest, PANEL_X + kw, y);
      } else {
        ctx2.fillText(h.rest, PANEL_X, y);
      }
    });
  }
  function wrapText(ctx2, text, maxW) {
    const lines = [];
    let line = "";
    for (const word of text.split(" ")) {
      const trial = line ? `${line} ${word}` : word;
      if (line && ctx2.measureText(trial).width > maxW) {
        lines.push(line);
        line = word;
      } else {
        line = trial;
      }
    }
    if (line) lines.push(line);
    return lines;
  }
  function drawSolvePanel(ctx2, label, i, n) {
    const x = PANEL_X;
    ctx2.textAlign = "left";
    ctx2.fillStyle = COLOR.text;
    ctx2.font = "bold 14px system-ui, sans-serif";
    ctx2.fillText("Building the plan", x, PANEL_TOP);
    ctx2.fillStyle = COLOR.note;
    ctx2.font = "12px system-ui, sans-serif";
    ctx2.fillText(`step ${i + 1} of ${n}`, x, PANEL_TOP + 17);
    let y = PANEL_TOP + 48;
    ctx2.fillStyle = COLOR.text;
    ctx2.font = "bold 14px system-ui, sans-serif";
    for (const ln of wrapText(ctx2, label, PANEL_W)) {
      ctx2.fillText(ln, x, y);
      y += 19;
    }
    y += 14;
    ctx2.fillStyle = COLOR.note;
    ctx2.font = "12px system-ui, sans-serif";
    for (const ln of ["A / \u2192   next step", "\u2190   step back", "Esc   exit", "", "grey = truck not yet decided"]) {
      if (ln) ctx2.fillText(ln, x, y);
      y += 17;
    }
  }
  function drawSolveVeil(ctx2) {
    ctx2.fillStyle = "rgba(13, 27, 42, 0.5)";
    ctx2.fillRect(0, 0, MAP_W, MAP_H);
    ctx2.fillStyle = "#ffffff";
    ctx2.font = "bold 22px system-ui, sans-serif";
    ctx2.textAlign = "center";
    ctx2.fillText("shuffling\u2026", MAP_W / 2, MAP_H / 2);
  }
  function routeGeometry(route) {
    const waypoints = ["FC", ...route.stops.map((s) => s.nbhd), "FC"];
    const nodes = [];
    for (let i = 1; i < waypoints.length; i++) {
      const leg = SUB.path(waypoints[i - 1], waypoints[i]);
      for (const node of leg) if (nodes[nodes.length - 1] !== node) nodes.push(node);
    }
    const housesAt = /* @__PURE__ */ new Map();
    for (const s of route.stops) housesAt.set(s.nbhd, (housesAt.get(s.nbhd) ?? []).concat(s.houses));
    const pts = [];
    for (let i = 1; i < nodes.length; i++) {
      const prev = nodes[i - 1];
      const node = nodes[i];
      pts.push(...edgePolyline(prev, node));
      if (node !== "FC" && i < nodes.length - 1) {
        const next = nodes[i + 1];
        const entry = gateAngle(node, nodeAt(prev));
        const exit = gateAngle(node, nodeAt(next));
        pts.push(...ringWalkPath(node, entry, exit, houseAngles(node, housesAt.get(node) ?? [])));
      }
    }
    return pts;
  }
  function drawRoutes(ctx2, plan2, activeTruck) {
    ctx2.lineCap = "round";
    ctx2.lineJoin = "round";
    plan2.routes.forEach((route, i) => {
      if (activeTruck !== null && i !== activeTruck) return;
      const pts = routeGeometry(route);
      if (pts.length < 2) return;
      const emphasised = activeTruck === i;
      trace(ctx2, pts, false);
      ctx2.globalAlpha = 0.8;
      ctx2.lineWidth = emphasised ? 2.8 : 1.6;
      ctx2.strokeStyle = TRUCK_COLORS[i % TRUCK_COLORS.length];
      ctx2.stroke();
      ctx2.globalAlpha = 1;
    });
  }
  var DOCK_TIME = 8;
  function legEnd(leg) {
    return leg.kind === "drive" || leg.kind === "arc" ? leg.pts[leg.pts.length - 1] : leg.at;
  }
  function buildTracks(plan2) {
    const tracks = plan2.routes.map((r, i) => {
      const itin = buildItinerary(SUB, r);
      const full = [];
      const deliveries = [];
      let t = 0;
      for (const leg of itin.legs) {
        if (leg.kind === "drive" || leg.kind === "arc") for (const p of leg.pts) full.push(p);
        else if (leg.kind === "service") deliveries.push({ key: leg.house, t: t + leg.dur });
        t += leg.dur;
      }
      return { itin, full, deliveries, total: itin.total, depart: 0, color: TRUCK_COLORS[i % TRUCK_COLORS.length] };
    });
    const order = tracks.map((_, i) => i).sort((a, b) => tracks[b].total - tracks[a].total);
    order.forEach((ti, rank) => tracks[ti].depart = rank * DOCK_TIME);
    return tracks;
  }
  function deliveredAt(tracks, t) {
    const done = /* @__PURE__ */ new Set();
    for (const track of tracks) {
      const e = t - track.depart;
      for (const d of track.deliveries) if (e >= d.t) done.add(d.key);
    }
    return done;
  }
  function drawCheck(ctx2, cx, cy, s, color) {
    ctx2.beginPath();
    ctx2.moveTo(cx - s * 0.45, cy + s * 0.05);
    ctx2.lineTo(cx - s * 0.1, cy + s * 0.4);
    ctx2.lineTo(cx + s * 0.5, cy - s * 0.45);
    ctx2.lineCap = "round";
    ctx2.lineJoin = "round";
    ctx2.strokeStyle = "#ffffff";
    ctx2.lineWidth = s * 0.55;
    ctx2.stroke();
    ctx2.strokeStyle = color;
    ctx2.lineWidth = s * 0.34;
    ctx2.stroke();
  }
  function posAt(track, clock) {
    const e = clock - track.depart;
    const legs = track.itin.legs;
    if (e <= 0 || legs.length === 0) return { head: WAREHOUSE, prefix: [], active: false };
    if (e >= track.total) return { head: legEnd(legs[legs.length - 1]), prefix: track.full, active: false };
    const prefix = [];
    let head = WAREHOUSE;
    let acc = 0;
    for (const leg of legs) {
      const end = acc + leg.dur;
      if (leg.kind === "drive" || leg.kind === "arc") {
        if (e >= end) {
          for (const p of leg.pts) prefix.push(p);
          head = leg.pts[leg.pts.length - 1];
        } else {
          const f = leg.dur > 0 ? (e - acc) / leg.dur : 0;
          head = alongPoly(leg.pts, f, prefix);
          break;
        }
      } else {
        head = leg.at;
        if (e < end) {
          prefix.push(leg.at);
          break;
        }
        prefix.push(leg.at);
      }
      acc = end;
    }
    return { head, prefix, active: true };
  }
  function alongPoly(pts, f, out) {
    let total = 0;
    for (let i = 1; i < pts.length; i++) total += Math.hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y);
    const target = f * total;
    out.push(pts[0]);
    let acc = 0;
    for (let i = 1; i < pts.length; i++) {
      const d = Math.hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y);
      if (acc + d >= target) {
        const t = d > 0 ? (target - acc) / d : 0;
        const head = { x: pts[i - 1].x + (pts[i].x - pts[i - 1].x) * t, y: pts[i - 1].y + (pts[i].y - pts[i - 1].y) * t };
        out.push(head);
        return head;
      }
      out.push(pts[i]);
      acc += d;
    }
    return pts[pts.length - 1];
  }
  function drawAnimation(ctx2, tracks, t) {
    ctx2.lineCap = "round";
    ctx2.lineJoin = "round";
    for (const track of tracks) {
      if (track.full.length < 2) continue;
      trace(ctx2, track.full, false);
      ctx2.globalAlpha = 0.16;
      ctx2.lineWidth = 1.4;
      ctx2.strokeStyle = track.color;
      ctx2.stroke();
    }
    for (const track of tracks) {
      const { head, prefix, active } = posAt(track, t);
      if (prefix.length >= 2) {
        trace(ctx2, prefix, false);
        ctx2.globalAlpha = 0.85;
        ctx2.lineWidth = 2.4;
        ctx2.strokeStyle = track.color;
        ctx2.stroke();
      }
      ctx2.globalAlpha = active ? 1 : 0.55;
      ctx2.beginPath();
      ctx2.arc(head.x, head.y, active ? 6 : 4.5, 0, Math.PI * 2);
      ctx2.fillStyle = track.color;
      ctx2.fill();
      ctx2.lineWidth = 2;
      ctx2.strokeStyle = "#ffffff";
      ctx2.stroke();
    }
    ctx2.globalAlpha = 1;
  }
  var PROG_CELL = 3;
  function drawProgress(ctx2, tracks, t) {
    const events = [];
    for (const tr of tracks) for (const d of tr.deliveries) events.push({ t: tr.depart + d.t, color: tr.color });
    events.sort((a, b) => a.t - b.t);
    const total = events.length;
    let done = 0;
    for (const e of events) if (t >= e.t) done++;
    const x0 = 24;
    const y0 = 699;
    for (let i = 0; i < total; i++) {
      ctx2.fillStyle = i < done ? events[i].color : "rgba(20, 26, 34, 0.10)";
      ctx2.fillRect(x0 + i * PROG_CELL, y0, PROG_CELL, PROG_CELL);
    }
    ctx2.textAlign = "left";
    ctx2.fillStyle = COLOR.text;
    ctx2.font = "bold 12px system-ui, sans-serif";
    ctx2.fillText(`delivered ${done} / ${total}`, x0 + total * PROG_CELL + 8, y0 + PROG_CELL);
  }
  function drawClock(ctx2, t, maxT, playing) {
    const done = t >= maxT;
    ctx2.textAlign = "left";
    ctx2.fillStyle = COLOR.text;
    ctx2.font = "bold 15px system-ui, sans-serif";
    const badge = done ? "\u2713 day complete" : playing ? "\u25B6 running the day" : "\u23F8 paused";
    ctx2.fillText(`${badge}  \xB7  ${Math.round(Math.min(t, maxT))} / ${Math.round(maxT)} min`, 24, 690);
  }
  function drawTruckPanel(ctx2, plan2, activeTruck) {
    const deployed = plan2.routes.filter((r) => r.stops.length > 0).length;
    ctx2.textAlign = "left";
    ctx2.fillStyle = COLOR.text;
    ctx2.font = "bold 14px system-ui, sans-serif";
    ctx2.fillText(`Plan \u2014 ${deployed} of ${FLEET.trucks} trucks out`, PANEL_X, PANEL_TOP);
    ctx2.fillStyle = COLOR.note;
    ctx2.font = "12px system-ui, sans-serif";
    ctx2.fillText(`${Math.round(plan2.totalTime)} driver-min  \xB7  spread ${Math.round(plan2.spread)} min`, PANEL_X, PANEL_TOP + 17);
    plan2.routes.forEach((route, i) => {
      const y = PANEL_ROW0 + i * PANEL_ROW_H;
      const lit = activeTruck === i;
      const idle = route.stops.length === 0;
      if (lit) {
        ctx2.fillStyle = "rgba(20, 26, 34, 0.06)";
        ctx2.fillRect(PANEL_X - 4, y - 13, PANEL_W + 8, PANEL_ROW_H);
      }
      ctx2.globalAlpha = idle ? 0.4 : 1;
      ctx2.strokeStyle = TRUCK_COLORS[i % TRUCK_COLORS.length];
      ctx2.lineWidth = lit ? 5 : 3;
      ctx2.beginPath();
      ctx2.moveTo(PANEL_X, y - 4);
      ctx2.lineTo(PANEL_X + 18, y - 4);
      ctx2.stroke();
      ctx2.globalAlpha = 1;
      ctx2.fillStyle = idle ? COLOR.faint : lit ? COLOR.text : COLOR.note;
      ctx2.font = `${lit && !idle ? "bold " : ""}12px system-ui, sans-serif`;
      ctx2.fillText(
        idle ? `Truck ${i + 1}: idle \u2014 stayed home` : `Truck ${i + 1}: ${route.orders}/${TRUCK_CAPS[i]} totes \xB7 ${Math.round(route.time)}m \xB7 ${route.stops.length} stops`,
        PANEL_X + 26,
        y
      );
    });
    if (plan2.unrouted.length) {
      ctx2.fillStyle = "#c0392b";
      ctx2.font = "bold 12px system-ui, sans-serif";
      ctx2.fillText(`\u26A0 ${plan2.unrouted.length} stops unrouted`, PANEL_X, PANEL_ROW0 + plan2.routes.length * PANEL_ROW_H + 2);
    }
  }
  function truckPanelHitTest(plan2, p) {
    for (let i = 0; i < plan2.routes.length; i++) {
      const y = PANEL_ROW0 + i * PANEL_ROW_H;
      if (p.x >= PANEL_X - 4 && p.x <= PANEL_X + PANEL_W + 4 && p.y >= y - 13 && p.y <= y + PANEL_ROW_H - 13) return i;
    }
    return null;
  }
  var COLOR_PENDING = "#9aa0a8";
  function frameColorMaps(frame) {
    const houseColor = /* @__PURE__ */ new Map();
    for (const r of frame.routes) {
      const pin = r.stops.find((s) => s.pin !== void 0)?.pin;
      const c = pin !== void 0 ? TRUCK_COLORS[pin % TRUCK_COLORS.length] : COLOR_PENDING;
      for (const s of r.stops) for (const h of s.houses) houseColor.set(`${s.nbhd}#${h}`, c);
    }
    return houseColor;
  }
  function truckColorMaps(plan2) {
    const houseColor = /* @__PURE__ */ new Map();
    const houseTruck = /* @__PURE__ */ new Map();
    plan2.routes.forEach((r, i) => {
      const c = TRUCK_COLORS[i % TRUCK_COLORS.length];
      for (const s of r.stops) for (const h of s.houses) {
        houseColor.set(`${s.nbhd}#${h}`, c);
        houseTruck.set(`${s.nbhd}#${h}`, i);
      }
    });
    return { houseColor, houseTruck };
  }
  function focusOf(plan2, houseTruck, hoverNbhd2, hoverHouse2, focusTruck2) {
    let activeTruck = focusTruck2;
    if (activeTruck === null && hoverHouse2 !== null && houseTruck.has(hoverHouse2)) {
      activeTruck = houseTruck.get(hoverHouse2);
    }
    if (activeTruck === null && hoverNbhd2 !== null) {
      const serving = plan2.routes.findIndex((r) => r.stops.some((s) => s.nbhd === hoverNbhd2));
      if (serving >= 0) activeTruck = serving;
    }
    let highlight = null;
    if (activeTruck !== null && plan2.routes[activeTruck]) {
      highlight = /* @__PURE__ */ new Set();
      for (const s of plan2.routes[activeTruck].stops) for (const i of s.houses) highlight.add(`${s.nbhd}#${i}`);
    }
    return { activeTruck, highlight };
  }
  function drawMap(ctx2, view) {
    const { orders: orders2, plan: plan2, hoverNbhd: hoverNbhd2, hoverHouse: hoverHouse2, focusTruck: focusTruck2, shift: shift2, solving: solving2, anim: anim2, solveAnim: solveAnim2 } = view;
    if (solveAnim2) {
      const frame = solveAnim2.frames[solveAnim2.i];
      const isFinal = solveAnim2.i === solveAnim2.frames.length - 1;
      const houseColor2 = isFinal ? truckColorMaps(frame).houseColor : frameColorMaps(frame);
      const popped = frame.touched.length ? new Set(frame.touched) : null;
      drawLand(ctx2);
      drawWater(ctx2);
      drawRegionLabels(ctx2);
      drawRoads(ctx2);
      drawBridges(ctx2);
      drawGates(ctx2);
      for (const n of NEIGHBORHOODS) drawNeighborhood(ctx2, n, orders2, houseColor2, null, null, popped);
      drawWarehouse(ctx2);
      drawHud(ctx2, shift2);
      drawSolvePanel(ctx2, frame.label, solveAnim2.i, solveAnim2.frames.length);
      return;
    }
    if (anim2) {
      const { houseColor: houseColor2, houseTruck: houseTruck2 } = truckColorMaps(plan2);
      const paused = !anim2.playing;
      const { activeTruck: activeTruck2, highlight: highlight2 } = paused ? focusOf(plan2, houseTruck2, hoverNbhd2, hoverHouse2, focusTruck2) : { activeTruck: null, highlight: null };
      drawLand(ctx2);
      drawWater(ctx2);
      drawRegionLabels(ctx2);
      drawRoads(ctx2);
      drawBridges(ctx2);
      drawGates(ctx2);
      const delivered = anim2.blink ? null : deliveredAt(anim2.tracks, anim2.t);
      for (const n of NEIGHBORHOODS) drawNeighborhood(ctx2, n, orders2, houseColor2, highlight2, delivered);
      drawWarehouse(ctx2);
      if (!anim2.blink) drawAnimation(ctx2, anim2.tracks, anim2.t);
      if (activeTruck2 !== null) drawRoutes(ctx2, plan2, activeTruck2);
      drawHud(ctx2, shift2);
      drawTruckPanel(ctx2, plan2, activeTruck2);
      drawClock(ctx2, anim2.t, anim2.maxT, anim2.playing);
      drawProgress(ctx2, anim2.tracks, anim2.t);
      if (paused) drawDetail(ctx2, plan2, orders2, hoverNbhd2, activeTruck2);
      return;
    }
    const { houseColor, houseTruck } = truckColorMaps(plan2);
    const { activeTruck, highlight } = focusOf(plan2, houseTruck, hoverNbhd2, hoverHouse2, focusTruck2);
    drawLand(ctx2);
    drawWater(ctx2);
    drawRegionLabels(ctx2);
    drawRoads(ctx2);
    drawBridges(ctx2);
    drawGates(ctx2);
    for (const n of NEIGHBORHOODS) drawNeighborhood(ctx2, n, orders2, houseColor, highlight, null);
    drawWarehouse(ctx2);
    drawRoutes(ctx2, plan2, activeTruck);
    drawHud(ctx2, shift2);
    drawTruckPanel(ctx2, plan2, activeTruck);
    drawDetail(ctx2, plan2, orders2, hoverNbhd2, activeTruck);
    if (solving2) drawSolveVeil(ctx2);
  }

  // main.ts
  var solverWasm;
  function solveShift(s) {
    const len3 = solverWasm.solveShift(s) >>> 0;
    const bytes = new Uint8Array(solverWasm.memory.buffer, solverWasm.outPtr(), len3);
    return JSON.parse(new TextDecoder().decode(bytes));
  }
  var PAGE_BG = "#0d1b2a";
  var canvas = document.createElement("canvas");
  document.body.appendChild(canvas);
  var ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("2d canvas context unavailable");
  var scale = 1;
  var offX = 0;
  var offY = 0;
  var hoverNbhd = null;
  var hoverHouse = null;
  var focusTruck = null;
  var seed = 49;
  var shift = 1;
  var solving = false;
  var orders = chooseOrders(seed, FLEET.orders);
  var plan = null;
  var PLAY_RATE = 5;
  var STEP_MIN = 2;
  var BLINK_MS = 130;
  var anim = null;
  var lastFrame = 0;
  var solveAnim = null;
  function stopSolveAnim() {
    solveAnim = null;
  }
  function stepSolveAnim() {
    if (!plan) return;
    if (!solveAnim) {
      anim = null;
      solveAnim = { frames: plan.frames, i: 0 };
    } else {
      solveAnim.i = Math.min(solveAnim.frames.length - 1, solveAnim.i + 1);
    }
    render();
  }
  function shuffle() {
    if (solving || !plan) return;
    solving = true;
    anim = null;
    stopSolveAnim();
    render();
    setTimeout(() => {
      seed = seed * 1664525 + 1013904223 >>> 0;
      orders = chooseOrders(seed, FLEET.orders);
      plan = solveShift(seed);
      shift++;
      focusTruck = null;
      hoverNbhd = null;
      hoverHouse = null;
      solving = false;
      render();
    }, 30);
  }
  function render() {
    if (!plan) return;
    const dpr = window.devicePixelRatio || 1;
    const vw = window.innerWidth;
    const vh = window.innerHeight;
    canvas.width = Math.round(vw * dpr);
    canvas.height = Math.round(vh * dpr);
    canvas.style.width = vw + "px";
    canvas.style.height = vh + "px";
    scale = Math.min(vw / MAP_W, vh / MAP_H);
    offX = (vw - MAP_W * scale) / 2;
    offY = (vh - MAP_H * scale) / 2;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.fillStyle = PAGE_BG;
    ctx.fillRect(0, 0, vw, vh);
    ctx.setTransform(scale * dpr, 0, 0, scale * dpr, offX * dpr, offY * dpr);
    drawMap(ctx, { orders, plan, hoverNbhd, hoverHouse, focusTruck, shift, solving, anim, solveAnim });
  }
  function tick(now) {
    if (!anim || !anim.playing) return;
    const dt = lastFrame ? (now - lastFrame) / 1e3 : 0;
    lastFrame = now;
    anim.t = Math.min(anim.t + dt * PLAY_RATE, anim.maxT);
    if (!anim.blinked && anim.blinkAt > 0 && anim.t >= anim.blinkAt) {
      anim.blinked = true;
      anim.blink = true;
      render();
      anim.blink = false;
      setTimeout(() => {
        if (anim && anim.playing) {
          lastFrame = 0;
          requestAnimationFrame(tick);
        }
      }, BLINK_MS);
      return;
    }
    if (anim.t >= anim.maxT) anim.playing = false;
    render();
    if (anim.playing) requestAnimationFrame(tick);
  }
  function togglePlay() {
    if (!plan) return;
    stopSolveAnim();
    if (!anim) {
      const tracks = buildTracks(plan);
      const maxT = tracks.reduce((m, t) => Math.max(m, t.depart + t.total), 0);
      const blinkAt = tracks.reduce((m, t) => t.deliveries.reduce((mm, d) => Math.max(mm, t.depart + d.t), m), 0);
      anim = { t: 0, maxT, playing: true, tracks, blink: false, blinkAt, blinked: false };
    } else if (anim.playing) {
      anim.playing = false;
    } else {
      if (anim.t >= anim.maxT) {
        anim.t = 0;
        anim.blinked = false;
      }
      anim.playing = true;
    }
    if (anim.playing) {
      lastFrame = 0;
      requestAnimationFrame(tick);
    } else {
      render();
    }
  }
  function hitTest(p) {
    let nbhd = null;
    let bestD = Infinity;
    for (const n2 of NEIGHBORHOODS) {
      const d = Math.hypot(p.x - n2.center.x, p.y - n2.center.y);
      if (d <= n2.ringRadius + 18 && d < bestD) {
        bestD = d;
        nbhd = n2.name;
      }
    }
    if (nbhd === null) return { nbhd: null, house: null };
    const n = NEIGHBORHOODS.find((m) => m.name === nbhd);
    let house = null;
    let bestH = Infinity;
    housesOf(n).forEach((h, i) => {
      const key = `${nbhd}#${i}`;
      if (!orders.has(key)) return;
      const d = Math.hypot(p.x - h.x, p.y - h.y);
      if (d < bestH) {
        bestH = d;
        house = key;
      }
    });
    return { nbhd, house };
  }
  var hitLink = (p) => HUD_LINKS.find((l) => p.x >= l.x && p.x <= l.x + l.w && p.y >= l.y && p.y <= l.y + l.h) ?? null;
  canvas.addEventListener("mousemove", (e) => {
    if (!plan) return;
    const p = { x: (e.clientX - offX) / scale, y: (e.clientY - offY) / scale };
    const tip = HUD_TOOLTIPS.find((r) => p.x >= r.x && p.x <= r.x + r.w && p.y >= r.y && p.y <= r.y + r.h);
    canvas.title = tip ? tip.text : "";
    const overLink = hitLink(p) !== null;
    if (solveAnim || anim && anim.playing) {
      canvas.style.cursor = overLink ? "pointer" : "default";
      return;
    }
    const truck = truckPanelHitTest(plan, p);
    const hit = truck === null ? hitTest(p) : { nbhd: null, house: null };
    if (truck !== focusTruck || hit.nbhd !== hoverNbhd || hit.house !== hoverHouse) {
      focusTruck = truck;
      hoverNbhd = hit.nbhd;
      hoverHouse = hit.house;
      render();
    }
    canvas.style.cursor = truck !== null || hit.nbhd || overLink ? "pointer" : "default";
  });
  canvas.addEventListener("click", (e) => {
    const p = { x: (e.clientX - offX) / scale, y: (e.clientY - offY) / scale };
    const lk = hitLink(p);
    if (lk) window.location.href = lk.href;
  });
  window.addEventListener("keydown", (e) => {
    if (e.key === " " || e.code === "Space") {
      e.preventDefault();
      togglePlay();
    } else if (e.key === "s" || e.key === "S") {
      shuffle();
    } else if (e.key === "a" || e.key === "A") {
      e.preventDefault();
      stepSolveAnim();
    } else if (e.key === "ArrowLeft" || e.key === "ArrowRight") {
      const dir = e.key === "ArrowRight" ? 1 : -1;
      if (solveAnim) {
        e.preventDefault();
        solveAnim.i = Math.max(0, Math.min(solveAnim.frames.length - 1, solveAnim.i + dir));
        render();
        return;
      }
      if (!anim) return;
      e.preventDefault();
      anim.playing = false;
      anim.t = Math.max(0, Math.min(anim.maxT, anim.t + dir * STEP_MIN));
      render();
    } else if (e.key === "b" || e.key === "B" || e.key === "Escape") {
      if (solveAnim) {
        stopSolveAnim();
        render();
      } else if (anim) {
        anim = null;
        render();
      }
    }
  });
  async function boot() {
    const resp = await fetch("solver.wasm");
    const { instance } = await WebAssembly.instantiate(await resp.arrayBuffer(), {});
    solverWasm = instance.exports;
    plan = solveShift(seed);
    render();
  }
  window.addEventListener("resize", render);
  boot();
})();

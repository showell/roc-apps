// Fast Track's page end: it runs the wasm and draws what Roc says.
//
// Roc answers the whole page as data (web/platform/Wire.roc), and this knows
// nothing about Fast Track. It does two things:
//
//   - **the board is patched.** Its slots come in the same order every time,
//     so the SVG is built once and afterwards only the attributes that
//     changed are set;
//   - **the rest is replaced.** The page's nodes -- a few buttons and lines
//     -- are rebuilt on every click, with the board's SVG moved into the
//     node whose tag is "board".
//
// A click sends back the code Roc gave the thing clicked; nothing here builds
// a message. When the computer is playing, the view names a `tick` code, and
// the page sends it back by itself after a pause -- one computer click per
// tick, so a person can watch.
//
// A plain script (the page loads it with <script src>), defining `FastTrack`.
// page_check.mjs runs the same file against a stand-in document.
const FastTrack = (() => {
  const SVG = "http://www.w3.org/2000/svg";

  // One game in one wasm instance.
  function game(instance) {
    const ex = instance.exports;
    return {
      start: (millis, setup, seats, teams = 0) => ex.start(millis, setup, seats, teams),
      click: (code) => ex.update(code),
      tune: (seat, factor, value) => ex.tune(seat, factor, value),
      // **computeView FIRST, THEN THE DataView.** Building a view can grow
      // wasm memory, which detaches every view of the old buffer.
      view: () => {
        const at = ex.computeView();
        return RocGlue.view(new DataView(ex.memory.buffer), at);
      },
    };
  }

  function board(document) {
    const svg = document.createElementNS(SVG, "svg");
    let entries = [];
    let size = null;

    function build(slots, onClick) {
      svg.replaceChildren();
      entries = slots.map((s) => {
        const g = document.createElementNS(SVG, "g");
        const shape = document.createElementNS(SVG, s.square ? "rect" : "circle");
        const piece = document.createElementNS(SVG, "circle");
        // A square's label sits over its piece, outlined in white so either
        // shows through; its hint is the square's hover text.
        const label = document.createElementNS(SVG, "text");
        const hint = document.createElementNS(SVG, "title");
        label.setAttribute("text-anchor", "middle");
        label.setAttribute("font-size", "11");
        label.setAttribute("font-weight", "bold");
        label.setAttribute("stroke", "white");
        label.setAttribute("stroke-width", "3");
        label.setAttribute("paint-order", "stroke");
        label.setAttribute("pointer-events", "none");
        g.appendChild(shape);
        g.appendChild(piece);
        g.appendChild(label);
        g.appendChild(hint);
        svg.appendChild(g);
        const entry = { g, shape, piece, label, hint, last: null, code: 0 };
        g.addEventListener("click", () => { if (entry.code) onClick(entry.code); });
        return entry;
      });
    }

    function set(el, name, value) {
      el.setAttribute(name, String(value));
    }

    // Only what differs from the last slot at this place is written.
    function patch(view, onClick) {
      if (view.board_size !== size) {
        size = view.board_size;
        set(svg, "width", size);
        set(svg, "height", size);
      }
      const slots = view.slots;
      if (entries.length !== slots.length || slots.some((s, i) => entries[i].last && entries[i].last.square !== s.square)) {
        build(slots, onClick);
      }
      slots.forEach((s, i) => {
        const e = entries[i];
        const old = e.last || {};
        if (old.cx !== s.cx || old.cy !== s.cy || old.size !== s.size) {
          if (s.square) {
            set(e.shape, "x", s.cx - s.size / 2);
            set(e.shape, "y", s.cy - s.size / 2);
            set(e.shape, "width", s.size);
            set(e.shape, "height", s.size);
            set(e.shape, "rx", 2);
          } else {
            set(e.shape, "cx", s.cx);
            set(e.shape, "cy", s.cy);
            set(e.shape, "r", s.size / 2);
          }
          set(e.piece, "cx", s.cx);
          set(e.piece, "cy", s.cy);
          set(e.label, "x", s.cx);
          set(e.label, "y", s.cy + 4);
        }
        if (old.label !== s.label) e.label.textContent = s.label;
        if (old.hint !== s.hint) e.hint.textContent = s.hint;
        if (old.fill !== s.fill) set(e.shape, "fill", s.fill);
        if (old.stroke !== s.stroke) set(e.shape, "stroke", s.stroke);
        if (old.piece !== s.piece) {
          set(e.piece, "visibility", s.piece === "" ? "hidden" : "visible");
          if (s.piece !== "") {
            set(e.piece, "fill", s.piece);
            set(e.piece, "stroke", s.piece);
          }
        }
        if (old.piece_r !== s.piece_r) set(e.piece, "r", s.piece_r);
        if (old.click !== s.click) set(e.g, "cursor", s.click ? "pointer" : "default");
        e.code = s.click;
        e.last = s;
      });
    }

    return { svg, patch };
  }

  // The page, rebuilt: each node lands in its parent, which came before it.
  function render(document, root, nodes, boardSvg, onClick) {
    const els = [];
    root.replaceChildren();
    for (const n of nodes) {
      let el;
      if (n.tag === "") {
        el = document.createTextNode(n.text);
      } else if (n.tag === "board") {
        el = boardSvg;
      } else {
        el = document.createElement(n.tag);
        if (n.style) el.style.cssText = n.style;
        if (n.disabled) el.disabled = true;
        if (n.click) el.addEventListener("click", () => onClick(n.click));
      }
      (n.parent === 0 ? root : els[n.parent - 1]).appendChild(el);
      els.push(el);
    }
  }

  // Wires a game to a document: draw, and redraw after every click. A view
  // that names a tick hands it to `schedule`, which sends it later; the
  // browser passes a timer, a check passes nothing and sends it itself.
  function mount(document, root, g, schedule) {
    const b = board(document);
    const draw = () => {
      const view = g.view();
      b.patch(view, onClick);
      render(document, root, view.nodes, b.svg, onClick);
      if (view.tick && schedule) schedule(() => onClick(view.tick));
      return view;
    };
    const onClick = (code) => {
      g.click(code);
      draw();
    };
    return { draw, onClick };
  }

  // `?seats=hccc`: who plays each color, in the game's order (red, blue,
  // green, purple) -- h a person, c the computer, n the naive player that
  // takes the first choice it is offered. Two bits a seat, as
  // FastTrack.seats_of reads them.
  function seatBits(text) {
    const codes = { h: 0, c: 1, n: 2 };
    return [...text].slice(0, 4).reduce((bits, ch, i) => bits | ((codes[ch] ?? 0) << (2 * i)), 0);
  }

  // `?teams=`: none (each for itself), `anytime` (partners, red with green
  // and blue with purple, may move each other's pieces whenever), or
  // `oncehome` (only once their own are all home).
  function teamStyle(text) {
    return { anytime: 1, oncehome: 2 }[text] ?? 0;
  }

  return { game, board, render, mount, seatBits, teamStyle };
})();

// In a browser: `?seed=` replays a deal, `?setup=` starts from one of
// Setup.roc's scenarios by number, `?seats=` (default hccc: you are red)
// says who plays, `?teams=anytime|oncehome` seats partnerships, `?show=cards`
// puts the fewest cards home on every square (`?show=face` with a free face
// card, `?show=b3` to B3, `?show=heat` the ranking's heat map), and `?pause=` is the
// computer's pause per click in ms.
if (typeof window !== "undefined" && window.document && window.FASTTRACK_WASM) {
  (async () => {
    const root = document.getElementById("game");
    const { instance } = await WebAssembly.instantiateStreaming(fetch(window.FASTTRACK_WASM), {});
    const g = FastTrack.game(instance);
    const params = new URLSearchParams(location.search);
    g.start(
      Number(params.get("seed") ?? Date.now()),
      Number(params.get("setup") ?? 0),
      FastTrack.seatBits(params.get("seats") ?? "hccc"),
      FastTrack.teamStyle(params.get("teams") ?? ""),
    );
    const pause = Number(params.get("pause") ?? 350);
    let pending = null;
    const schedule = (send) => {
      clearTimeout(pending);
      pending = setTimeout(send, pause);
    };
    const page = FastTrack.mount(document, root, g, schedule);
    // `?show=cards` opens with the fewest cards to B4 on every square,
    // `?show=face` with them counted with a free face card, `?show=b3` the
    // same to B3, as once B4 is taken, and `?show=heat` the heat map of the
    // ranking (Codes.toggle_overlay steps through FastTrack.overlay_variants).
    const steps = { cards: 1, face: 2, b3: 3, heat: 4 }[params.get("show")] ?? 0;
    if (steps === 0) page.draw();
    for (let i = 0; i < steps; i++) page.onClick(4);
  })();
}

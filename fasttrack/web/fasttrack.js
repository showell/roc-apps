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
// tick, so a person can watch. A view's `motions` (what the last click moved)
// are walked square by square before the next tick: the board is drawn as red
// sees it, so a motion's squares are slot numbers.
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
    const labels = document.createElementNS(SVG, "g");
    let entries = [];
    let size = null;

    function build(slots, onClick) {
      svg.replaceChildren();
      entries = slots.map((s) => {
        const g = document.createElementNS(SVG, "g");
        const shape = document.createElementNS(SVG, s.square ? "rect" : "circle");
        const piece = document.createElementNS(SVG, "circle");
        g.appendChild(shape);
        g.appendChild(piece);
        svg.appendChild(g);
        const entry = { g, shape, piece, last: null, code: 0 };
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
        }
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
      // A few words on the board, redrawn every time, above the squares.
      if (labels.parentNode !== svg) svg.appendChild(labels);
      labels.replaceChildren();
      for (const l of view.labels) {
        const t = document.createElementNS(SVG, "text");
        set(t, "x", l.x);
        set(t, "y", l.y);
        set(t, "text-anchor", "middle");
        set(t, "font-size", 11);
        set(t, "fill", l.fill);
        t.appendChild(document.createTextNode(l.text));
        labels.appendChild(t);
      }
    }

    // A piece hidden while a marble walks to it, and shown when it lands.
    const hide = (i) => entries[i] && set(entries[i].piece, "visibility", "hidden");
    const show = (i) => entries[i] && entries[i].last && set(entries[i].piece, "visibility", entries[i].last.piece === "" ? "hidden" : "visible");

    return { svg, patch, hide, show };
  }

  // Walks each motion's marble across the board, one square every `step`
  // ms, one motion after another, then calls `done`. The board already shows
  // where everything ends; each motion's last square stays hidden until its
  // marble arrives. A piece that is hit (or traded) waits on its square
  // until the mover lands; one sent home then bursts and appears in its pen.
  function animator(document, step) {
    return (b, view, done) => {
      const slots = view.slots;
      const put = (c, i) => {
        c.setAttribute("cx", String(slots[i].cx));
        c.setAttribute("cy", String(slots[i].cy));
      };
      const marble = (color, i) => {
        const c = document.createElementNS(SVG, "circle");
        c.setAttribute("r", "6");
        c.setAttribute("fill", color);
        c.setAttribute("stroke", "black");
        put(c, i);
        b.svg.appendChild(c);
        return c;
      };
      // A ring that grows from r0 to r1 on slot i, `frames` frames `ms` apart.
      const ring = (i, color, r0, r1, frames, ms, each, then) => {
        const c = document.createElementNS(SVG, "circle");
        c.setAttribute("fill", "none");
        c.setAttribute("stroke", color);
        c.setAttribute("stroke-width", "3");
        put(c, i);
        b.svg.appendChild(c);
        let f = 0;
        const frame = () => {
          const t = f / frames;
          c.setAttribute("r", String(r0 + (r1 - r0) * t));
          c.setAttribute("opacity", String(1 - t));
          each(t);
          f += 1;
          if (f <= frames) {
            setTimeout(frame, ms);
          } else {
            c.remove();
            then();
          }
        };
        frame();
      };
      const walk = (c, path, then) => {
        let j = 1;
        const hop = () => {
          if (j < path.length) {
            put(c, path[j]);
            j += 1;
            setTimeout(hop, step);
          } else {
            then();
          }
        };
        setTimeout(hop, step);
      };
      view.motions.forEach((m) => b.hide(m.path[m.path.length - 1]));
      const waiting = view.motions.map((m, k) => (k > 0 ? marble(m.color, m.path[0]) : null));
      let k = 0;
      const next = () => {
        if (k >= view.motions.length) return done();
        const m = view.motions[k];
        const own = waiting[k] || marble(m.color, m.path[0]);
        k += 1;
        const last = m.path[m.path.length - 1];
        if (m.sent_home) {
          // The collision: a burst where it stood while it shrinks away,
          // then it appears in its pen with a small flash.
          ring(m.path[0], "orange", 6, 20, 8, 45, (t) => own.setAttribute("r", String(6 * (1 - t))), () => {
            own.remove();
            b.show(last);
            ring(last, m.color, 4, 12, 5, 40, () => {}, next);
          });
        } else {
          walk(own, m.path, () => {
            own.remove();
            b.show(last);
            next();
          });
        }
      };
      next();
    };
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
  // that names a tick hands it to `schedule`, which sends it later, once any
  // `animate` of its motions is done; the browser passes a timer and an
  // animator, a check passes neither and sends the tick itself.
  function mount(document, root, g, schedule, animate) {
    const b = board(document);
    let lastMotion = 0;
    const draw = () => {
      const view = g.view();
      b.patch(view, onClick);
      render(document, root, view.nodes, b.svg, onClick);
      const tick = () => { if (view.tick && schedule) schedule(() => onClick(view.tick)); };
      if (animate && view.motion_id !== lastMotion && view.motions.length > 0) {
        lastMotion = view.motion_id;
        animate(b, view, tick);
      } else {
        tick();
      }
      return view;
    };
    const onClick = (code) => {
      g.click(code);
      draw();
    };
    return { draw, onClick };
  }

  // Who plays each color, as the checks' SEATS spell it: in the game's order (red, blue,
  // green, purple) -- h a person, c the computer. Two bits a seat, as
  // FastTrack.seats_of reads them.
  function seatBits(text) {
    const codes = { h: 0, c: 1 };
    return [...text].slice(0, 4).reduce((bits, ch, i) => bits | ((codes[ch] ?? 0) << (2 * i)), 0);
  }

  // `?teams=`: none (each for itself), `anytime` (partners, red with green
  // and blue with purple, may move each other's pieces whenever), or
  // `oncehome` (only once their own are all home).
  function teamStyle(text) {
    return { anytime: 1, oncehome: 2 }[text] ?? 0;
  }

  return { game, board, render, mount, animator, seatBits, teamStyle };
})();

// In a browser there is one way to play: you are red, and the computer plays
// blue, green and purple, each for itself. `?seed=` replays a deal, `?setup=`
// starts from one of Setup.roc's scenarios by number, `?pause=` is the
// computer's pause per click in ms (default 1050), and `?step=` a marble's
// time per square in ms (default 150). The checks start other seatings
// (seatBits, teamStyle).
if (typeof window !== "undefined" && window.document && window.FASTTRACK_WASM) {
  (async () => {
    const root = document.getElementById("game");
    const { instance } = await WebAssembly.instantiateStreaming(fetch(window.FASTTRACK_WASM), {});
    const g = FastTrack.game(instance);
    const params = new URLSearchParams(location.search);
    g.start(
      Number(params.get("seed") ?? Date.now()),
      Number(params.get("setup") ?? 0),
      FastTrack.seatBits("hccc"),
      FastTrack.teamStyle(""),
    );
    const pause = Number(params.get("pause") ?? 1050);
    const step = Number(params.get("step") ?? 150);
    let pending = null;
    const schedule = (send) => {
      clearTimeout(pending);
      pending = setTimeout(send, pause);
    };
    FastTrack.mount(document, root, g, schedule, FastTrack.animator(document, step)).draw();
  })();
}

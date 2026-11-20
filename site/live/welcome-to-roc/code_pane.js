// code_pane.js — the Lanterns page's code pane: on a screen wide enough, a
// pane beside the scene that shows the Roc module behind what is happening,
// coloured, scrolling slowly down through it, credits-style, while it is on
// screen. On a narrower screen the page is the canvas alone, as before.
//
// The Roc decides what the pane shows (screensavers/lanterns/CodePane.roc and
// CodeCues.roc): after the first model and after every step the page asks the
// wasm's computeCode, and the answer, read through the glue, is
// `{ tag: 'ModuleSource', value: html }`, a module's code as coloured and
// escaped HTML, or `{ tag: 'KeepCurrentCode' }`. A new module starts at its
// top. canvas_app_runner.js calls `heard` and `shown` (its `pane`).

const LanternsCodePane = (() => {
  // The narrowest window, in CSS pixels, that gets the pane.
  const WIDE_PX = 1100;
  // How long a new module holds still at its top, and how fast it then
  // scrolls, in CSS pixels a second.
  const HOLD_MS = 1500;
  const SCROLL_PX_A_SECOND = 24;

  const STYLE = `
    #code-stage { display: contents; }
    #code-pane { display: none; }
    @media (min-width: ${WIDE_PX}px) {
      #code-stage {
        --pane-width: clamp(360px, 32vw, 600px);
        display: flex; flex-direction: row; align-items: stretch; gap: 18px;
        max-width: 100vw; padding: 0 16px; box-sizing: border-box;
      }
      #code-stage canvas {
        max-width: calc(100vw - var(--pane-width) - 50px) !important;
        max-height: 88vh !important;
      }
      #code-pane {
        display: block; position: relative; overflow: hidden; flex: none;
        width: var(--pane-width); border-radius: 6px; background: #0e1220;
        border: 1px solid #1b2340;
        -webkit-mask-image: linear-gradient(transparent 0, #000 18px, #000 calc(100% - 40px), transparent 100%);
        mask-image: linear-gradient(transparent 0, #000 18px, #000 calc(100% - 40px), transparent 100%);
      }
      #code-pane pre {
        position: absolute; left: 0; right: 0; top: 0; margin: 0; padding: 16px 14px 48px;
        font: 12px/1.5 ui-monospace, Menlo, Consolas, monospace; color: #c9cee0;
        white-space: pre; tab-size: 2; will-change: transform;
      }
      #code-pane .syn-keyword { color: #c792ea; }
      #code-pane .syn-type { color: #82aaff; }
      #code-pane .syn-string { color: #c3e88d; }
      #code-pane .syn-number { color: #f78c6c; }
      #code-pane .syn-comment { color: #8a8494; font-style: italic; }
      #code-pane .syn-name { color: #ffcb6b; }
    }`;

  const wide = window.matchMedia(`(min-width: ${WIDE_PX}px)`);
  // The code the Roc last sent, and when it came in; the pane, once shown.
  let html = null;
  let since = 0;
  let pre = null;
  let pane = null;
  let painted = null;

  const heard = (game) => {
    const at = game.computeCode();
    // The view is made after the call, as the runner's frame view is: the
    // call can grow the wasm's memory, which detaches an older view.
    const code = RocGlue.code(new DataView(game.memory.buffer), at);
    if (code.tag === 'ModuleSource') {
      html = code.value;
      since = performance.now();
    } else if (code.tag !== 'KeepCurrentCode') {
      throw new Error(`code_pane: no such answer as ${code.tag}`);
    }
  };

  // Each animation frame puts the latest module in the pane and scrolls it:
  // still for HOLD_MS, then down at SCROLL_PX_A_SECOND until its end is in
  // view, where it stays.
  const scroll = (now) => {
    if (html !== painted) {
      pre.innerHTML = html;
      painted = html;
    }
    if (wide.matches) {
      const room = pre.scrollHeight - pane.clientHeight;
      const moved = (Math.max(0, now - since - HOLD_MS) * SCROLL_PX_A_SECOND) / 1000;
      pre.style.transform = `translateY(${-Math.round(Math.max(0, Math.min(moved, room)))}px)`;
    }
    requestAnimationFrame(scroll);
  };

  // The canvas goes into a stage beside the pane. On a narrow screen the
  // stage is no box at all (`display: contents`) and the pane is hidden, so
  // the canvas lays out as it did without them.
  const shown = (canvas) => {
    const style = document.createElement('style');
    style.textContent = STYLE;
    document.head.appendChild(style);
    const stage = document.createElement('div');
    stage.id = 'code-stage';
    pane = document.createElement('div');
    pane.id = 'code-pane';
    pre = document.createElement('pre');
    pane.append(pre);
    canvas.replaceWith(stage);
    stage.append(canvas, pane);
    requestAnimationFrame(scroll);
  };

  return { heard, shown };
})();

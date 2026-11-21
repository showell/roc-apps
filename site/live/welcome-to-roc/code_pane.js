// code_pane.js — the Lanterns page's code pane: on a screen wide enough, a
// pane beside the scene that shows the Roc module behind what is happening,
// coloured, under a strip naming its file, scrolling down through it while it
// is on screen. On a narrower screen the page is the canvas alone, as before.
//
// The Roc decides everything the pane shows (screensavers/lanterns/CodePane.roc
// and CodeCues.roc): after the first model and after every step the page asks
// the wasm's computeCode, and the answer, read through the glue, is either
// `{ tag: 'ModuleSource', value: { file, html, top_line, pane_lines, page } }`, a
// new module, its code as coloured and escaped HTML, on a `Dark` or `Light`
// page, or `{ tag: 'ScrollTo', value }`, the line now at the pane's top. Lines are the Roc's unit: the page sizes its
// lines so that `pane_lines` of them fill the code's area exactly, and turns a
// line into pixels by that height, so the Roc's last scroll puts a module's
// last line at the pane's foot. A pause holds the scroll, since the Roc's
// model holds. canvas_app_runner.js calls `heard` and `shown` (its `pane`).

const LanternsCodePane = (() => {
  // The narrowest window, in CSS pixels, that gets the pane.
  const WIDE_PX = 1100;
  // A line's height over its type's size.
  const LEADING = 1.5;
  // The folder every module's file is in, shown before its name.
  const FOLDER = 'screensavers/lanterns/';

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
        display: flex; flex-direction: column; overflow: hidden; flex: none;
        width: var(--pane-width); border-radius: 6px; background: #0e1220;
        border: 1px solid #1b2340;
      }
      #code-file {
        flex: none; padding: 9px 14px 8px; border-bottom: 1px solid #1b2340;
        font: 12px/1.3 ui-monospace, Menlo, Consolas, monospace; color: #6d7aa8;
        white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
      }
      #code-file b { font-size: 16px; font-weight: 700; color: #ffcb6b; letter-spacing: 0.01em; }
      #code-lines { flex: 1; position: relative; overflow: hidden; }
      #code-pane pre {
        position: absolute; left: 0; right: 0; top: 0; margin: 0; padding: 0 14px;
        font-family: ui-monospace, Menlo, Consolas, monospace; color: #c9cee0;
        white-space: pre; tab-size: 2; will-change: transform;
      }
      #code-pane .syn-keyword { color: #c792ea; }
      #code-pane .syn-type { color: #82aaff; }
      #code-pane .syn-string { color: #c3e88d; }
      #code-pane .syn-number { color: #f78c6c; }
      #code-pane .syn-comment { color: #8a8494; font-style: italic; }
      #code-pane .syn-name { color: #ffcb6b; }
      #code-pane.light { background: #ffffff; border-color: #d0d7de; }
      #code-pane.light #code-file { color: #57606a; border-bottom-color: #d0d7de; }
      #code-pane.light #code-file b { color: #953800; }
      #code-pane.light pre { color: #24292f; }
      #code-pane.light .syn-keyword { color: #cf222e; }
      #code-pane.light .syn-type { color: #116329; }
      #code-pane.light .syn-string { color: #0a3069; }
      #code-pane.light .syn-number { color: #0550ae; }
      #code-pane.light .syn-comment { color: #6e7781; }
      #code-pane.light .syn-name { color: #8250df; }
    }`;

  const wide = window.matchMedia(`(min-width: ${WIDE_PX}px)`);
  // What the Roc last said: the module, and the line at the pane's top.
  let module = null;
  let topLine = 0;
  // The pane's parts once shown, the module they hold, and a line's height.
  let parts = null;
  let painted = null;
  let lineHeight = 0;

  const heard = (game) => {
    const at = game.computeCode();
    // The view is made after the call, as the runner's frame view is: the
    // call can grow the wasm's memory, which detaches an older view.
    const code = RocGlue.code(new DataView(game.memory.buffer), at);
    if (code.tag === 'ModuleSource') {
      module = code.value;
      topLine = code.value.top_line;
    } else if (code.tag === 'ScrollTo') {
      topLine = code.value;
    } else {
      throw new Error(`code_pane: no such answer as ${code.tag}`);
    }
  };

  // A new module: its name in the strip and its code on the page the Roc
  // names, the strip lit and the code faded in for a moment, so its arrival
  // shows.
  const arrive = () => {
    parts.pane.classList.toggle('light', module.page.tag === 'Light');
    parts.folder.textContent = FOLDER;
    parts.name.textContent = module.file;
    parts.pre.innerHTML = module.html;
    painted = module;
    parts.strip.animate([{ background: 'rgba(255, 203, 107, 0.16)' }, { background: 'rgba(255, 203, 107, 0)' }], { duration: 900, easing: 'ease-out' });
    parts.pre.animate([{ opacity: 0.25 }, { opacity: 1 }], { duration: 400, easing: 'ease-out' });
  };

  // Each animation frame puts the latest module in the pane and its top line
  // at the top: `pane_lines` lines fill the code's area, whatever its height.
  const render = () => {
    if (module !== painted) arrive();
    if (wide.matches) {
      const height = parts.lines.clientHeight / module.pane_lines;
      if (height !== lineHeight) {
        lineHeight = height;
        parts.pre.style.fontSize = `${height / LEADING}px`;
        parts.pre.style.lineHeight = `${height}px`;
      }
      parts.pre.style.transform = `translateY(${-topLine * lineHeight}px)`;
    }
    requestAnimationFrame(render);
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
    const pane = document.createElement('div');
    pane.id = 'code-pane';
    const strip = document.createElement('div');
    strip.id = 'code-file';
    const folder = document.createElement('span');
    const name = document.createElement('b');
    strip.append(folder, name);
    const lines = document.createElement('div');
    lines.id = 'code-lines';
    const pre = document.createElement('pre');
    lines.append(pre);
    pane.append(strip, lines);
    parts = { pane, strip, folder, name, lines, pre };
    canvas.replaceWith(stage);
    stage.append(canvas, pane);
    requestAnimationFrame(render);
  };

  return { heard, shown };
})();

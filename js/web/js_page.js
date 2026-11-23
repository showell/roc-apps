// js_page -- the page for the JavaScript subset: an editor, a Run button and
// the output, with a few sample programs to start from. Everything the page
// shows, its styles included, is made here, so the HTML is only a door.

import { loadRunner } from "./js_runner.js";

const SAMPLES = {
  "Closures": `function counter() {
  let count = 0;
  return { up: () => ++count, get: () => count };
}
const c = counter();
c.up(); c.up(); c.up();
console.log("count:", c.get());

const fs = [];
for (let i = 0; i < 4; i++) fs.push(() => i * i);
console.log(fs.map((f) => f()));
`,
  "Fibonacci": `function fib(n) {
  return n < 2 ? n : fib(n - 1) + fib(n - 2);
}
const out = [];
for (let i = 0; i <= 15; i++) out.push(fib(i));
console.log(out);
`,
  "Word count": `const text = "the quick brown fox jumps over the lazy dog the fox";
const counts = {};
for (const w of text.split(" ")) counts[w] = (counts[w] ?? 0) + 1;
console.log(counts);
const top = Object.entries(counts).sort((a, b) => b[1] - a[1]);
console.log(top.slice(0, 3));
`,
  "Quicksort": `function quicksort(xs) {
  if (xs.length <= 1) return xs;
  const pivot = xs[0];
  const rest = xs.slice(1);
  return quicksort(rest.filter((x) => x < pivot))
    .concat([pivot], quicksort(rest.filter((x) => x >= pivot)));
}
console.log(quicksort([5, 3, 9, 1, 7, 2, 8, 6, 4, 0]));
`,
  "Outside the subset": `class Point {
  constructor(x, y) { this.x = x; this.y = y; }
}
console.log(new Point(1, 2));
`,
};

const CSS = `
  :root { color-scheme: light dark; --ink: #1b1b1b; --dim: #6a6a6a; --line: #d8d4cc; --paper: #faf8f4; --bad: #a33a1f; }
  @media (prefers-color-scheme: dark) {
    :root { --ink: #e8e6e1; --dim: #9a968e; --line: #3a3833; --paper: #1a1917; --bad: #e08a6c; }
  }
  body { margin: 0; background: var(--paper); color: var(--ink);
         font: 15px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; }
  .wrap { max-width: 1000px; margin: 0 auto; padding: 28px 16px; }
  h1 { font-size: 20px; margin: 0 0 4px; font-weight: 600; }
  .sub { color: var(--dim); font-size: 13px; margin: 0 0 20px; }
  .bar { display: flex; gap: 10px; align-items: center; margin: 0 0 10px; flex-wrap: wrap; }
  button, select { font: inherit; font-size: 14px; color: inherit; background: transparent;
                   border: 1px solid var(--ink); border-radius: 4px; padding: 5px 14px; }
  button:hover { background: var(--ink); color: var(--paper); }
  .cols { display: flex; gap: 18px; flex-wrap: wrap; }
  .col { flex: 1 1 380px; min-width: 0; }
  label { display: block; font-size: 12px; text-transform: uppercase; letter-spacing: .06em;
          color: var(--dim); margin: 0 0 6px; }
  textarea, pre { width: 100%; box-sizing: border-box; background: transparent; color: inherit;
                  border: 1px solid var(--line); border-radius: 4px; padding: 10px; margin: 0;
                  font: 13px/1.45 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
  textarea { height: 380px; resize: vertical; }
  pre { height: 380px; overflow: auto; white-space: pre; }
  .status { color: var(--dim); font-size: 13px; }
  .status.bad { color: var(--bad); }
`;

function element(tag, props = {}, children = []) {
  const e = document.createElement(tag);
  Object.assign(e, props);
  for (const c of children) e.appendChild(c);
  return e;
}

export function buildPage(runner) {
  document.head.appendChild(element("style", { textContent: CSS }));
  const picker = element("select", {}, Object.keys(SAMPLES).map((name) => element("option", { value: name, textContent: name })));
  const runButton = element("button", { textContent: "Run" });
  const status = element("span", { className: "status", textContent: "" });
  const editor = element("textarea", { spellcheck: false, value: SAMPLES["Closures"] });
  const output = element("pre", { textContent: "" });
  const wrap = element("div", { className: "wrap" }, [
    element("h1", { textContent: "JavaScript, in Roc" }),
    element("p", { className: "sub", textContent: "A subset of JavaScript run by a tree-walking interpreter written in Roc. Its console.log prints what node prints." }),
    element("div", { className: "bar" }, [picker, runButton, status]),
    element("div", { className: "cols" }, [
      element("div", { className: "col" }, [element("label", { textContent: "Program" }), editor]),
      element("div", { className: "col" }, [element("label", { textContent: "Output" }), output]),
    ]),
  ]);
  document.body.appendChild(wrap);

  const SAID = { ran: "ran to its end", faulted: "stopped", refused: "refused", crashed: "the interpreter crashed" };
  function runNow() {
    const started = performance.now();
    const r = runner.run(editor.value);
    const ms = Math.round(performance.now() - started);
    output.textContent = r.text;
    status.textContent = `${SAID[r.ending] ?? r.ending} in ${ms} ms`;
    status.className = r.ending === "ran" ? "status" : "status bad";
  }
  runButton.addEventListener("click", runNow);
  picker.addEventListener("change", () => { editor.value = SAMPLES[picker.value]; output.textContent = ""; status.textContent = ""; });
  return { picker, runButton, status, editor, output, runNow };
}

if (typeof window !== "undefined" && !window.JS_PAGE_CHECK) {
  const bytes = await (await fetch("js.wasm")).arrayBuffer();
  buildPage(await loadRunner(bytes));
}

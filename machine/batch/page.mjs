// Run the batch page's own script from Node, with no browser: a document just
// big enough for it, fetch answered from the dev channel, and every built
// unit run through the page's Run. Prints what each pane would show.
//
//   node machine/batch/page.mjs
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const dir = join(homedir(), "build/roc-apps/next/machine/batch");
const html = readFileSync(join(dir, "index.html"), "utf8");
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const units = JSON.parse(readFileSync(join(dir, "units.json"), "utf8"));

const painted = { pixels: 0, colours: new Set() };
const context = {
  createImageData: (w, h) => ({ width: w, height: h, data: new Uint8ClampedArray(w * h * 4) }),
  putImageData: (img) => {
    painted.pixels = img.width * img.height;
    painted.colours = new Set();
    for (let i = 0; i < img.data.length; i += 4) painted.colours.add((img.data[i] << 16) | (img.data[i + 1] << 8) | img.data[i + 2]);
  },
};
const el = () => ({ children: [], classList: { add() {}, remove() {} }, setAttribute() {}, appendChild() {}, getContext: () => context, dataset: {}, textContent: "", innerHTML: "", disabled: false, hidden: false });
const els = new Map();
globalThis.document = { getElementById: (id) => { if (!els.has(id)) els.set(id, el()); return els.get(id); }, createElement: el };
globalThis.requestAnimationFrame = (f) => setTimeout(f, 0);
globalThis.fetch = async (path) => ({
  json: async () => units,
  arrayBuffer: async () => { const b = readFileSync(join(dir, path)); return b.buffer.slice(b.byteOffset, b.byteOffset + b.byteLength); },
});

const page = new Function(script + "\nreturn { run, choose };")();
const pane = (id) => els.get(id)?.textContent ?? "";
for (const u of units) {
  page.choose(u);
  await page.run();
  console.log(`== ${u.name}`);
  console.log(`status : ${pane("status")}`);
  console.log(`screen : ${pane("screenlab")} -- ${pane("screennote")}${els.get("screen")?.hidden === false ? ` (${painted.pixels} pixels painted, ${painted.colours.size} colours)` : ""}`);
  if (pane("expected")) console.log(`expected:\n${pane("expected")}`);
  console.log(`roc    : ${pane("codelab")}; the first tab has ${pane("src").split("\n").length} lines`);
  console.log(`disk   : ${pane("disklab")} -- ${pane("disk")}`);
  console.log(`network: ${pane("wirelab")}`);
  if (pane("frames")) console.log(pane("frames"));
}

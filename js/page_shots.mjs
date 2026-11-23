// page_shots -- the JavaScript playground driven in headless Chromium: a
// sample picked by its title, run at a speed, the page shot while it draws
// and once it is done, and the canvas's pixels counted, so a check can say
// the canvas shows drawing without a person looking.
//
//   node js/page_shots.mjs <page-url> <shots-dir> <title-words> <speed> [<key> | click:<x>:<y>,...] [width:<px>]
//
// The sample is shot first as picked, before Run, where the page must show
// only its line saying the program hasn't run (no canvas, no console); then
// Run is pressed. `width:` sets the tab's width (1280 unless given; 390 is a
// phone's), and below 700 each shot scrolls the canvas's column into view,
// since a phone shows it under the editor.
//
// <speed> is the speed menu's place: 0 full speed, 1 a mark at a time, 2 ten
// at a time. With <key>, the canvas is focused and the key held down for two
// seconds, as a player would (the arrow-key sample). With `click:` and points
// in canvas units, each point is clicked with the mouse, a quarter second
// apart (the click sample). It prints one line a
// shot: the file, the status, and how many of the canvas's pixels are not
// its most common color; it exits 1 when the page threw or the canvas stayed
// one color.
import { join } from "node:path";
import { evaluate, load, shot, sleep, tab, withBrowser } from "../tools/chromium.mjs";

const [url, dir, words, speed = "0", ...rest] = process.argv.slice(2);
if (!url || !dir || !words) {
  console.error("usage: node js/page_shots.mjs <page-url> <shots-dir> <title-words> <speed> [<key> | click:<x>:<y>,...] [width:<px>]");
  process.exit(2);
}
const widthArg = rest.find((a) => a.startsWith("width:"));
const key = rest.find((a) => !a.startsWith("width:"));
const WIDTH = widthArg ? Number(widthArg.slice(6)) : 1280;
const HEIGHT = WIDTH < 700 ? 844 : 900;
const SCROLL = WIDTH < 700
  ? `document.querySelector(".waiting").parentElement.scrollIntoView({ block: "start" })`
  : "0";

// The column before Run: the line shown, the canvas, its label and the console hidden.
const BEFORE = `(() => {
  const seen = (e) => e.offsetParent !== null;
  const line = document.querySelector(".waiting");
  return { line: seen(line), label: seen(line.nextElementSibling), canvas: seen(document.querySelector("canvas")),
           console: seen(document.querySelector("pre")) };
})()`;

const COUNT = `(() => {
  const c = document.querySelector("canvas");
  const d = c.getContext("2d").getImageData(0, 0, c.width, c.height).data;
  const seen = new Map();
  for (let i = 0; i < d.length; i += 4) {
    const k = (d[i] << 16) | (d[i + 1] << 8) | d[i + 2];
    seen.set(k, (seen.get(k) ?? 0) + 1);
  }
  const most = Math.max(...seen.values());
  return { marked: d.length / 4 - most, colors: seen.size, status: document.querySelector(".status").textContent };
})()`;

let bad = false;
await withBrowser(async (link) => {
  const page = await tab(link, { width: WIDTH, height: HEIGHT });
  await load(link, page, url);
  const picked = await evaluate(page, `(() => {
    const select = document.querySelector("select");
    const o = [...select.options].find((o) => o.textContent.includes(${JSON.stringify(words)}));
    if (!o) return null;
    select.value = o.value;
    select.dispatchEvent(new Event("change"));
    const speed = document.querySelectorAll("select")[1];
    speed.value = ${JSON.stringify(speed)};
    return o.textContent;
  })()`);
  if (!picked) { console.log(`no sample's title holds \`${words}\``); bad = true; return; }
  console.log(`sample: ${picked}, speed ${speed}, ${WIDTH} px wide`);
  await evaluate(page, SCROLL);
  const before = join(dir, "before.png");
  await shot(page, before);
  const b = await evaluate(page, BEFORE);
  const beforeOk = b.line && !b.canvas && !b.label && !b.console;
  console.log(`${before}: ${beforeOk ? "the not-yet-run line alone" : `wrong: ${JSON.stringify(b)}`}`);
  if (!beforeOk) bad = true;
  await evaluate(page, `[...document.querySelectorAll("button")].find((b) => b.textContent === "Run").click()`);
  const moments = [["early", 1200], ["later", 2500], ["end", 6000]];
  for (const [name, wait] of moments) {
    if (key && key.startsWith("click:") && name === "early") {
      const box = await evaluate(page, `(() => { const b = document.querySelector("canvas").getBoundingClientRect(); return { left: b.left, top: b.top, width: b.width }; })()`);
      for (const point of key.slice(6).split(",")) {
        const [cx, cy] = point.split(":").map(Number);
        const x = box.left + (cx * box.width) / 400;
        const y = box.top + (cy * box.width) / 400;
        for (const type of ["mousePressed", "mouseReleased"]) {
          await page.send("Input.dispatchMouseEvent", { type, x, y, button: "left", clickCount: 1 });
        }
        await sleep(250);
      }
    } else if (key && name === "early") {
      await page.send("Input.dispatchKeyEvent", { type: "keyDown", key, code: key });
      await sleep(2000);
      await page.send("Input.dispatchKeyEvent", { type: "keyUp", key, code: key });
    }
    await sleep(wait);
    await evaluate(page, SCROLL);
    const file = join(dir, `${name}.png`);
    await shot(page, file);
    const c = await evaluate(page, COUNT);
    console.log(`${file}: status \`${c.status}\`, ${c.marked} pixels marked, ${c.colors} colors`);
    if (name === "end" && c.marked === 0) bad = true;
  }
  for (const t of page.thrown) { console.log(`thrown: ${t}`); bad = true; }
}, { args: [`--window-size=${WIDTH},${HEIGHT}`] });
process.exit(bad ? 1 : 0);

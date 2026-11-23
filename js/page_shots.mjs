// page_shots -- the JavaScript playground driven in headless Chromium: a
// sample picked by its title, run at a speed, the page shot while it draws
// and once it is done, and the canvas's pixels counted, so a check can say
// the canvas shows drawing without a person looking.
//
//   node js/page_shots.mjs <page-url> <shots-dir> <title-words> <speed> [<key>]
//
// <speed> is the speed menu's place: 0 full speed, 1 a mark at a time, 2 ten
// at a time. With <key>, the canvas is focused and the key held down for two
// seconds, as a player would (the arrow-key sample). It prints one line a
// shot: the file, the status, and how many of the canvas's pixels are not
// its most common color; it exits 1 when the page threw or the canvas stayed
// one color.
import { join } from "node:path";
import { evaluate, load, shot, sleep, tab, withBrowser } from "../tools/chromium.mjs";

const [url, dir, words, speed = "0", key] = process.argv.slice(2);
if (!url || !dir || !words) {
  console.error("usage: node js/page_shots.mjs <page-url> <shots-dir> <title-words> <speed> [<key>]");
  process.exit(2);
}

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
  const page = await tab(link, { width: 1280, height: 900 });
  await load(link, page, url);
  const picked = await evaluate(page, `(() => {
    const select = document.querySelector("select");
    const o = [...select.options].find((o) => o.textContent.includes(${JSON.stringify(words)}));
    if (!o) return null;
    select.value = o.value;
    select.dispatchEvent(new Event("change"));
    const speed = document.querySelectorAll("select")[1];
    speed.value = ${JSON.stringify(speed)};
    [...document.querySelectorAll("button")].find((b) => b.textContent === "Run").click();
    return o.textContent;
  })()`);
  if (!picked) { console.log(`no sample's title holds \`${words}\``); bad = true; return; }
  console.log(`sample: ${picked}, speed ${speed}`);
  const moments = [["early", 1200], ["later", 2500], ["end", 6000]];
  for (const [name, wait] of moments) {
    if (key && name === "early") {
      await page.send("Input.dispatchKeyEvent", { type: "keyDown", key, code: key });
      await sleep(2000);
      await page.send("Input.dispatchKeyEvent", { type: "keyUp", key, code: key });
    }
    await sleep(wait);
    const file = join(dir, `${name}.png`);
    await shot(page, file);
    const c = await evaluate(page, COUNT);
    console.log(`${file}: status \`${c.status}\`, ${c.marked} pixels marked, ${c.colors} colors`);
    if (name === "end" && c.marked === 0) bad = true;
  }
  for (const t of page.thrown) { console.log(`thrown: ${t}`); bad = true; }
}, { args: ["--window-size=1280,900"] });
process.exit(bad ? 1 : 0);

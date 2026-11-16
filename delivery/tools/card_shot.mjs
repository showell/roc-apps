// card_shot.mjs takes the landing page's picture of Seattle Delivery: the
// page in headless Chromium, 1200 by 720 (the map's own size), the first
// shift's day played for a few seconds so the trucks are out on their
// routes, with the site's bar hidden.
//
//   node delivery/tools/card_shot.mjs <page url> <out.png>
//
// site/squeeze_png.mjs then makes it small; delivery/build.shale runs both
// on the page it stages.
import { withBrowser, tab, load, press, shot, sleep, evaluate } from "./chromium.mjs";

const [url, out] = process.argv.slice(2);
if (!url || !out) {
  console.error("usage: card_shot.mjs <page url> <out.png>");
  process.exit(2);
}

let failed = "";
await withBrowser(async (link) => {
  const page = await tab(link, { width: 1200, height: 720 });
  await load(link, page, url);
  await press(page, " ", "Space");
  await sleep(5000);
  await evaluate(page, `(() => {
    for (const el of document.body.children) if (el.style.zIndex === "2147483647") el.style.display = "none";
  })()`);
  await sleep(200);
  await shot(page, out);
  const errors = [...page.thrown, ...page.said.filter((s) => s.level === "error").map((s) => s.text)];
  if (errors.length) failed = `console errors: ${errors.join(" | ")}`;
});
if (failed) {
  console.error(`card_shot: ${failed}`);
  process.exit(1);
}
console.log(`card_shot: ${out}`);

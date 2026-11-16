// card_shot.mjs takes the landing page's picture of Dog Park: Level Two in
// headless Chromium, 960 by 720, its middle dog dragged round a loop so the
// park is in motion (a herd following, cows scattering, a trail of poop),
// with the page's buttons and the site's bar hidden and the score left
// showing. The critters are emoji, so the box needs a colour emoji font
// (fc-list names one); a shot without it shows no critters.
//
//   node dog-park/tools/card_shot.mjs <page url> <out.png>
//
// site/squeeze_png.mjs then makes it small; README, "The landing page's
// picture", has the steps.
import { withBrowser, tab, load, nearestDog, drag, line, shot, sleep, evaluate } from "./lib/chromium.mjs";

const [url, out] = process.argv.slice(2);
if (!url || !out) {
  console.error("usage: card_shot.mjs <page url> <out.png>");
  process.exit(2);
}

let failed = "";
await withBrowser(async (link) => {
  const page = await tab(link, { width: 960, height: 720, before: `if (localStorage.getItem("dogpark.level") === null) localStorage.setItem("dogpark.level", "level 2 of 2");` });
  await load(link, page, url);
  if (!page.said.some((s) => /level 2 of 2: a new park/.test(s.text))) failed = "the page did not open on a new Level Two";
  const dog = await nearestDog(page, 2);
  // A loop: east, south, west, north, and east again, at a dog's walking pace.
  const path = [...line(160, 0, 20)];
  for (const [dx, dy] of [[160, 120], [-40, 120], [-40, 0], [60, -40]]) {
    const at = path.at(-1);
    path.push(...line(dx - at.dx, dy - at.dy, 20).map((p) => ({ dx: at.dx + p.dx, dy: at.dy + p.dy })));
  }
  await drag(page, dog, path);
  await sleep(600);
  await evaluate(page, `(() => {
    for (const id of ["map", "debug", "reset", "levels", "next", "toast"]) document.getElementById(id)?.style.setProperty("display", "none");
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

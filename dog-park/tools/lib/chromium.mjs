// Dog Park's own moves for its page check (tools/page_check.mjs) and its
// landing-page picture (tools/card_shot.mjs): finding a dog and dragging it.
// The browser and the rest of the DevTools helpers are the repository's
// tools/chromium.mjs, which these re-export so each tool imports from here.
import { evaluate, sleep } from "../../../tools/chromium.mjs";

export { withBrowser, tab, evaluate, load, shot, sleep } from "../../../tools/chromium.mjs";

/**
 * The dog of `level`'s first layout (1-based) nearest the screen's middle,
 * on screen, { id, x, y }: the page opens on the world's centre, and its own
 * physics.js says where the layout puts each dog.
 */
export const nearestDog = (page, level) => evaluate(page, `(async () => {
  const { instantiatePhysics } = await import("./physics.js");
  const p = await instantiatePhysics(await fetch("physics.wasm"));
  p.reset(${level - 1});
  const world = p.raw.tilePx() * p.raw.worldTiles();
  const left = Math.round(world / 2 - innerWidth / 2);
  const top = Math.round(world / 2 - innerHeight / 2);
  const dogs = p.critters().dogs.map((d) => ({ id: d.id, x: d.x / 256 - left, y: d.y / 256 - top }));
  dogs.sort((a, b) => Math.hypot(a.x - innerWidth / 2, a.y - innerHeight / 2) - Math.hypot(b.x - innerWidth / 2, b.y - innerHeight / 2));
  return dogs[0];
})()`);

/** A mouse drag from `from` along `path`, a list of { dx, dy } from it, a step every 70 ms. */
export async function drag(page, from, path) {
  const mouse = (type, x, y) => page.send("Input.dispatchMouseEvent", { type, x, y, button: "left", buttons: type === "mouseReleased" ? 0 : 1, clickCount: 1 });
  await mouse("mousePressed", from.x, from.y);
  for (const p of path) {
    await mouse("mouseMoved", from.x + p.dx, from.y + p.dy);
    await sleep(70);
  }
  const end = path.at(-1) ?? { dx: 0, dy: 0 };
  await mouse("mouseReleased", from.x + end.dx, from.y + end.dy);
}

/** A straight line of `steps` steps to (dx, dy), for `drag`. */
export const line = (dx, dy, steps) => Array.from({ length: steps }, (_, k) => ({ dx: (dx * (k + 1)) / steps, dy: (dy * (k + 1)) / steps }));

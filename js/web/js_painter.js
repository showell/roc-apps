// js_painter -- paints the canvas playground's effects on a 2D canvas, one
// line at a time, as js_runner.js hands them over. A line is an effect's
// written form (Canvas.line_of in js/roc/Canvas.roc): its name, its numbers,
// and a color or words last.
//
// The fill and the stroke are the painter's state, as in p5.js: a shape is
// filled when there is a fill and outlined when there is a stroke. Each run
// starts on a white canvas, filling white and stroking black one pixel wide.
// A color the canvas doesn't know leaves its color as it was, as a browser's
// canvas does.

import { unescaped } from "./js_runner.js";

export const SIZE = 400;

export function makePainter(ctx) {
  let filling = true;
  let stroking = true;

  function shape(draw) {
    ctx.beginPath();
    draw();
    if (filling) ctx.fill();
    if (stroking) ctx.stroke();
  }

  function reset() {
    filling = true;
    stroking = true;
    ctx.fillStyle = "white";
    ctx.fillRect(0, 0, SIZE, SIZE);
    ctx.strokeStyle = "black";
    ctx.lineWidth = 1;
  }

  // Each line: its name, then the words after it.
  function paint(line) {
    const space = line.indexOf(" ");
    const name = space < 0 ? line : line.slice(0, space);
    const rest = space < 0 ? "" : line.slice(space + 1);
    const n = (count) => rest.split(" ", count).map(Number);
    const after = (count) => rest.split(" ").slice(count).join(" ");
    switch (name) {
      case "background": {
        const was = ctx.fillStyle;
        ctx.fillStyle = rest;
        ctx.fillRect(0, 0, SIZE, SIZE);
        ctx.fillStyle = was;
        break;
      }
      case "fill": filling = true; ctx.fillStyle = rest; break;
      case "noFill": filling = false; break;
      case "stroke": stroking = true; ctx.lineWidth = n(1)[0]; ctx.strokeStyle = after(1); break;
      case "noStroke": stroking = false; break;
      case "line": {
        const [x1, y1, x2, y2] = n(4);
        ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2);
        if (stroking) ctx.stroke();
        break;
      }
      case "rect": { const [x, y, w, h] = n(4); shape(() => ctx.rect(x, y, w, h)); break; }
      case "circle": { const [x, y, r] = n(3); shape(() => ctx.arc(x, y, Math.abs(r), 0, 2 * Math.PI)); break; }
      case "ellipse": {
        const [x, y, rx, ry] = n(4);
        shape(() => ctx.ellipse(x, y, Math.abs(rx), Math.abs(ry), 0, 0, 2 * Math.PI));
        break;
      }
      case "polygon": {
        const c = rest.split(" ").map(Number);
        shape(() => { ctx.moveTo(c[0], c[1]); for (let i = 2; i < c.length; i += 2) ctx.lineTo(c[i], c[i + 1]); ctx.closePath(); });
        break;
      }
      case "text": {
        const [x, y, size] = n(3);
        ctx.font = `${size}px -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif`;
        if (filling) ctx.fillText(unescaped(after(3)), x, y);
        break;
      }
      case "log": break;
      default: throw new Error(`js_painter: no effect named \`${name}\``);
    }
  }

  return { reset, paint };
}

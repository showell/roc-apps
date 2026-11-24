// The copy buttons' pure half (copy.js, ported from the essay surface's):
// the text a block copies, and which way the copy goes when the clipboard API
// is there, missing, refused or broken, and when the textarea fallback fails too. Run by
// tools/verify.shale, `node book_builder/copy_test.cjs`; it prints one
// "ok:" line a check and exits 1 on the first that fails.
"use strict";
const c = require("./copy.js");

let passed = 0;
function check(what, got, want) {
  const g = JSON.stringify(got), w = JSON.stringify(want);
  if (g !== w) {
    console.log("FAIL: " + what + ": got " + g + ", want " + w);
    process.exit(1);
  }
  passed++;
  console.log("ok: " + what);
}

// The text: the renderer's last newline goes, and nothing else does.
check("the renderer's newline goes", c.sourceOf("a\nb\n"), "a\nb");
check("a blank last line stays", c.sourceOf("a\n\n"), "a\n");
check("leading and inner space stays", c.sourceOf("  x\n\ty  \n"), "  x\n\ty  ");
check("text with no newline is whole", c.sourceOf("x"), "x");

// Each way, with what was copied.
function ways(clipboard, textareaWorks) {
  const got = { clipboard: [], textarea: [] };
  const w = {
    clipboard: clipboard && {
      writeText(t) { got.clipboard.push(t); return clipboard(t); }
    },
    textarea(t) { got.textarea.push(t); return textareaWorks(t); }
  };
  return { w, got };
}

async function main() {
  let r = ways((t) => Promise.resolve(), () => true);
  check("the clipboard API first", await c.copyText("x", r.w), "clipboard");
  check("the API alone is used", r.got, { clipboard: ["x"], textarea: [] });

  r = ways(null, () => true);
  check("no API (plain http): the textarea", await c.copyText("x", r.w), "textarea");
  check("the textarea gets the text", r.got.textarea, ["x"]);

  r = ways(() => Promise.reject(new Error("NotAllowedError")), () => true);
  check("the API refused: the textarea", await c.copyText("y", r.w), "textarea");
  check("both were tried", r.got, { clipboard: ["y"], textarea: ["y"] });

  r = ways(() => { throw new Error("broken"); }, () => true);
  check("the API throws: the textarea", await c.copyText("z", r.w), "textarea");

  r = ways(null, () => false);
  check("execCommand says no: none, so the page selects", await c.copyText("x", r.w), "none");

  r = ways(null, () => { throw new Error("no execCommand"); });
  check("execCommand throws: none", await c.copyText("x", r.w), "none");

  r = ways(() => Promise.reject(new Error("no")), () => false);
  check("both fail: none", await c.copyText("x", r.w), "none");

  console.log(passed + " checks passed");
}
main();

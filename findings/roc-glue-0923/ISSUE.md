`roc glue` fails with "runtime error" on nightly 2026-09-23 (c7852fd), even DebugGlue on test/glue/cli-main; 09-22 is fine

From a checkout of roc at `c7852fd` (the commit the 09-23 nightly names), with that nightly's `roc`:

```
$ roc glue src/glue/src/DebugGlue.roc /tmp/out test/glue/cli-main/main.roc
Error running glue spec: crashed with message: runtime error
Error: Compilation failed
```

With `nightly-2026-09-22-e494788` and its own `DebugGlue.roc` (from `e494788`), the same command prints the type table (`[dbg] [{ modules: [...], provides_entries: [{ exported: ProvidedProcedure(...), ... }], types: [...] }]`) and "Glue spec returned 0 files".

Every platform we tried fails the same way on 09-23 -- roc's `test/glue/cli-main`, and three of ours (a wasm page platform, a canvas-app platform, a native CLI platform) -- and every one works on 09-22, both with DebugGlue and with our own glue script. `roc check` on the glue script itself finds no errors; the crash is while running it, and says nothing more than "runtime error".

x86-64 Linux, the release tarballs from roc-lang/nightlies.

**Where we hit it.** Our browser pages read their views through a JavaScript reader that a glue script writes (`glue/JsGlue.roc`), so on 09-23 no page builds; we stay on 09-22.

---

Reported by Claude (Anthropic's Claude Code), working with @showell. Notes in https://github.com/showell/roc-apps/tree/master/findings/roc-glue-0923.

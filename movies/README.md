# The movies

A movie is a value: a size, a way to step forwards and back, and a frame of
shapes. A player is a function of one. There are two players -- `web/blitter.js`
on a canvas, and `ray/player/MoviePlayer.roc` on roc-ray -- and neither knows
anything about any particular movie.

## Every movie is the same five things

| file | what |
|---|---|
| `<Name>.roc` | the movie: a `Movie.Movie(Model)` and whatever builds its frames |
| `<Name>App.roc` | the wasm app: the platform's exports over a boxed model |
| `main.roc` | the roc-ray app: names the movie and hands it to `MoviePlayer` |
| `page.html` | the page: `window.SHOW` names the module, the scene count and the hint, and loads the blitter |
| anything else `*.roc` | the movie's own, staged beside it |

`movie/` at the repository root is staged with every one of them. Nothing else
is: a movie that needs a module borrows it by owning a copy, which is why
Halloween holds `Skeleton.roc`.

    movies/build.sh halloween      # the page into dev, http://<box>:9210/halloween/
    ray/build.sh halloween         # the native program, ~/build/roc-apps/ray/halloween/
    node web/page_check.mjs halloween          # the page, run the way a browser runs it
    FRAMES=1500 node web/page_check.mjs halloween   # all of a long one

| movie | what |
|---|---|
| `safari/` | the driving screensaver: 120 modules emitted from Codex, now source, and the specs that grade them |
| `capture_plot/` | roc-ray's own example, as a movie: gridlines, text and a progress bar, all polygons |
| `particles/` | roc-ray's fountain |
| `halloween/` | a child walks up to a house past six skeletons; the first movie here placed in metres and projected rather than drawn in screen coordinates |

// embed.js sits a canvas app's page inside a page of prose. Each app stays an
// ordinary page of its own, served beside the prose and shown in an iframe:
//
//   <iframe class="canvas-app" src="../sky_widget/" loading="lazy"
//           style="aspect-ratio: 640 / 360"></iframe>
//   <script src="embed.js"></script>
//
// canvas_app_runner.js lays a page out for a whole window and listens for the
// wheel, and neither suits a frame in a column of text. This reaches into each
// frame, which is on the same origin, and changes four things. The canvas
// fills the frame. The wheel goes on scrolling the prose, since no widget reads
// it. A click hands the frame the keyboard, because the runner's pointerdown
// cancels the browser's own focusing. A frame off the screen stops, because a
// browser goes on running a same-origin frame it can't see, and a page of
// these would keep a core busy.
const FILL_THE_FRAME = `
  body { height: auto !important; background: none !important; display: block !important; }
  canvas { display: block !important; width: 100% !important; height: auto !important;
           max-width: none !important; max-height: none !important; }
`;

// The runner asks for each animation frame in turn, so holding back one answer
// stops it, and the runner's own cap on catching up covers the time away.
function stopWhileOffScreen(frame) {
  const view = frame.contentWindow;
  const askBrowser = view.requestAnimationFrame.bind(view);
  let onScreen = true;
  let waiting = null;
  view.requestAnimationFrame = (callback) => {
    if (onScreen) return askBrowser(callback);
    waiting = callback;
    return 0;
  };
  new IntersectionObserver(([sighting]) => {
    onScreen = sighting.isIntersecting;
    if (onScreen && waiting) {
      askBrowser(waiting);
      waiting = null;
    }
  }).observe(frame);
}

function fitFrame(frame) {
  const view = frame.contentWindow;
  const style = view.document.createElement('style');
  style.textContent = FILL_THE_FRAME;
  view.document.head.append(style);
  view.addEventListener('wheel', (event) => event.stopImmediatePropagation(), { capture: true });
  view.addEventListener('pointerdown', () => view.focus());
}

for (const frame of document.querySelectorAll('iframe.canvas-app')) {
  frame.addEventListener('load', () => {
    fitFrame(frame);
    stopWhileOffScreen(frame);
  });
}

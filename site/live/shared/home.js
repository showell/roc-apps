// The way home, and the dev channel's banner, for every page of Steve's Roc
// Apps. A page loads it with one line, the path relative to the page:
//
//   <script src="../shared/home.js"></script>
//
// The site's root is the directory above this script, so a page at any depth,
// on any host, links to its own channel's landing page. Only the dev root holds
// a `channel` file, and a page there shows a banner naming it; staging and prod
// serve the same files and show none. The landing page loads it too, and gets
// the banner without the link.
(() => {
  const root = new URL('..', document.currentScript.src);
  const pill = 'padding:3px 8px;border-radius:4px;color:#fff;text-decoration:none;pointer-events:auto';
  const bar = document.createElement('div');
  bar.style.cssText = 'position:fixed;top:6px;right:6px;z-index:2147483647;display:flex;gap:6px;'
    + 'font:12px/1.4 system-ui,sans-serif;pointer-events:none';
  if (new URL('.', location.href).href !== root.href) {
    const home = document.createElement('a');
    home.href = root.href;
    home.textContent = "Steve's Roc Apps";
    home.style.cssText = pill + ';background:rgba(24,24,24,.72)';
    bar.append(home);
  }
  const show = () => document.body.append(bar);
  document.body ? show() : document.addEventListener('DOMContentLoaded', show);
  fetch(new URL('channel', root)).then(r => (r.ok ? r.text() : '')).then(text => {
    const channel = text.trim();
    if (!channel) return;
    const banner = document.createElement('span');
    banner.textContent = channel;
    banner.style.cssText = pill + ';background:#b3261e';
    bar.prepend(banner);
  }).catch(() => {});
})();

#!/bin/bash
# Install the pages as systemd --user services that survive reboots and
# logouts (linger is on for this user). Rerun after editing a unit;
# idempotent. The same pattern as essay-repl-server/ops/install.sh.
#
#   safari-web       :9201  the safari demo: safari/web/, whose module only safari/publish.sh writes
#   safari-web-next  :9203  the preview: ~/build/roc-apps/next, whatever safari/wasm/build.sh and gpu/build.sh last built
#   gallery-web      :9204  the gpu gallery demo: gpu/live/, which only gpu/publish.sh writes
#   games-web        :9205  the games demo: games/live/, which only games/publish.sh writes
#
# All read the file per request with no-store, so a publish or a build is
# live at once, no restart.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p ~/.config/systemd/user
ln -sf "$PWD/safari-web.service" "$PWD/safari-web-next.service" "$PWD/gallery-web.service" "$PWD/games-web.service" ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now safari-web safari-web-next gallery-web games-web
systemctl --user --no-pager status safari-web safari-web-next gallery-web games-web | grep -E "service -|Active"
if [ "$(loginctl show-user "$USER" -P Linger)" != "yes" ]; then
    echo "NOTE: linger is off -- the service dies with your last login."
    echo "Fix once with: sudo loginctl enable-linger $USER"
fi

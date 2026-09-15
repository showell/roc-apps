#!/bin/bash
# Install the pages as systemd --user services that survive reboots and
# logouts (linger is on for this user). Rerun after editing a unit;
# idempotent. The same pattern as essay-repl-server/ops/install.sh.
#
#   roc-site         :9210  dev: ~/build/roc-apps/next, whatever the build scripts last wrote
#                    :9200  staging: site/live/, which only site/publish.sh writes
#   safari-web       :9201  the old safari demo, frozen in ~/build/roc-apps/safari-demo/
#   safari-web-next  :9203  the old preview: ~/build/roc-apps/next
#   gallery-web      :9204  the old gpu gallery demo: gpu/live/
#   games-web        :9205  the old games demo: games/live/
#
# roc-site is Caddy (ops/Caddyfile, the binary at ~/build/caddy/caddy); the
# other four run safari/web/serve.py until their ports become redirects. All
# read the file per request with no-store, so a publish or a build is live at
# once, no restart.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p ~/.config/systemd/user
ln -sf "$PWD/roc-site.service" "$PWD/safari-web.service" "$PWD/safari-web-next.service" "$PWD/gallery-web.service" "$PWD/games-web.service" ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now roc-site safari-web safari-web-next gallery-web games-web
systemctl --user --no-pager status roc-site safari-web safari-web-next gallery-web games-web | grep -E "service -|Active"
if [ "$(loginctl show-user "$USER" -P Linger)" != "yes" ]; then
    echo "NOTE: linger is off -- the service dies with your last login."
    echo "Fix once with: sudo loginctl enable-linger $USER"
fi

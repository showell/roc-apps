#!/bin/bash
# Install the pages as systemd --user services that survive reboots and
# logouts (linger is on for this user). Rerun after editing a unit;
# idempotent. The same pattern as essay-repl-server/ops/install.sh.
#
#   roc-site  :9210  dev: ~/build/roc-apps/next, whatever the build scripts last wrote
#             :9200  staging: site/live/, which only site/publish.sh writes
#             :9201, :9203, :9204, :9205  redirects from the ports announced before the site
#
# roc-site is Caddy (ops/Caddyfile), from the release binary at
# ~/build/caddy/caddy. It reads a file per request with no-store, so a publish
# or a build is live at once; `systemctl --user reload roc-site` after editing
# the Caddyfile.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p ~/.config/systemd/user
ln -sf "$PWD/roc-site.service" ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now roc-site
systemctl --user --no-pager status roc-site | grep -E "service -|Active"
if [ "$(loginctl show-user "$USER" -P Linger)" != "yes" ]; then
    echo "NOTE: linger is off -- the service dies with your last login."
    echo "Fix once with: sudo loginctl enable-linger $USER"
fi

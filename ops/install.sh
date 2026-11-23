#!/bin/bash
# Install the pages as systemd --user services that survive reboots and
# logouts (linger is on for this user). Rerun after editing a unit;
# idempotent.
#
#   roc-site  :9210  dev: ~/build/roc-apps/next, whatever the build scripts last wrote
#             :9200  staging: site/live/, which only site/publish.sh and site/publish_screensavers.shale write
#             :9201, :9203  redirects from the ports announced before the site
#
# roc-site is Caddy (ops/Caddyfile), from the release binary at
# ~/build/caddy/caddy. It reads a file per request with no-store, so a publish
# or a build is live at once; `systemctl --user restart roc-site` after editing
# the Caddyfile (it has no admin endpoint, so no reload). ops/install_hardened.sh
# replaces this user service with a hardened system one.
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

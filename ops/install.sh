#!/bin/bash
# Install the safari page as a systemd --user service that survives reboots
# and logouts (linger is on for this user). Rerun after editing the unit;
# idempotent. The same pattern as essay-repl-server/ops/install.sh.
#
# The service serves safari/web/ as it is on disk: a rebuild with
# safari/wasm/build.sh is live at once, no restart, because serve.py sends
# no-store and reads the file per request.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p ~/.config/systemd/user
ln -sf "$PWD/safari-web.service" ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now safari-web
systemctl --user --no-pager status safari-web | head -5
if [ "$(loginctl show-user "$USER" -P Linger)" != "yes" ]; then
    echo "NOTE: linger is off -- the service dies with your last login."
    echo "Fix once with: sudo loginctl enable-linger $USER"
fi

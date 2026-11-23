#!/bin/bash
# Install roc-site as a hardened system service (ops/roc-site.hardened.service)
# in place of the user service ops/install.sh installs. The box's owner runs
# it with sudo, from the roc-apps checkout; no agent does. Rerun it after
# editing ops/Caddyfile or the unit (it copies both again and restarts).
#
#   sudo ops/install_hardened.sh
#
# It copies the Caddy binary to /usr/local/bin/caddy (root's; from
# ~/build/caddy/caddy unless CADDY= names another, and that file is the
# user's to write, so check what it prints: `caddy version` and its sha256,
# against Caddy's own release), ops/Caddyfile to /etc/roc-site/Caddyfile, and
# the unit, its @USER@ and @HOME@ filled in, to
# /etc/systemd/system/roc-site.service; then it stops and disables the user
# service of the same name, and enables and starts the system one.
#
# To go back to the user service:
#   sudo systemctl disable --now roc-site
#   sudo rm /etc/systemd/system/roc-site.service && sudo systemctl daemon-reload
#   ops/install.sh          (as yourself)
set -euo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "run it with sudo: sudo ops/install_hardened.sh"; exit 2; }
user="${SUDO_USER:-}"
[ -n "$user" ] && [ "$user" != root ] || { echo "run it with sudo from the account that owns the checkout"; exit 2; }
home="$(getent passwd "$user" | cut -d: -f6)"
caddy="${CADDY:-$home/build/caddy/caddy}"
[ -f "$caddy" ] && [ ! -L "$caddy" ] || { echo "no Caddy binary at $caddy (CADDY= names another)"; exit 2; }
for d in "$home/showell_repos/roc-apps/site/live" "$home/build/roc-apps/next"; do
    [ -d "$d" ] || { echo "$d is not there, and the unit binds it in"; exit 2; }
done

install -o root -g root -m 755 "$caddy" /usr/local/bin/caddy.new
mv -T -f /usr/local/bin/caddy.new /usr/local/bin/caddy
install -d -o root -g root -m 755 /etc/roc-site
install -o root -g root -m 644 Caddyfile /etc/roc-site/Caddyfile
/usr/local/bin/caddy validate --adapter caddyfile --config /etc/roc-site/Caddyfile
sed "s|@USER@|$user|g; s|@HOME@|$home|g" roc-site.hardened.service > /etc/systemd/system/roc-site.service.new
chmod 644 /etc/systemd/system/roc-site.service.new
mv -T -f /etc/systemd/system/roc-site.service.new /etc/systemd/system/roc-site.service

# The user service of the same name, stopped and disabled, so one Caddy
# holds the ports.
uid="$(id -u "$user")"
sudo -u "$user" XDG_RUNTIME_DIR="/run/user/$uid" systemctl --user disable --now roc-site 2>/dev/null || true

systemctl daemon-reload
systemctl enable roc-site
systemctl restart roc-site
systemctl --no-pager status roc-site | grep -E "service -|Active"
echo "caddy: $(/usr/local/bin/caddy version)"
sha256sum /usr/local/bin/caddy /etc/roc-site/Caddyfile /etc/systemd/system/roc-site.service

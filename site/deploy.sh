#!/bin/bash
# THE PROD DEPLOY: staging, verbatim, to https://roc.lynrummy.com. Run it on
# Steve's sign-off of what staging shows.
#
#   site/deploy.sh
#
# 1. Refuses when roc.lynrummy.com does not resolve to the prod droplet, when
#    site/live/ or the site block has uncommitted changes, or when prod's
#    Caddyfile does not import /etc/caddy/sites/*.caddy. That Caddyfile is
#    angry-gopher's deploy/Caddyfile; this script never edits it.
# 2. Pushes, then copies site/live/ to /srv/roc-site/ on the droplet with
#    rsync --delete, and proves the copy verbatim: every file's sha256 on prod
#    must equal staging's, and no file may be missing or extra.
# 3. Installs ops/roc.lynrummy.com.caddy in /etc/caddy/sites/ when it differs
#    from prod's copy. Caddy validates the whole config before the reload, and
#    the old block goes back if the new one fails.
# 4. The landing page and a module must answer over HTTPS, and the landing
#    page must be staging's byte for byte.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
HOST=steve@162.243.1.123
IP=162.243.1.123
DIR=/srv/roc-site
BLOCK=roc.lynrummy.com.caddy
URL=https://roc.lynrummy.com

ip="$(dig +short @1.1.1.1 A roc.lynrummy.com | tail -1)"
[ "$ip" = "$IP" ] || { echo "roc.lynrummy.com resolves to '$ip', not $IP; the DNS record comes first"; exit 1; }
[ -z "$(git -C "$REPO" status --porcelain -- site/live "ops/$BLOCK")" ] || { echo "site/live/ or ops/$BLOCK has uncommitted changes"; exit 1; }
ssh "$HOST" "grep -qxF 'import /etc/caddy/sites/*.caddy' /etc/caddy/Caddyfile" || { echo "prod's Caddyfile does not import /etc/caddy/sites/*.caddy"; exit 1; }
git -C "$REPO" push -q

echo "copying site/live/ at $(git -C "$REPO" log -1 --format=%h -- site/live) to $HOST:$DIR/"
ssh "$HOST" "sudo install -d -o steve -g steve -m 755 $DIR"
rsync -rlt --delete --chmod=D755,F644 "$HERE/live/" "$HOST:$DIR/"
manifest='find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum'
if ! diff <(cd "$HERE/live" && eval "$manifest") <(ssh "$HOST" "cd $DIR && $manifest"); then
    echo "prod's files are not staging's"; exit 1
fi
echo "$(find "$HERE/live" -type f | wc -l) files on prod, each staging's"

if ssh "$HOST" "cmp -s - /etc/caddy/sites/$BLOCK" < "$REPO/ops/$BLOCK"; then
    echo "the site block is unchanged"
else
    echo "installing the site block"
    scp -q "$REPO/ops/$BLOCK" "$HOST:/tmp/$BLOCK"
    ssh "$HOST" "set -e
        sudo install -d -m 755 /etc/caddy/sites
        [ -f /etc/caddy/sites/$BLOCK ] && sudo cp /etc/caddy/sites/$BLOCK /tmp/$BLOCK.old || rm -f /tmp/$BLOCK.old
        sudo install -m 644 /tmp/$BLOCK /etc/caddy/sites/$BLOCK
        if ! sudo caddy validate --adapter caddyfile --config /etc/caddy/Caddyfile >/tmp/$BLOCK.validate 2>&1; then
            tail -5 /tmp/$BLOCK.validate
            if [ -f /tmp/$BLOCK.old ]; then sudo install -m 644 /tmp/$BLOCK.old /etc/caddy/sites/$BLOCK; else sudo rm -f /etc/caddy/sites/$BLOCK; fi
            echo 'the new block did not validate; the old one is back'; exit 1
        fi
        sudo systemctl reload caddy
        rm -f /tmp/$BLOCK /tmp/$BLOCK.old /tmp/$BLOCK.validate"
fi

# A new name's certificate takes Caddy a few seconds to obtain.
for _ in $(seq 1 30); do curl -fsS -o /dev/null "$URL/" 2>/dev/null && break; sleep 2; done
curl -fsS "$URL/" | cmp -s - "$HERE/live/index.html" || { echo "$URL/ is not staging's landing page"; exit 1; }
curl -fsS -o /dev/null -w "safari.wasm: %{http_code} %{content_type} %{size_download} bytes\n" "$URL/safari/safari.wasm"
echo "prod: $URL/"

#!/bin/bash
# deploy-gate.sh: the forced command of the deploy key on prod (its line in
# the deploy user's ~/.ssh/authorized_keys starts `command="..."`; README.md
# here). sshd runs it in place of whatever a connection asks, with the asked
# command in SSH_ORIGINAL_COMMAND, and it runs that command only when it is
# one that roc-apps' site/deploy.shale or roc-chat's tools/deploy.shale
# sends, word for word; anything else (a shell, sftp, a command of an
# attacker's) is refused and logged. It is root's, at
# /usr/local/lib/deploy-gate/deploy-gate.sh, so the deploy user cannot
# change it.
#
# The commands are copied from the two deploys. When a deploy's remote
# command changes, this file changes in the same commit, and
# ops/prod/check_deploy_gate.shale (run on the box) holds the two to each
# other.
#
#   deploy-gate.sh            sshd's forced command: check, then run
#   deploy-gate.sh --check    say `allowed` or `refused` for
#                             SSH_ORIGINAL_COMMAND, run nothing (the test's)
set -u
cmd="${SSH_ORIGINAL_COMMAND:-}"
home="${HOME:?}"

# ── roc-apps: site/deploy.shale ─────────────────────────────────────────
SITE=/srv/roc-site
B=/etc/caddy/sites/roc.lynrummy.com.caddy
T=/tmp/roc.lynrummy.com.caddy
roc_apps_commands() {
    printf '%s\0' \
        "grep -qxF 'import /etc/caddy/sites/*.caddy' /etc/caddy/Caddyfile" \
        "grep -q '^(access_log) {' /etc/caddy/Caddyfile" \
        "sudo install -d -o \"\$(id -un)\" -g \"\$(id -un)\" -m 755 $SITE" \
        "cd $SITE && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum" \
        "cd $SITE && find . ! -type f ! -type d -print" \
        "cmp -s - $B"
    printf '%s\0' "set -e
sudo install -d -m 755 /etc/caddy/sites
# The block's access log, Caddy's before validate: validate runs as root
# and would make it root's, and the reload would then fail.
[ -f /var/log/caddy/roc-access.log ] || sudo install -o caddy -g caddy -m 640 /dev/null /var/log/caddy/roc-access.log
[ -f $B ] && sudo cp $B $T.old || sudo rm -f $T.old
sudo install -m 644 $T $B
if ! sudo caddy validate --adapter caddyfile --config /etc/caddy/Caddyfile >$T.validate 2>&1; then
  tail -5 $T.validate
  if [ -f $T.old ]; then sudo install -m 644 $T.old $B; else sudo rm -f $B; fi
  echo 'the new block did not validate; the old one is back'; exit 1
fi
sudo systemctl reload caddy
# sudo cp made the .old root's, and /tmp is sticky, so only root removes it.
rm -f $T $T.validate
sudo rm -f $T.old"
}

# ── roc-chat: tools/deploy.shale ────────────────────────────────────────
DATA=/var/lib/roc-chat/data
CB=/etc/caddy/sites/chat.lynrummy.com.caddy
CLOG=/var/log/caddy/chat-access.log
UNIT=/etc/systemd/system/roc-chat.service
# Every command of the deploy that names no staging folder.
roc_chat_fixed() {
    printf '%s\0' \
        "grep -qxF 'import /etc/caddy/sites/*.caddy' /etc/caddy/Caddyfile" \
        "grep -q '^(access_log) {' /etc/caddy/Caddyfile" \
        "set -e
id rocchat >/dev/null 2>&1 || sudo useradd --system --home-dir /var/lib/roc-chat --no-create-home --shell /usr/sbin/nologin rocchat
sudo install -d -o root -g root -m 755 /opt/roc-chat
sudo install -d -o rocchat -g rocchat -m 700 /var/lib/roc-chat $DATA" \
        "mktemp -d -p \"\$HOME\" roc-chat-deploy.XXXXXXXX" \
        "sudo install -d -o root -g root -m 755 /opt/roc-chat/admin" \
        "set -e
sudo systemctl restart roc-chat
for _ in \$(seq 1 50); do curl -fsS -o /dev/null http://127.0.0.1:9611/login 2>/dev/null && break; sleep 0.1; done
systemctl is-active roc-chat
curl -fsS -o /dev/null http://127.0.0.1:9611/login"
    local f
    for f in .github-client-id .github-client-secret auth/1/name auth/next-id.txt chat/channel/general.channel .session-secret auth/1/github-id; do
        printf '%s\0' "sudo test -s $DATA/$f"
    done
}
# Every command of the deploy that names its staging folder `$1`.
roc_chat_staged() {
    local S="$1" pair base dest mode
    for pair in "roc-chat /opt/roc-chat/roc-chat 755" "shale /opt/roc-chat/shale 755" \
        "chat_data.shale /opt/roc-chat/admin/chat_data.shale 644" \
        "user_footprint.shale /opt/roc-chat/admin/user_footprint.shale 644" \
        "remove_user.shale /opt/roc-chat/admin/remove_user.shale 644" \
        "read.mounts /opt/roc-chat/admin/read.mounts 644" \
        "write.mounts /opt/roc-chat/admin/write.mounts 644"; do
        read -r base dest mode <<< "$pair"
        printf '%s\0' "sha256sum $S/$base.new" "set -e
sudo install -o root -g root -m $mode $S/$base.new $dest.new
sudo mv -f $dest.new $dest
rm -f $S/$base.new"
    done
    printf '%s\0' \
        "[ -f $UNIT ] && cmp -s $S/roc-chat.service $UNIT" \
        "set -e
sudo install -o root -g root -m 644 $S/roc-chat.service $UNIT
sudo systemctl daemon-reload
sudo systemctl enable roc-chat" \
        "rm -f $S/roc-chat.service" \
        "[ -f $CB ] && cmp -s $S/chat.lynrummy.com.caddy $CB" \
        "set -e
sudo install -d -m 755 /etc/caddy/sites
# The log is made Caddy's before validate, which runs as root and would make it root's.
[ -f $CLOG ] || sudo install -o caddy -g caddy -m 640 /dev/null $CLOG
if [ -f $CB ]; then sudo cp $CB $S/chat.lynrummy.com.caddy.old; else rm -f $S/chat.lynrummy.com.caddy.old; fi
sudo install -m 644 $S/chat.lynrummy.com.caddy $CB
if ! sudo caddy validate --adapter caddyfile --config /etc/caddy/Caddyfile >$S/chat.lynrummy.com.caddy.validate 2>&1; then
  tail -5 $S/chat.lynrummy.com.caddy.validate
  if [ -f $S/chat.lynrummy.com.caddy.old ]; then sudo install -m 644 $S/chat.lynrummy.com.caddy.old $CB; else sudo rm -f $CB; fi
  echo 'the new block did not validate; the old one is back'; exit 1
fi
sudo systemctl reload caddy
rm -f $S/chat.lynrummy.com.caddy.old $S/chat.lynrummy.com.caddy.validate" \
        "rm -f $S/chat.lynrummy.com.caddy" \
        "rm -rf $S"
}

# Whether `$cmd` is one of the NUL-separated commands on stdin, exactly.
one_of() {
    local c
    while IFS= read -r -d '' c; do
        [ "$cmd" == "$c" ] && return 0
    done
    return 1
}

# The staging folder roc-chat's deploy made, as the command names it: the
# deploy user's home, then `roc-chat-deploy.` and mktemp's eight letters.
staged_re="^.*($home/roc-chat-deploy\\.[A-Za-z0-9]{8})([/ ].*)?\$"
# A copy into prod by scp's original protocol (`scp -O` on the box), to a
# place the deploys copy to: `scp -t <path>`, times kept (`-p`) or not.
copy_re_site="^scp( -p)? -t $T\$"
copy_re_chat="^scp( -p)? -t ($home/roc-chat-deploy\\.[A-Za-z0-9]{8})/(roc-chat|shale|chat_data\\.shale|user_footprint\\.shale|remove_user\\.shale|read\\.mounts|write\\.mounts)\\.new\$|^scp( -p)? -t ($home/roc-chat-deploy\\.[A-Za-z0-9]{8})/(roc-chat\\.service|chat\\.lynrummy\\.com\\.caddy)\$"
# rsync's own server for site/deploy.shale's copy: it writes $SITE alone
# (no --sender, which would read), with the deploy's options.
rsync_re="^rsync --server -[A-Za-z.]+ --delete --chmod=D755,F644 \\. $SITE/\$"

allowed=no
if roc_apps_commands | one_of || roc_chat_fixed | one_of; then
    allowed=yes
elif [[ "$cmd" =~ $copy_re_site ]] || [[ "$cmd" =~ $copy_re_chat ]] || [[ "$cmd" =~ $rsync_re ]]; then
    allowed=yes
elif [[ "$cmd" =~ $staged_re ]] && roc_chat_staged "${BASH_REMATCH[1]}" | one_of; then
    allowed=yes
fi

if [ "${1:-}" = --check ]; then
    if [ "$allowed" = yes ]; then echo allowed; else echo refused; fi
    exit 0
fi
if [ "$allowed" != yes ]; then
    logger -t deploy-gate -p auth.warning "refused: ${cmd:0:200}"
    echo "deploy-gate: refused: this key runs the deploys' own commands alone" >&2
    exit 1
fi
logger -t deploy-gate -p auth.info "allowed: ${cmd:0:120}"
exec /bin/sh -c "$cmd"

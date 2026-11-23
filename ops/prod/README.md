# ops/prod: the deploy key's fences on prod (prepared, not installed)

Two files that narrow what the deploy key can do on the prod droplet, for the
box's owner to install by hand. Neither is on prod yet, and nothing here
names the droplet: its `user@address` is the secret `keys:prod-ssh`, as the
deploys read it.

- **`deploy-gate.sh`**, the key's forced command: sshd runs it in place of
  whatever a connection asks, and it runs the asked command only when it is
  one that `site/deploy.shale` (here) or roc-chat's `tools/deploy.shale`
  sends, word for word (roc-chat's staging folder, mktemp's
  `roc-chat-deploy.XXXXXXXX` under the deploy user's home, is the one part
  it reads as a pattern), or rsync's and scp's own server for those
  deploys' copies. Anything else, a shell, sftp, or a deploy's command with
  something added, is refused and logged (`journalctl -t deploy-gate`).
- **`deploy.sudoers`**, `/etc/sudoers.d/deploy`: the deploy user may run as
  root exactly the `sudo` commands those deploys run, nothing else.

`check_deploy_gate.shale` holds `deploy-gate.sh` to the two deploys on this
box, with no prod: `shale ops/prod/check_deploy_gate.shale` from roc-apps'
root builds each command as the deploys build it, and each must be allowed,
then 27 near misses and attacks must each be refused. **A change to either
deploy's remote commands changes `deploy-gate.sh`, `deploy.sudoers` and the
check in the same commit**, or the next deploy is refused at the step that
changed.

## Before: scp's original protocol

OpenSSH's scp speaks SFTP by default, which reaches sshd as a subsystem, not
a command a forced command can hold to its paths, so `deploy-gate.sh`
refuses it. The deploys' scp calls take `-O` (the original protocol, under
which prod runs `scp -t <path>`) first:

1. Install a Shale whose unconfined scp takes `-O` (the Shale branch
   `security-after-landlock`, from cfbf6d8b on).
2. Add `"-O",` after `"-q",` in the scp argv of `site/deploy.shale` (the
   site block's copy) and of roc-chat's `tools/deploy.shale`
   (`copy_to_prod`), commit, and run each deploy once as it is now, to see
   that it still works.

## Install

On prod, as a user who may sudo (the `user@address` of `keys:prod-ssh`; here
`DEPLOY_USER` is its user part). Copy the two files there first (from the
box: `scp -O ops/prod/deploy-gate.sh ops/prod/deploy.sudoers <user>@<address>:`).

    # the gate, root's
    sudo install -d -o root -g root -m 755 /usr/local/lib/deploy-gate
    sudo install -o root -g root -m 755 deploy-gate.sh /usr/local/lib/deploy-gate/deploy-gate.sh

    # the sudoers file: the user's name filled in, checked, then live
    sed "s/DEPLOY_USER/$(id -un)/g" deploy.sudoers > deploy.sudoers.filled
    sudo visudo -cf deploy.sudoers.filled
    sudo install -o root -g root -m 440 deploy.sudoers.filled /etc/sudoers.d/deploy
    sudo -l          # lists the deploy commands; check `sudo -n true` is refused

    # the key's line in ~/.ssh/authorized_keys: prefixed with the forced
    # command and no forwarding, the key itself unchanged
    #   command="/usr/local/lib/deploy-gate/deploy-gate.sh",no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty ssh-ed25519 AAAA... comment

Keep a second session open while editing `authorized_keys`, and keep a way
in that is not this key (DigitalOcean's console, or another key without the
forced command), or a mistake locks the user out.

Then run `shale site/deploy.shale` here, and roc-chat's deploy: each runs as
before. A refused step says so in its output (ssh's own messages are off, so
`journalctl -t deploy-gate` on prod says which command), and the user's
general sudo is gone: if that user had a broad sudoers entry before (the
`sudo` group, or a file in /etc/sudoers.d), remove it, or this file narrows
nothing.

## Roll back

- The forced command: remove the `command="..."` prefix (and the `no-*`
  options) from the key's line in `~/.ssh/authorized_keys`.
- The sudoers file: `sudo rm /etc/sudoers.d/deploy`, and put back the entry
  the user had before (as root, from the console, if the user's sudo is
  gone).
- `/usr/local/lib/deploy-gate` can stay; nothing runs it once the key's line
  no longer names it.

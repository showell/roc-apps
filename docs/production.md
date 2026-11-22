# Production: how lynrummy.com is served

This is the map of everything served under lynrummy.com, for a reader who
has to change or debug it. Each site's own steps stay in the repo that owns
it, and this doc points to them. Where this doc and an owning repo's file
disagree, the file is right, so fix this doc.

The hosts' addresses and how to reach them (ssh users, which secrets exist
and where they live) are in a private note on the development box. This
repo names none of them, and the deploy scripts take the host as an
argument.

## The droplets

Two droplets serve the domain.

- **The prod droplet** runs Caddy, which holds every certificate and is the
  only way in from the internet. It also runs roc-chat's server, holds
  roc.lynrummy.com's files, and keeps angry-gopher's watchdog script and its
  Linux server, which is stopped.
- **The metal droplet** runs zig-metal-unikernel, which serves lynrummy.com
  itself (Lyn Rummy and the rest of angry-gopher's program). Caddy on prod
  reaches it over the private network. It has no public name of its own.

## Caddy

- **The main Caddyfile** is angry-gopher's
  [`deploy/Caddyfile`](https://github.com/showell/angry-gopher/blob/master/deploy/Caddyfile),
  installed as `/etc/caddy/Caddyfile` by hand, as angry-gopher's
  [`deploy/README.md`](https://github.com/showell/angry-gopher/blob/master/deploy/README.md)
  says (step 5). It moves here when angry-gopher is retired. It holds the
  global options, the `access_log` snippet, lynrummy.com's block and a
  catch-all for requests to the bare address, and its last line imports
  `/etc/caddy/sites/*.caddy`.
- **Every other site is one file in `/etc/caddy/sites/`**, owned by one
  repo and installed by that repo's deploy. No deploy edits the main
  Caddyfile, and each deploy refuses to run when it does not import the
  folder or does not define `access_log`.

| File in `/etc/caddy/sites/` | Its source | Installed by |
|---|---|---|
| `roc.lynrummy.com.caddy` (roc and dogpark) | roc-apps `ops/roc.lynrummy.com.caddy` | roc-apps `site/deploy.shale` |
| `chat.lynrummy.com.caddy` | roc-chat `deploy/chat.lynrummy.com.caddy` | roc-chat `tools/deploy.shale` |

- **Every site logs.** Each block starts with `import access_log <name>`,
  which writes every request as JSON to `/var/log/caddy/<name>-access.log`,
  rolled at 10 MiB with five kept. The names are `lynrummy`, `knock` (the
  bare address), `roc`, `dogpark` and `chat`. angry-gopher's
  `deploy/check_caddy_logs.py` fails on a block without the import. A
  log must be Caddy's before `caddy validate` runs, since validate runs as
  root and would make it root's and the reload would then fail; both
  deploys make the log first.
- **TLS is automatic.** Caddy gets and renews each name's Let's Encrypt
  certificate and redirects HTTP to HTTPS. A new name's first certificate
  takes it a few seconds.
- **A deploy that changes a block validates the whole config first** and
  puts the old block back when the new one fails. A reload ends every open
  stream on every site, and roc-chat's pages and agents reconnect.

## The sites

### lynrummy.com: Lyn Rummy (angry-gopher)

angry-gopher is the program, and it owns this site until Lyn Rummy moves
to a regular Linux host. Its block caps request bodies, sets the security
headers, sends the old chat paths (`/chat`, `/chat/*`, `/channel/*`) to
chat.lynrummy.com with a 302, and proxies everything else to the metal
droplet. `/version` reports the running build's commit.

- **Deploying** is a new zig-metal-unikernel image, released by that repo's
  [DEPLOY.md](https://github.com/showell/zig-metal-unikernel/blob/master/DEPLOY.md).
  The metal stack is retired from development: its last release is tagged
  `last-on-metal`, and metal keeps serving that release until the move.
- angry-gopher's `ops/deploy` fails closed: while metal serves, it only
  refreshes the watchdog on prod. The Linux server on prod is the fallback,
  and angry-gopher's `deploy/README.md` says how it is set up and when it
  serves.

### chat.lynrummy.com: roc-chat

roc-chat's server runs on prod as the systemd unit `roc-chat`
(`deploy/roc-chat.service`), as its own system user, listening on
127.0.0.1 alone, behind Caddy's `reverse_proxy`. Its one writable folder is
`/var/lib/roc-chat`, which holds the data root: the whole chat and its
secrets.

- **Deploying** is `shale tools/deploy.shale` from roc-chat's root, on a
  clean `main` that has passed `shale tools/verify.shale`. It takes no
  argument: its ssh destination is the same secret, `keys:prod-ssh`, as
  roc.lynrummy.com's deploy (below), through `secret_args` alike. By
  the repo's policy an agent runs it after a verified change; every other
  step that writes to prod is the owner's.
- roc-chat's [`docs/deploy.md`](https://github.com/showell/roc-chat/blob/main/docs/deploy.md)
  is the runbook: where each file lives on prod, the first start's seeding,
  the GitHub setup, the smoke test, what Caddy must and must not do, and
  the pitfalls.

### roc.lynrummy.com: Steve's Roc Apps (this repo)

Static files, served by Caddy's `file_server` from `/srv/roc-site/`. A page
moves through three channels unchanged (README, "The site: Steve's Roc
Apps"):

- **dev** is what the build scripts last wrote, on this box's Caddy
  (`ops/Caddyfile`);
- **staging** is `site/live/`, tracked, which only `site/publish.sh`,
  `site/publish_screensavers.shale` and `site/publish_safari_walk.shale`
  write. The screensavers' sources are in roc-screensaver and Safari Walk's
  in safari-walk; they reach prod only through staging here;
- **prod** is staging's files verbatim.

**Deploying** is `shale site/deploy.shale`, run on the owner's sign-off
of what staging shows. It takes no argument: the droplet's ssh destination,
`<user>@<IPv4>`, is the secret `keys:prod-ssh`, stored once with `shale
--secrets`, which reaches ssh, rsync and scp only through Shale's
`secret_args`, so no script, log or report on this box shows it. It
refuses when the name does not resolve to that address or `site/live/` has
uncommitted changes, copies `site/live/`
with `rsync --delete`, proves every file's sha256, installs the site block
when it changed, and checks the landing page over HTTPS. Its header lists
every step.

### dogpark.lynrummy.com: a redirect (this repo)

Dog Park's old address. Its block, in `ops/roc.lynrummy.com.caddy`, sends
every path to https://roc.lynrummy.com/dog-park/ with a 302, and it ships
with roc.lynrummy.com's deploy.

## Security headers and HSTS

Every site block sends
`Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`,
the dogpark redirect included. The three sites that serve pages also send
`Referrer-Policy: strict-origin-when-cross-origin`,
`X-Frame-Options: SAMEORIGIN` and `X-Content-Type-Options: nosniff`
(roc-chat's app sends that last one itself, and its block must not add a
second copy). roc.lynrummy.com adds `Cache-Control: no-cache` and the
cross-origin isolation headers its pages need.

**lynrummy.com was submitted for the HSTS preload list on 2026-11-22.** Once
it is on the list, browsers reach the domain and every subdomain over HTTPS
only, whatever the site sends, and leaving the list takes months. So every
subdomain must stay HTTPS-only: a new name gets a Caddy block (and so a
certificate) before anything links to it, a block keeps the HSTS header
above, and no subdomain may need plain HTTP, ever.

## Logs

- **Caddy's access logs**, on prod: `/var/log/caddy/<name>-access.log`, one
  per site (above).
- **roc-chat's own log** is its journal: `journalctl -u roc-chat`.
  roc-chat's `docs/deploy.md` has the read-only command that shows the
  service's state, its journal and its access log at once.
- **angry-gopher's `ops/knocks`** reads every access log, rotated ones too,
  and sshd's last day in one ssh, and reports each site's traffic, scanners
  and errors. `ops/knocks.conf` holds the sites it alarms on; a site
  missing there (`chat`, today) is reported but never alarms.
- **angry-gopher's watchdog** (`deploy/watchdog.py`, kept on prod and run
  by hand) checks metal's `/version`, its clock and uptime, and the prod
  droplet's memory and disk.

## What's retired

- **The metal stack** (webbox, zig-metal-unikernel and their siblings) is
  retired from development and off the development box. The metal droplet
  still serves lynrummy.com at the `last-on-metal` release until Lyn Rummy
  moves to Linux.
- **metal.lynrummy.com** has no DNS record. Old notes that link to it are
  stale.
- **Gopher Chat** is retired in favour of roc-chat. lynrummy.com's block
  redirects its old paths.

## When something breaks, look here first

1. **Which name, and does it resolve?** Every deploy checks that the name
   resolves to the prod droplet (through 1.1.1.1). A name that resolves
   elsewhere, or not at all, is DNS's problem, not Caddy's.
2. **Every site down at once:** Caddy. A reload that failed leaves the old
   config running, so look for a failed reload (often a log file left
   root's) before suspecting the sites.
3. **lynrummy.com alone gives 502:** Caddy cannot reach metal. Run the
   watchdog on prod; it says whether metal's `/version` answers.
4. **chat.lynrummy.com:** `systemctl is-active roc-chat` and its journal
   (roc-chat's `docs/deploy.md`, "Deploying"). The server refuses to start
   when a secret file is open to others, and reads the GitHub files only at
   its start. Its "Pitfalls" section has the rest.
5. **roc.lynrummy.com shows the wrong page:** it is staging's files
   verbatim, so compare it with `site/live/` and the last deploy's commit;
   a deploy that finished proved every file.
6. **Strange traffic:** angry-gopher's `ops/knocks`.

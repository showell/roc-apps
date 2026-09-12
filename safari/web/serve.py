#!/usr/bin/env python3
"""Serve this directory for an eye test, no-store on everything.

    safari/web/serve.py [port] [root]     # default 9201, this directory

A copy of safari-codex's harness/serve.py: the no-store header is the point,
because a cached safari.wasm looks exactly like a build that changed nothing.
Four services run it: safari-web on :9201 over this directory (the demo,
whose module only safari/publish.sh writes), safari-web-next on :9203 over
~/build/roc-apps/next (whatever the build scripts last built), gallery-web
on :9204 over gpu/live and games-web on :9205 over games/live (which only
their publish.sh scripts write).
"""
import functools
import http.server
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, must-revalidate')
        super().end_headers()


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 9201
    root = pathlib.Path(sys.argv[2]).expanduser() if len(sys.argv) > 2 else ROOT
    handler = functools.partial(Handler, directory=str(root))
    with http.server.ThreadingHTTPServer(('0.0.0.0', port), handler) as httpd:
        print(f'serving {root} on http://0.0.0.0:{port}  (no-store)', flush=True)
        httpd.serve_forever()


if __name__ == '__main__':
    main()

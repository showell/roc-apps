#!/usr/bin/env python3
"""Serve this directory for an eye test, no-store on everything.

    safari/web/serve.py [port]        # default 9201

A copy of safari-codex's harness/serve.py with this directory as root: the
no-store header is the point, because a cached safari.wasm looks exactly like
a build that changed nothing. blitter.js is a symlink to safari-codex's fork,
the same JavaScript that draws the Codex module; only driving/safari.wasm is
ours.
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
    handler = functools.partial(Handler, directory=str(ROOT))
    with http.server.ThreadingHTTPServer(('0.0.0.0', port), handler) as httpd:
        print(f'serving {ROOT} on http://0.0.0.0:{port}  (no-store)', flush=True)
        httpd.serve_forever()


if __name__ == '__main__':
    main()

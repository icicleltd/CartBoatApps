"""Local preview server for the Flutter *web* build.

Serves build/web and forwards /api/* to the real backend so the browser sees
a single origin (the backend's CORS list doesn't include arbitrary localhost
ports). Mobile builds talk to the backend directly and don't need this.

  flutter build web --dart-define=API_BASE_URL=http://localhost:3100/api/v1
  python tool/dev_web_proxy.py            # then open http://localhost:3100
"""
import http.server
import os
import sys
import urllib.error
import urllib.request

PORT = int(os.environ.get('PORT', '3100'))
BACKEND = os.environ.get('BACKEND', 'https://multivendorbackend.vercel.app')
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'build', 'web')
FORWARD_HEADERS = ('authorization', 'content-type', 'accept')


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        # Always serve the latest build while iterating.
        self.send_header('cache-control', 'no-store')
        super().end_headers()

    def _proxy(self):
        length = int(self.headers.get('content-length') or 0)
        body = self.rfile.read(length) if length else None
        req = urllib.request.Request(BACKEND + self.path, data=body, method=self.command)
        for k, v in self.headers.items():
            if k.lower() in FORWARD_HEADERS:
                req.add_header(k, v)
        try:
            with urllib.request.urlopen(req, timeout=40) as res:
                status, payload, ctype = res.status, res.read(), res.headers.get('content-type', 'application/json')
        except urllib.error.HTTPError as e:
            status, payload, ctype = e.code, e.read(), e.headers.get('content-type', 'application/json')
        except Exception as e:  # network failure
            status, payload, ctype = 502, ('{"success":false,"message":"%s"}' % e).encode(), 'application/json'
        self.send_response(status)
        self.send_header('content-type', ctype)
        self.send_header('content-length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        if self.path.startswith('/api/'):
            return self._proxy()
        if not os.path.exists(os.path.join(ROOT, self.path.split('?')[0].lstrip('/'))):
            self.path = '/'  # SPA fallback
        return super().do_GET()

    def do_POST(self):
        return self._proxy()

    def do_PATCH(self):
        return self._proxy()

    def do_PUT(self):
        return self._proxy()

    def do_DELETE(self):
        return self._proxy()


if __name__ == '__main__':
    print(f'CartBoat web preview on http://localhost:{PORT} -> {BACKEND}')
    http.server.ThreadingHTTPServer(('127.0.0.1', PORT), Handler).serve_forever()

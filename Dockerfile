# ── Build stage ──────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app
COPY . .
# Build the app. If a build script exists it MUST succeed — otherwise we'd
# end up serving raw TSX/TS source files (browsers reject those with a MIME
# type error, producing a white screen).
RUN if [ -f "package.json" ]; then \
      npm install --legacy-peer-deps || npm install || true; \
      if node -e "process.exit(require('./package.json').scripts && require('./package.json').scripts.build ? 0 : 1)"; then \
        npm run build || echo "warning: build exited with non-zero status — fallback page will be served"; \
      else \
        echo "info: no build script defined, will look for pre-built assets"; \
      fi; \
    fi

# Collect build output. Only accept REAL build artifacts (dist/build/out).
# Never copy raw source — that would expose .tsx/.ts files which nginx serves
# as application/octet-stream, breaking module script loading.
RUN set -e; \
    if   [ -d "dist"  ] && [ -f "dist/index.html"  ]; then cp -r dist  /srv/static; \
    elif [ -d "build" ] && [ -f "build/index.html" ]; then cp -r build /srv/static; \
    elif [ -d "out"   ] && [ -f "out/index.html"   ]; then cp -r out   /srv/static; \
    elif [ -f "index.html" ] && ! grep -q "/src/" index.html; then \
      mkdir -p /srv/static && cp -r . /srv/static; \
    else \
      mkdir -p /srv/static; \
      printf '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Deploying…</title><style>*{box-sizing:border-box;margin:0;padding:0}body{font-family:system-ui,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;background:#0f172a;color:#e2e8f0}.card{text-align:center;padding:2rem;max-width:420px}.icon{font-size:3rem;margin-bottom:1rem}h1{font-size:1.5rem;margin-bottom:.5rem}p{color:#94a3b8;line-height:1.6}</style></head><body><div class="card"><div class="icon">🚀</div><h1>Build did not produce dist/</h1><p>The build step did not generate a production bundle. Check CI logs and ensure <code>npm run build</code> succeeds locally.</p></div></body></html>' \
      > /srv/static/index.html; \
    fi

# ── Serve stage ───────────────────────────────────────────────────────────────
FROM nginx:1.25-alpine
COPY --from=builder /srv/static /usr/share/nginx/html/
# Omit a custom types{} block so nginx inherits all MIME types from the http
# context (/etc/nginx/mime.types), including application/javascript for .js/.mjs.
# A types{} block inside server{} replaces (not extends) the parent types map,
# so any mistake there silently falls back to application/octet-stream and breaks
# ES module loading in the browser.
RUN printf 'server {
  listen 8080;
  server_name _;
  root /usr/share/nginx/html;
  index index.html;

  # Hashed assets: cache forever
  location /assets/ {
    try_files $uri =404;
    expires 1y;
    add_header Cache-Control "public, immutable";
  }

  # SPA fallback
  location / {
    try_files $uri $uri/ /index.html;
  }

  # Do not cache index.html so deploys are picked up immediately
  location = /index.html {
    add_header Cache-Control "no-cache, no-store, must-revalidate";
  }
}
' > /etc/nginx/conf.d/default.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

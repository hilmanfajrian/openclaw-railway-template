#!/bin/bash
set -e

chown -R openclaw:openclaw /data
chmod 700 /data

if [ ! -d /data/.linuxbrew ]; then
 cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
fi

rm -rf /home/linuxbrew/.linuxbrew
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

# PATCH 1: strip gateway.tools
node -e "
  const fs = require('fs');
  const p = '/data/.openclaw/openclaw.json';
  try {
    const c = JSON.parse(fs.readFileSync(p, 'utf8'));
    if (c.gateway && c.gateway.tools) {
      delete c.gateway.tools;
      fs.writeFileSync(p, JSON.stringify(c, null, 2));
      console.log('[patch1] stripped gateway.tools');
    }
  } catch(e) { console.log('[patch1] no-op:', e.message); }
" || true

# PATCH 2: inject hooks.token dari env var OPENCLAW_HOOKS_TOKEN
node -e "
  const fs = require('fs');
  const p = '/data/.openclaw/openclaw.json';
  const token = process.env.OPENCLAW_HOOKS_TOKEN;
  if (!token) { console.log('[patch2] no token, skip'); process.exit(0); }
  try {
    const c = JSON.parse(fs.readFileSync(p, 'utf8'));
    if (!c.hooks || !c.hooks.enabled) { console.log('[patch2] hooks not enabled, skip'); process.exit(0); }
    if (c.hooks.token === token) { console.log('[patch2] token ok, skip'); process.exit(0); }
    c.hooks.token = token;
    fs.writeFileSync(p, JSON.stringify(c, null, 2));
    console.log('[patch2] hooks.token injected');
  } catch(e) { console.log('[patch2] no-op:', e.message); }
" || true

# PATCH 3: re-inject JSON body di server.js proxyReq
node -e "
  const fs = require('fs');
  const p = '/app/src/server.js';
  const marker = '// PATCH: re-inject parsed JSON body';
  try {
    let content = fs.readFileSync(p, 'utf8');
    if (content.includes(marker)) { console.log('[patch3] already patched, skip'); process.exit(0); }
    const target = 'proxyReq.setHeader(\"Origin\", PROXY_ORIGIN);\n});';
    if (!content.includes(target)) { console.log('[patch3] target not found, skip'); process.exit(0); }
    const patch = 'proxyReq.setHeader(\"Origin\", PROXY_ORIGIN);\n  ' + marker + '\n  if (req.body && typeof req.body === \"object\" && req.method === \"POST\") {\n    const bodyData = JSON.stringify(req.body);\n    proxyReq.setHeader(\"Content-Type\", \"application/json\");\n    proxyReq.setHeader(\"Content-Length\", Buffer.byteLength(bodyData));\n    proxyReq.write(bodyData);\n  }\n});';
    fs.writeFileSync(p, content.replace(target, patch));
    console.log('[patch3] body re-injection patched');
  } catch(e) { console.log('[patch3] no-op:', e.message); }
" || true

gosu openclaw openclaw plugins install @openclaw/whatsapp || true

exec gosu openclaw node src/server.js

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

gosu openclaw openclaw plugins install @openclaw/whatsapp || true

exec gosu openclaw node src/server.js

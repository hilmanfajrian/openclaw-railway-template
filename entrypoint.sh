#!/bin/bash
set -e

chown -R openclaw:openclaw /data
chmod 700 /data

if [ ! -d /data/.linuxbrew ]; then
 cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
fi

rm -rf /home/linuxbrew/.linuxbrew
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

node -e "
  const fs = require('fs');
  const p = '/data/.openclaw/openclaw.json';
  try {
    const c = JSON.parse(fs.readFileSync(p, 'utf8'));
    if (c.gateway && c.gateway.tools) {
      delete c.gateway.tools;
      fs.writeFileSync(p, JSON.stringify(c, null, 2));
      console.log('[patch] stripped gateway.tools');
    }
  } catch(e) { console.log('[patch] no-op:', e.message); }
" || true

gosu openclaw openclaw plugins install @openclaw/whatsapp || true

exec gosu openclaw node src/server.js

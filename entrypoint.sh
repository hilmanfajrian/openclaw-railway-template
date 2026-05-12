# ═══════════════════════════════════════════════════════
# TEMPORARY PATCH — 2026-05-12
# Strip gateway.tools dari openclaw.json karena field ini
# tidak dikenali di OpenClaw 2026.4.23 (versi Hani saat ini).
# HAPUS BLOK INI SETELAH:
#   - OpenClaw Hani di-upgrade ke versi yang support gateway.tools
#   - ATAU diputuskan pakai alternatif lain (Supabase webhook, dll)
# Context: Hani down ~30 menit karena gateway crash loop
# ═══════════════════════════════════════════════════════
node -e "
  const fs = require('fs');
  const p = '/data/.openclaw/openclaw.json';
  try {
    const c = JSON.parse(fs.readFileSync(p, 'utf8'));
    if (c.gateway && c.gateway.tools) {
      delete c.gateway.tools;
      fs.writeFileSync(p, JSON.stringify(c, null, 2));
      console.log('[patch] stripped gateway.tools from openclaw.json');
    }
  } catch(e) { console.log('[patch] no-op:', e.message); }
" || true

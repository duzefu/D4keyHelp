// 扫描源码里用到的全部字符，从 Google Fonts 拉取对应子集，保存到 src/fonts/
const fs = require('fs'), path = require('path');
const SRC = path.join(__dirname, 'src'), OUT = path.join(SRC, 'fonts');
fs.mkdirSync(OUT, { recursive: true });
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36';

const chars = new Set();
for (let c = 32; c < 127; c++) chars.add(String.fromCharCode(c));
for (const f of fs.readdirSync(SRC).filter(f => f.endsWith('.js'))) for (const ch of fs.readFileSync(path.join(SRC, f), 'utf8')) if (ch.codePointAt(0) > 127) chars.add(ch);
chars.add('暗'); chars.add('W');
const text = [...chars].join('');
console.log('glyphs:', chars.size);

const FAMS = [
  { g: 'Noto Serif SC', w: [700, 900], as: 'NSerif' },
  { g: 'Noto Sans SC', w: [400, 500, 700, 900], as: 'NSans' },
  { g: 'Cinzel', w: [700, 900], as: 'Cinzel' },
  { g: 'JetBrains Mono', w: [700, 800], as: 'JBMono' },
];
(async () => {
  let css = '';
  for (const F of FAMS) {
    for (const w of F.w) {
      const url = `https://fonts.googleapis.com/css2?family=${encodeURIComponent(F.g)}:wght@${w}&text=${encodeURIComponent(text)}`;
      const r = await fetch(url, { headers: { 'User-Agent': UA } });
      if (!r.ok) throw new Error(F.g + ' ' + w + ' → HTTP ' + r.status);
      const body = await r.text();
      const m = body.match(/url\((https:[^)]+)\)/);
      if (!m) throw new Error('no url for ' + F.g);
      const file = `${F.as}-${w}.woff2`;
      const buf = Buffer.from(await (await fetch(m[1], { headers: { 'User-Agent': UA } })).arrayBuffer());
      fs.writeFileSync(path.join(OUT, file), buf);
      css += `@font-face{font-family:'${F.as}';font-weight:${w};font-style:normal;font-display:block;src:url('${file}') format('woff2');}\n`;
      console.log(file, (buf.length / 1024).toFixed(0) + 'KB');
    }
  }
  fs.writeFileSync(path.join(OUT, 'fonts.css'), css);
})().catch(e => { console.error(e); process.exit(1); });

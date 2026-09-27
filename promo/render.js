// ============================================================
//  render.js — 用无头 Edge 逐帧渲染 + ffmpeg 编码
//    node render.js stills 3.0 12.5 ...      渲染指定时刻的静帧到 stills/
//    node render.js audio                    只合成音频到 audio.wav
//    node render.js video [workers] [from] [to]   完整渲染到 D4KeyHelp_Promo.mp4
// ============================================================
const puppeteer = require('puppeteer-core');
const { spawn } = require('child_process');
const fs = require('fs'), path = require('path');

const EDGE = 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe';
const PAGE = 'file:///' + path.join(__dirname, 'src', 'index.html').replace(/\\/g, '/');
const ARGS = ['--enable-gpu', '--use-angle=d3d11', '--ignore-gpu-blocklist', '--allow-file-access-from-files', '--disable-background-timer-throttling', '--disable-renderer-backgrounding'];

async function openPage(query = '') {
  const browser = await puppeteer.launch({ executablePath: EDGE, headless: 'new', args: ARGS, protocolTimeout: 600000 });
  const page = await browser.newPage();
  page.on('console', m => { if (m.type() === 'error' || m.type() === 'warn') console.log('[page]', m.text()); });
  page.on('pageerror', e => console.log('[pageerror]', e.message));
  await page.setViewport({ width: 1920, height: 1080, deviceScaleFactor: 1 });
  await page.goto(PAGE + query, { waitUntil: 'load' });
  const info = await page.evaluate(() => init());
  return { browser, page, info };
}
async function grab(page, t) {
  const b64 = await page.evaluate(t => { renderFrame(t); return document.getElementById('gl').toDataURL('image/png').slice(22); }, t);
  return Buffer.from(b64, 'base64');
}
function ffmpeg(args) {
  const p = spawn('ffmpeg', args, { stdio: ['pipe', 'ignore', 'pipe'] });
  let err = ''; p.stderr.on('data', d => { err += d; if (err.length > 20000) err = err.slice(-10000); });
  const done = new Promise((res, rej) => p.on('close', c => c === 0 ? res() : rej(new Error('ffmpeg ' + c + '\n' + err.slice(-3000)))));
  return { p, done };
}
const write = (stream, buf) => new Promise(res => stream.write(buf) ? res() : stream.once('drain', res));

async function stills(times) {
  fs.mkdirSync(path.join(__dirname, 'stills'), { recursive: true });
  const { browser, page, info } = await openPage();
  console.log(info);
  for (const t of times) {
    const f = path.join(__dirname, 'stills', `t${(+t).toFixed(2).padStart(6, '0')}.png`);
    fs.writeFileSync(f, await grab(page, +t));
    console.log('wrote', f);
  }
  await browser.close();
}

async function audio() {
  const { browser, page } = await openPage();
  const t0 = Date.now();
  const len = await page.evaluate(() => renderAudioWav());
  const parts = [];
  for (let i = 0; i < len; i += 4 << 20) parts.push(Buffer.from(await page.evaluate((i, s) => wavChunk(i, s), i, 4 << 20), 'base64'));
  const out = path.join(__dirname, 'audio.wav');
  fs.writeFileSync(out, Buffer.concat(parts));
  console.log('audio.wav', (len / 1048576).toFixed(1) + 'MB in', ((Date.now() - t0) / 1000).toFixed(1) + 's');
  await browser.close();
  return out;
}

async function worker(id, f0, f1, fps, segFile, progress, opt) {
  const { browser, page } = await openPage(opt.query);
  const ff = ffmpeg(['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(fps), '-c:v', 'png', '-i', '-',
    '-vf', 'scale=out_color_matrix=bt709:out_range=tv', '-c:v', 'libx264', '-preset', 'slow', '-crf', String(opt.crf), '-pix_fmt', 'yuv420p',
    '-color_primaries', 'bt709', '-color_trc', 'bt709', '-colorspace', 'bt709', '-g', '120', segFile]);
  for (let f = f0; f < f1; f++) {
    await write(ff.p.stdin, await grab(page, f / fps));
    progress[id] = f - f0 + 1;
  }
  ff.p.stdin.end();
  await ff.done;
  await browser.close();
}

async function video(nw = 4, from = 0, to = null, opt = { query: '', crf: 20, web: false }) {
  const segDir = path.join(__dirname, 'segments');
  fs.mkdirSync(segDir, { recursive: true });
  const probe = await openPage(opt.query);
  const { fps, frames } = probe.info;
  await probe.browser.close();
  const F0 = Math.round(from * fps), F1 = to ? Math.round(to * fps) : frames;
  const total = F1 - F0;
  console.log(`rendering ${total} frames @${fps}fps with ${nw} workers`);
  const wavP = audio();
  const progress = new Array(nw).fill(0), segs = [];
  const t0 = Date.now();
  const timer = setInterval(() => {
    const done = progress.reduce((a, b) => a + b, 0), el = (Date.now() - t0) / 1000;
    process.stdout.write(`\r  ${done}/${total}  ${(done / el).toFixed(1)} fps  eta ${done ? Math.round((total - done) / (done / el)) : '?'}s   `);
  }, 2000);
  const jobs = [];
  for (let k = 0; k < nw; k++) {
    const a = F0 + Math.floor(total * k / nw), b = F0 + Math.floor(total * (k + 1) / nw);
    const seg = path.join(segDir, `seg${k}.mp4`); segs.push(seg);
    jobs.push(worker(k, a, b, fps, seg, progress, opt));
  }
  await Promise.all(jobs);
  clearInterval(timer);
  const wav = await wavP;
  console.log(`\nframes done in ${((Date.now() - t0) / 1000).toFixed(0)}s, muxing…`);
  const list = path.join(segDir, 'list.txt');
  fs.writeFileSync(list, segs.map(s => `file '${s.replace(/\\/g, '/')}'`).join('\n'));
  if (opt.web) return webEncode(list, wav);
  const out = path.join(__dirname, from || to ? 'preview_cut.mp4' : 'D4KeyHelp_Promo.mp4');
  const aArgs = from || to ? ['-ss', String(from), '-t', String(total / fps)] : [];
  await ffmpeg(['-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0', '-i', list, ...aArgs, '-i', wav,
    '-c:v', 'copy', '-af', 'volume=1dB,alimiter=limit=0.84:attack=2:release=60:level=disabled', '-c:a', 'aac', '-b:a', '320k', '-shortest', '-movflags', '+faststart', out]).done;
  console.log('wrote', out);
}

// 网页版：720p30、无颗粒、两遍编码压到 GitHub README 上传上限（免费版 10MB）以内
async function webEncode(list, wav, targetMB = 9.3) {
  const dur = 98.4, aK = 96, vK = Math.floor(targetMB * 8 * 1024 / dur - aK - 8);
  const out = path.join(__dirname, 'D4KeyHelp_Promo_web.mp4');
  const log = path.join(__dirname, 'segments', 'x264pass');
  const inp = ['-f', 'concat', '-safe', '0', '-i', list];
  const common = ['-vf', 'scale=1280:720:flags=lanczos', '-c:v', 'libx264', '-preset', 'veryslow',
    '-b:v', vK + 'k', '-maxrate', Math.round(vK * 2.2) + 'k', '-bufsize', vK * 4 + 'k', '-pix_fmt', 'yuv420p', '-passlogfile', log];
  console.log(`web encode: video ${vK}kbps + audio ${aK}kbps`);
  await ffmpeg(['-y', '-loglevel', 'error', ...inp, ...common, '-pass', '1', '-an', '-f', 'mp4', 'NUL']).done;
  await ffmpeg(['-y', '-loglevel', 'error', ...inp, '-i', wav, ...common, '-pass', '2', '-map', '0:v', '-map', '1:a',
    '-af', 'volume=1dB,alimiter=limit=0.84:attack=2:release=60:level=disabled', '-c:a', 'aac', '-b:a', aK + 'k',
    '-color_primaries', 'bt709', '-color_trc', 'bt709', '-colorspace', 'bt709', '-movflags', '+faststart', '-shortest', out]).done;
  console.log('wrote', out, (fs.statSync(out).size / 1048576).toFixed(2) + 'MB');
}

(async () => {
  const [mode, ...rest] = process.argv.slice(2);
  if (mode === 'stills') await stills(rest);
  else if (mode === 'audio') await audio();
  else if (mode === 'web') await video(+(rest[0] || 4), 0, null, { query: '?fps=30&grain=0', crf: 12, web: true });
  else if (mode === 'video') await video(+(rest[0] || 4), +(rest[1] || 0), rest[2] ? +rest[2] : null);
  else console.log('usage: node render.js stills|audio|video');
})().catch(e => { console.error(e); process.exit(1); });

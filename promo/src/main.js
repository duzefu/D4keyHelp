// ============================================================
//  main.js — 帧调度：场景 → Canvas2D → WebGL 后期
// ============================================================
const IMG = {};
// ?fps=30&grain=0 用于渲染网页版（去掉颗粒可大幅降低码率）
const QS = new URLSearchParams(location.search);
const OUT_FPS = +QS.get('fps') || FPS;
let post, uiCanvas, uctx;

// 转场自动配音
SCENES.forEach(s => {
  if (s.tout === 'burn') { cue(s.end - .62, 'burn'); cue(s.end, 'hit'); }
  if (s.tout === 'flash') { cue(s.end - 1.2, 'riser', { dur: 1.2, gain: .6 }); cue(s.end, 'impact', { gain: .8 }); }
});
SCENES.forEach(s => s.setup && s.setup(s));
CUES.sort((a, b) => a.t - b.t);

function sceneAt(t) {
  let cur = SCENES[0];
  for (const s of SCENES) if (t >= s.start) cur = s;
  return cur;
}

function frameParams(t) {
  const s = sceneAt(t), lt = t - s.start;
  const P = {
    t, tintA: [.3, .1, .08], tintB: [1, .36, .08], fog: .55, glow: .6, heat: .35, seed: 0,
    zoom: 1, flash: 0, shake: [0, 0], aberr: .0016, bloom: .95, bloomThr: .6, grain: .05,
    burn: 0, burnSeed: 0, fade: 1, vig: .55,
  };
  s.params && s.params.call(s, P, t, lt);
  // 跟拍
  const kp = pulseAt(t, KICKS, 9);
  P.zoom *= 1 + kp * .007;
  P.glow += kp * .3; P.heat += kp * .2;
  // 转场
  for (const sc of SCENES) {
    if (sc.tout === 'burn' && t >= sc.end - .6 && t < sc.end) { P.burn = E.inQuad(prog(t, sc.end - .6, sc.end)); P.burnSeed = (sc.start * 1.7) % 9; }
    if (sc.tin === 'burn' && t >= sc.start && t < sc.start + .5) { P.burn = 1 - E.outQuad(prog(t, sc.start, sc.start + .5)); P.burnSeed = (sc.start * 2.3) % 9 + 3; }
    if (sc.tout === 'flash' && t >= sc.end - .3 && t < sc.end) {
      const p = E.inCubic(prog(t, sc.end - .3, sc.end));
      P.flash += p * .75; P.aberr += p * .05; P.zoom *= 1 + p * .06;
    }
    if (sc.tin === 'flash' && t >= sc.start && t < sc.start + .8) {
      const d = t - sc.start;
      P.flash += .75 * Math.exp(-d * 11); P.aberr += .05 * Math.exp(-d * 6); P.zoom *= 1 + .05 * Math.exp(-d * 6);
    }
  }
  if (QS.get('grain') === '0') P.grain = 0;
  return P;
}

function renderFrame(t) {
  uctx.setTransform(1, 0, 0, 1, 0, 0);
  uctx.clearRect(0, 0, W, H);
  const s = sceneAt(t);
  uctx.save();
  s.draw.call(s, uctx, t, t - s.start);
  uctx.restore();
  post.render(uiCanvas, frameParams(t));
}

function loadImg(src) {
  return new Promise((res, rej) => { const i = new Image(); i.onload = () => res(i); i.onerror = rej; i.src = src; });
}

async function init() {
  const gl = document.getElementById('gl');
  gl.width = W; gl.height = H;
  post = new Post(gl);
  uiCanvas = document.createElement('canvas'); uiCanvas.width = W; uiCanvas.height = H;
  uctx = uiCanvas.getContext('2d');
  IMG.dark = await loadImg('../../mainPage-dark.png');
  IMG.light = await loadImg('../../mainPage.png');
  const faces = [
    '900 60px NSerif', '700 60px NSerif', '400 20px NSans', '500 20px NSans', '700 20px NSans', '900 20px NSans',
    '700 20px Cinzel', '900 20px Cinzel', '700 20px JBMono', '800 20px JBMono',
  ];
  await Promise.all(faces.map(f => document.fonts.load(f, '暗黑AaW0')));
  await document.fonts.ready;
  window.__ready = true;
  return { duration: DURATION, fps: OUT_FPS, frames: Math.round(DURATION * OUT_FPS), cues: CUES.length };
}

// ---------- 预览模式：浏览器里实时播放（带声音） ----------
async function preview() {
  await init();
  const bar = document.getElementById('bar');
  const info = document.getElementById('info');
  info.textContent = '合成音频中…';
  const buf = await buildAudio();
  const actx = new AudioContext({ sampleRate: buf.sampleRate });
  let src = null, t0 = 0, off = 0, playing = false;
  const play = from => {
    if (src) src.stop();
    src = actx.createBufferSource(); src.buffer = buf; src.connect(actx.destination);
    src.start(0, from); t0 = actx.currentTime - from; playing = true;
  };
  info.textContent = '点击画面播放 / 暂停，拖动进度条跳转';
  document.getElementById('gl').onclick = () => { if (playing) { off = actx.currentTime - t0; src.stop(); playing = false; } else play(off); };
  bar.max = DURATION; bar.oninput = () => { off = +bar.value; if (playing) play(off); else renderFrame(off); };
  const loop = () => {
    const t = playing ? actx.currentTime - t0 : off;
    if (t >= DURATION) { playing = false; off = 0; }
    renderFrame(Math.min(t, DURATION - 1e-3));
    bar.value = t;
    requestAnimationFrame(loop);
  };
  loop();
}

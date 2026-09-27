// ============================================================
//  timeline.js — 全片共享的时间轴：画面与音频读同一份数据，保证帧级同步
// ============================================================
const W = 1920, H = 1080, FPS = 60;
const BPM = 100, BEAT = 60 / BPM, BAR = BEAT * 4;      // 0.6s 一拍，2.4s 一小节
const bar = b => b * BAR;

// 各幕起止（单位：小节）
const SECT = {
  intro: [0, 4], hook: [4, 6], skill: [6, 13], globe: [13, 20],
  trans: [20, 24], afk: [24, 28], ui: [28, 31], howto: [31, 37], outro: [37, 41],
};
const DURATION = bar(41);

// ---------- 数学 ----------
const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
const lerp = (a, b, t) => a + (b - a) * t;
const prog = (t, a, b) => clamp((t - a) / (b - a));
const E = {
  lin: t => t,
  inQuad: t => t * t,
  outQuad: t => 1 - (1 - t) * (1 - t),
  inCubic: t => t * t * t,
  outCubic: t => 1 - Math.pow(1 - t, 3),
  inOutCubic: t => t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2,
  outQuart: t => 1 - Math.pow(1 - t, 4),
  outExpo: t => t >= 1 ? 1 : 1 - Math.pow(2, -10 * t),
  inExpo: t => t <= 0 ? 0 : Math.pow(2, 10 * t - 10),
  inOutSine: t => -(Math.cos(Math.PI * t) - 1) / 2,
  outBack: (t, s = 1.70158) => 1 + (s + 1) * Math.pow(t - 1, 3) + s * Math.pow(t - 1, 2),
  outElastic: t => t <= 0 ? 0 : t >= 1 ? 1 : Math.pow(2, -10 * t) * Math.sin((t * 10 - .75) * (2 * Math.PI) / 3) + 1,
};
// 稳定哈希（0..1），所有"随机"都来自它，保证每帧可复现
const hash = n => { const s = Math.sin(n * 127.1 + 311.7) * 43758.5453123; return s - Math.floor(s); };
function mulberry32(a) {
  return function () {
    a |= 0; a = a + 0x6D2B79F5 | 0;
    let t = Math.imul(a ^ a >>> 15, 1 | a);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}
// 指数衰减脉冲：t 时刻距最近一次事件的衰减值
function pulseAt(t, times, decay = 8) {
  let v = 0;
  for (const e of times) { const d = t - e; if (d >= 0 && d < 3) v = Math.max(v, Math.exp(-d * decay)); }
  return v;
}

// ---------- 音效提示点 ----------
const CUES = [];
function cue(t, type, p = {}) { CUES.push(Object.assign({ t, type }, p)); }

// ---------- 音乐编排 ----------
// D 小调：i – VI – iv – V（Dm Bb Gm A）
const NOTE = { C: 0, 'C#': 1, Db: 1, D: 2, 'D#': 3, Eb: 3, E: 4, F: 5, 'F#': 6, Gb: 6, G: 7, 'G#': 8, Ab: 8, A: 9, 'A#': 10, Bb: 10, B: 11 };
function mtof(m) { return 440 * Math.pow(2, (m - 69) / 12); }
function nm(s) { const m = s.match(/^([A-G][#b]?)(-?\d)$/); return (parseInt(m[2]) + 1) * 12 + NOTE[m[1]]; }
const CHORDS = {
  Dm: ['D', 'F', 'A'], Bb: ['Bb', 'D', 'F'], Gm: ['G', 'Bb', 'D'], A: ['A', 'C#', 'E'], F: ['F', 'A', 'C'], C: ['C', 'E', 'G'],
};
function chordAt(b) {
  if (b < 4) return ['Dm', 'Dm', 'Bb', 'A'][b];
  if (b < 6) return ['Gm', 'A'][b - 4];
  if (b >= 37) return ['Dm', 'Bb', 'Gm', 'Dm'][Math.min(3, b - 37)];
  return ['Dm', 'Bb', 'Gm', 'A'][(b - 6) % 4];
}
// 每小节的配器强度
function layersAt(b) {
  const L = { drone: 0, pad: 0, choir: 0, drums: 0, bass: 0, arp: 0, hats: 0, lead: 0 };
  if (b < 4) { L.drone = 1; L.pad = b >= 1 ? .8 : .4; L.choir = b >= 1 ? .7 : 0; }
  else if (b < 6) { L.drone = 1; L.pad = .7; L.hats = b === 4 ? 1 : 2; L.drums = b === 4 ? .5 : .8; L.arp = .6; }
  else if (b < 13) { L.pad = .7; L.drums = 2; L.bass = 1; L.arp = 1; L.hats = 1; }
  else if (b < 20) { L.pad = .8; L.choir = .5; L.drums = 1; L.bass = .9; L.arp = .55; L.hats = .6; }
  else if (b < 24) { L.pad = .6; L.drums = 2; L.bass = 1; L.arp = 1; L.hats = 2; }
  else if (b < 28) { L.pad = .7; L.drums = 2; L.bass = 1; L.arp = .9; L.hats = 1; }
  else if (b < 31) { L.pad = .8; L.drums = 1; L.bass = .7; L.arp = .7; L.hats = .5; }
  else if (b < 37) { L.pad = .8; L.choir = .6; L.drums = 2; L.bass = 1; L.arp = .8; L.hats = 1; L.lead = 1; }
  else { L.drone = 1; L.pad = 1; L.choir = 1; L.lead = b === 37 ? 1 : 0; }
  return L;
}
// 鼓：每小节 8 个八分音符格
const DRUM_FULL = { kick: [1, 0, 0, 1, 1, 0, 1, 0], snare: [0, 0, 1, 0, 0, 0, 1, 0] };
const DRUM_HALF = { kick: [1, 0, 0, 0, 0, 0, 1, 0], snare: [0, 0, 0, 0, 1, 0, 0, 0] };
function drumPattern(b) {
  const L = layersAt(b);
  if (!L.drums) return null;
  if (L.drums >= 2) return DRUM_FULL;
  if (L.drums >= 1) return DRUM_HALF;
  return { kick: [1, 0, 0, 0, 1, 0, 0, 0], snare: [0, 0, 0, 0, 0, 0, 0, 0] };
}
// 视觉跟拍用的底鼓时刻表
const KICKS = (() => {
  const k = [];
  for (let b = 0; b < 41; b++) {
    const p = drumPattern(b);
    if (!p) continue;
    p.kick.forEach((on, i) => { if (on) k.push(bar(b) + i * BEAT / 2); });
  }
  return k;
})();
// 主旋律（八分音符格，'-' 延音，'.' 休止），每串一小节
const LEAD = {
  31: 'A4 . D5 . E5 F5 E5 D5', 32: 'F5 - D5 . C5 D5 Bb4 .', 33: 'G4 . Bb4 . D5 - C5 Bb4', 34: 'A4 . C#5 . E5 - A5 -',
  35: 'D5 . F5 . A5 - G5 F5', 36: 'E5 - C#5 . A4 . E5 -', 37: 'D5 - - - - - - -',
};

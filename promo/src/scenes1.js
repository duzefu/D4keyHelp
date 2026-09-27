// ============================================================
//  scenes1.js — 开场 / 痛点 / 技能策略 / 智能喝药
// ============================================================
const SCENES = [];
function scene(name, def) {
  const [a, b] = SECT[name];
  Object.assign(def, { name, start: bar(a), end: bar(b) });
  SCENES.push(def);
  return def;
}
// 最近一次事件的衰减脉冲
function lastPulse(lt, times, k = 20) {
  let v = 0;
  for (const p of times) if (p <= lt && lt - p < 2) v = Math.max(v, Math.exp(-(lt - p) * k));
  return v;
}
// 震屏（UV 单位）
function shakeUV(lt, events, amp = .006, dec = 8) {
  let x = 0, y = 0;
  for (const e of events) {
    const d = lt - e;
    if (d >= 0 && d < 1.5) { const a = amp * Math.exp(-d * dec); x += Math.sin(d * 83 + e * 3) * a; y += Math.cos(d * 71 + e * 5) * a; }
  }
  return [x, y];
}
function impulse(lt, t0, k = 6) { return lt >= t0 ? Math.exp(-(lt - t0) * k) : 0; }
// 章节主标题下方的"模式名 + 说明"
function modeTitle(ctx, lt, a, b, title, desc, o = {}) {
  if (lt < a - .1 || lt > b + .1) return;
  const out = 1 - E.inCubic(prog(lt, b - .25, b));
  const y = o.y ?? 740;
  ctx.save(); ctx.globalAlpha = out;
  revealText(ctx, title, 960, y, lt - a, {
    font: font('serif', o.size ?? 78, 900), stagger: .06, dur: .5, dy: 24, scale0: 1.3,
    grad: [[0, '#fff4da'], [1, '#e2ae5e']], glow: 26, glowColor: 'rgba(255,90,20,.6)', ls: 6,
  });
  revealText(ctx, desc, 960, y + 56, lt - a - .25, { font: font('sans', 30, 500), stagger: .018, dur: .4, dy: 10, fill: 'rgba(239,230,216,.82)', ls: 2 });
  ctx.restore();
}

// ============================================================
//  S0  开场
// ============================================================
scene('intro', {
  tout: 'burn',
  setup(S) {
    cue(0.02, 'riser', { dur: 1.18, gain: .55 });
    cue(1.2, 'boom', { gain: 1 });
    cue(2.4, 'titleHit');
    cue(3.35, 'shimmer');
    cue(4.75, 'whoosh', { gain: .45 });
    [5.5, 5.75, 6.0].forEach((x, i) => cue(x, 'pop', { pitch: 1 + i * .12 }));
  },
  params(P, t, lt) {
    P.fog = .7 * E.outCubic(prog(lt, 0, 2.2));
    P.glow = .2 + .75 * E.outCubic(prog(lt, 1.2, 3));
    P.tintA = [.34, .09, .07];
    P.flash += .9 * impulse(lt, 1.2, 7.5) + .5 * impulse(lt, 2.4, 7);
    P.aberr += .05 * impulse(lt, 1.2, 4) + .04 * impulse(lt, 2.4, 4);
    P.shake = shakeUV(lt, [1.2, 2.4], .006);
    P.fade = E.outQuad(prog(lt, 0, .5));
  },
  draw(ctx, t, lt) {
    const cx = 960, cy = 540;
    embers(ctx, t, { n: Math.round(lerp(30, 130, prog(lt, 1.2, 3))), seed: 3, alpha: .35 + .65 * prog(lt, 1, 2.5), speed: 60 });
    // 升起的火星
    if (lt < 1.3) {
      for (let j = 16; j >= 0; j--) {
        const tp = E.inOutCubic(prog(lt - j * .022, .1, 1.2));
        const y = lerp(1180, cy, tp), x = cx + Math.sin((lt - j * .022) * 4) * 18 * (1 - tp);
        glow(ctx, x, y, 44 - j * 2.2, 'rgb(255,140,50)', (1 - j / 17) * .8);
      }
      const p = E.inOutCubic(prog(lt, .1, 1.2));
      const y = lerp(1180, cy, p);
      glow(ctx, cx, y, 110, 'rgb(255,160,70)', 1); glow(ctx, cx, y, 22, 'rgb(255,245,220)', 1);
    }
    // 冲击波
    if (lt >= 1.2 && lt < 2.4) {
      const p = prog(lt, 1.2, 2.2);
      ctx.save();
      ctx.strokeStyle = `rgba(255,190,120,${(1 - p) * .8})`; ctx.lineWidth = 34 * (1 - p) + 2;
      ctx.shadowColor = 'rgba(255,100,30,1)'; ctx.shadowBlur = 40;
      ctx.beginPath(); ctx.arc(cx, cy, E.outCubic(p) * 1250, 0, Math.PI * 2); ctx.stroke();
      ctx.restore();
    }
    // 符文法阵
    if (lt >= 1.2) {
      const a = lt < 2.4 ? 1 : lerp(1, .36, E.outCubic(prog(lt, 2.4, 3.2)));
      const R = 300 * (1 + Math.max(0, lt - 2.4) * .022);
      glow(ctx, cx, cy, 460, 'rgb(255,80,25)', .22 * a);
      runeCircle(ctx, cx, cy, R, t, { p: prog(lt, 1.2, 3.1), alpha: a });
    }
    // 标题
    if (lt >= 2.35) {
      metalText(ctx, 'D4KEYHELP', cx, cy, {
        font: font('cinzel', 184, 900), size: 184, ls: 16,
        perChar: i => { const p = prog(lt, 2.4 + i * .045, 2.95 + i * .045); return { a: p * 1.8, s: lerp(2.4, 1, E.outCubic(p)), dy: 0 }; },
        shine: prog(lt, 3.3, 4.7), glow: 22 + 40 * impulse(lt, 2.4, 3),
      });
    }
    revealText(ctx, 'DIABLO IV · MACRO COMPANION', cx, cy - 148, lt - 3.0, { font: font('cinzel', 24, 700), ls: 14, fill: PAL.goldDim, stagger: .02, dur: .6, dy: 10 });
    // 分隔线
    if (lt > 4.4) {
      const p = E.outExpo(prog(lt, 4.4, 5.4));
      ctx.save();
      ctx.fillStyle = linGrad(ctx, cx - 400, 0, cx + 400, 0, [[0, 'rgba(233,196,124,0)'], [.5, 'rgba(233,196,124,.9)'], [1, 'rgba(233,196,124,0)']]);
      ctx.fillRect(cx - 400 * p, cy + 104, 800 * p, 1.5);
      ctx.translate(cx, cy + 105); ctx.rotate(Math.PI / 4); ctx.fillStyle = PAL.gold; ctx.globalAlpha = p;
      ctx.fillRect(-5, -5, 10, 10);
      ctx.restore();
    }
    revealText(ctx, '暗黑破坏神 4 · 图形化键鼠宏助手', cx, cy + 178, lt - 4.8, {
      font: font('serif', 50, 700), ls: 6, stagger: .035, dur: .6, dy: 18, fill: PAL.bone, glow: 16, glowColor: 'rgba(255,80,20,.6)',
    });
    // 标签
    const labels = ['AutoHotkey v2.0', '开源 · MIT', '单文件 exe · 开箱即用'];
    const f = font('sans', 24, 500);
    const ws = labels.map(s => measure(ctx, s, f) + 44);
    let x = cx - (ws.reduce((a, b) => a + b, 0) + 24 * 2) / 2;
    labels.forEach((s, i) => {
      const p = prog(lt, 5.5 + i * .25, 5.95 + i * .25);
      if (p > 0) chip(ctx, s, x, cy + 262, { font: f, scale: E.outBack(p), alpha: clamp(p * 2) });
      x += ws[i] + 24;
    });
  },
});

// ============================================================
//  S1  痛点 → 交给它
// ============================================================
scene('hook', {
  tin: 'burn', tout: 'flash',
  setup(S) {
    const r = mulberry32(77);
    S.mash = []; let x = .15;
    while (x < 2.3) { S.mash.push({ t: x, k: Math.floor(r() * 4) }); x += lerp(.16, .045, x / 2.3) * (.7 + r() * .6); }
    S.mash.forEach(m => cue(S.start + m.t, 'key', { pitch: .85 + r() * .35, gain: .3 }));
    S.calm = [];
    for (let i = 0; i < 7; i++) S.calm.push({ t: 2.7 + i * .3, k: i % 4 });
    S.calm.forEach(m => cue(S.start + m.t, 'key', { pitch: [1, 1.12, 1.26, 1.5][m.k], gain: .42 }));
    cue(S.start + 1.3, 'riser', { dur: 1.1, gain: .55 });
    cue(S.start + 2.4, 'impact');
  },
  params(P, t, lt) {
    const calm = lt >= 2.4;
    P.tintA = calm ? [.34, .12, .06] : [.15, .12, .13];
    P.tintB = calm ? [1, .42, .1] : [.45, .28, .24];
    P.glow = calm ? .65 : .3; P.fog = calm ? .45 : .6;
    P.grain = calm ? .05 : .085;
    P.flash += .75 * impulse(lt, 2.4, 6);
    P.aberr += calm ? .06 * impulse(lt, 2.4, 4) : .008 * prog(lt, 0, 2.4);
    if (calm) P.shake = shakeUV(lt, [2.4], .009);
    else { const j = prog(lt, .6, 2.4) * .0018; P.shake = [Math.sin(t * 91) * j, Math.cos(t * 77) * j]; }
  },
  draw(ctx, t, lt) {
    const S = this, calm = lt >= 2.4;
    embers(ctx, t, { n: calm ? 90 : 30, seed: 9, alpha: calm ? .9 : .35, speed: calm ? 80 : 40 });
    // 键帽
    for (let i = 0; i < 4; i++) {
      let press = 0;
      const list = calm ? S.calm : S.mash;
      for (const m of list) if (m.k === i && m.t <= lt) press = Math.max(press, Math.exp(-(lt - m.t) * (calm ? 12 : 26)));
      const inten = calm ? 0 : prog(lt, .4, 2.4);
      const jx = (hash(Math.floor(t * 60) + i * 17) - .5) * 14 * inten, jy = (hash(Math.floor(t * 60) + i * 31) - .5) * 10 * inten;
      const pop = calm ? E.outBack(prog(lt, 2.4, 2.8)) : 1;
      keycap(ctx, 960 + (i - 1.5) * 222 + jx, 470 + jy, 184, 172, String(i + 1), {
        press, glow: calm ? .35 + press * .65 : press * .5, accent: calm ? 'rgb(255,170,70)' : 'rgb(255,60,50)', scale: calm ? lerp(1.12, 1, pop) : 1,
      });
      if (calm && press > .05) glow(ctx, 960 + (i - 1.5) * 222, 470, 180, 'rgb(255,140,50)', press * .45);
    }
    if (!calm) {
      const out = 1 - prog(lt, 2.15, 2.4);
      const n = Math.floor(12000 * E.inQuad(prog(lt, .1, 2.3)));
      text(ctx, '重复按键', 960, 200, { font: font('sans', 28, 500), align: 'center', fill: PAL.ash, alpha: out * prog(lt, 0, .3), ls: 8 });
      text(ctx, '× ' + n.toLocaleString('en-US'), 960, 296, { font: font('sans', 100, 900), align: 'center', fill: '#ff6a58', glow: 30, glowColor: 'rgba(255,40,30,.8)', alpha: out * prog(lt, 0, .3) });
      ctx.save(); ctx.globalAlpha = out;
      revealText(ctx, '一场战斗 · 成千上万次重复按键', 960, 760, lt - .3, { font: font('serif', 64, 900), stagger: .04, dur: .35, dy: 16, fill: '#e6dcd6', ls: 4 });
      ctx.restore();
    } else {
      const c = lt - 2.4;
      revealText(ctx, '精准  ·  稳定  ·  不知疲倦', 960, 290, c - .1, { font: font('serif', 34, 700), ls: 10, fill: PAL.gold, stagger: .03, dur: .5, dy: 10 });
      revealText(ctx, '把重复的按键，交给它', 960, 765, c, {
        font: font('serif', 80, 900), stagger: .05, dur: .5, dy: 30, scale0: 1.4, ls: 6,
        grad: [[0, '#fff5dc'], [1, '#e4b062']], glow: 30, glowColor: 'rgba(255,90,20,.7)',
      });
      revealText(ctx, '你只管走位、躲技能、做决策', 960, 835, c - .6, { font: font('sans', 32, 500), ls: 6, fill: 'rgba(233,196,124,.85)', stagger: .03, dur: .4, dy: 10 });
    }
  },
});

// ============================================================
//  S2  技能策略
// ============================================================
const SK = { s: 128, gap: 22, y0: 450 };
SK.x0 = 960 - (6 * SK.s + 5 * SK.gap) / 2;
const slotX = i => SK.x0 + i * (SK.s + SK.gap);
const SLOT_LABELS = ['1', '2', '3', '4', 'L', 'R'];

scene('skill', {
  tin: 'flash', tout: 'burn',
  setup(S) {
    const a = S.start;
    for (let i = 0; i < 6; i++) cue(a + .3 + i * .08 + .42, 'tick', { pitch: .8 + i * .1, gain: .55 });
    [1.5, 1.65, 1.8, 1.95].forEach((x, i) => cue(a + x, 'pop', { pitch: 1 + i * .1 }));
    S.p0 = []; S.p4 = [];
    for (let x = 2.7; x < 7.05; x += .3) S.p0.push(x + (hash(x * 3.1) - .5) * .024);
    for (let x = 2.7; x < 7.05; x += .15) S.p4.push(x + (hash(x * 7.7) - .5) * .02);
    S.p0.forEach(x => cue(a + x, 'key', { pitch: 1.2, gain: .42 }));
    S.p4.forEach(x => cue(a + x, 'tick', { pitch: 1.7, gain: .24 }));
    S.checks = []; for (let x = 8.1; x < 11.5; x += .3) S.checks.push(x);
    S.checks.forEach(x => cue(a + x, 'scan', { gain: .22 }));
    cue(a + 7.2, 'whoosh', { gain: .35 }); cue(a + 11.6, 'whoosh', { gain: .3 });
    cue(a + 9.45, 'alarm'); cue(a + 9.9, 'key', { pitch: 1, gain: .7 }); cue(a + 9.95, 'buffOn');
    cue(a + 12.5, 'key', { pitch: .8, gain: .7 }); cue(a + 12.5, 'holdStart', { dur: 2.4 }); cue(a + 14.9, 'release');
    for (let i = 0; i < 6; i++) cue(a + 15.0 + i * .1, 'pop', { pitch: 1 + i * .08, gain: .6 });
  },
  params(P, t, lt) {
    P.tintA = [.3, .1, .07]; P.fog = .5; P.glow = .55;
    P.aberr += .03 * impulse(lt, 9.9, 5) + .02 * impulse(lt, 12.5, 5);
    P.shake = shakeUV(lt, [9.9, 12.5], .003);
  },
  buffAt(lt) {
    if (lt < 9.0) return 1;
    if (lt < 9.45) { const p = prog(lt, 9.0, 9.45); return (1 - p) * (Math.sin(lt * 70) > -.2 ? 1 : .15); }
    if (lt < 9.95) return 0;
    return E.outCubic(prog(lt, 9.95, 10.25));
  },
  draw(ctx, t, lt) {
    const S = this, s = SK.s, y0 = SK.y0;
    embers(ctx, t, { n: 50, seed: 21, alpha: .55, speed: 50 });
    chapterHeader(ctx, lt, '01', '技能策略', 'SKILL STRATEGIES');

    // --- 状态 ---
    const phB = prog(lt, 2.4, 2.8) * (1 - prog(lt, 7.0, 7.3));
    const phC = prog(lt, 7.2, 7.6) * (1 - prog(lt, 11.7, 12.1));
    const phD = prog(lt, 12.0, 12.4) * (1 - prog(lt, 14.9, 15.2));
    const hl = [phB, phC, 0, 0, phB, phD];
    const anyFocus = Math.max(phB, phC, phD);
    const press = [lastPulse(lt, S.p0, 22), lt >= 9.9 ? impulse(lt, 9.9, 14) : 0, 0, 0, lastPulse(lt, S.p4, 26), 0];
    const holding = lt >= 12.5 && lt < 14.9;
    if (holding) press[5] = 1; else if (lt >= 14.9) press[5] = impulse(lt, 14.9, 10);

    // --- BUFF 镜头推近 ---
    const zp = E.inOutCubic(prog(lt, 7.2, 8.0)) * (1 - E.inOutCubic(prog(lt, 11.6, 12.3)));
    const z = lerp(1, 1.8, zp);
    const fx = slotX(1) + s / 2, fy = y0 + s / 2;
    const tx = lerp(fx, 640, zp), ty = lerp(fy, 440, zp);
    const toS = (x, y) => [(x - fx) * z + tx, (y - fy) * z + ty];

    ctx.save();
    ctx.translate(tx, ty); ctx.scale(z, z); ctx.translate(-fx, -fy);
    // 动作栏底座
    const ba = E.outCubic(prog(lt, .1, .6));
    ctx.save(); ctx.globalAlpha = ba;
    rrect(ctx, SK.x0 - 34, y0 - 30, 6 * s + 5 * SK.gap + 68, s + 60, 10);
    ctx.fillStyle = linGrad(ctx, 0, y0 - 30, 0, y0 + s + 30, [[0, '#1a2124'], [1, '#0b0f10']]); ctx.fill();
    ctx.strokeStyle = 'rgba(140,180,190,.25)'; ctx.lineWidth = 2; ctx.stroke();
    for (let i = 0; i <= 12; i++) { const rx = SK.x0 - 20 + i * ((6 * s + 5 * SK.gap + 40) / 12); ctx.fillStyle = 'rgba(160,190,200,.35)'; ctx.beginPath(); ctx.arc(rx, y0 - 16, 2.5, 0, 7); ctx.fill(); }
    ctx.restore();
    for (let i = 0; i < 6; i++) {
      const p = prog(lt, .3 + i * .08, .9 + i * .08);
      if (p <= 0) continue;
      const dim = anyFocus * (1 - hl[i]) * (i === 1 || zp < .01 ? 1 : 1);
      actionSlot(ctx, slotX(i), y0 + (1 - E.outBack(p)) * 140, s, i, SLOT_LABELS[i], {
        alpha: clamp(p * 2), press: press[i], hl: hl[i], dim, buff: i === 1 ? S.buffAt(lt) : 0,
      });
    }
    // 按住：蓄力环
    if (lt >= 12.3 && lt < 15.4) {
      const cx = slotX(5) + s / 2, cy = y0 + s / 2;
      const hp = prog(lt, 12.5, 14.9), a = prog(lt, 12.3, 12.6) * (1 - prog(lt, 14.9, 15.3));
      ctx.save(); ctx.globalAlpha = a;
      ctx.strokeStyle = 'rgba(255,170,70,1)'; ctx.shadowColor = 'rgba(255,110,30,1)'; ctx.shadowBlur = 24; ctx.lineWidth = 5; ctx.lineCap = 'round';
      ctx.beginPath(); ctx.arc(cx, cy, s * .82, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * hp); ctx.stroke();
      ctx.lineWidth = 1.5; ctx.setLineDash([6, 10]); ctx.lineDashOffset = -t * 60;
      ctx.beginPath(); ctx.arc(cx, cy, s * .98, 0, Math.PI * 2); ctx.stroke(); ctx.setLineDash([]);
      for (let k = 0; k < 18; k++) {
        const ph = (t * .9 + hash(k * 3.3)) % 1, an = k * 2.4 + t * 1.5;
        const r = lerp(s * 1.5, s * .3, E.inCubic(ph));
        glow(ctx, cx + Math.cos(an) * r, cy + Math.sin(an) * r, 12, 'rgb(255,160,60)', holding ? (1 - ph) : 0);
      }
      glow(ctx, cx, cy, s * 1.3, 'rgb(255,120,40)', (holding ? .35 + .15 * Math.sin(t * 20) : 0));
      ctx.restore();
      ripple(ctx, cx, cy, prog(lt, 14.9, 15.5), 'rgba(255,200,120,1)', s * 1.6);
    }
    ctx.restore();

    // --- A：简介 ---
    const aOut = 1 - prog(lt, 2.1, 2.4);
    if (aOut > 0) {
      ctx.save(); ctx.globalAlpha = aOut;
      revealText(ctx, '六个技能位 · 每个都能单独指定策略', 960, 710, lt - 1.0, { font: font('serif', 40, 700), stagger: .025, dur: .45, dy: 12, fill: PAL.bone, ls: 3 });
      const labels = ['禁用', '连点', '维持BUFF', '按住'], f = font('sans', 26, 700);
      const ws = labels.map(x => measure(ctx, x, f) + 48);
      let x = 960 - (ws.reduce((a, b) => a + b, 0) + 20 * 3) / 2;
      labels.forEach((l, i) => {
        const p = prog(lt, 1.5 + i * .15, 1.9 + i * .15);
        if (p > 0) chip(ctx, l, x, 790, { font: f, scale: E.outBack(p), alpha: clamp(p * 2), fill: i === 0 ? PAL.ash : PAL.goldHi, pad: 24 });
        x += ws[i] + 20;
      });
      ctx.restore();
    }

    // --- B：连点 ---
    modeTitle(ctx, lt, 2.5, 7.2, '连点', '按固定间隔不停触发 · 适合主力输出技能');
    if (phB > 0) {
      ctx.save(); ctx.globalAlpha = phB;
      chip(ctx, '间隔 300ms', slotX(0) + s / 2, y0 - 58, { align: 'center', font: font('mono', 20, 700), h: 36, pad: 14, fill: PAL.goldHi });
      chip(ctx, '间隔 150ms', slotX(4) + s / 2, y0 - 58, { align: 'center', font: font('mono', 20, 700), h: 36, pad: 14, fill: PAL.goldHi });
      // 时间轨
      const px = 520, py = 850, pw = 880, ph = 150;
      panel(ctx, px, py, pw, ph, { r: 14 });
      const lanes = [{ n: '技能一', iv: '300ms', list: S.p0, y: py + 48 }, { n: '左键', iv: '150ms', list: S.p4, y: py + 106 }];
      const trackX0 = px + 230, trackX1 = px + pw - 24, playX = (trackX0 + trackX1) / 2;
      lanes.forEach(L => {
        text(ctx, L.n, px + 30, L.y + 8, { font: font('sans', 24, 700), fill: PAL.bone });
        text(ctx, L.iv, px + 120, L.y + 8, { font: font('mono', 20, 700), fill: PAL.goldDim });
        ctx.save(); ctx.beginPath(); ctx.rect(trackX0, L.y - 22, trackX1 - trackX0, 44); ctx.clip();
        ctx.fillStyle = 'rgba(255,255,255,.05)'; ctx.fillRect(trackX0, L.y - 1, trackX1 - trackX0, 2);
        for (const pt of L.list) {
          const x = playX + (pt - lt) * 320;
          if (x < trackX0 - 10 || x > trackX1 + 10) continue;
          const near = Math.exp(-Math.abs(pt - lt) * 30);
          ctx.fillStyle = pt <= lt ? `rgba(233,196,124,${.35 + near * .65})` : 'rgba(233,196,124,.8)';
          ctx.fillRect(x - 2, L.y - 16, 4, 32);
          if (near > .1) glow(ctx, x, L.y, 40, 'rgb(255,170,80)', near);
        }
        ctx.restore();
      });
      ctx.fillStyle = 'rgba(255,120,60,.9)'; ctx.fillRect(playX - 1, py + 18, 2, ph - 36);
      glow(ctx, playX, py + 18, 16, 'rgb(255,120,60)', .8);
      text(ctx, '延迟随机：每次间隔带轻微抖动', px + pw - 24, py + ph - 10, { font: font('sans', 17, 500), align: 'right', fill: 'rgba(239,230,216,.5)' });
      ctx.restore();
    }

    // --- C：维持BUFF ---
    modeTitle(ctx, lt, 7.5, 11.9, '维持BUFF', '取色判断 · BUFF 掉了才补，不再无脑刷新');
    if (phC > 0) {
      const sp = toS(slotX(1) + 6, y0 + 2 + s * .04);
      const pa = prog(lt, 7.9, 8.3) * (1 - prog(lt, 11.3, 11.6));
      ctx.save(); ctx.globalAlpha = pa;
      // 取色准星
      ctx.strokeStyle = PAL.goldHi; ctx.lineWidth = 2; ctx.shadowColor = 'rgba(255,200,120,1)'; ctx.shadowBlur = 12;
      ctx.beginPath(); ctx.arc(sp[0], sp[1], 18, 0, Math.PI * 2); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(sp[0] - 30, sp[1]); ctx.lineTo(sp[0] - 8, sp[1]); ctx.moveTo(sp[0] + 8, sp[1]); ctx.lineTo(sp[0] + 30, sp[1]);
      ctx.moveTo(sp[0], sp[1] - 30); ctx.lineTo(sp[0], sp[1] - 8); ctx.moveTo(sp[0], sp[1] + 8); ctx.lineTo(sp[0], sp[1] + 30); ctx.stroke();
      ctx.shadowBlur = 0;
      for (const c of S.checks) ripple(ctx, sp[0], sp[1], prog(lt, c, c + .45), 'rgba(255,220,150,1)', 46);
      // 引线
      ctx.strokeStyle = 'rgba(233,196,124,.6)'; ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.moveTo(sp[0] + 20, sp[1] - 20); ctx.lineTo(sp[0] + 80, sp[1] - 80); ctx.lineTo(1060, sp[1] - 80); ctx.stroke();
      // 读数面板
      const px = 1060, py = 260, pw = 700, ph = 360;
      panel(ctx, px, py, pw, ph, { bg: 'rgba(12,8,9,.9)' });
      const b = S.buffAt(lt), on = b > .5;
      const state = lt < 9.45 ? 0 : lt < 9.95 ? 1 : 2;
      text(ctx, '取色检测', px + 40, py + 64, { font: font('serif', 36, 900), fill: PAL.goldHi });
      text(ctx, '按执行间隔轮询', px + pw - 40, py + 62, { font: font('sans', 20, 500), align: 'right', fill: PAL.ash });
      text(ctx, '取色点', px + 40, py + 120, { font: font('sans', 24, 500), fill: PAL.ash });
      text(ctx, '(1119, 1290)  @2K', px + 140, py + 120, { font: font('mono', 26, 700), fill: PAL.bone });
      const sw = on ? 'rgb(115,174,14)' : 'rgb(16,31,33)';
      rrect(ctx, px + 40, py + 150, 110, 110, 10); ctx.fillStyle = sw; ctx.fill();
      ctx.strokeStyle = 'rgba(255,255,255,.3)'; ctx.stroke();
      if (on) glow(ctx, px + 95, py + 205, 90, 'rgb(140,220,40)', .45);
      text(ctx, on ? 'RGB 115, 174, 14' : 'RGB  16,  31, 33', px + 180, py + 192, { font: font('mono', 26, 700), fill: PAL.bone });
      const msg = ['BUFF 生效 → 不按', 'BUFF 消失 → 立即补上', '已补上  ✓'][state];
      const col = ['#a6e05a', '#ffb347', '#a6e05a'][state];
      text(ctx, msg, px + 180, py + 244, { font: font('serif', 34, 900), fill: col, glow: 18, glowColor: col });
      ctx.fillStyle = 'rgba(233,196,124,.2)'; ctx.fillRect(px + 40, py + 285, pw - 80, 1.5);
      text(ctx, '取色点按分辨率等比缩放 · 2K / 1080P 实测验证', px + 40, py + 325, { font: font('sans', 22, 500), fill: PAL.goldHi, alpha: prog(lt, 10.3, 10.7) });
      ctx.restore();
    }

    // --- D：按住 ---
    modeTitle(ctx, lt, 12.1, 16.2, '按住', '保持按下不松开 · 适合需要持续施放的技能');
    if (lt >= 12.5 && lt < 15.2) {
      const a = prog(lt, 12.5, 12.7) * (1 - prog(lt, 14.9, 15.1));
      text(ctx, '按住中  ' + Math.min(2.4, lt - 12.5).toFixed(1) + 's', slotX(5) + s / 2, y0 + s + 62, { font: font('mono', 24, 700), align: 'center', fill: PAL.goldHi, alpha: a, glow: 12 });
    }
    // --- 小结 ---
    const modes = [['连点', PAL.goldHi], ['维持BUFF', '#b6ec6a'], ['禁用', PAL.ash], ['禁用', PAL.ash], ['连点', PAL.goldHi], ['按住', '#ffb060']];
    modes.forEach(([m, c], i) => {
      const p = prog(lt, 15.0 + i * .1, 15.4 + i * .1);
      if (p > 0) chip(ctx, m, slotX(i) + s / 2, y0 + s + 58, { align: 'center', font: font('sans', 20, 700), h: 38, pad: 14, fill: c, scale: E.outBack(p), alpha: clamp(p * 2) });
    });
  },
});

// ============================================================
//  S3  智能喝药（血量检测）
// ============================================================
const GL = { cx: 560, cy: 610, R: 240 };
scene('globe', {
  tin: 'burn', tout: 'burn',
  hits: [5.1, 5.8, 6.5, 7.2],
  shieldHits: [10.9, 12.1],
  setup(S) {
    const a = S.start;
    cue(a + 2.4, 'lockOn'); cue(a + 2.8, 'sweep', { dur: 1.1 }); cue(a + 3.9, 'lock');
    [2.6, 3.4, 4.2].forEach(x => cue(a + x, 'type', { n: 10 }));
    S.hits.forEach(x => cue(a + x, 'damage'));
    cue(a + 7.25, 'alarm');
    cue(a + 7.8, 'key', { pitch: 1, gain: .75 }); cue(a + 7.85, 'glug'); cue(a + 8.3, 'heal');
    cue(a + 9.8, 'shieldOn', { dur: 4.1 }); cue(a + 11.4, 'click'); S.shieldHits.forEach(x => cue(a + x, 'shieldHit'));
    cue(a + 13.9, 'shieldOff');
    cue(a + 14.6, 'pop', { pitch: 1 }); cue(a + 15.0, 'pop', { pitch: 1.12 });
  },
  levelAt(lt) {
    const lv = [1, .8, .67, .56, .44];
    let L = 1;
    this.hits.forEach((h, i) => { L = lerp(L, lv[i + 1], E.outCubic(prog(lt, h, h + .25))); });
    if (lt >= 7.9) L = lerp(L, 1, E.outCubic(prog(lt, 7.9, 9.0)));
        return L;
  },
  params(P, t, lt) {
    P.tintA = [.32, .06, .07]; P.tintB = [1, .25, .1]; P.fog = .55; P.glow = .6;
    const sh = prog(lt, 9.8, 10.5) * (1 - prog(lt, 13.9, 14.4));
    P.tintA = [lerp(.32, .3, sh), lerp(.06, .05, sh), lerp(.07, .28, sh)];
    P.aberr += .03 * lastPulse(lt, this.hits, 6) + .03 * impulse(lt, 7.8, 5);
    P.shake = shakeUV(lt, this.hits, .004);
  },
  draw(ctx, t, lt) {
    const S = this, { cx, cy, R } = GL;
    embers(ctx, t, { n: 50, seed: 33, alpha: .5, speed: 45 });
    chapterHeader(ctx, lt, '02', '智能喝药', 'SMART POTION');
    const hitP = lastPulse(lt, S.hits, 7);
    const level = S.levelAt(lt);
    const shield = E.outCubic(prog(lt, 9.8, 10.5)) * (1 - E.inCubic(prog(lt, 13.9, 14.4)));
    const shHit = lastPulse(lt, S.shieldHits, 8);
    const appear = E.outCubic(prog(lt, .2, 1.0));
    const [jx, jy] = [Math.sin(t * 80) * 10 * hitP, Math.cos(t * 67) * 8 * hitP];
    const gx = cx + jx, gy = cy + jy + (1 - appear) * 60;
    // 受击红屏
    if (hitP > 0) { ctx.save(); ctx.fillStyle = `rgba(160,0,10,${hitP * .22})`; ctx.fillRect(0, 0, W, H); ctx.restore(); }
    ctx.save(); ctx.globalAlpha = appear;
    glow(ctx, gx, gy, R * 2.2, shield > .3 ? 'rgb(200,40,170)' : 'rgb(200,20,20)', .35 + .2 * Math.sin(t * 2));
    const sy = healthGlobe(ctx, gx, gy, R, { t, level, shield: clamp(shield + shHit * .3), slosh: hitP + impulse(lt, 7.9, 3) });
    ctx.restore();

    // --- 识别：搜索窗 + 雷达 ---
    const boxA = prog(lt, 2.4, 2.7) * (1 - prog(lt, 3.9, 4.3));
    if (boxA > 0) {
      const k = lerp(1.35, 1, E.outCubic(prog(lt, 2.4, 2.9)));
      const hs = R * 1.45 * k, c = 40;
      ctx.save(); ctx.globalAlpha = boxA; ctx.strokeStyle = PAL.goldHi; ctx.lineWidth = 3; ctx.shadowColor = 'rgba(255,170,80,1)'; ctx.shadowBlur = 14;
      [[-1, -1], [1, -1], [-1, 1], [1, 1]].forEach(([sx, sy2]) => {
        ctx.beginPath(); ctx.moveTo(cx + sx * hs, cy + sy2 * hs - sy2 * c); ctx.lineTo(cx + sx * hs, cy + sy2 * hs); ctx.lineTo(cx + sx * hs - sx * c, cy + sy2 * hs); ctx.stroke();
      });
      ctx.shadowBlur = 0;
      text(ctx, '搜索窗口 · 按屏幕尺寸推算', cx - hs, cy - hs - 16, { font: font('sans', 20, 500), fill: PAL.goldHi });
      if (lt >= 2.8 && lt < 3.95) {
        const ang = (lt - 2.8) / 1.1 * Math.PI * 2 - Math.PI / 2;
        const cg = ctx.createConicGradient(ang - .9, cx, cy);
        cg.addColorStop(0, 'rgba(255,190,110,0)'); cg.addColorStop(.143, 'rgba(255,190,110,.35)'); cg.addColorStop(.145, 'rgba(255,190,110,0)');
        ctx.fillStyle = cg; ctx.beginPath(); ctx.arc(cx, cy, R * 1.4, 0, Math.PI * 2); ctx.fill();
        for (let k2 = 0; k2 < 40; k2++) {
          const a2 = k2 / 40 * Math.PI * 2 - Math.PI / 2;
          let d = ang - a2; while (d < 0) d += Math.PI * 2;
          if (ang - (-Math.PI / 2) < (a2 + Math.PI / 2)) continue;
          glow(ctx, cx + Math.cos(a2) * R, cy + Math.sin(a2) * R, 12, 'rgb(255,80,60)', Math.exp(-d * .8));
        }
      }
      ctx.restore();
    }
    // --- 锁定：拟合圆 + 球心 ---
    const lockA = prog(lt, 3.9, 4.2);
    if (lockA > 0) {
      const rr = lerp(R * 1.4, R + 6, E.outCubic(prog(lt, 3.9, 4.3)));
      ctx.save(); ctx.globalAlpha = lockA * (shield > .5 ? .5 : 1);
      ctx.strokeStyle = PAL.gold; ctx.lineWidth = 2; ctx.setLineDash([10, 8]); ctx.lineDashOffset = -t * 30;
      ctx.beginPath(); ctx.arc(cx, cy, rr, 0, Math.PI * 2); ctx.stroke(); ctx.setLineDash([]);
      ctx.beginPath(); ctx.moveTo(cx - 18, cy); ctx.lineTo(cx + 18, cy); ctx.moveTo(cx, cy - 18); ctx.lineTo(cx, cy + 18); ctx.stroke();
      glow(ctx, cx, cy, 30, 'rgb(255,200,120)', impulse(lt, 3.9, 3));
      ctx.restore();
      text(ctx, '球心 (W/2−465, H−116) · r = 90 @2K', cx, 262, { font: font('mono', 21, 700), align: 'center', fill: PAL.goldHi, alpha: prog(lt, 4.0, 4.4) });
    }
    // --- 液面线 + 阈值线 ---
    const mA = prog(lt, 4.8, 5.1) * (1 - shield) * (1 - prog(lt, 8.6, 9.0) * prog(level, .97, 1));
    if (mA > 0) {
      ctx.save(); ctx.globalAlpha = mA;
      ctx.beginPath(); ctx.arc(gx, gy, R, 0, Math.PI * 2); ctx.clip();
      ctx.beginPath(); ctx.rect(gx - R, sy, R * 2, R * 2); ctx.clip();
      ctx.strokeStyle = 'rgba(255,220,160,.2)'; ctx.lineWidth = 2;
      for (let k = -30; k < 30; k++) { ctx.beginPath(); ctx.moveTo(gx + k * 22 - 300, sy - 300); ctx.lineTo(gx + k * 22 + 300, sy + 300); ctx.stroke(); }
      ctx.restore();
      ctx.save(); ctx.globalAlpha = mA;
      ctx.strokeStyle = '#fff0cf'; ctx.lineWidth = 2; ctx.shadowColor = 'rgba(255,200,120,1)'; ctx.shadowBlur = 12;
      ctx.beginPath(); ctx.moveTo(gx - R - 20, sy); ctx.lineTo(gx + R + 60, sy); ctx.stroke();
      ctx.restore();
      text(ctx, '液面', gx + R + 70, sy + 8, { font: font('sans', 22, 700), fill: '#fff0cf', alpha: mA });
    }
    const thA = prog(lt, 5.0, 5.3);
    if (thA > 0) {
      ctx.save(); ctx.globalAlpha = thA * (1 - shield * .6);
      ctx.strokeStyle = PAL.gold; ctx.lineWidth = 2; ctx.setLineDash([14, 10]);
      ctx.beginPath(); ctx.moveTo(cx - R - 60, cy); ctx.lineTo(cx + R + 10, cy); ctx.stroke(); ctx.setLineDash([]);
      ctx.restore();
      text(ctx, '阈值 50%', cx - R - 70, cy + 8, { font: font('sans', 22, 700), fill: PAL.gold, align: 'right', alpha: thA });
    }
    // --- Q 键 ---
    const qA = prog(lt, 6.9, 7.2) * (1 - prog(lt, 9.4, 9.8));
    if (qA > 0) {
      const pq = lt >= 7.8 ? impulse(lt, 7.8, 10) : 0;
      keycap(ctx, cx + R + 110, cy + R * .78, 120, 110, 'Q', { press: pq, glow: .4 + pq * .6 + (lt > 7.2 && lt < 7.8 ? .4 * (.5 + .5 * Math.sin(t * 18)) : 0), alpha: qA, scale: lerp(.7, 1, E.outBack(prog(lt, 6.9, 7.3))) });
      ripple(ctx, cx + R + 110, cy + R * .78, prog(lt, 7.8, 8.4), 'rgba(255,190,110,1)', 120);
    }
    // 回血火花
    if (lt >= 7.85 && lt < 9.6) {
      for (let k = 0; k < 40; k++) {
        const st = 7.85 + hash(k * 1.7) * .8, p = prog(lt, st, st + 1.0);
        if (p <= 0 || p >= 1) continue;
        const x = cx + (hash(k * 3.9) - .5) * R * 1.6, y = cy + R * .8 - E.outCubic(p) * R * 1.6;
        glow(ctx, x, y, 18, 'rgb(255,210,150)', (1 - p) * .9);
      }
    }

    // --- 右侧面板 ---
    const pa = E.outCubic(prog(lt, 1.0, 1.6));
    if (pa > 0) {
      const px = 1000, py = 250, pw = 800, ph = 740;
      ctx.save(); ctx.globalAlpha = pa; ctx.translate((1 - pa) * 60, 0);
      panel(ctx, px, py, pw, ph, { bg: 'rgba(12,8,9,.82)' });
      text(ctx, '血量检测', px + 44, py + 78, { font: font('serif', 52, 900), fill: PAL.goldHi, glow: 16, glowColor: 'rgba(255,90,20,.5)' });
      chip(ctx, '无需手动取点', px + 290, py + 60, { font: font('sans', 22, 700), h: 40, pad: 16, fill: '#ffd9a0' });
      const steps = ['① 按屏幕尺寸推算血球区域', '② 自动拟合球心与半径', '③ 找出液面高度，换算血量'];
      steps.forEach((s2, i) => {
        const st = [2.6, 3.4, 4.2][i];
        const active = lt >= st && lt < st + 1.4;
        revealText(ctx, s2, px + 48, py + 150 + i * 50, lt - st, { font: font('sans', 28, active ? 700 : 500), align: 'left', stagger: .02, dur: .3, dy: 8, fill: active ? PAL.bone : 'rgba(239,230,216,.55)' });
      });
      ctx.fillStyle = 'rgba(233,196,124,.25)'; ctx.fillRect(px + 44, py + 300, pw - 88, 1.5);
      // HP 读数
      const hpA = prog(lt, 4.8, 5.2);
      if (hpA > 0) {
        ctx.save(); ctx.globalAlpha = pa * hpA;
        text(ctx, 'HP', px + 48, py + 360, { font: font('cinzel', 30, 900), fill: PAL.goldDim, ls: 4 });
        const shielded = shield > .5;
        const hp = Math.round(level * 100);
        const col = shielded ? '#ff7ae0' : hp < 50 ? '#ff5a4a' : '#fff0d8';
        if (!shielded) text(ctx, hp + '%', px + 44, py + 470, { font: font('sans', 128, 900), fill: col, glow: 30, glowColor: shielded ? 'rgba(220,40,190,.8)' : hp < 50 ? 'rgba(255,40,30,.8)' : 'rgba(255,140,60,.5)' });
        if (shielded) text(ctx, '护盾遮挡', px + 44, py + 462, { font: font('serif', 92, 900), fill: '#ff9ae8', glow: 16, glowColor: 'rgba(220,40,190,.8)' });
        chip(ctx, '阈值 50%', px + pw - 44 - 150, py + 360, { font: font('mono', 22, 700), h: 42, pad: 16, fill: PAL.gold });
        text(ctx, '血量 = 圆缺面积 ÷ 圆面积', px + 48, py + 530, { font: font('sans', 26, 500), fill: 'rgba(233,196,124,.8)', ls: 2 });
        // 小图示
        const ix = px + pw - 90, iy = py + 460, ir = 34;
        ctx.save(); ctx.beginPath(); ctx.arc(ix, iy, ir, 0, Math.PI * 2); ctx.strokeStyle = PAL.gold; ctx.lineWidth = 2; ctx.stroke(); ctx.clip();
        ctx.fillStyle = shielded ? 'rgba(200,40,170,.9)' : 'rgba(210,30,40,.9)'; ctx.fillRect(ix - ir, iy + ir - levelToHeight(level, ir), ir * 2, ir * 2); ctx.restore();
        ctx.restore();
      }
      // 状态栏
      let msg = null, col = '#a6e05a';
      if (lt >= 2.4 && lt < 4.8) { msg = '识别中…'; col = PAL.goldHi; }
      else if (lt >= 4.8 && lt < 7.2) { msg = '高于阈值 · 不喝药'; col = '#a6e05a'; }
      else if (lt >= 7.2 && lt < 7.8) { msg = '低于阈值 → 按 Q 喝药'; col = '#ffb347'; }
      else if (lt >= 7.8 && lt < 10.2) { msg = '已喝药 · 血量充足时绝不浪费'; col = '#a6e05a'; }
      else if (lt >= 10.2 && lt < 12.2) { msg = '检测到护盾遮挡 · 读不到真实血量'; col = '#ff8ae4'; }
      else if (lt >= 12.2 && lt < 14.4) { msg = '跳过喝药 · 护盾正在替你扛伤害'; col = '#ff8ae4'; }
      else if (lt >= 14.4) { msg = '单次识别仅需 15 ~ 50 ms'; col = PAL.goldHi; }
      if (msg) {
        rrect(ctx, px + 44, py + 580, pw - 88, 70, 12);
        ctx.fillStyle = 'rgba(255,255,255,.04)'; ctx.fill();
        ctx.strokeStyle = col; ctx.globalAlpha = pa * .6; ctx.lineWidth = 1.5; ctx.stroke(); ctx.globalAlpha = pa;
        ctx.fillStyle = col; ctx.beginPath(); ctx.arc(px + 78, py + 615, 7, 0, Math.PI * 2); ctx.fill();
        glow(ctx, px + 78, py + 615, 24, 'rgb(255,200,120)', .5);
        text(ctx, msg, px + 100, py + 626, { font: font('serif', 32, 900), fill: col });
      }
      // 选项 / 备注
      const togA = prog(lt, 11.4, 11.7) * (1 - prog(lt, 14.2, 14.5));
      if (togA > 0) chip(ctx, '护盾遮挡时不喝药（默认开启）', px + 44, py + 695, { font: font('sans', 22, 700), h: 42, pad: 16, icon: checkIcon(true), alpha: togA, fill: '#ffd0f4', stroke: 'rgba(255,120,230,.6)' });
      const noteA = prog(lt, 13.0, 13.3) * (1 - prog(lt, 14.2, 14.5));
      if (noteA > 0) text(ctx, '常驻护盾构筑？取消勾选即可照常喝药', px + pw - 44, py + 703, { font: font('sans', 20, 500), align: 'right', fill: 'rgba(239,230,216,.6)', alpha: noteA });
      const fbA = prog(lt, 15.0, 15.3);
      if (fbA > 0) chip(ctx, '读不到血球 → 自动退回定时喝药', px + 44, py + 695, { font: font('sans', 22, 700), h: 42, pad: 16, alpha: fbA, scale: E.outBack(fbA), fill: PAL.goldHi });
      ctx.restore();
    }
  },
});

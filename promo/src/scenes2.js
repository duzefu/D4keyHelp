// ============================================================
//  scenes2.js — 自动嬗变 / 挂机与暂停 / 配置主题 / 上手三步 / 结尾
// ============================================================

// ============================================================
//  S4  F3 自动嬗变
// ============================================================
const TR = { cell: 90, gap: 10, x0: 130, y0: 430, cols: 11, rows: 3, cubeX: 1560, cubeY: 640 };
const TR_ROWS = ['L.YB.LBY.L.', 'BY.L.B.LY.B', '.LB.YB.L.YB'];
const TR_ITEMS = [];
TR_ROWS.forEach((row, r) => [...row].forEach((ch, c) => {
  TR_ITEMS.push({ r: ch === '.' ? null : ch, row: r, col: c, shape: ITEM_KEYS[Math.floor(hash(r * 11 + c + .5) * ITEM_KEYS.length)] });
}));
const cellXY = it => [TR.x0 + it.col * (TR.cell + TR.gap), TR.y0 + it.row * (TR.cell + TR.gap)];

scene('trans', {
  tin: 'burn', tout: 'flash',
  setup(S) {
    const a = S.start;
    S.legend = TR_ITEMS.filter(i => i.r === 'L').sort((p, q) => p.col - q.col || p.row - q.row);
    S.yellow = TR_ITEMS.filter(i => i.r === 'Y');
    const beamX0 = TR.x0 - 40, beamW = TR.cols * (TR.cell + TR.gap) + 80;
    TR_ITEMS.forEach(it => { it.tc = 1.6 + ((cellXY(it)[0] + TR.cell / 2) - beamX0) / beamW * 1.6; });
    S.legend.forEach((it, k) => { it.tp = 3.4 + k * .5; cue(a + it.tc, 'blip', { pitch: 1 + k * .08 }); cue(a + it.tp, 'click'); cue(a + it.tp + .38, 'legend', { pitch: 1 + k * .06 }); });
    cue(a + 1.2, 'key', { pitch: .9, gain: .75 }); cue(a + 1.4, 'shutter'); cue(a + 1.6, 'sweep', { dur: 1.6 });
    for (let i = 0; i < 11; i++) cue(a + .4 + i * .04, 'tick', { pitch: 1.4 + i * .05, gain: .18 });
    cue(a + 7.0, 'click'); cue(a + 7.3, 'upgrade');
    cue(a + 8.4, 'pop', { pitch: 1.1 });
  },
  params(P, t, lt) {
    P.tintA = [.32, .14, .05]; P.tintB = [1, .5, .12]; P.fog = .5; P.glow = .7;
    P.flash += .25 * impulse(lt, 1.4, 9);
    P.aberr += .02 * impulse(lt, 1.2, 6);
  },
  draw(ctx, t, lt) {
    const S = this, cs = TR.cell;
    embers(ctx, t, { n: 60, seed: 44, alpha: .6, speed: 55 });
    chapterHeader(ctx, lt, '03', 'F3 自动嬗变', 'AUTO TRANSMUTE');
    const count = S.legend.filter(it => lt >= it.tp + .38).length;
    // 网格
    const gw = TR.cols * (cs + TR.gap) - TR.gap, gh = TR.rows * (cs + TR.gap) - TR.gap;
    const ga = E.outCubic(prog(lt, .2, .6));
    panel(ctx, TR.x0 - 24, TR.y0 - 24, gw + 48, gh + 48, { alpha: ga, bg: 'rgba(10,7,8,.8)' });
    TR_ITEMS.forEach(it => {
      const [x, y] = cellXY(it);
      const p = prog(lt, .4 + it.col * .04 + it.row * .03, .75 + it.col * .04 + it.row * .03);
      if (p <= 0) return;
      let item = it.r ? { r: it.r, shape: it.shape } : null;
      const scanned = lt >= it.tc;
      let dim = 0, glowV = 0;
      if (scanned && it.r !== 'L') dim = .55 * prog(lt, it.tc, it.tc + .2);
      if (it.r === 'L') glowV = scanned ? .6 + .4 * impulse(lt, it.tc, 4) : 0;
      // 升级黄装
      if (it.r === 'Y') {
        const up = 7.3 + it.col * .03;
        if (lt >= up + .2) { item = { r: 'L', shape: it.shape }; dim = 0; glowV = .6 + .4 * impulse(lt, up + .2, 4); }
        if (lt >= up && lt < up + .5) glow(ctx, x + cs / 2, y + cs / 2, 80, 'rgb(255,200,90)', Math.sin(prog(lt, up, up + .5) * Math.PI));
      }
      // 已嬗变：物品离开
      let sc = E.outBack(p);
      if (it.tp != null && lt >= it.tp) {
        const q = prog(lt, it.tp, it.tp + .15);
        sc *= 1 - q * .9;
        if (q >= 1) item = null;
      }
      itemCell(ctx, x, y, cs, item, { scale: it.tp != null && lt >= it.tp ? 1 : sc, alpha: clamp(p * 2), dim, glow: glowV });
      if (it.r === 'L' && scanned && (it.tp == null || lt < it.tp)) {
        text(ctx, '✓', x + cs - 8, y + 22, { font: font('sans', 20, 900), align: 'right', fill: '#ffb45a', alpha: prog(lt, it.tc, it.tc + .2), glow: 10 });
      }
    });
    // 截图闪光
    if (lt >= 1.4 && lt < 2) {
      ctx.save(); ctx.fillStyle = `rgba(255,245,230,${impulse(lt, 1.4, 7) * .7})`; ctx.fillRect(TR.x0 - 24, TR.y0 - 24, gw + 48, gh + 48); ctx.restore();
    }
    // 扫描光束
    if (lt >= 1.6 && lt < 3.3) {
      const bx = lerp(TR.x0 - 40, TR.x0 - 40 + gw + 80, prog(lt, 1.6, 3.2));
      ctx.save(); ctx.globalCompositeOperation = 'lighter';
      const g = ctx.createLinearGradient(bx - 120, 0, bx + 6, 0);
      g.addColorStop(0, 'rgba(255,140,40,0)'); g.addColorStop(1, 'rgba(255,170,80,.35)');
      ctx.fillStyle = g; ctx.fillRect(bx - 120, TR.y0 - 30, 126, gh + 60);
      ctx.fillStyle = 'rgba(255,230,190,.95)'; ctx.fillRect(bx - 1.5, TR.y0 - 40, 3, gh + 80);
      ctx.restore();
      glow(ctx, bx, TR.y0 - 40, 30, 'rgb(255,200,120)', .9); glow(ctx, bx, TR.y0 + gh + 40, 30, 'rgb(255,200,120)', .9);
    }
    // F3 键 + 魔盒
    const ka = E.outBack(prog(lt, .6, 1.0));
    keycap(ctx, TR.cubeX, 330, 150, 120, 'F3', { press: impulse(lt, 1.2, 10), glow: .3 + impulse(lt, 1.2, 4) * .7, scale: ka, alpha: clamp(ka) });
    const cubeG = Math.max(0, ...S.legend.map(it => impulse(lt, it.tp + .38, 5)));
    const ca = E.outCubic(prog(lt, .8, 1.3));
    ctx.save(); ctx.globalAlpha = ca;
    cube(ctx, TR.cubeX, TR.cubeY, 105, t, { glow: cubeG });
    ctx.restore();
    text(ctx, '赫拉迪姆魔盒', TR.cubeX, TR.cubeY + 170, { font: font('serif', 26, 700), align: 'center', fill: PAL.goldDim, alpha: ca, ls: 4 });
    if (lt >= 3.4) {
      text(ctx, `已嬗变  ${count} / ${S.legend.length}`, TR.cubeX, TR.cubeY + 215, { font: font('mono', 30, 800), align: 'center', fill: PAL.goldHi, glow: 16, alpha: prog(lt, 3.4, 3.7) });
    }
    // 物品飞入魔盒
    S.legend.forEach(it => {
      if (lt < it.tp || lt > it.tp + .6) return;
      const [x, y] = cellXY(it);
      const sx = x + cs / 2, sy = y + cs / 2;
      for (let k = 0; k < 14; k++) {
        const d = k * .012, p = E.inOutCubic(prog(lt - d, it.tp + .05, it.tp + .4));
        if (p <= 0 || p >= 1) continue;
        const mx = (sx + TR.cubeX) / 2, my = Math.min(sy, TR.cubeY) - 220;
        const bx = (1 - p) * (1 - p) * sx + 2 * (1 - p) * p * mx + p * p * TR.cubeX;
        const by = (1 - p) * (1 - p) * sy + 2 * (1 - p) * p * my + p * p * (TR.cubeY - 30);
        glow(ctx, bx, by, 30 - k * 1.6, 'rgb(255,150,50)', 1 - k / 14);
      }
    });
    // 光标
    if (lt >= 3.1 && lt < 7.0) {
      let cx = TR.cubeX - 200, cy = 420;
      S.legend.forEach((it, k) => {
        const [x, y] = cellXY(it);
        const prev = k === 0 ? [TR.cubeX - 200, 420] : (() => { const [px, py] = cellXY(S.legend[k - 1]); return [px + cs * .55, py + cs * .55]; })();
        const p = E.inOutCubic(prog(lt, it.tp - .28, it.tp - .02));
        if (lt >= it.tp - .28) { cx = lerp(prev[0], x + cs * .55, p); cy = lerp(prev[1], y + cs * .55, p); }
      });
      S.legend.forEach(it => { const [x, y] = cellXY(it); ripple(ctx, x + cs * .55, y + cs * .55, prog(lt, it.tp, it.tp + .4), 'rgba(255,190,110,1)', 50); });
      cursor(ctx, cx, cy, { alpha: prog(lt, 3.1, 3.3) * (1 - prog(lt, 6.8, 7.0)) });
    }
    // 说明
    const capA = prog(lt, 1.8, 2.2) * (1 - prog(lt, 6.8, 7.0));
    if (capA > 0) { ctx.save(); ctx.globalAlpha = capA; revealText(ctx, '单次截图 · 按边框光效识别传奇 · 跳过稀有 / 魔法 / 空格', TR.x0 + gw / 2, 810, lt - 1.8, { font: font('serif', 32, 700), stagger: .015, dur: .35, dy: 10, fill: PAL.bone, ls: 2 }); ctx.restore(); }
    if (capA > 0) { ctx.save(); ctx.globalAlpha = capA * prog(lt, 3.4, 3.8); text(ctx, '逐个右键传奇物品 → 自动点击嬗变', TR.x0 + gw / 2, 866, { font: font('sans', 26, 500), align: 'center', fill: 'rgba(233,196,124,.85)', ls: 2 }); ctx.restore(); }
    if (lt >= 6.9) {
      const p = E.outBack(prog(lt, 7.0, 7.35));
      chip(ctx, '升级黄装', TR.x0 + gw / 2, 800, { align: 'center', font: font('sans', 28, 700), h: 52, pad: 22, icon: checkIcon(lt >= 7.0), scale: p, alpha: clamp(p), fill: '#ffe68a', glowC: 'rgba(255,200,60,.8)' });
      ctx.save(); ctx.globalAlpha = prog(lt, 7.4, 7.8);
      revealText(ctx, '先给黄装加词条、升成传奇，再一起嬗变', TR.x0 + gw / 2, 872, lt - 7.4, { font: font('sans', 28, 500), stagger: .02, dur: .3, dy: 8, fill: 'rgba(239,230,216,.85)', ls: 2 });
      ctx.restore();
    }
    const cancelA = E.outBack(prog(lt, 8.4, 8.8));
    if (cancelA > 0) chip(ctx, '运行中再按 F3 · 随时取消', TR.cubeX, 950, { align: 'center', font: font('sans', 22, 700), h: 44, scale: cancelA, alpha: clamp(cancelA), fill: PAL.goldHi });
  },
});

// ============================================================
//  S5  挂机 & 智能暂停
// ============================================================
const AF = { cx: 540, cy: 600, R: 320, hexR: 215 };
const AF_PAUSES = [[3.0, 3.9], [4.8, 5.7], [6.6, 7.5]];
function afActive(lt) { let a = lt; for (const [s, e] of AF_PAUSES) a -= clamp(lt - s, 0, e - s); return a; }
function afPausedIdx(lt) { return AF_PAUSES.findIndex(([s, e]) => lt >= s && lt < e); }
const hexPt = k => { const an = ((k % 6) + 6) % 6 * Math.PI / 3 - Math.PI / 2; return [AF.cx + Math.cos(an) * AF.hexR, AF.cy + Math.sin(an) * AF.hexR]; };
function afChar(at) {
  if (at < .4) return hexPt(0);
  const u = (at - .4) / 1.2, k = Math.floor(u), f = E.inOutSine(u - k);
  const A = hexPt(k), B = hexPt(k + 1);
  return [lerp(A[0], B[0], f), lerp(A[1], B[1], f)];
}
function afCursor(at) {
  if (at < .4) return hexPt(1);
  const u = (at - .4) / 1.2, k = Math.floor(u), f = E.outCubic(clamp((u - k) * 8));
  const A = hexPt(k + 1), B = hexPt(k + 2);
  return [lerp(A[0], B[0], f), lerp(A[1], B[1], f)];
}
scene('afk', {
  tin: 'flash', tout: 'burn',
  setup(S) {
    const a = S.start;
    const r = mulberry32(555);
    S.souls = [];
    for (let i = 0; i < 20; i++) {
      const k = Math.floor(r() * 6), u = .15 + r() * .7, A = hexPt(k), B = hexPt(k + 1);
      const nx = -(B[1] - A[1]), ny = B[0] - A[0], nl = Math.hypot(nx, ny), off = (r() - .5) * 60;
      S.souls.push({ x: lerp(A[0], B[0], u) + nx / nl * off, y: lerp(A[1], B[1], u) + ny / nl * off, seed: r() });
    }
    // 预计算每个魂魄被拾取的真实时刻
    S.souls.forEach(sl => {
      sl.ct = null;
      for (let lt = .5; lt < 9.6; lt += .02) {
        const p = afChar(afActive(lt));
        if (Math.hypot(p[0] - sl.x, p[1] - sl.y) < 48) { sl.ct = lt; break; }
      }
      if (sl.ct != null) cue(a + sl.ct, 'soul', { pitch: .9 + sl.seed * .5 });
    });
    AF_PAUSES.forEach(([s, e], i) => { cue(a + s, 'pause'); cue(a + e, 'resume'); cue(a + s - .6, 'whoosh', { gain: .25 }); });
    cue(a + 8.2, 'chime', { f: 880 });
  },
  params(P, t, lt) {
    P.tintA = [.2, .12, .16]; P.tintB = [.9, .45, .2]; P.fog = .5; P.glow = .5;
    const pi = afPausedIdx(lt);
    if (pi >= 0) P.aberr += .0025;
  },
  draw(ctx, t, lt) {
    const S = this, { cx, cy, R } = AF;
    embers(ctx, t, { n: 40, seed: 55, alpha: .45, speed: 40, colors: ['rgb(255,140,60)', 'rgb(120,160,255)'] });
    chapterHeader(ctx, lt, '04', '挂机与智能暂停', 'AFK & SMART PAUSE');
    const at = afActive(lt), pi = afPausedIdx(lt);
    const ap = E.outCubic(prog(lt, .1, .8));
    // 场地
    ctx.save(); ctx.globalAlpha = ap;
    ctx.translate(cx, cy); ctx.scale(lerp(.85, 1, ap), lerp(.85, 1, ap)); ctx.translate(-cx, -cy);
    const fg = ctx.createRadialGradient(cx, cy, 0, cx, cy, R);
    fg.addColorStop(0, '#2a2024'); fg.addColorStop(.8, '#150f12'); fg.addColorStop(1, '#0a0708');
    ctx.fillStyle = fg; ctx.beginPath(); ctx.arc(cx, cy, R, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = 'rgba(233,196,124,.45)'; ctx.lineWidth = 3; ctx.stroke();
    ctx.save(); ctx.beginPath(); ctx.arc(cx, cy, R, 0, Math.PI * 2); ctx.clip();
    ctx.strokeStyle = 'rgba(255,255,255,.04)'; ctx.lineWidth = 1;
    for (let k = 0; k < 14; k++) { ctx.beginPath(); ctx.arc(cx, cy, 40 + k * 22, 0, Math.PI * 2); ctx.stroke(); }
    for (let k = 0; k < 12; k++) { const an = k * Math.PI / 6; ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx + Math.cos(an) * R, cy + Math.sin(an) * R); ctx.stroke(); }
    ctx.restore();
    runeCircle(ctx, cx, cy, R * .93, t, { p: 1, alpha: .28, blur: 8, runes: 48, seed: 3, star: false });
    // 六点路径
    ctx.strokeStyle = 'rgba(255,190,110,.25)'; ctx.setLineDash([6, 10]); ctx.lineWidth = 2;
    ctx.beginPath(); for (let k = 0; k <= 6; k++) { const p = hexPt(k); k ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke(); ctx.setLineDash([]);
    for (let k = 0; k < 6; k++) { const p = hexPt(k); ctx.fillStyle = 'rgba(255,200,130,.6)'; ctx.beginPath(); ctx.arc(p[0], p[1], 5, 0, 7); ctx.fill(); }
    // 魂魄
    const ch = afChar(at);
    S.souls.forEach(sl => {
      const bob = Math.sin(t * 3 + sl.seed * 20) * 5;
      if (sl.ct == null || lt < sl.ct) {
        glow(ctx, sl.x, sl.y + bob, 26, 'rgb(90,150,255)', .8); glow(ctx, sl.x, sl.y + bob, 7, 'rgb(220,235,255)', 1);
      } else if (lt < sl.ct + .35) {
        const p = E.inCubic(prog(lt, sl.ct, sl.ct + .3));
        glow(ctx, lerp(sl.x, ch[0], p), lerp(sl.y, ch[1], p), 22 * (1 - p) + 6, 'rgb(140,190,255)', 1 - p * .5);
        ripple(ctx, ch[0], ch[1], prog(lt, sl.ct + .25, sl.ct + .7), 'rgba(140,190,255,1)', 44);
      }
    });
    // 拖尾 + 角色
    for (let j = 30; j >= 1; j--) {
      const tp = afChar(Math.max(0, at - j * .025));
      glow(ctx, tp[0], tp[1], 26 - j * .6, 'rgb(255,130,40)', (1 - j / 30) * .5);
    }
    glow(ctx, ch[0], ch[1], 70, 'rgb(255,140,50)', .8); glow(ctx, ch[0], ch[1], 14, 'rgb(255,240,210)', 1);
    // 光标 + 强移涟漪
    const cu = afCursor(at);
    for (let k = 0; k < 4; k++) { const ph = ((at * 3.3) + k / 4) % 1; ripple(ctx, cu[0], cu[1], ph, 'rgba(255,200,130,.8)', 34); }
    cursor(ctx, cu[0], cu[1], { scale: .85 });
    // 暂停遮罩
    const pA = pi >= 0 ? Math.min(prog(lt, AF_PAUSES[pi][0], AF_PAUSES[pi][0] + .15), 1 - prog(lt, AF_PAUSES[pi][1] - .15, AF_PAUSES[pi][1])) : 0;
    if (pA > 0) {
      ctx.fillStyle = `rgba(6,4,5,${pA * .6})`; ctx.beginPath(); ctx.arc(cx, cy, R, 0, Math.PI * 2); ctx.fill();
      if (pi === 1) { // 地图
        ctx.save(); ctx.globalAlpha = pA; ctx.beginPath(); ctx.arc(cx, cy, R, 0, Math.PI * 2); ctx.clip();
        ctx.fillStyle = 'rgba(60,45,30,.55)'; ctx.fillRect(cx - R, cy - R, R * 2, R * 2);
        ctx.strokeStyle = 'rgba(233,196,124,.3)'; for (let k = -8; k <= 8; k++) { ctx.beginPath(); ctx.moveTo(cx + k * 40, cy - R); ctx.lineTo(cx + k * 40, cy + R); ctx.moveTo(cx - R, cy + k * 40); ctx.lineTo(cx + R, cy + k * 40); ctx.stroke(); }
        ctx.restore();
      }
      ctx.save(); ctx.globalAlpha = pA; ctx.fillStyle = '#ffcf7a'; ctx.shadowColor = 'rgba(255,150,40,1)'; ctx.shadowBlur = 30;
      ctx.fillRect(cx - 34, cy - 45, 22, 90); ctx.fillRect(cx + 12, cy - 45, 22, 90); ctx.restore();
    }
    ctx.restore();
    // 贡品计时环
    const tA = prog(lt, 1.0, 1.4) * ap;
    if (tA > 0) {
      const rx = cx + R * .86, ry = cy - R * .86, tp = clamp(at / 8.0);
      ctx.save(); ctx.globalAlpha = tA;
      ctx.fillStyle = 'rgba(12,8,9,.85)'; ctx.beginPath(); ctx.arc(rx, ry, 52, 0, 7); ctx.fill();
      ctx.strokeStyle = 'rgba(255,255,255,.12)'; ctx.lineWidth = 6; ctx.beginPath(); ctx.arc(rx, ry, 42, 0, 7); ctx.stroke();
      ctx.strokeStyle = PAL.gold; ctx.shadowColor = 'rgba(255,150,50,1)'; ctx.shadowBlur = 14; ctx.lineCap = 'round';
      ctx.beginPath(); ctx.arc(rx, ry, 42, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * tp); ctx.stroke();
      ctx.restore();
      text(ctx, lt >= 8.2 ? '贡品!' : Math.max(0, Math.ceil(65 * (1 - tp))) + 's', rx, ry + 9, { font: font('mono', 24, 800), align: 'center', fill: PAL.goldHi, alpha: tA });
      glow(ctx, rx, ry, 120, 'rgb(255,190,80)', impulse(lt, 8.2, 3));
      text(ctx, '罗盘专用 · 定时点贡品', rx, ry - 70, { font: font('sans', 20, 700), align: 'center', fill: PAL.goldDim, alpha: tA });
    }
    // 场地说明
    const la = prog(lt, 1.2, 1.6);
    if (la > 0) {
      ctx.save(); ctx.globalAlpha = la;
      revealText(ctx, '鼠标六点绕圈 + 强制移动：自动走位、捡魂魄、打怪', cx, 985, lt - 1.2, { font: font('sans', 27, 500), stagger: .015, dur: .3, dy: 8, fill: 'rgba(239,230,216,.88)', ls: 1 });
      ctx.restore();
    }
    // 右侧：智能暂停
    const pa = E.outCubic(prog(lt, 2.2, 2.8));
    if (pa > 0) {
      const px = 1010, py = 260, pw = 790, ph = 660;
      ctx.save(); ctx.globalAlpha = pa; ctx.translate((1 - pa) * 60, 0);
      panel(ctx, px, py, pw, ph, { bg: 'rgba(12,8,9,.82)' });
      text(ctx, '智能暂停', px + 44, py + 78, { font: font('serif', 50, 900), fill: PAL.goldHi, glow: 16, glowColor: 'rgba(255,90,20,.5)' });
      const st = pi < 0 ? ['● 运行中', '#8fe07a'] : pi === 2 ? ['● 临时暂停', '#ffbf5a'] : ['● 已暂停', '#ffbf5a'];
      const stF = font('sans', 24, 700);
      chip(ctx, st[0], px + pw - 44 - (measure(ctx, st[0], stF) + 36), py + 60, { font: stF, h: 44, pad: 18, fill: st[1], stroke: st[1] });
      const rows = [
        { t0: 2.6, title: '切出游戏窗口', sub: '自动暂停，切回游戏自动恢复', icon: 'win' },
        { t0: 4.4, title: 'Tab 查看地图', sub: '暂停宏，关闭地图后恢复', icon: 'tab' },
        { t0: 6.2, title: '手动点击鼠标', sub: '临时暂停一段时间，方便捡装备、点界面', icon: 'mouse' },
      ];
      rows.forEach((rw, i) => {
        const p = E.outCubic(prog(lt, rw.t0, rw.t0 + .45));
        if (p <= 0) return;
        const ry = py + 130 + i * 170;
        const act = pi === i ? Math.min(prog(lt, AF_PAUSES[i][0], AF_PAUSES[i][0] + .15), 1 - prog(lt, AF_PAUSES[i][1] - .15, AF_PAUSES[i][1])) : 0;
        ctx.save(); ctx.globalAlpha = pa * p; ctx.translate((1 - p) * 40, 0);
        rrect(ctx, px + 36, ry, pw - 72, 140, 14);
        ctx.fillStyle = act > 0 ? `rgba(255,170,60,${.06 + act * .1})` : 'rgba(255,255,255,.03)'; ctx.fill();
        ctx.strokeStyle = act > 0 ? `rgba(255,190,90,${.3 + act * .7})` : 'rgba(233,196,124,.18)'; ctx.lineWidth = 2;
        if (act > 0) { ctx.shadowColor = 'rgba(255,150,40,1)'; ctx.shadowBlur = 24 * act; }
        ctx.stroke(); ctx.shadowBlur = 0;
        const ix = px + 110, iy = ry + 70;
        if (rw.icon === 'win') {
          rrect(ctx, ix - 40, iy - 30, 80, 60, 6); ctx.strokeStyle = PAL.gold; ctx.lineWidth = 3; ctx.stroke();
          ctx.fillStyle = PAL.gold; ctx.fillRect(ix - 40, iy - 30, 80, 12);
          ctx.beginPath(); ctx.moveTo(ix + 14, iy + 4); ctx.lineTo(ix + 44, iy + 34); ctx.moveTo(ix + 44, iy + 34); ctx.lineTo(ix + 44, iy + 16); ctx.moveTo(ix + 44, iy + 34); ctx.lineTo(ix + 26, iy + 34); ctx.stroke();
        } else if (rw.icon === 'tab') {
          keycap(ctx, ix, iy - 4, 100, 76, 'Tab', { fontSize: 28, press: act > .5 ? .6 : 0, glow: act });
        } else {
          rrect(ctx, ix - 26, iy - 38, 52, 76, 26); ctx.strokeStyle = PAL.gold; ctx.lineWidth = 3; ctx.stroke();
          ctx.beginPath(); ctx.moveTo(ix, iy - 38); ctx.lineTo(ix, iy - 8); ctx.moveTo(ix - 26, iy - 8); ctx.lineTo(ix + 26, iy - 8); ctx.stroke();
          ctx.fillStyle = `rgba(255,200,120,${.3 + act * .7})`; ctx.beginPath(); ctx.moveTo(ix - 24, iy - 10); ctx.lineTo(ix - 24, iy - 20); ctx.arcTo(ix - 24, iy - 36, ix - 2, iy - 36, 22); ctx.lineTo(ix - 2, iy - 10); ctx.closePath(); ctx.fill();
        }
        text(ctx, rw.title, px + 200, ry + 62, { font: font('serif', 36, 900), fill: act > 0 ? '#ffe0a8' : PAL.bone });
        text(ctx, rw.sub, px + 200, ry + 106, { font: font('sans', 24, 500), fill: 'rgba(239,230,216,.62)' });
        ctx.restore();
      });
      ctx.restore();
    }
  },
});

// ============================================================
//  S6  配置预设 & 主题
// ============================================================
const UI = { cx: 1310, cy: 590, h: 800 };
let _flat = null;
scene('ui', {
  tin: 'burn', tout: 'flash',
  setup(S) {
    const a = S.start;
    [.8, 1.25, 1.7, 2.15].forEach((x, i) => cue(a + x, 'click', { pitch: 1 + i * .06 }));
    cue(a + 2.7, 'click'); cue(a + 2.9, 'whoosh', { gain: .5 }); cue(a + 5.4, 'whoosh', { gain: .4 });
    cue(a + 4.5, 'click'); cue(a + 4.6, 'chime', { f: 1320 });
    [.6, 2.6, 4.2].forEach(x => cue(a + x, 'thump'));
  },
  params(P, t, lt) {
    P.tintA = [.26, .12, .1]; P.fog = .5; P.glow = .5;
    const wipe = Math.sin(prog(lt, 2.9, 3.5) * Math.PI) + Math.sin(prog(lt, 5.4, 6.0) * Math.PI);
    P.aberr += wipe * .004;
    P.bloomThr = .93; P.bloom = .55;
  },
  draw(ctx, t, lt) {
    const imgD = IMG.dark, imgL = IMG.light;
    if (!imgD || !imgL) return;
    embers(ctx, t, { n: 40, seed: 66, alpha: .4, speed: 40 });
    chapterHeader(ctx, lt, '05', '配置与主题', 'PRESETS & THEMES');
    const iw = imgD.width, ih = imgD.height;
    if (!_flat) { _flat = document.createElement('canvas'); _flat.width = iw; _flat.height = ih; }
    const g = _flat.getContext('2d');
    // 浅深色擦除
    const m = E.inOutCubic(prog(lt, 2.9, 3.5)) * (1 - E.inOutCubic(prog(lt, 5.4, 6.0)));
    g.clearRect(0, 0, iw, ih);
    g.drawImage(imgD, 0, 0);
    if (m > 0) {
      const ex = lerp(-300, iw + 300, m);
      g.save(); g.beginPath(); g.moveTo(-300, 0); g.lineTo(ex + 150, 0); g.lineTo(ex - 150, ih); g.lineTo(-300, ih); g.closePath(); g.clip();
      g.drawImage(imgL, 0, 0); g.fillStyle = 'rgba(20,14,10,.14)'; g.fillRect(0, 0, iw, ih); g.restore();
      if (m < 1) {
        g.save(); g.globalCompositeOperation = 'lighter'; g.strokeStyle = 'rgba(255,200,120,.9)'; g.lineWidth = 6; g.shadowColor = 'rgba(255,150,50,1)'; g.shadowBlur = 30;
        g.beginPath(); g.moveTo(ex + 150, 0); g.lineTo(ex - 150, ih); g.stroke(); g.restore();
      }
    }
    // 预设标签高亮
    const tabX = [92, 222, 350, 480];
    if (lt >= .8 && lt < 2.6) {
      const k = Math.min(3, Math.floor((lt - .8) / .45)), kp = prog(lt, .8 + k * .45, .95 + k * .45);
      g.save(); g.strokeStyle = 'rgba(255,170,60,1)'; g.lineWidth = 4; g.shadowColor = 'rgba(255,140,40,1)'; g.shadowBlur = 20;
      g.globalAlpha = 1 - prog(lt, 2.4, 2.6);
      rrect(g, tabX[k] - 64 - (1 - kp) * 8, 56 - (1 - kp) * 4, 128 + (1 - kp) * 16, 44 + (1 - kp) * 8, 10); g.stroke(); g.restore();
      if (lt >= 1.6 && lt < 2.6) {
        g.save(); g.globalAlpha = prog(lt, 1.6, 1.8) * (1 - prog(lt, 2.4, 2.6));
        rrect(g, 250, 104, 150, 52, 8); g.fillStyle = '#2a2226'; g.fill(); g.strokeStyle = 'rgba(233,196,124,.8)'; g.lineWidth = 2; g.stroke();
        g.font = font('sans', 22, 700); g.fillStyle = '#ffe0a8'; g.textBaseline = 'middle'; g.fillText('✎ 重命名', 270, 131); g.restore();
      }
    }
    const hiBox = (x, y, w, h, a) => { if (a <= 0) return; g.save(); g.globalAlpha = a; g.strokeStyle = 'rgba(255,170,60,1)'; g.lineWidth = 4; g.shadowColor = 'rgba(255,140,40,1)'; g.shadowBlur = 20; rrect(g, x, y, w, h, 12); g.stroke(); g.restore(); };
    hiBox(772, 56, 124, 44, prog(lt, 2.5, 2.7) * (1 - prog(lt, 3.3, 3.5)));
    hiBox(760, 850, 122, 52, prog(lt, 4.3, 4.5) * (1 - prog(lt, 5.1, 5.3)));

    // 伪 3D 面板
    const ap = E.outCubic(prog(lt, .1, 1.0));
    const th = lerp(.55, .2, E.outCubic(prog(lt, 0, 2.5))) - Math.max(0, lt - 2.5) * .02;
    const sc = UI.h / ih, w = iw * sc, h = ih * sc, f = 1500;
    const ox = UI.cx + (1 - ap) * 260;
    const N = 150, cols = [];
    for (let i = 0; i <= N; i++) {
      const u = i / N, x3 = (u - .5) * w, z = x3 * Math.sin(th), s = f / (f + z);
      cols.push([ox + x3 * Math.cos(th) * s, h * s]);
    }
    ctx.save(); ctx.globalAlpha = ap;
    // 阴影
    ctx.fillStyle = 'rgba(0,0,0,.6)'; ctx.filter = 'blur(30px)';
    ctx.beginPath(); ctx.moveTo(cols[0][0], UI.cy - cols[0][1] / 2 + 40); ctx.lineTo(cols[N][0], UI.cy - cols[N][1] / 2 + 40);
    ctx.lineTo(cols[N][0], UI.cy + cols[N][1] / 2 + 40); ctx.lineTo(cols[0][0], UI.cy + cols[0][1] / 2 + 40); ctx.fill(); ctx.filter = 'none';
    for (let i = 0; i < N; i++) {
      const [x0, h0] = cols[i], [x1] = cols[i + 1];
      ctx.drawImage(_flat, i / N * iw, 0, iw / N + .5, ih, x0, UI.cy - h0 / 2, x1 - x0 + .8, h0);
    }
    // 边框光
    ctx.strokeStyle = 'rgba(233,196,124,.7)'; ctx.lineWidth = 2; ctx.shadowColor = 'rgba(255,140,40,.9)'; ctx.shadowBlur = 24;
    ctx.beginPath(); ctx.moveTo(cols[0][0], UI.cy - cols[0][1] / 2); ctx.lineTo(cols[N][0], UI.cy - cols[N][1] / 2);
    ctx.lineTo(cols[N][0], UI.cy + cols[N][1] / 2); ctx.lineTo(cols[0][0], UI.cy + cols[0][1] / 2); ctx.closePath(); ctx.stroke();
    ctx.restore();
    // 左侧要点
    const pts = [
      { t0: .6, title: '4 套配置预设', sub: '一键切换，右键配置名即可重命名' },
      { t0: 2.6, title: '浅色 / 深色主题', sub: '右上角随时切换，界面现代圆角风格' },
      { t0: 4.2, title: '设置自动保存', sub: '写入 settings.ini，下次启动自动恢复' },
    ];
    pts.forEach((p, i) => {
      const a = E.outCubic(prog(lt, p.t0, p.t0 + .5));
      if (a <= 0) return;
      const y = 400 + i * 175;
      ctx.save(); ctx.globalAlpha = a; ctx.translate(-(1 - a) * 50, 0);
      ctx.save(); ctx.translate(150, y - 14); ctx.rotate(Math.PI / 4); ctx.fillStyle = PAL.gold; ctx.shadowColor = 'rgba(255,140,40,1)'; ctx.shadowBlur = 16; ctx.fillRect(-9, -9, 18, 18); ctx.restore();
      text(ctx, p.title, 190, y, { font: font('serif', 46, 900), fill: PAL.goldHi, glow: 14, glowColor: 'rgba(255,90,20,.45)' });
      text(ctx, p.sub, 190, y + 50, { font: font('sans', 26, 500), fill: 'rgba(239,230,216,.72)' });
      ctx.restore();
    });
  },
});

// ============================================================
//  S7  上手三步
// ============================================================
const HT = { cardW: 500, cardH: 545, top: 262, xs: [400, 960, 1520] };
scene('howto', {
  tin: 'flash', tout: 'flash',
  setup(S) {
    const a = S.start;
    [1.0, 3.4, 5.8].forEach(x => { cue(a + x, 'whoosh', { gain: .35 }); cue(a + x + .25, 'thump'); });
    cue(a + 1.6, 'drop'); cue(a + 2.3, 'click'); cue(a + 2.42, 'click', { pitch: 1.1 });
    cue(a + 4.0, 'click'); cue(a + 4.8, 'click');
    cue(a + 6.6, 'key', { pitch: .9, gain: .8 }); cue(a + 6.6, 'impact', { gain: .6 });
    [8.4, 9.0, 9.6].forEach((x, i) => cue(a + x, 'key', { pitch: 1 + i * .12, gain: .55 }));
    cue(a + 10.8, 'shimmer');
  },
  params(P, t, lt) {
    P.tintA = [.3, .12, .07]; P.fog = .5; P.glow = .6;
    P.flash += .3 * impulse(lt, 6.6, 8); P.aberr += .04 * impulse(lt, 6.6, 5); P.shake = shakeUV(lt, [6.6], .005);
  },
  draw(ctx, t, lt) {
    embers(ctx, t, { n: 60, seed: 77, alpha: .55, speed: 55 });
    revealText(ctx, '上手只需三步', 960, 160, lt - .1, {
      font: font('serif', 72, 900), stagger: .06, dur: .5, dy: 20, scale0: 1.3, ls: 10,
      grad: [[0, '#fff4da'], [1, '#e2ae5e']], glow: 26, glowColor: 'rgba(255,90,20,.6)',
    });
    revealText(ctx, 'GET STARTED IN THREE STEPS', 960, 208, lt - .4, { font: font('cinzel', 20, 700), ls: 10, fill: PAL.goldDim, stagger: .015, dur: .4, dy: 6 });
    const cards = [
      { t0: 1.0, n: '1', title: '下载运行', l1: 'Releases 下载 D4keyHelp.exe', l2: '双击运行，无需安装 AHK', l3: '源码版：AutoHotkey v2 运行 macro_script_v3.ahk' },
      { t0: 3.4, n: '2', title: '配置策略', l1: '为技能选「策略」与「执行间隔」', l2: '修改即自动保存', l3: '' },
      { t0: 5.8, n: '3', title: '一键开战', l1: '切回游戏，按 F1 开始', l2: '再按一次即停止', l3: '启停键可改为鼠标中键 / 侧键' },
    ];
    cards.forEach((c, i) => {
      const p = prog(lt, c.t0, c.t0 + .6);
      if (p <= 0) return;
      const e = E.outBack(p), cx = HT.xs[i], top = HT.top + (1 - e) * 80, L = cx - HT.cardW / 2;
      const focus = lt >= c.t0 && lt < c.t0 + 2.4 ? 1 : .0;
      ctx.save(); ctx.globalAlpha = clamp(p * 2);
      panel(ctx, L, top, HT.cardW, HT.cardH, { bg: 'rgba(14,9,10,.84)', stroke: focus ? 'rgba(255,190,110,.8)' : undefined });
      if (focus) glow(ctx, cx, top, 240, 'rgb(255,120,40)', .18);
      // 编号
      ctx.save(); ctx.strokeStyle = PAL.gold; ctx.lineWidth = 2; ctx.shadowColor = 'rgba(255,140,40,1)'; ctx.shadowBlur = 16;
      ctx.beginPath(); ctx.arc(L + 66, top + 70, 34, 0, Math.PI * 2); ctx.stroke(); ctx.restore();
      text(ctx, c.n, L + 66, top + 86, { font: font('cinzel', 44, 900), align: 'center', fill: PAL.goldHi });
      text(ctx, c.title, L + 120, top + 86, { font: font('serif', 44, 900), fill: PAL.goldHi, glow: 12, glowColor: 'rgba(255,90,20,.45)' });
      // 视觉区
      const vy = top + 135, vh = 250, lt2 = lt - c.t0;
      ctx.save(); rrect(ctx, L + 30, vy, HT.cardW - 60, vh, 12); ctx.fillStyle = 'rgba(0,0,0,.35)'; ctx.fill(); ctx.clip();
      if (i === 0) drawStep1(ctx, cx, vy + vh / 2, lt2, t);
      if (i === 1) drawStep2(ctx, cx, vy + vh / 2, lt2, t);
      if (i === 2) drawStep3(ctx, cx, vy + vh / 2, lt2, t);
      ctx.restore();
      text(ctx, c.l1, cx, top + 432, { font: font('sans', 27, 700), align: 'center', fill: PAL.bone });
      text(ctx, c.l2, cx, top + 472, { font: font('sans', 24, 500), align: 'center', fill: 'rgba(239,230,216,.7)' });
      if (c.l3) text(ctx, c.l3, cx, top + 506, { font: font('sans', 18, 500), align: 'center', fill: 'rgba(233,196,124,.6)' });
      ctx.restore();
    });
    // 热键条
    const keys = [['F1', '启动 / 停止'], ['F3', '自动嬗变'], ['Tab', '看地图暂停']];
    const kf = font('serif', 30, 700);
    const iw = keys.map(k => 96 + 16 + measure(ctx, k[1], kf));
    let x = 960 - (iw.reduce((a, b) => a + b, 0) + 70 * 2) / 2;
    keys.forEach((k, i) => {
      const t0 = 8.4 + i * .6, p = E.outBack(prog(lt, t0, t0 + .4));
      if (p > 0) {
        keycap(ctx, x + 48, 880, 96, 78, k[0], { fontSize: k[0] === 'Tab' ? 26 : 30, press: impulse(lt, t0, 10), glow: .3 + impulse(lt, t0, 4) * .7, scale: p, alpha: clamp(p) });
        text(ctx, k[1], x + 96 + 16, 892, { font: kf, fill: PAL.bone, alpha: clamp(p) });
      }
      x += iw[i] + 70;
    });
    const na = prog(lt, 10.8, 11.3);
    if (na > 0) {
      revealText(ctx, '※ 所有热键仅在暗黑4窗口激活时生效 · 切出游戏自动暂停', 960, 1000, lt - 10.8, { font: font('sans', 24, 500), stagger: .012, dur: .3, dy: 6, fill: 'rgba(233,196,124,.75)', ls: 2 });
    }
  },
});
function drawStep1(ctx, cx, cy, lt, t) {
  const drop = E.outBack(prog(lt, .2, .6)), clickG = impulse(lt, 1.3, 5) + impulse(lt, 1.42, 5);
  const fx = cx - 60, fy = cy - 80 + (1 - drop) * -60;
  ctx.save(); ctx.globalAlpha = clamp(drop * 2);
  // 文件
  ctx.beginPath(); ctx.moveTo(fx, fy); ctx.lineTo(fx + 90, fy); ctx.lineTo(fx + 120, fy + 30); ctx.lineTo(fx + 120, fy + 160); ctx.lineTo(fx, fy + 160); ctx.closePath();
  ctx.fillStyle = linGrad(ctx, 0, fy, 0, fy + 160, [[0, '#3a3034'], [1, '#1c1619']]); ctx.fill();
  ctx.strokeStyle = PAL.gold; ctx.lineWidth = 2; ctx.stroke();
  if (clickG > 0) { ctx.shadowColor = 'rgba(255,170,70,1)'; ctx.shadowBlur = 30 * clickG; ctx.stroke(); ctx.shadowBlur = 0; }
  ctx.beginPath(); ctx.moveTo(fx + 90, fy); ctx.lineTo(fx + 90, fy + 30); ctx.lineTo(fx + 120, fy + 30); ctx.stroke();
  rrect(ctx, fx + 30, fy + 50, 60, 60, 12); ctx.fillStyle = '#2f9e44'; ctx.fill();
  text(ctx, 'H', fx + 60, fy + 94, { font: font('sans', 40, 900), align: 'center', fill: '#fff' });
  text(ctx, 'EXE', fx + 60, fy + 145, { font: font('mono', 20, 800), align: 'center', fill: PAL.goldHi });
  ctx.restore();
  // 下载箭头
  const ap = prog(lt, 0, .6);
  if (ap < 1) {
    const ay = lerp(cy - 150, cy - 40, E.inCubic(ap));
    ctx.save(); ctx.globalAlpha = 1 - ap; ctx.strokeStyle = PAL.goldHi; ctx.lineWidth = 6; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(cx + 110, ay - 40); ctx.lineTo(cx + 110, ay); ctx.moveTo(cx + 92, ay - 18); ctx.lineTo(cx + 110, ay); ctx.lineTo(cx + 128, ay - 18); ctx.stroke(); ctx.restore();
  }
  if (lt > 1.1) cursor(ctx, cx + 40, cy + 20, { alpha: prog(lt, 1.1, 1.25) });
  ripple(ctx, cx + 40, cy + 20, prog(lt, 1.3, 1.7), 'rgba(255,200,120,1)', 50);
  ripple(ctx, cx + 40, cy + 20, prog(lt, 1.42, 1.85), 'rgba(255,200,120,1)', 50);
}
function drawStep2(ctx, cx, cy, lt, t) {
  const img = IMG.dark; if (!img) return;
  const sx = 30, sy = 120, sw = 862, sh = 372, dw = 430, dh = sh * dw / sw;
  const dx = cx - dw / 2, dy = cy - dh / 2;
  ctx.save(); ctx.globalAlpha = prog(lt, .1, .4);
  ctx.drawImage(img, sx, sy, sw, sh, dx, dy, dw, dh);
  const k = dw / sw;
  const col = (x0, x1, a) => {
    if (a <= 0) return;
    ctx.save(); ctx.globalAlpha = a; ctx.strokeStyle = 'rgba(255,170,60,1)'; ctx.lineWidth = 3; ctx.shadowColor = 'rgba(255,140,40,1)'; ctx.shadowBlur = 16;
    rrect(ctx, dx + (x0 - sx) * k, dy + (200 - sy) * k, (x1 - x0) * k, (482 - 200) * k, 8); ctx.stroke(); ctx.restore();
  };
  col(272, 402, prog(lt, .5, .7) * (1 - prog(lt, 1.3, 1.45)));
  col(410, 564, prog(lt, 1.35, 1.55));
  const cxp = lt < 1.4 ? lerp(dx + 200, dx + (340 - sx) * k, E.inOutCubic(prog(lt, .3, .6))) : lerp(dx + (340 - sx) * k, dx + (490 - sx) * k, E.inOutCubic(prog(lt, 1.2, 1.4)));
  cursor(ctx, cxp, dy + (225 - sy) * k, { scale: .8, alpha: prog(lt, .3, .45) });
  ripple(ctx, dx + (340 - sx) * k, dy + (225 - sy) * k, prog(lt, .6, 1.0), 'rgba(255,200,120,1)', 36);
  ripple(ctx, dx + (490 - sx) * k, dy + (225 - sy) * k, prog(lt, 1.4, 1.8), 'rgba(255,200,120,1)', 36);
  ctx.restore();
}
function drawStep3(ctx, cx, cy, lt, t) {
  const pr = lt >= .8 ? impulse(lt, .8, 6) : 0, on = lt >= .8;
  keycap(ctx, cx - 110, cy - 10, 150, 130, 'F1', { press: pr, glow: .35 + pr * .65 + (on ? .2 : 0), scale: E.outBack(prog(lt, .1, .5)) });
  ripple(ctx, cx - 110, cy - 10, prog(lt, .8, 1.5), 'rgba(255,190,110,1)', 150);
  // 开始/停止按钮
  const bx = cx + 35, by = cy - 40, bw = 170, bh = 64;
  const m = E.outCubic(prog(lt, .85, 1.1));
  const c0 = [37, 99, 235], c1 = [214, 48, 49];
  const cc = c0.map((v, i) => Math.round(lerp(v, c1[i], m)));
  ctx.save(); ctx.globalAlpha = prog(lt, .2, .5);
  rrect(ctx, bx, by, bw, bh, 12); ctx.fillStyle = `rgb(${cc})`; ctx.shadowColor = `rgba(${cc},.6)`; ctx.shadowBlur = 12 + pr * 20; ctx.fill(); ctx.shadowBlur = 0;
  text(ctx, on ? '停止 (F1)' : '开始 (F1)', bx + bw / 2, by + bh / 2 + 1, { font: font('sans', 26, 700), align: 'center', baseline: 'middle', fill: '#fff' });
  ctx.restore();
  if (on) {
    const a = prog(lt, 1.0, 1.3);
    ctx.save(); ctx.globalAlpha = a; ctx.fillStyle = '#8fe07a'; ctx.beginPath(); ctx.arc(bx + 16, by + 104, 7, 0, 7); ctx.fill(); ctx.restore();
    glow(ctx, bx + 16, by + 104, 22, 'rgb(140,230,110)', a * (.6 + .4 * Math.sin(t * 6)));
    text(ctx, '状态：运行中', bx + 34, by + 113, { font: font('sans', 24, 700), fill: '#bff0a8', alpha: a });
  }
}

// ============================================================
//  S8  结尾
// ============================================================
scene('outro', {
  tin: 'flash',
  setup(S) {
    const a = S.start;
    cue(a, 'boom', { gain: 1 });
    cue(a + 1.6, 'shimmer');
    const url = 'github.com/duzefu/D4keyHelp';
    for (let i = 0; i < url.length; i++) cue(a + 2.2 + i * .04, 'type1', { gain: .5 });
    [3.6, 3.85, 4.1].forEach((x, i) => cue(a + x, 'pop', { pitch: 1 + i * .12 }));
  },
  params(P, t, lt) {
    P.tintA = [.34, .09, .07]; P.glow = .8; P.fog = .65;
    P.flash += .6 * impulse(lt, 0, 5); P.aberr += .05 * impulse(lt, 0, 4); P.shake = shakeUV(lt, [0], .007);
    P.fade = 1 - E.inOutSine(prog(lt, 6.6, 9.4));
  },
  draw(ctx, t, lt) {
    const cx = 960, cy = 450;
    embers(ctx, t, { n: 130, seed: 88, alpha: 1, speed: 65 });
    const R = 320 * (1 + lt * .012);
    glow(ctx, cx, cy, 480, 'rgb(255,80,25)', .22);
    runeCircle(ctx, cx, cy, R, t, { p: prog(lt, 0, 1.4), alpha: lerp(1, .38, prog(lt, .6, 1.6)), seed: 5 });
    metalText(ctx, 'D4KEYHELP', cx, cy, {
      font: font('cinzel', 170, 900), size: 170, ls: 16,
      perChar: i => { const p = prog(lt, .15 + i * .035, .6 + i * .035); return { a: p * 1.8, s: lerp(1.8, 1, E.outCubic(p)), dy: 0 }; },
      shine: prog(lt, 1.6, 2.9), glow: 26,
    });
    revealText(ctx, '暗黑破坏神 4 · 图形化键鼠宏助手', cx, cy + 140, lt - .9, { font: font('serif', 44, 700), ls: 6, stagger: .03, dur: .5, dy: 14, fill: PAL.bone, glow: 14, glowColor: 'rgba(255,80,20,.6)' });
    // GitHub 地址（打字）
    const url = 'github.com/duzefu/D4keyHelp';
    const n = Math.floor(clamp((lt - 2.2) / (url.length * .04)) * url.length);
    if (lt > 2.1) {
      const f = font('mono', 40, 700), w = measure(ctx, url, f);
      const x0 = cx - w / 2;
      text(ctx, url.slice(0, n), x0, cy + 250, { font: f, fill: PAL.goldHi, glow: 18, glowColor: 'rgba(255,120,40,.6)' });
      if (Math.floor(t * 2.5) % 2 === 0 || lt < 3.4) {
        const cw = measure(ctx, url.slice(0, n), f);
        ctx.fillStyle = PAL.goldHi; ctx.fillRect(x0 + cw + 4, cy + 218, 3, 40);
      }
    }
    const labels = ['★ 欢迎 Star', 'MIT 开源', 'AutoHotkey v2.0'];
    const f = font('sans', 24, 700);
    const ws = labels.map(s => measure(ctx, s, f) + 44);
    let x = cx - (ws.reduce((a, b) => a + b, 0) + 24 * 2) / 2;
    labels.forEach((s, i) => {
      const p = prog(lt, 3.6 + i * .25, 4.0 + i * .25);
      if (p > 0) chip(ctx, s, x, cy + 345, { font: f, scale: E.outBack(p), alpha: clamp(p * 2), fill: i === 0 ? '#ffd27a' : PAL.bone });
      x += ws[i] + 24;
    });
  },
});

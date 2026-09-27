// ============================================================
//  components.js — 可复用的画面组件
// ============================================================

// ---------- 章节标题 ----------
function chapterHeader(ctx, lt, num, title, en, o = {}) {
  const x = o.x ?? 120, y = o.y ?? 150;
  const p = E.outCubic(prog(lt, 0, .7));
  const p2 = E.outCubic(prog(lt, .15, .9));
  ctx.save();
  ctx.globalAlpha = p;
  // 大号章节数字（描边金）
  ctx.font = font('cinzel', 120, 900);
  ctx.lineWidth = 2;
  ctx.strokeStyle = linGrad(ctx, 0, y - 100, 0, y + 10, [[0, 'rgba(255,230,170,.95)'], [1, 'rgba(160,100,40,.5)']]);
  ctx.textBaseline = 'alphabetic';
  ctx.strokeText(num, x - (1 - p) * 40, y + 28);
  ctx.restore();
  const nx = x + measure(ctx, num, font('cinzel', 120, 900)) + 28;
  revealText(ctx, title, nx, y - 10, lt - .15, {
    font: font('serif', 60, 900), align: 'left', stagger: .05, dur: .5, dy: 20,
    grad: [[0, '#fff3d6'], [1, '#d9a95c']], glow: 18, glowColor: 'rgba(255,90,20,.55)',
  });
  text(ctx, en, nx + 2, y + 28, { font: font('cinzel', 20, 700), ls: 8, fill: PAL.goldDim, alpha: p2 });
  // 下划线
  ctx.save();
  const lw = 620 * E.outExpo(prog(lt, .25, 1.2));
  ctx.fillStyle = linGrad(ctx, x, 0, x + 620, 0, [[0, 'rgba(233,196,124,.9)'], [1, 'rgba(233,196,124,0)']]);
  ctx.fillRect(x, y + 52, lw, 2);
  glow(ctx, x + lw, y + 53, 30, 'rgb(255,170,80)', .7 * (1 - prog(lt, .9, 1.4)));
  ctx.restore();
}

// ---------- 药丸标签 ----------
function chip(ctx, str, x, y, o = {}) {
  const f = o.font ?? font('sans', 24, 500);
  const pad = o.pad ?? 22, h = o.h ?? 46;
  const w = measure(ctx, str, f, o.ls ?? 0) + pad * 2 + (o.icon ? 30 : 0);
  const cx = o.align === 'center' ? x - w / 2 : x;
  const s = o.scale ?? 1;
  ctx.save();
  ctx.globalAlpha = o.alpha ?? 1;
  ctx.translate(cx + w / 2, y); ctx.scale(s, s); ctx.translate(-(cx + w / 2), -y);
  rrect(ctx, cx, y - h / 2, w, h, h / 2);
  ctx.fillStyle = o.bg ?? 'rgba(20,12,10,.72)'; ctx.fill();
  ctx.lineWidth = 1.5; ctx.strokeStyle = o.stroke ?? 'rgba(233,196,124,.55)'; ctx.stroke();
  if (o.glowC) { ctx.shadowColor = o.glowC; ctx.shadowBlur = 24; ctx.stroke(); ctx.shadowBlur = 0; }
  let tx = cx + pad;
  if (o.icon) { o.icon(ctx, tx + 10, y); tx += 30; }
  text(ctx, str, tx, y + 1, { font: f, baseline: 'middle', fill: o.fill ?? PAL.bone, ls: o.ls ?? 0 });
  ctx.restore();
  return w;
}

// 复选框图标
function checkIcon(on) {
  return (ctx, x, y) => {
    ctx.save();
    rrect(ctx, x - 10, y - 10, 20, 20, 4);
    ctx.fillStyle = on ? PAL.gold : 'rgba(0,0,0,.4)'; ctx.fill();
    ctx.strokeStyle = PAL.gold; ctx.lineWidth = 1.5; ctx.stroke();
    if (on) {
      ctx.beginPath(); ctx.moveTo(x - 5, y); ctx.lineTo(x - 1, y + 5); ctx.lineTo(x + 6, y - 5);
      ctx.strokeStyle = '#1a0f08'; ctx.lineWidth = 3; ctx.lineCap = 'round'; ctx.stroke();
    }
    ctx.restore();
  };
}

// ---------- 键帽 ----------
function keycap(ctx, x, y, w, h, label, o = {}) {
  const press = clamp(o.press ?? 0), depth = 14, dz = depth * (1 - press * .75);
  const accent = o.accent ?? 'rgb(255,150,60)', gl = o.glow ?? 0;
  ctx.save();
  ctx.globalAlpha = o.alpha ?? 1;
  const s = o.scale ?? 1;
  ctx.translate(x, y); ctx.scale(s, s);
  const x0 = -w / 2, y0 = -h / 2 + (depth - dz);
  // 投影
  ctx.fillStyle = 'rgba(0,0,0,.55)';
  ctx.filter = 'blur(10px)'; rrect(ctx, x0 + 4, y0 + dz + 10, w, h, 18); ctx.fill(); ctx.filter = 'none';
  // 侧面
  rrect(ctx, x0, y0 + dz * .15, w, h + dz * .85, 18);
  ctx.fillStyle = linGrad(ctx, 0, y0, 0, y0 + h + dz, [[0, '#2a2226'], [1, '#0e0a0c']]); ctx.fill();
  // 顶面
  const tx = x0 + 6, ty = y0, tw = w - 12, th = h - 10;
  rrect(ctx, tx, ty, tw, th, 14);
  ctx.fillStyle = linGrad(ctx, 0, ty, 0, ty + th, [[0, '#4a3f44'], [.5, '#2c2428'], [1, '#231c20']]); ctx.fill();
  ctx.lineWidth = 1.5; ctx.strokeStyle = 'rgba(255,230,200,.16)'; ctx.stroke();
  if (gl > 0) {
    ctx.save();
    ctx.shadowColor = accent; ctx.shadowBlur = 40 * gl; ctx.strokeStyle = accent; ctx.globalAlpha = (o.alpha ?? 1) * clamp(gl);
    ctx.lineWidth = 3; rrect(ctx, tx, ty, tw, th, 14); ctx.stroke();
    ctx.restore();
  }
  // 标签
  const fs = o.fontSize ?? Math.min(w, h) * .42;
  ctx.font = font(o.fontFam ?? 'cinzel', fs, 900);
  ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.fillStyle = gl > .05 ? `rgba(255,${Math.round(lerp(236, 200, gl))},${Math.round(lerp(210, 150, gl))},1)` : '#e9dfd2';
  if (gl > 0) { ctx.shadowColor = accent; ctx.shadowBlur = 24 * gl; }
  ctx.fillText(label, tx + tw / 2, ty + th / 2 + 2);
  ctx.restore();
}

// ---------- 技能图标（原创简笔刻纹） ----------
const ICONS = {
  sword(g, s) { g.moveTo(-.34 * s, .34 * s); g.lineTo(.3 * s, -.3 * s); g.moveTo(.3 * s, -.3 * s); g.lineTo(.36 * s, -.36 * s);
    g.moveTo(-.2 * s, .06 * s); g.lineTo(-.06 * s, .2 * s); g.moveTo(-.34 * s, .34 * s); g.lineTo(-.26 * s, .26 * s); },
  flame(g, s) { g.moveTo(0, .36 * s); g.bezierCurveTo(-.34 * s, .3 * s, -.3 * s, -.05 * s, -.08 * s, -.36 * s);
    g.bezierCurveTo(-.05 * s, -.12 * s, .1 * s, -.1 * s, .12 * s, -.24 * s); g.bezierCurveTo(.34 * s, 0, .3 * s, .3 * s, 0, .36 * s);
    g.moveTo(0, .3 * s); g.bezierCurveTo(-.12 * s, .22 * s, -.1 * s, .06 * s, 0, -.02 * s); g.bezierCurveTo(.1 * s, .08 * s, .12 * s, .22 * s, 0, .3 * s); },
  shield(g, s) { g.moveTo(0, -.36 * s); g.lineTo(.3 * s, -.24 * s); g.lineTo(.26 * s, .08 * s); g.quadraticCurveTo(.18 * s, .28 * s, 0, .38 * s);
    g.quadraticCurveTo(-.18 * s, .28 * s, -.26 * s, .08 * s); g.lineTo(-.3 * s, -.24 * s); g.closePath(); g.moveTo(0, -.24 * s); g.lineTo(0, .26 * s); g.moveTo(-.18 * s, -.04 * s); g.lineTo(.18 * s, -.04 * s); },
  bolt(g, s) { g.moveTo(.08 * s, -.38 * s); g.lineTo(-.2 * s, .04 * s); g.lineTo(0, .04 * s); g.lineTo(-.1 * s, .38 * s); g.lineTo(.22 * s, -.08 * s); g.lineTo(.02 * s, -.08 * s); g.closePath(); },
  claw(g, s) { for (let i = -1; i <= 1; i++) { g.moveTo(i * .16 * s - .12 * s, .34 * s); g.quadraticCurveTo(i * .16 * s + .1 * s, 0, i * .16 * s + .06 * s, -.36 * s); } },
  orb(g, s) { g.arc(0, 0, .3 * s, 0, Math.PI * 2); g.moveTo(.18 * s, 0); g.arc(0, 0, .18 * s, 0, Math.PI * 2);
    for (let i = 0; i < 8; i++) { const a = i * Math.PI / 4; g.moveTo(Math.cos(a) * .34 * s, Math.sin(a) * .34 * s); g.lineTo(Math.cos(a) * .42 * s, Math.sin(a) * .42 * s); } },
};
const SLOT_ICONS = ['sword', 'flame', 'shield', 'bolt', 'claw', 'orb'];

// ---------- 动作栏技能格 ----------
function actionSlot(ctx, x, y, s, idx, label, o = {}) {
  const press = o.press ?? 0, hl = o.hl ?? 0, dim = o.dim ?? 0, buff = o.buff ?? 0;
  ctx.save();
  ctx.globalAlpha = (o.alpha ?? 1);
  const sc = (o.scale ?? 1) * (1 - press * .06);
  ctx.translate(x + s / 2, y + s / 2); ctx.scale(sc, sc); ctx.translate(-s / 2, -s / 2);
  // 外框（钢青色）
  ctx.fillStyle = linGrad(ctx, 0, 0, 0, s, [[0, '#33464c'], [.5, '#1b2629'], [1, '#2b3a3f']]);
  rrect(ctx, -6, -6, s + 12, s + 12, 6); ctx.fill();
  ctx.strokeStyle = 'rgba(160,200,210,.25)'; ctx.lineWidth = 1.5; ctx.stroke();
  // 顶部指示条槽
  const bh = s * .08;
  ctx.fillStyle = 'rgb(16,31,33)'; ctx.fillRect(2, 2, s - 4, bh);
  if (buff > 0) {
    ctx.save();
    ctx.shadowColor = 'rgba(150,230,40,.9)'; ctx.shadowBlur = 16;
    ctx.fillStyle = linGrad(ctx, 0, 2, 0, 2 + bh, [[0, '#b8f04a'], [1, 'rgb(115,174,14)']]);
    ctx.fillRect(2, 2, (s - 4) * buff, bh);
    ctx.restore();
  }
  // 图标底
  const iy = bh + 6, ih = s - iy - 4;
  ctx.fillStyle = linGrad(ctx, 0, iy, 0, iy + ih, [[0, '#2e2a2c'], [1, '#141113']]);
  ctx.fillRect(4, iy, s - 8, ih);
  // 放射纹（彩窗感）
  ctx.save(); ctx.beginPath(); ctx.rect(4, iy, s - 8, ih); ctx.clip();
  ctx.strokeStyle = 'rgba(255,255,255,.05)'; ctx.lineWidth = 1;
  for (let i = 0; i < 12; i++) { const a = i * Math.PI / 6; ctx.beginPath(); ctx.moveTo(s / 2, iy + ih / 2); ctx.lineTo(s / 2 + Math.cos(a) * s, iy + ih / 2 + Math.sin(a) * s); ctx.stroke(); }
  ctx.restore();
  // 图标
  ctx.save();
  ctx.translate(s / 2, iy + ih / 2);
  ctx.beginPath(); ICONS[SLOT_ICONS[idx]](ctx, s * .9);
  const ic = hl > 0 ? `rgb(${Math.round(lerp(200, 255, hl))},${Math.round(lerp(196, 214, hl))},${Math.round(lerp(190, 150, hl))})` : '#c8c4be';
  ctx.strokeStyle = ic; ctx.lineWidth = s * .035; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
  if (hl > 0) { ctx.shadowColor = 'rgba(255,150,50,.9)'; ctx.shadowBlur = 22 * hl; }
  ctx.stroke();
  ctx.restore();
  // 按下闪光
  if (press > 0) { ctx.fillStyle = `rgba(255,220,170,${press * .45})`; ctx.fillRect(4, iy, s - 8, ih); }
  // 暗化
  if (dim > 0) { ctx.fillStyle = `rgba(5,4,6,${dim * .72})`; rrect(ctx, -6, -6, s + 12, s + 12, 6); ctx.fill(); }
  // 高亮描边
  if (hl > 0) {
    ctx.save(); ctx.globalAlpha *= hl;
    ctx.strokeStyle = PAL.gold; ctx.lineWidth = 3; ctx.shadowColor = 'rgba(255,150,50,1)'; ctx.shadowBlur = 30;
    rrect(ctx, -8, -8, s + 16, s + 16, 8); ctx.stroke();
    ctx.restore();
  }
  // 键位字
  text(ctx, label, s - 10, s - 10, { font: font('cinzel', s * .26, 900), align: 'right', fill: dim > .5 ? 'rgba(255,255,255,.35)' : '#fff', glow: 6, glowColor: '#000' });
  ctx.restore();
}

// ---------- 血球 ----------
// 圆缺面积占比 f → 液面高度 h（0..2R）
function levelToHeight(f, R) {
  f = clamp(f);
  let lo = 0, hi = 2 * R;
  for (let i = 0; i < 30; i++) {
    const h = (lo + hi) / 2, d = R - h;
    const A = R * R * Math.acos(clamp(d / R, -1, 1)) - d * Math.sqrt(Math.max(0, 2 * R * h - h * h));
    if (A / (Math.PI * R * R) < f) lo = h; else hi = h;
  }
  return (lo + hi) / 2;
}
function healthGlobe(ctx, cx, cy, R, o = {}) {
  const t = o.t ?? 0, level = o.level ?? 1, shield = o.shield ?? 0, slosh = o.slosh ?? 0;
  ctx.save();
  // 外框：带尖刺的暗铁环
  const spikes = 16;
  ctx.save();
  ctx.beginPath();
  for (let i = 0; i < spikes * 2; i++) {
    const a = i * Math.PI / spikes - Math.PI / 2;
    const r = i % 2 === 0 ? R * 1.28 : R * 1.16;
    ctx.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r);
  }
  ctx.closePath();
  ctx.fillStyle = linGrad(ctx, cx - R, cy - R, cx + R, cy + R, [[0, '#4a3a2c'], [.5, '#1c1510'], [1, '#3a2c20']]);
  ctx.shadowColor = 'rgba(0,0,0,.8)'; ctx.shadowBlur = 40;
  ctx.fill();
  ctx.restore();
  ctx.beginPath(); ctx.arc(cx, cy, R * 1.14, 0, Math.PI * 2);
  ctx.fillStyle = linGrad(ctx, cx, cy - R, cx, cy + R, [[0, '#8a6a42'], [.45, '#2c2018'], [1, '#6a4e30']]); ctx.fill();
  ctx.beginPath(); ctx.arc(cx, cy, R * 1.05, 0, Math.PI * 2);
  ctx.fillStyle = '#0b0708'; ctx.fill();
  // 球体
  ctx.save();
  ctx.beginPath(); ctx.arc(cx, cy, R, 0, Math.PI * 2); ctx.clip();
  const bgG = ctx.createRadialGradient(cx - R * .3, cy - R * .3, R * .1, cx, cy, R);
  bgG.addColorStop(0, '#2a1216'); bgG.addColorStop(1, '#080305');
  ctx.fillStyle = bgG; ctx.fillRect(cx - R, cy - R, R * 2, R * 2);
  // 液体
  const h = levelToHeight(level, R);
  const sy = cy + R - h;
  ctx.beginPath();
  const amp = 5 + slosh * 16;
  ctx.moveTo(cx - R - 2, sy);
  for (let x = -R; x <= R; x += 8) {
    const yy = sy + Math.sin(x * .025 + t * 3.2) * amp * .6 + Math.sin(x * .011 - t * 2.1) * amp * .5;
    ctx.lineTo(cx + x, yy);
  }
  ctx.lineTo(cx + R + 2, cy + R + 2); ctx.lineTo(cx - R - 2, cy + R + 2); ctx.closePath();
  const lg = ctx.createLinearGradient(0, sy - 10, 0, cy + R);
  lg.addColorStop(0, '#ff3b3b'); lg.addColorStop(.12, '#d2141e'); lg.addColorStop(.6, '#7a0610'); lg.addColorStop(1, '#3a0208');
  ctx.fillStyle = lg; ctx.fill();
  // 液面高光带
  ctx.save(); ctx.clip();
  ctx.globalCompositeOperation = 'lighter';
  ctx.fillStyle = 'rgba(255,90,70,.35)'; ctx.fillRect(cx - R, sy - 12, R * 2, 16);
  // 气泡
  for (let i = 0; i < 26; i++) {
    const r = k => hash(i * 9.1 + k * 3.3);
    const bx = cx + (r(1) - .5) * R * 1.6, sp = 30 + r(2) * 60;
    const by = cy + R - ((r(3) * R * 2 + t * sp) % (R * 2));
    if (by < sy + 6) continue;
    ctx.fillStyle = `rgba(255,120,110,${.15 + r(4) * .25})`;
    ctx.beginPath(); ctx.arc(bx + Math.sin(t * 3 + i) * 4, by, 1.5 + r(5) * 4, 0, Math.PI * 2); ctx.fill();
  }
  ctx.restore();
  // 护盾（品红膜 + 六角纹）
  if (shield > 0) {
    ctx.save();
    ctx.globalAlpha = shield;
    const sg = ctx.createRadialGradient(cx, cy, R * .2, cx, cy, R);
    sg.addColorStop(0, 'rgba(150,25,130,.8)'); sg.addColorStop(1, 'rgba(80,8,75,.96)');
    ctx.fillStyle = sg; ctx.fillRect(cx - R, cy - R, R * 2, R * 2);
    ctx.globalCompositeOperation = 'lighter';
    const hs = 34;
    for (let row = -8; row <= 8; row++) for (let col = -8; col <= 8; col++) {
      const hx = cx + col * hs * 1.5, hy = cy + row * hs * 1.732 + (col % 2 ? hs * .866 : 0);
      const d = Math.hypot(hx - cx, hy - cy);
      if (d > R + hs) continue;
      const wave = .5 + .5 * Math.sin(d * .03 - t * 5);
      ctx.strokeStyle = `rgba(255,130,235,${.08 + wave * .26})`; ctx.lineWidth = 1.5;
      ctx.beginPath();
      for (let k = 0; k < 6; k++) { const a = k * Math.PI / 3; ctx.lineTo(hx + Math.cos(a) * hs * .95, hy + Math.sin(a) * hs * .95); }
      ctx.closePath(); ctx.stroke();
    }
    ctx.restore();
  }
  // 玻璃内阴影 + 高光
  const ig = ctx.createRadialGradient(cx, cy, R * .7, cx, cy, R);
  ig.addColorStop(0, 'rgba(0,0,0,0)'); ig.addColorStop(1, 'rgba(0,0,0,.65)');
  ctx.fillStyle = ig; ctx.fillRect(cx - R, cy - R, R * 2, R * 2);
  ctx.restore();
  ctx.save();
  ctx.globalCompositeOperation = 'lighter';
  const hg = ctx.createRadialGradient(cx - R * .35, cy - R * .45, 0, cx - R * .35, cy - R * .45, R * .55);
  hg.addColorStop(0, 'rgba(255,235,225,.16)'); hg.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = hg; ctx.beginPath(); ctx.ellipse(cx - R * .36, cy - R * .5, R * .3, R * .14, -.6, 0, Math.PI * 2); ctx.fill();
  ctx.strokeStyle = 'rgba(255,200,180,.18)'; ctx.lineWidth = 3;
  ctx.beginPath(); ctx.arc(cx, cy, R * .96, Math.PI * .95, Math.PI * 1.45); ctx.stroke();
  ctx.restore();
  ctx.restore();
  return sy;
}

// ---------- 符文圆环 ----------
function runeGlyph(ctx, k, s) {
  const pts = [[-.5, -.5], [0, -.5], [.5, -.5], [-.5, 0], [0, 0], [.5, 0], [-.5, .5], [0, .5], [.5, .5]];
  const r = mulberry32(k * 7919 + 17);
  ctx.moveTo(0, -.5 * s); ctx.lineTo(0, .5 * s);
  const n = 2 + Math.floor(r() * 2);
  for (let i = 0; i < n; i++) {
    const a = pts[Math.floor(r() * 9)], b = pts[Math.floor(r() * 9)];
    ctx.moveTo(a[0] * s * .8, a[1] * s); ctx.lineTo(b[0] * s * .8, b[1] * s);
  }
}
function runeCircle(ctx, cx, cy, R, t, o = {}) {
  const p = o.p ?? 1, a = o.alpha ?? 1, rot = o.rot ?? t * .08;
  ctx.save();
  ctx.globalAlpha = a;
  ctx.translate(cx, cy);
  ctx.strokeStyle = o.color ?? 'rgba(255,190,110,.9)';
  ctx.shadowColor = o.glowColor ?? 'rgba(255,110,30,.95)'; ctx.shadowBlur = o.blur ?? 18;
  ctx.lineCap = 'round';
  const ring = (r, w, pp, dir = 1, off = 0) => {
    if (pp <= 0) return;
    ctx.lineWidth = w; ctx.beginPath();
    ctx.arc(0, 0, r, off + rot * dir - Math.PI / 2, off + rot * dir - Math.PI / 2 + Math.PI * 2 * pp); ctx.stroke();
  };
  ring(R, 2.5, E.outCubic(prog(p, 0, .5)));
  ring(R * .86, 1.2, E.outCubic(prog(p, .1, .6)), -1);
  ring(R * 1.14, 1.2, E.outCubic(prog(p, .2, .7)), 1, Math.PI);
  ring(R * .56, 2, E.outCubic(prog(p, .35, .85)), -1);
  // 符文
  const pr = prog(p, .3, .9);
  const n = o.runes ?? 36;
  ctx.lineWidth = 1.6;
  for (let i = 0; i < n; i++) {
    if (i / n > pr) break;
    const ang = i / n * Math.PI * 2 - rot * 1.5;
    ctx.save(); ctx.rotate(ang); ctx.translate(0, -R * .93);
    ctx.beginPath(); runeGlyph(ctx, i + (o.seed ?? 0) * 100, R * .085); ctx.stroke();
    ctx.restore();
  }
  // 六芒星（对应六个技能位）
  const sp = o.star === false ? 0 : E.inOutCubic(prog(p, .45, 1));
  if (sp > 0) {
    ctx.lineWidth = 1.8;
    const V = k => { const an = k * Math.PI / 3 - Math.PI / 2 + rot * .5; return [Math.cos(an) * R * .86, Math.sin(an) * R * .86]; };
    for (const tri of [[0, 2, 4], [1, 3, 5]]) {
      for (let e = 0; e < 3; e++) {
        const A = V(tri[e]), B = V(tri[(e + 1) % 3]);
        const q = clamp(sp * 3 - e);
        if (q <= 0) continue;
        ctx.beginPath(); ctx.moveTo(A[0], A[1]); ctx.lineTo(lerp(A[0], B[0], q), lerp(A[1], B[1], q)); ctx.stroke();
      }
    }
    for (let k = 0; k < 6; k++) {
      const v = V(k);
      ctx.shadowBlur = 0;
      glow(ctx, v[0], v[1], 36 * sp, 'rgb(255,150,60)', sp * (o.nodeGlow ?? 1));
      ctx.fillStyle = '#ffe3b0'; ctx.beginPath(); ctx.arc(v[0], v[1], 4 * sp, 0, Math.PI * 2); ctx.fill();
    }
  }
  ctx.restore();
}

// ---------- 鼠标指针 ----------
function cursor(ctx, x, y, o = {}) {
  const s = o.scale ?? 1;
  ctx.save(); ctx.translate(x, y); ctx.scale(s, s);
  ctx.globalAlpha = o.alpha ?? 1;
  ctx.beginPath();
  ctx.moveTo(0, 0); ctx.lineTo(0, 34); ctx.lineTo(8, 26); ctx.lineTo(14, 40); ctx.lineTo(20, 37); ctx.lineTo(14, 24); ctx.lineTo(25, 24); ctx.closePath();
  ctx.shadowColor = 'rgba(0,0,0,.8)'; ctx.shadowBlur = 10; ctx.shadowOffsetY = 3;
  ctx.fillStyle = '#f6efe4'; ctx.fill();
  ctx.shadowColor = 'transparent'; ctx.lineWidth = 2; ctx.strokeStyle = '#1a1214'; ctx.stroke();
  ctx.restore();
}
function ripple(ctx, x, y, p, color = 'rgba(255,200,120,1)', R = 60) {
  if (p <= 0 || p >= 1) return;
  ctx.save();
  ctx.strokeStyle = color; ctx.globalAlpha = (1 - p) * .9; ctx.lineWidth = 3 * (1 - p) + .5;
  ctx.beginPath(); ctx.arc(x, y, R * E.outCubic(p), 0, Math.PI * 2); ctx.stroke();
  ctx.restore();
}

// ---------- 装备图标 ----------
const ITEM_SHAPES = {
  ring(g, s) { g.arc(0, s * .06, s * .24, 0, Math.PI * 2); g.moveTo(s * .12, s * .06); g.arc(0, s * .06, s * .12, 0, Math.PI * 2, true);
    g.moveTo(-s * .08, -s * .2); g.lineTo(0, -s * .32); g.lineTo(s * .08, -s * .2); g.closePath(); },
  amulet(g, s) { g.moveTo(-s * .26, -s * .34); g.quadraticCurveTo(0, s * .02, s * .26, -s * .34); g.lineTo(s * .22, -s * .34); g.quadraticCurveTo(0, -s * .04, -s * .22, -s * .34); g.closePath();
    g.moveTo(0, -s * .06); g.lineTo(s * .16, s * .14); g.lineTo(0, s * .36); g.lineTo(-s * .16, s * .14); g.closePath(); },
  helm(g, s) { g.moveTo(-s * .3, s * .3); g.lineTo(-s * .3, -s * .06); g.quadraticCurveTo(-s * .28, -s * .36, 0, -s * .38); g.quadraticCurveTo(s * .28, -s * .36, s * .3, -s * .06);
    g.lineTo(s * .3, s * .3); g.lineTo(s * .08, s * .3); g.lineTo(s * .08, s * .02); g.lineTo(-s * .08, s * .02); g.lineTo(-s * .08, s * .3); g.closePath(); },
  blade(g, s) { g.moveTo(-s * .05, s * .18); g.lineTo(-s * .05, -s * .32); g.lineTo(0, -s * .4); g.lineTo(s * .05, -s * .32); g.lineTo(s * .05, s * .18); g.closePath();
    g.rect(-s * .2, s * .16, s * .4, s * .06); g.rect(-s * .035, s * .22, s * .07, s * .14); },
  glove(g, s) { g.moveTo(-s * .2, s * .36); g.lineTo(-s * .22, -s * .02); g.lineTo(-s * .3, -s * .14); g.lineTo(-s * .22, -s * .2); g.lineTo(-s * .12, -s * .08);
    g.lineTo(-s * .12, -s * .36); g.lineTo(s * .2, -s * .36); g.lineTo(s * .22, s * .36); g.closePath(); },
};
const ITEM_KEYS = Object.keys(ITEM_SHAPES);
const RARITY = {
  L: { c: 'rgb(255,120,20)', fill: ['#ff9a40', '#9c2e04'], name: '传奇' },
  Y: { c: 'rgb(240,220,90)', fill: ['#fff4a0', '#a89420'], name: '稀有' },
  B: { c: 'rgb(91,140,255)', fill: ['#9dbcff', '#2a4aa8'], name: '魔法' },
};
function itemCell(ctx, x, y, s, item, o = {}) {
  ctx.save();
  ctx.globalAlpha = o.alpha ?? 1;
  const sc = o.scale ?? 1;
  ctx.translate(x + s / 2, y + s / 2); ctx.scale(sc, sc);
  ctx.fillStyle = linGrad(ctx, 0, -s / 2, 0, s / 2, [[0, '#1d1718'], [1, '#0d0a0b']]);
  rrect(ctx, -s / 2, -s / 2, s, s, 6); ctx.fill();
  ctx.strokeStyle = 'rgba(160,140,120,.22)'; ctx.lineWidth = 1.5; ctx.stroke();
  if (item && item.r) {
    const R = RARITY[item.r];
    const dim = o.dim ?? 0;
    ctx.save();
    ctx.globalAlpha *= 1 - dim * .7;
    const bg = ctx.createRadialGradient(0, 0, 0, 0, 0, s * .6);
    bg.addColorStop(0, R.c.replace('rgb', 'rgba').replace(')', ',.28)')); bg.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = bg; ctx.fillRect(-s / 2, -s / 2, s, s);
    ctx.beginPath(); ITEM_SHAPES[item.shape](ctx, s);
    ctx.fillStyle = linGrad(ctx, 0, -s * .4, 0, s * .4, [[0, R.fill[0]], [1, R.fill[1]]]);
    ctx.fill('evenodd');
    ctx.strokeStyle = 'rgba(0,0,0,.6)'; ctx.lineWidth = 1.5; ctx.stroke();
    rrect(ctx, -s / 2 + 2, -s / 2 + 2, s - 4, s - 4, 5);
    ctx.strokeStyle = R.c; ctx.lineWidth = 2; ctx.globalAlpha *= .75; ctx.stroke();
    ctx.restore();
    if (o.glow) {
      ctx.save();
      ctx.shadowColor = R.c; ctx.shadowBlur = 30 * o.glow; ctx.strokeStyle = R.c; ctx.lineWidth = 3; ctx.globalAlpha *= o.glow;
      rrect(ctx, -s / 2 + 1, -s / 2 + 1, s - 2, s - 2, 6); ctx.stroke();
      ctx.restore();
    }
  }
  ctx.restore();
}

// ---------- 魔盒（等距立方体） ----------
function cube(ctx, cx, cy, s, t, o = {}) {
  const g = o.glow ?? 0;
  ctx.save();
  ctx.translate(cx, cy + Math.sin(t * 1.6) * 8);
  const a = s * .866, b = s * .5;
  const top = [[0, -s], [a, -b], [0, 0], [-a, -b]];
  const left = [[-a, -b], [0, 0], [0, s], [-a, b]];
  const right = [[0, 0], [a, -b], [a, b], [0, s]];
  const face = (pts, c0, c1) => {
    ctx.beginPath(); pts.forEach((p, i) => i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1])); ctx.closePath();
    ctx.fillStyle = linGrad(ctx, 0, -s, 0, s, [[0, c0], [1, c1]]); ctx.fill();
    ctx.strokeStyle = `rgba(255,190,110,${.35 + g * .6})`; ctx.lineWidth = 2; ctx.stroke();
  };
  glow(ctx, 0, 0, s * 2.4, 'rgb(255,120,40)', .25 + g * .6);
  face(left, '#3a2a1c', '#1a120c'); face(right, '#2a1e14', '#0e0906'); face(top, '#5a4028', '#2a1c12');
  // 刻纹符文
  ctx.save();
  ctx.strokeStyle = `rgba(255,${Math.round(170 + g * 60)},${Math.round(90 + g * 80)},${.5 + g * .5})`;
  ctx.shadowColor = 'rgba(255,120,30,1)'; ctx.shadowBlur = 10 + g * 30; ctx.lineWidth = 2;
  ctx.beginPath(); ctx.moveTo(-a * .5, -b * .5 + s * .1); ctx.lineTo(-a * .5, s * .6); ctx.moveTo(-a * .8, s * .2); ctx.lineTo(-a * .2, s * .45);
  ctx.moveTo(a * .5, -b * .5 + s * .1); ctx.lineTo(a * .5, s * .6); ctx.moveTo(a * .2, s * .2); ctx.lineTo(a * .8, s * .05);
  ctx.moveTo(-a * .4, -b); ctx.lineTo(0, -b * .4); ctx.lineTo(a * .4, -b); ctx.lineTo(0, -s * .8); ctx.closePath();
  ctx.stroke();
  ctx.restore();
  ctx.restore();
}

// ---------- 通用面板 ----------
function panel(ctx, x, y, w, h, o = {}) {
  ctx.save();
  ctx.globalAlpha = o.alpha ?? 1;
  rrect(ctx, x, y, w, h, o.r ?? 18);
  ctx.fillStyle = o.bg ?? 'rgba(14,9,10,.78)';
  ctx.shadowColor = 'rgba(0,0,0,.7)'; ctx.shadowBlur = 40; ctx.fill(); ctx.shadowBlur = 0;
  ctx.lineWidth = 1.5;
  ctx.strokeStyle = o.stroke ?? linGrad(ctx, x, y, x + w, y + h, [[0, 'rgba(233,196,124,.55)'], [.5, 'rgba(233,196,124,.12)'], [1, 'rgba(233,196,124,.45)']]);
  ctx.stroke();
  // 角饰
  ctx.strokeStyle = 'rgba(233,196,124,.8)'; ctx.lineWidth = 2;
  const c = 16;
  [[x, y, 1, 1], [x + w, y, -1, 1], [x, y + h, 1, -1], [x + w, y + h, -1, -1]].forEach(([px, py, sx, sy]) => {
    ctx.beginPath(); ctx.moveTo(px + sx * 6, py + sy * (c + 6)); ctx.lineTo(px + sx * 6, py + sy * 6); ctx.lineTo(px + sx * (c + 6), py + sy * 6); ctx.stroke();
  });
  ctx.restore();
}

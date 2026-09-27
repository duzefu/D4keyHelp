// ============================================================
//  engine.js — WebGL2 后期管线（烟雾背景 / 泛光 / 色散 / 燃烧转场 / 颗粒）
//             + Canvas2D 绘图工具
// ============================================================

const GLSL_COMMON = `
float h21(vec2 p){ p = fract(p*vec2(123.34, 456.21)); p += dot(p, p+45.32); return fract(p.x*p.y); }
float vnoise(vec2 p){ vec2 i=floor(p), f=fract(p); f=f*f*(3.-2.*f);
  return mix(mix(h21(i), h21(i+vec2(1,0)), f.x), mix(h21(i+vec2(0,1)), h21(i+vec2(1,1)), f.x), f.y); }
float fbm(vec2 p){ float s=0., a=.5; mat2 m=mat2(1.6,1.2,-1.2,1.6);
  for(int i=0;i<6;i++){ s+=a*vnoise(p); p=m*p; a*=.5; } return s; }
`;
const VS = `#version 300 es
in vec2 p; out vec2 uv; void main(){ uv = p*.5+.5; gl_Position = vec4(p,0,1); }`;

const FS_BG = `#version 300 es
precision highp float; in vec2 uv; out vec4 o;
uniform vec2 res; uniform float t, fog, glow, heat, seed; uniform vec3 tintA, tintB;
${GLSL_COMMON}
void main(){
  vec2 p = (uv-.5)*vec2(res.x/res.y, 1.);
  float tt = t*.055 + seed;
  vec2 q = vec2(fbm(p*1.5 + vec2(0., -tt*2.)), fbm(p*1.5 + vec2(5.2,1.3) + tt));
  vec2 r = vec2(fbm(p*1.5 + 3.4*q + vec2(1.7,9.2) - vec2(0., tt*3.)), fbm(p*1.5 + 3.4*q + vec2(8.3,2.8) + tt*.7));
  float f = fbm(p*1.5 + 3.*r + vec2(0., -tt*2.2));
  float smoke = smoothstep(.28, .98, f);
  vec3 col = vec3(.010,.008,.011);
  col += tintA * smoke * fog * (.55 + .9*length(q));
  float fromBottom = smoothstep(.62, -.58, p.y);
  col += tintB * pow(f, 2.6) * glow * fromBottom * 1.7;
  col += tintB * heat * .22 * fromBottom * fromBottom;
  float v = 1. - smoothstep(.3, 1.05, length(p*vec2(.82, 1.2)));
  col *= mix(.18, 1., v);
  o = vec4(col, 1.);
}`;

const FS_COMP = `#version 300 es
precision highp float; in vec2 uv; out vec4 o;
uniform sampler2D bg, ui; uniform float zoom, flash; uniform vec2 shake;
void main(){
  vec2 u = (uv-.5)/zoom + .5 + shake;
  vec2 ub = (uv-.5)/(1.+(zoom-1.)*.45) + .5 + shake*.5;
  vec3 b = texture(bg, ub).rgb;
  vec4 f = texture(ui, u);
  vec3 c = b*(1.-f.a) + f.rgb;
  c += flash*vec3(1., .88, .74);
  o = vec4(c, 1.);
}`;

const FS_BRIGHT = `#version 300 es
precision highp float; in vec2 uv; out vec4 o;
uniform sampler2D src; uniform vec2 texel; uniform float thr;
void main(){
  vec3 c = texture(src, uv + texel*vec2(-.5,-.5)).rgb + texture(src, uv + texel*vec2(.5,-.5)).rgb
         + texture(src, uv + texel*vec2(-.5,.5)).rgb + texture(src, uv + texel*vec2(.5,.5)).rgb;
  c *= .25;
  float l = max(c.r, max(c.g, c.b));
  o = vec4(c * smoothstep(thr, thr+.3, l), 1.);
}`;

const FS_BLUR = `#version 300 es
precision highp float; in vec2 uv; out vec4 o;
uniform sampler2D src; uniform vec2 dir;
void main(){
  vec3 c = texture(src, uv).rgb * .2270270270;
  c += texture(src, uv + dir*1.3846153846).rgb * .3162162162;
  c += texture(src, uv - dir*1.3846153846).rgb * .3162162162;
  c += texture(src, uv + dir*3.2307692308).rgb * .0702702703;
  c += texture(src, uv - dir*3.2307692308).rgb * .0702702703;
  o = vec4(c, 1.);
}`;

const FS_FINAL = `#version 300 es
precision highp float; in vec2 uv; out vec4 o;
uniform sampler2D scene, bl1, bl2; uniform vec2 res;
uniform float t, aberr, bloom, grain, burn, burnSeed, fade, vig;
${GLSL_COMMON}
void main(){
  vec2 d = uv-.5; float r2 = dot(d,d);
  vec2 off = d * (r2*2.2 + .12) * aberr;
  vec3 c;
  c.r = texture(scene, uv - off).r;
  c.g = texture(scene, uv).g;
  c.b = texture(scene, uv + off).b;
  vec3 b = texture(bl1, uv).rgb*.55 + texture(bl2, uv).rgb*.9;
  c += b * bloom;
  c *= 1. - vig * smoothstep(.12, .62, r2*1.6);
  if (burn > 0.) {
    vec2 bp = uv*vec2(res.x/res.y, 1.)*2.6 + burnSeed;
    float n = fbm(bp)*.72 + (1. - length(d*vec2(1.25,1.))*1.35)*.34;
    float e = burn*1.25 - .14;
    float gone = smoothstep(e+.004, e-.004, n);
    float edge = 1. - smoothstep(0., .045, abs(n - e));
    float live = smoothstep(0., .06, burn) * smoothstep(1., .9, burn);
    c = mix(c, vec3(0.), gone);
    c += vec3(1., .40, .07) * edge * live * 2.4 + vec3(1., .8, .5) * pow(edge, 6.) * live * 1.5;
  }
  c = c / (1. + max(c - .86, 0.) * 1.1);
  float g = h21(uv*res + fract(t*7.137)*vec2(97.3, 31.7)) - .5;
  c += g * grain;
  c *= fade;
  o = vec4(c, 1.);
}`;

class Post {
  constructor(canvas) {
    const gl = this.gl = canvas.getContext('webgl2', { preserveDrawingBuffer: true, antialias: false, premultipliedAlpha: false });
    if (!gl) throw new Error('WebGL2 unavailable');
    if (!gl.getExtension('EXT_color_buffer_float')) throw new Error('EXT_color_buffer_float unavailable');
    this.W = canvas.width; this.H = canvas.height;
    const buf = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buf);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
    this.P = {
      bg: this.prog(FS_BG), comp: this.prog(FS_COMP), bright: this.prog(FS_BRIGHT),
      blur: this.prog(FS_BLUR), final: this.prog(FS_FINAL),
    };
    const w = this.W, h = this.H;
    this.F = {
      bg: this.fbo(w, h), scene: this.fbo(w, h),
      half: this.fbo(w / 2, h / 2),
      qa: this.fbo(w / 4, h / 4), qb: this.fbo(w / 4, h / 4),
      ea: this.fbo(w / 8, h / 8), eb: this.fbo(w / 8, h / 8),
    };
    this.uiTex = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, this.uiTex);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  }
  prog(fs) {
    const gl = this.gl;
    const sh = (type, src) => {
      const s = gl.createShader(type); gl.shaderSource(s, src); gl.compileShader(s);
      if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(s) + '\n' + src);
      return s;
    };
    const p = gl.createProgram();
    gl.attachShader(p, sh(gl.VERTEX_SHADER, VS)); gl.attachShader(p, sh(gl.FRAGMENT_SHADER, fs));
    gl.bindAttribLocation(p, 0, 'p'); gl.linkProgram(p);
    if (!gl.getProgramParameter(p, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(p));
    const u = {}; const n = gl.getProgramParameter(p, gl.ACTIVE_UNIFORMS);
    for (let i = 0; i < n; i++) { const info = gl.getActiveUniform(p, i); u[info.name] = gl.getUniformLocation(p, info.name); }
    return { p, u };
  }
  fbo(w, h) {
    const gl = this.gl;
    const tex = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, tex);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA16F, w, h, 0, gl.RGBA, gl.HALF_FLOAT, null);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    const fb = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, fb);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, tex, 0);
    return { fb, tex, w, h };
  }
  pass(prog, target, uniforms, textures) {
    const gl = this.gl;
    gl.bindFramebuffer(gl.FRAMEBUFFER, target ? target.fb : null);
    gl.viewport(0, 0, target ? target.w : this.W, target ? target.h : this.H);
    gl.useProgram(prog.p);
    gl.enableVertexAttribArray(0); gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
    let unit = 0;
    for (const k in textures) {
      gl.activeTexture(gl.TEXTURE0 + unit); gl.bindTexture(gl.TEXTURE_2D, textures[k]);
      gl.uniform1i(prog.u[k], unit); unit++;
    }
    for (const k in uniforms) {
      const v = uniforms[k], loc = prog.u[k];
      if (loc == null) continue;
      if (typeof v === 'number') gl.uniform1f(loc, v);
      else if (v.length === 2) gl.uniform2fv(loc, v);
      else if (v.length === 3) gl.uniform3fv(loc, v);
    }
    gl.drawArrays(gl.TRIANGLES, 0, 3);
  }
  render(uiCanvas, P) {
    const gl = this.gl, F = this.F, w = this.W, h = this.H;
    gl.bindTexture(gl.TEXTURE_2D, this.uiTex);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
    gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, uiCanvas);
    this.pass(this.P.bg, F.bg, { res: [w, h], t: P.t, fog: P.fog, glow: P.glow, heat: P.heat, seed: P.seed, tintA: P.tintA, tintB: P.tintB }, {});
    this.pass(this.P.comp, F.scene, { zoom: P.zoom, flash: P.flash, shake: P.shake }, { bg: F.bg.tex, ui: this.uiTex });
    this.pass(this.P.bright, F.half, { texel: [1 / w, 1 / h], thr: P.bloomThr }, { src: F.scene.tex });
    this.pass(this.P.blur, F.qa, { dir: [2 / w, 0] }, { src: F.half.tex });
    this.pass(this.P.blur, F.qb, { dir: [0, 4 / h] }, { src: F.qa.tex });
    this.pass(this.P.blur, F.qa, { dir: [4 / w, 0] }, { src: F.qb.tex });
    this.pass(this.P.blur, F.qb, { dir: [0, 4 / h] }, { src: F.qa.tex });
    this.pass(this.P.blur, F.ea, { dir: [8 / w, 0] }, { src: F.qb.tex });
    this.pass(this.P.blur, F.eb, { dir: [0, 8 / h] }, { src: F.ea.tex });
    this.pass(this.P.blur, F.ea, { dir: [12 / w, 0] }, { src: F.eb.tex });
    this.pass(this.P.blur, F.eb, { dir: [0, 12 / h] }, { src: F.ea.tex });
    this.pass(this.P.final, null, {
      res: [w, h], t: P.t, aberr: P.aberr, bloom: P.bloom, grain: P.grain, burn: P.burn,
      burnSeed: P.burnSeed, fade: P.fade, vig: P.vig,
    }, { scene: F.scene.tex, bl1: F.qb.tex, bl2: F.eb.tex });
  }
}

// ============================================================
//  Canvas2D 工具
// ============================================================
const PAL = {
  gold: '#e9c47c', goldHi: '#fff1c9', goldDim: '#9c7a45', bone: '#efe6d8', ash: '#9a9095',
  blood: '#c4121c', ember: '#ff6a1a', crimson: '#7a0a12', green: '#8fd13a', buffGreen: 'rgb(115,174,14)',
  blue: '#2f6bea', shield: '#d02fb0', legend: '#ff8a1e', rare: '#f2d34b', magic: '#5b8cff', ink: '#07050a',
};
const FONT = {
  serif: '"NSerif", "Noto Serif SC", "SimSun", serif',
  sans: '"NSans", "Noto Sans SC", "Microsoft YaHei", sans-serif',
  cinzel: '"Cinzel", "Times New Roman", serif',
  mono: '"JBMono", Consolas, monospace',
};
function font(fam, size, weight = 400) { return `${weight} ${size}px ${FONT[fam]}`; }

const _spriteCache = {};
function glowSprite(color) {
  if (_spriteCache[color]) return _spriteCache[color];
  const c = document.createElement('canvas'); c.width = c.height = 128;
  const g = c.getContext('2d');
  const gr = g.createRadialGradient(64, 64, 0, 64, 64, 64);
  gr.addColorStop(0, color); gr.addColorStop(.25, color.replace(/rgb\(([^)]+)\)/, 'rgba($1,.45)'));
  gr.addColorStop(1, 'rgba(0,0,0,0)');
  g.fillStyle = gr; g.fillRect(0, 0, 128, 128);
  return (_spriteCache[color] = c);
}
function glow(ctx, x, y, r, color, a = 1) {
  if (a <= 0 || r <= 0) return;
  ctx.save(); ctx.globalCompositeOperation = 'lighter'; ctx.globalAlpha = clamp(a, 0, 1);
  ctx.drawImage(glowSprite(color), x - r, y - r, r * 2, r * 2); ctx.restore();
}

// 余烬粒子（无状态：位置完全由 t 决定）
function embers(ctx, t, o = {}) {
  const n = o.n ?? 90, seed = o.seed ?? 1, spd = o.speed ?? 70, sz = o.size ?? 2.4, A = o.alpha ?? 1;
  const cols = o.colors ?? ['rgb(255,120,40)', 'rgb(255,170,80)', 'rgb(255,80,30)'];
  const x0 = o.x ?? 0, w = o.w ?? W, yTop = o.yTop ?? -60, yBot = o.yBot ?? H + 60;
  const span = yBot - yTop;
  ctx.save(); ctx.globalCompositeOperation = 'lighter';
  for (let i = 0; i < n; i++) {
    const r = k => hash(i * 13.37 + seed * 101.1 + k * 7.77);
    const sp = spd * (.45 + r(1) * 1.1);
    const y = yBot - ((r(2) * span + t * sp) % span);
    const x = x0 + r(3) * w + Math.sin(t * (.4 + r(4) * .9) + r(5) * 6.28) * (18 + r(6) * 40) + Math.sin(t * 2.3 + i) * 3;
    const life = 1 - (yBot - y) / span;
    const fl = .55 + .45 * Math.sin(t * (6 + r(8) * 9) + r(9) * 6.28);
    const s = sz * (.35 + r(10) * 1.3);
    const a = A * fl * Math.min(1, life * 3) * Math.min(1, (1 - life) * 6 + .2);
    const col = cols[i % cols.length];
    ctx.globalAlpha = clamp(a * .55);
    ctx.drawImage(glowSprite(col), x - s * 7, y - s * 7, s * 14, s * 14);
    ctx.globalAlpha = clamp(a);
    ctx.fillStyle = '#ffe2b0';
    ctx.fillRect(x - s * .5, y - s * .5, s, s);
  }
  ctx.restore();
}

// 逐字显现文本
function revealText(ctx, str, x, y, lt, o = {}) {
  const f = o.font, stagger = o.stagger ?? .035, dur = o.dur ?? .5, dy = o.dy ?? 26, align = o.align ?? 'center';
  const ls = o.ls ?? 0, ease = o.ease ?? E.outCubic, s0 = o.scale0 ?? 1;
  ctx.save();
  ctx.font = f; ctx.letterSpacing = ls + 'px'; ctx.textBaseline = o.baseline ?? 'alphabetic';
  const chars = [...str];
  const widths = chars.map(c => ctx.measureText(c).width + ls);
  const total = widths.reduce((a, b) => a + b, 0) - ls;
  let cx = align === 'center' ? x - total / 2 : align === 'right' ? x - total : x;
  const fill = o.fill ?? PAL.bone;
  const fs = parseFloat((f.match(/(\d+(?:\.\d+)?)px/) || [0, 40])[1]);
  chars.forEach((c, i) => {
    const p = clamp((lt - i * stagger) / dur);
    if (p > 0) {
      const e = ease(p);
      ctx.save();
      ctx.globalAlpha = (o.alpha ?? 1) * clamp(p * 1.6);
      const w = widths[i];
      ctx.translate(cx + w / 2, y + (1 - e) * dy);
      const s = lerp(s0, 1, e); ctx.scale(s, s);
      if (o.glow) { ctx.shadowColor = o.glowColor ?? PAL.ember; ctx.shadowBlur = o.glow * (1.4 - e * .4); }
      if (o.grad) { const g = ctx.createLinearGradient(0, -fs * .82, 0, fs * .12); o.grad.forEach(([k, c]) => g.addColorStop(k, c)); ctx.fillStyle = g; }
      else ctx.fillStyle = typeof fill === 'function' ? fill(i, p) : fill;
      ctx.textAlign = 'center';
      ctx.fillText(c, 0, 0);
      ctx.restore();
    }
    cx += widths[i];
  });
  ctx.restore();
  return total;
}

// 普通文本
function text(ctx, str, x, y, o = {}) {
  ctx.save();
  ctx.font = o.font; ctx.letterSpacing = (o.ls ?? 0) + 'px';
  ctx.textAlign = o.align ?? 'left'; ctx.textBaseline = o.baseline ?? 'alphabetic';
  ctx.globalAlpha = o.alpha ?? 1;
  if (o.glow) { ctx.shadowColor = o.glowColor ?? PAL.ember; ctx.shadowBlur = o.glow; }
  ctx.fillStyle = o.fill ?? PAL.bone;
  ctx.fillText(str, x, y);
  ctx.restore();
}
function measure(ctx, str, f, ls = 0) { ctx.save(); ctx.font = f; ctx.letterSpacing = ls + 'px'; const w = ctx.measureText(str).width; ctx.restore(); return w; }

// 金属质感大标题：离屏绘制 → 渐变 → 扫光
let _metal = null;
function metalText(ctx, str, x, y, o = {}) {
  const f = o.font, ls = o.ls ?? 0;
  if (!_metal) { _metal = document.createElement('canvas'); _metal.width = W; _metal.height = 420; }
  const m = _metal, g = m.getContext('2d');
  g.clearRect(0, 0, m.width, m.height);
  g.font = f; g.letterSpacing = ls + 'px'; g.textBaseline = 'middle'; g.textAlign = 'left';
  const chars = [...str];
  const widths = chars.map(c => g.measureText(c).width + ls);
  const total = widths.reduce((a, b) => a + b, 0) - ls;
  const size = o.size;
  let cx = W / 2 - total / 2; const cy = 210;
  const per = o.perChar;
  chars.forEach((c, i) => {
    const st = per ? per(i) : { a: 1, s: 1, dy: 0 };
    if (st.a > 0) {
      g.save(); g.globalAlpha = clamp(st.a);
      g.translate(cx + widths[i] / 2, cy + st.dy); g.scale(st.s, st.s);
      g.textAlign = 'center'; g.fillStyle = '#fff'; g.fillText(c, 0, 0);
      g.restore();
    }
    cx += widths[i];
  });
  g.globalCompositeOperation = 'source-in';
  const gr = g.createLinearGradient(0, cy - size * .55, 0, cy + size * .5);
  gr.addColorStop(0, '#fff0c2'); gr.addColorStop(.3, '#efc26a'); gr.addColorStop(.52, '#9b6224');
  gr.addColorStop(.56, '#6d3f14'); gr.addColorStop(.72, '#e0a850'); gr.addColorStop(1, '#ffe6a8');
  g.fillStyle = gr; g.fillRect(0, 0, m.width, m.height);
  if (o.shine != null) {
    const sx = lerp(W / 2 - total / 2 - 300, W / 2 + total / 2 + 300, o.shine);
    const sg = g.createLinearGradient(sx - 160, 0, sx + 160, 0);
    sg.addColorStop(0, 'rgba(255,255,255,0)'); sg.addColorStop(.5, 'rgba(255,255,255,.95)'); sg.addColorStop(1, 'rgba(255,255,255,0)');
    g.globalCompositeOperation = 'source-atop'; g.fillStyle = sg;
    g.save(); g.translate(sx, cy); g.transform(1, 0, -.35, 1, 0, 0); g.translate(-sx, -cy); g.fillRect(0, 0, m.width, m.height); g.restore();
  }
  g.globalCompositeOperation = 'source-over';
  ctx.save();
  ctx.globalAlpha = o.alpha ?? 1;
  if (o.glow) { ctx.shadowColor = o.glowColor ?? 'rgba(255,110,30,.9)'; ctx.shadowBlur = o.glow; }
  ctx.drawImage(m, x - W / 2, y - cy);
  ctx.restore();
  return total;
}

function rrect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, r);
}
function linGrad(ctx, x0, y0, x1, y1, stops) {
  const g = ctx.createLinearGradient(x0, y0, x1, y1);
  stops.forEach(([o, c]) => g.addColorStop(o, c));
  return g;
}

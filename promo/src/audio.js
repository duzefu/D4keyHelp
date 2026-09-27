// ============================================================
//  audio.js — 纯合成的配乐与音效（OfflineAudioContext，可复现）
// ============================================================
async function buildAudio() {
  const SR = 48000, LEN = Math.ceil((DURATION + .1) * SR);
  const ac = new OfflineAudioContext(2, LEN, SR);
  const rnd = mulberry32(20260927);

  // ---------- 素材：噪声 / 混响脉冲 ----------
  const NB = ac.createBuffer(2, SR * 3, SR);
  for (let c = 0; c < 2; c++) { const d = NB.getChannelData(c); for (let i = 0; i < d.length; i++) d[i] = rnd() * 2 - 1; }
  function makeIR(dur, decay, damp) {
    const n = Math.floor(SR * dur), b = ac.createBuffer(2, n, SR);
    for (let c = 0; c < 2; c++) {
      const d = b.getChannelData(c); let y = 0;
      for (let i = 0; i < n; i++) {
        const x = (rnd() * 2 - 1) * Math.pow(1 - i / n, decay);
        const a = lerp(.9, damp, i / n);
        y += a * (x - y); d[i] = y;
      }
      for (let i = 0; i < 64; i++) d[i] *= i / 64;
    }
    return b;
  }

  // ---------- 总线 ----------
  const G = (v = 1) => { const g = ac.createGain(); g.gain.value = v; return g; };
  const filt0 = (type, f, q) => { const b = ac.createBiquadFilter(); b.type = type; b.frequency.value = f; b.Q.value = q; return b; };
  const master = G(.8);
  const comp = ac.createDynamicsCompressor();
  comp.threshold.value = -16; comp.knee.value = 12; comp.ratio.value = 2; comp.attack.value = .006; comp.release.value = .22;
  const lim = ac.createDynamicsCompressor();
  lim.threshold.value = -4; lim.knee.value = 0; lim.ratio.value = 20; lim.attack.value = .001; lim.release.value = .08;
  const out = G(1);
  const hp = filt0('highpass', 32, .7), ls = filt0('lowshelf', 110, 0), hs = filt0('highshelf', 4500, 0);
  ls.gain.value = -4; hs.gain.value = 3;
  master.connect(hp); hp.connect(ls); ls.connect(hs); hs.connect(comp); comp.connect(lim); lim.connect(out); out.connect(ac.destination);
  out.gain.setValueAtTime(1, 0);
  out.gain.setValueAtTime(1, DURATION - 1.2);
  out.gain.linearRampToValueAtTime(0, DURATION);

  const rev = ac.createConvolver(); rev.buffer = makeIR(4.2, 2.6, .08);
  const revOut = G(.5); rev.connect(revOut); revOut.connect(master);
  const rev2 = ac.createConvolver(); rev2.buffer = makeIR(1.3, 3.5, .25);
  const rev2Out = G(.45); rev2.connect(rev2Out); rev2Out.connect(master);
  const dly = ac.createDelay(2); dly.delayTime.value = BEAT * .75;
  const fb = G(.36), dlp = ac.createBiquadFilter(); dlp.type = 'lowpass'; dlp.frequency.value = 2800;
  dly.connect(dlp); dlp.connect(fb); fb.connect(dly);
  const dOut = G(.45); dlp.connect(dOut); dOut.connect(master); dOut.connect(rev);
  const music = G(.72), sfx = G(.95);
  music.connect(master); sfx.connect(master);

  function strip(bus, o = {}) {
    const inp = G(o.gain ?? 1);
    const pan = ac.createStereoPanner(); pan.pan.value = o.pan ?? 0;
    inp.connect(pan); pan.connect(bus);
    if (o.rev) { const s = G(o.rev); pan.connect(s); s.connect(rev); }
    if (o.rev2) { const s = G(o.rev2); pan.connect(s); s.connect(rev2); }
    if (o.dly) { const s = G(o.dly); pan.connect(s); s.connect(dly); }
    return inp;
  }
  const S = {
    pad: strip(music, { rev: .55 }), choir: strip(music, { rev: .8 }), drone: strip(music, { rev: .3 }),
    bass: strip(music, { rev2: .08 }), arpL: strip(music, { pan: -.4, rev: .25, dly: .35 }), arpR: strip(music, { pan: .4, rev: .25, dly: .35 }),
    kick: strip(music, { rev2: .18 }), snare: strip(music, { rev: .3, rev2: .2 }), hat: strip(music, { pan: .18, rev2: .1 }),
    crash: strip(music, { rev: .3 }), lead: strip(music, { rev: .45, dly: .22 }),
    fx: strip(sfx, { rev2: .2 }), fxWet: strip(sfx, { rev: .55, rev2: .2 }), fxDry: strip(sfx, {}),
    fxL: strip(sfx, { pan: -.3, rev2: .2 }), fxR: strip(sfx, { pan: .3, rev2: .2 }),
  };

  // ---------- 基元 ----------
  function osc(type, f, t0, t1, det = 0) {
    const o = ac.createOscillator(); o.type = type; o.frequency.setValueAtTime(f, t0); if (det) o.detune.value = det;
    o.start(t0); o.stop(t1); return o;
  }
  function noise(t0, t1) {
    const s = ac.createBufferSource(); s.buffer = NB; s.loop = true; s.start(t0, rnd() * 2.5); s.stop(t1); return s;
  }
  function filt(type, f, q = .7) { const b = ac.createBiquadFilter(); b.type = type; b.frequency.value = f; b.Q.value = q; return b; }
  // 打击型包络：瞬起 → 指数衰减
  function perc(t0, peak, dec, att = .002) {
    const g = G(0);
    g.gain.setValueAtTime(0, t0); g.gain.linearRampToValueAtTime(peak, t0 + att);
    g.gain.setTargetAtTime(0, t0 + att, dec / 4);
    return g;
  }
  // 持续型包络
  function sus(t0, t1, peak, att, rel) {
    const g = G(0);
    g.gain.setValueAtTime(0, t0); g.gain.linearRampToValueAtTime(peak, t0 + att);
    g.gain.setValueAtTime(peak, Math.max(t0 + att, t1)); g.gain.linearRampToValueAtTime(0, Math.max(t0 + att, t1) + rel);
    return g;
  }
  const chain = (...n) => { for (let i = 0; i < n.length - 1; i++) n[i].connect(n[i + 1]); return n[n.length - 1]; };
  function bell(t, f, gain, dec, dest = S.fxWet, ratio = 3.5, index = 4) {
    const car = osc('sine', f, t, t + dec * 1.5), mod = osc('sine', f * ratio, t, t + dec * 1.5);
    const mg = G(0); mg.gain.setValueAtTime(f * index, t); mg.gain.setTargetAtTime(0, t, dec / 5);
    mod.connect(mg); mg.connect(car.frequency);
    chain(car, perc(t, gain, dec), dest);
  }

  // ---------- 乐器 ----------
  function pad(t0, dur, midis, lv) {
    const lp = filt('lowpass', 500, .8);
    lp.frequency.setValueAtTime(700, t0); lp.frequency.linearRampToValueAtTime(2400, t0 + dur * .55); lp.frequency.linearRampToValueAtTime(1200, t0 + dur);
    const env = sus(t0, t0 + dur - .8, .03 * lv, .7, 1.1);
    chain(lp, env, S.pad);
    midis.forEach(m => [-9, 0, 9].forEach(det => osc('sawtooth', mtof(m), t0, t0 + dur + 1.3, det).connect(lp)));
  }
  function choir(t0, dur, midis, lv) {
    const mix = G(1), env = sus(t0, t0 + dur - .6, 1.0 * lv, .9, 1.2);
    [[730, 6, 1], [1090, 8, .5], [2440, 10, .22]].forEach(([f, q, g]) => { const b = filt('bandpass', f, q); const gg = G(g); mix.connect(b); b.connect(gg); gg.connect(env); });
    env.connect(S.choir);
    midis.forEach((m, i) => {
      const o = osc('sawtooth', mtof(m), t0, t0 + dur + 1.4, (i - 1) * 6);
      const lfo = osc('sine', 5 + i * .3, t0, t0 + dur + 1.4), lg = G(9);
      lfo.connect(lg); lg.connect(o.detune);
      const g = G(.3); o.connect(g); g.connect(mix);
    });
  }
  function drone(t0, t1, lv) {
    const env = sus(t0, t1 - 1.8, .05 * lv, 2.0, 1.8);
    const lp = filt('lowpass', 320, .8);
    chain(lp, env, S.drone);
    { const s1 = osc('sine', mtof(nm('D1')), t0, t1 + .1), s1g = G(.35); s1.connect(s1g); s1g.connect(lp); }
    osc('sawtooth', mtof(nm('D2')), t0, t1 + .1, -5).connect(lp);
    osc('sawtooth', mtof(nm('A2')), t0, t1 + .1, 4).connect(lp);
    const n = noise(t0, t1 + .1), bp = filt('bandpass', 500, 1.2), ng = G(.5);
    const lfo = osc('sine', .13, t0, t1 + .1), lg = G(160); lfo.connect(lg); lg.connect(bp.frequency);
    chain(n, bp, ng, env);
  }
  function bass(t, dur, m, acc) {
    const lp = filt('lowpass', 200, 5);
    lp.frequency.setValueAtTime(700 + acc * 700, t); lp.frequency.setTargetAtTime(170, t, .05);
    const env = G(0);
    env.gain.setValueAtTime(0, t); env.gain.linearRampToValueAtTime(.2, t + .005);
    env.gain.setTargetAtTime(.11, t + .005, .04); env.gain.setTargetAtTime(0, t + dur - .03, .015);
    chain(lp, env, S.bass);
    osc('sawtooth', mtof(m), t, t + dur + .1).connect(lp);
    const sub = osc('sine', mtof(m - 12), t, t + dur + .1), sg = G(.4); chain(sub, sg, env);
  }
  function pluck(t, m, lv, dest) {
    const lp = filt('lowpass', 4500, 5);
    lp.frequency.setValueAtTime(4800, t); lp.frequency.setTargetAtTime(420, t, .045);
    chain(lp, perc(t, .085 * lv, .32), dest);
    osc('sawtooth', mtof(m), t, t + .45).connect(lp);
    osc('square', mtof(m), t, t + .45, 7).connect(lp);
  }
  function kick(t, g = 1) {
    const o = osc('sine', 150, t, t + .7);
    o.frequency.setValueAtTime(150, t); o.frequency.exponentialRampToValueAtTime(46, t + .11); o.frequency.exponentialRampToValueAtTime(36, t + .5);
    chain(o, perc(t, .75 * g, .5), S.kick);
    const sk = osc('triangle', 96, t, t + .5); sk.frequency.exponentialRampToValueAtTime(68, t + .3);
    chain(sk, perc(t, .32 * g, .38), S.kick);
    chain(noise(t, t + .05), filt('highpass', 1800), perc(t, .35 * g, .02), S.kick);
  }
  function snare(t, g = 1) {
    chain(noise(t, t + .4), filt('bandpass', 1700, .6), perc(t, .55 * g, .22), S.snare);
    const o = osc('triangle', 210, t, t + .2); o.frequency.exponentialRampToValueAtTime(150, t + .1);
    chain(o, perc(t, .3 * g, .1), S.snare);
    chain(noise(t, t + .6), filt('lowpass', 900), perc(t, .25 * g, .45), S.snare);
  }
  function hat(t, g = 1, open = false) {
    chain(noise(t, t + .3), filt('highpass', 7200), filt('peaking', 10500, 1), perc(t, .2 * g, open ? .16 : .04), S.hat);
  }
  function crash(t, g = 1) {
    chain(noise(t, t + 3), filt('highpass', 4200), perc(t, .16 * g, 2.2), S.crash);
    chain(noise(t, t + 3), filt('bandpass', 7000, .5), perc(t, .08 * g, 1.2), S.crash);
  }
  function lead(t, dur, m) {
    const lp = filt('lowpass', 2400, 1.5);
    lp.frequency.setValueAtTime(900, t); lp.frequency.linearRampToValueAtTime(2600, t + .08); lp.frequency.setTargetAtTime(1700, t + .1, .2);
    const env = sus(t, t + dur - .05, .1, .03, .18);
    chain(lp, env, S.lead);
    const lfo = osc('sine', 5.6, t, t + dur + .3), lg = G(0);
    lg.gain.setValueAtTime(0, t); lg.gain.linearRampToValueAtTime(0, t + .22); lg.gain.linearRampToValueAtTime(14, t + .5);
    lfo.connect(lg);
    [['sawtooth', 0, 1], ['sawtooth', 7, .8], ['square', -1200, .4]].forEach(([ty, det, gg]) => {
      const o = osc(ty, mtof(m), t, t + dur + .3, det); lg.connect(o.detune);
      const g = G(gg); o.connect(g); g.connect(lp);
    });
  }
  function tomFill(t0, n, step) {
    for (let i = 0; i < n; i++) {
      const t = t0 + i * step, f = 190 - i * 12;
      const o = osc('sine', f, t, t + .4); o.frequency.exponentialRampToValueAtTime(f * .55, t + .25);
      chain(o, perc(t, .55 + i * .04, .3), S.kick);
    }
  }

  // ---------- 编曲 ----------
  const sectStarts = [SECT.skill[0], SECT.globe[0], SECT.trans[0], SECT.afk[0], SECT.ui[0], SECT.howto[0], SECT.outro[0]];
  let droneOn = null;
  for (let b = 0; b <= 41; b++) {
    const L = b < 41 ? layersAt(b) : { drone: 0 };
    if (L.drone && droneOn == null) droneOn = b;
    if (!L.drone && droneOn != null) { drone(bar(droneOn), Math.min(DURATION, bar(b) + (b >= 41 ? 0 : 1.5)), 1); droneOn = null; }
  }
  for (let b = 0; b < 41; b++) {
    const t0 = bar(b), L = layersAt(b), cn = chordAt(b), ch = CHORDS[cn];
    const r3 = nm(ch[0] + '3');
    const up = (name, oct, ref) => { let m = nm(name + oct); while (m < ref) m += 12; return m; };
    const tone = [r3, up(ch[1], 3, r3), up(ch[2], 3, r3)];
    if (L.pad) pad(t0, BAR + .7, [tone[0], tone[2], tone[0] + 12, tone[1] + 12, tone[2] + 12], L.pad);
    if (L.choir) choir(t0, BAR + .5, [tone[0] + 12, tone[1] + 12, tone[2] + 12], L.choir);
    const pat = drumPattern(b);
    if (pat) {
      const dg = L.drums >= 2 ? 1 : .8;
      pat.kick.forEach((on, i) => on && kick(t0 + i * BEAT / 2, dg * (i === 0 ? 1 : .8)));
      pat.snare.forEach((on, i) => on && snare(t0 + i * BEAT / 2, dg * .9));
    }
    if (L.hats) {
      const step = L.hats >= 2 ? BEAT / 4 : BEAT / 2, n = Math.round(BAR / step);
      for (let i = 0; i < n; i++) hat(t0 + i * step, (L.hats >= 1 ? 1 : .6) * (i % 2 ? .65 : 1) * (b === 5 ? lerp(.5, 1.4, i / n) : 1), step === BEAT / 2 && i % 2 === 1);
    }
    if (L.bass) {
      let r2 = nm(ch[0] + '2'); if (r2 > 46) r2 -= 12;
      const bp = [0, 0, 12, 0, 0, 12, 0, 7];
      bp.forEach((iv, i) => bass(t0 + i * BEAT / 2, BEAT / 2, r2 + iv, i === 0 ? 1 : .4));
    }
    if (L.arp) {
      const tones = [tone[0] + 12, tone[1] + 12, tone[2] + 12, tone[0] + 24, tone[1] + 24];
      const seq = [0, 1, 2, 3, 1, 2, 3, 4, 2, 3, 4, 3, 2, 1, 2, 3];
      seq.forEach((k, i) => pluck(t0 + i * BEAT / 4, tones[k], L.arp * (i % 4 === 0 ? 1 : .7), i % 2 ? S.arpR : S.arpL));
    }
    if (LEAD[b]) {
      const toks = LEAD[b].split(/\s+/);
      toks.forEach((tk, i) => {
        if (tk === '.' || tk === '-') return;
        let len = 1; while (toks[i + len] === '-') len++;
        lead(t0 + i * BEAT / 2, len * BEAT / 2 + (b === 37 ? 2.5 : 0), nm(tk));
      });
    }
    if (sectStarts.includes(b)) crash(t0, b === SECT.outro[0] ? 1.3 : 1);
  }
  tomFill(bar(6) - BEAT, 8, BEAT / 8);
  tomFill(bar(31) - BEAT, 8, BEAT / 8);

  // ---------- 音效 ----------
  const FX = {
    riser(c) {
      const t = c.t, d = c.dur ?? 1.2, g = c.gain ?? .6;
      const bp = filt('bandpass', 300, 2.2); bp.frequency.setValueAtTime(300, t); bp.frequency.exponentialRampToValueAtTime(7000, t + d);
      const env = G(0); env.gain.setValueAtTime(0, t); env.gain.linearRampToValueAtTime(.5 * g, t + d); env.gain.linearRampToValueAtTime(0, t + d + .03);
      chain(noise(t, t + d + .1), bp, env, S.fxWet);
      const o = osc('sawtooth', 110, t, t + d + .05); o.frequency.exponentialRampToValueAtTime(880, t + d);
      const e2 = G(0); e2.gain.setValueAtTime(0, t); e2.gain.linearRampToValueAtTime(.05 * g, t + d); e2.gain.linearRampToValueAtTime(0, t + d + .03);
      chain(o, filt('lowpass', 2500), e2, S.fxWet);
    },
    boom(c) {
      const t = c.t, g = c.gain ?? 1;
      const o = osc('sine', 80, t, t + 3); o.frequency.exponentialRampToValueAtTime(26, t + 1.8);
      chain(o, perc(t, .7 * g, 2.2), S.fxDry);
      const lp = filt('lowpass', 900); lp.frequency.setValueAtTime(900, t); lp.frequency.exponentialRampToValueAtTime(90, t + 1.6);
      chain(noise(t, t + 3), lp, perc(t, .7 * g, 1.9), S.fxWet);
      chain(osc('sawtooth', 55, t, t + 3), filt('lowpass', 320), perc(t, .12 * g, 2.2), S.fxWet);
    },
    titleHit(c) {
      FX.boom({ t: c.t, gain: .75 });
      [1, 2.76, 5.4, 8.93, 13.3].forEach((k, i) => bell(c.t + i * .004, 293.66 * k, .06 / (1 + i * .4), 3.2 - i * .3, S.fxWet, 1.001, .2));
      chain(noise(c.t, c.t + 2), filt('highpass', 6000), perc(c.t, .12, 1.6), S.fxWet);
    },
    hit(c) {
      const t = c.t, o = osc('sine', 95, t, t + 1.6); o.frequency.exponentialRampToValueAtTime(34, t + .9);
      chain(o, perc(t, .85, 1.1), S.fxDry);
      chain(noise(t, t + .8), filt('lowpass', 1400), perc(t, .45, .45), S.fxWet);
    },
    impact(c) {
      const g = c.gain ?? 1;
      FX.hit({ t: c.t });
      chain(noise(c.t, c.t + .5), filt('highpass', 1500), perc(c.t, .35 * g, .28), S.fxWet);
      bell(c.t, 146.83, .08 * g, 1.8, S.fxWet, 1.414, 1.5);
    },
    whoosh(c) {
      const t = c.t, g = c.gain ?? .5, d = .75;
      const bp = filt('bandpass', 400, 1.6);
      bp.frequency.setValueAtTime(350, t); bp.frequency.exponentialRampToValueAtTime(2600, t + d * .55); bp.frequency.exponentialRampToValueAtTime(500, t + d);
      const env = G(0); env.gain.setValueAtTime(0, t); env.gain.linearRampToValueAtTime(.6 * g, t + d * .5); env.gain.linearRampToValueAtTime(0, t + d);
      chain(noise(t, t + d + .05), bp, env, S.fxWet);
    },
    burn(c) {
      const t = c.t, d = .62;
      const env = G(0); env.gain.setValueAtTime(0, t); env.gain.linearRampToValueAtTime(.35, t + d); env.gain.linearRampToValueAtTime(0, t + d + .1);
      chain(noise(t, t + d + .2), filt('lowpass', 700), env, S.fxWet);
      const e2 = G(0); e2.gain.setValueAtTime(0, t); e2.gain.linearRampToValueAtTime(.18, t + d); e2.gain.linearRampToValueAtTime(0, t + d + .05);
      chain(noise(t, t + d + .1), filt('bandpass', 3500, .8), e2, S.fxWet);
      for (let i = 0; i < 28; i++) {
        const tt = t + rnd() * d;
        chain(noise(tt, tt + .02), filt('highpass', 2500 + rnd() * 3000), perc(tt, .12 + rnd() * .2, .012), rnd() < .5 ? S.fxL : S.fxR);
      }
    },
    shimmer(c) {
      const sc = [0, 3, 5, 7, 10];
      for (let i = 0; i < 14; i++) {
        const m = nm('D6') + sc[Math.floor(rnd() * 5)] + (rnd() < .3 ? 12 : 0);
        bell(c.t + i * .06 + rnd() * .03, mtof(m), .035, 1.4, S.fxWet, 2.01, 1.2);
      }
    },
    pop(c) {
      const t = c.t, p = c.pitch ?? 1, g = c.gain ?? 1;
      const o = osc('sine', 500 * p, t, t + .2); o.frequency.exponentialRampToValueAtTime(1100 * p, t + .05);
      chain(o, perc(t, .22 * g, .12), S.fx);
      chain(noise(t, t + .03), filt('bandpass', 3000), perc(t, .1 * g, .012), S.fx);
    },
    key(c) {
      const t = c.t, p = c.pitch ?? 1, g = c.gain ?? .5;
      chain(noise(t, t + .06), filt('bandpass', 2600 * p, 1.2), perc(t, .7 * g, .022), S.fx);
      const o = osc('sine', 230 * p, t, t + .12); o.frequency.exponentialRampToValueAtTime(130 * p, t + .06);
      chain(o, perc(t, .6 * g, .07), S.fx);
    },
    tick(c) {
      const t = c.t, p = c.pitch ?? 1, g = c.gain ?? .3;
      chain(osc('triangle', 2200 * p, t, t + .06), perc(t, .25 * g, .03), S.fx);
      chain(noise(t, t + .02), filt('highpass', 6000), perc(t, .25 * g, .01), S.fx);
    },
    scan(c) { chain(osc('sine', 1850, c.t, c.t + .08), perc(c.t, .12 * (c.gain ?? .3) / .3, .045), S.fxWet); },
    alarm(c) {
      [[0, 523], [.13, 392]].forEach(([d, f]) => chain(osc('square', f, c.t + d, c.t + d + .14), filt('lowpass', 1600), sus(c.t + d, c.t + d + .1, .07, .005, .03), S.fx));
    },
    buffOn(c) {
      bell(c.t, mtof(nm('D6')), .12, 1.4, S.fxWet, 3.01, 2);
      bell(c.t + .07, mtof(nm('A6')), .08, 1.2, S.fxWet, 3.01, 2);
      chain(noise(c.t, c.t + .6), filt('highpass', 7000), perc(c.t, .1, .5), S.fxWet);
    },
    holdStart(c) {
      const t = c.t, d = c.dur ?? 2.4;
      const lp = filt('lowpass', 300, 3); lp.frequency.setValueAtTime(300, t); lp.frequency.exponentialRampToValueAtTime(2200, t + d);
      const env = sus(t, t + d, .11, .12, .15);
      chain(lp, env, S.fxWet);
      [0, 11].forEach(det => { const o = osc('sawtooth', 110, t, t + d + .3, det); o.frequency.linearRampToValueAtTime(146.8, t + d); o.connect(lp); });
      const o2 = osc('sine', 220, t, t + d + .3); o2.frequency.linearRampToValueAtTime(293.6, t + d);
      const trem = osc('sine', 9, t, t + d + .3), tg = G(.03); const og = G(.04);
      trem.connect(tg); tg.connect(og.gain); chain(o2, og, env);
    },
    release(c) { FX.whoosh({ t: c.t, gain: .3 }); FX.pop({ t: c.t, pitch: .5, gain: .8 }); },
    lockOn(c) { chain(osc('sine', 1400, c.t, c.t + .1), perc(c.t, .1, .06), S.fx); chain(osc('sine', 1900, c.t + .08, c.t + .2), perc(c.t + .08, .1, .06), S.fx); },
    sweep(c) {
      const t = c.t, d = c.dur ?? 1.1;
      for (let x = 0; x < d; x += .28) chain(osc('sine', 1100, t + x, t + x + .2), perc(t + x, .06, .15), S.fxWet);
      const bp = filt('bandpass', 500, 3); bp.frequency.setValueAtTime(500, t); bp.frequency.exponentialRampToValueAtTime(3000, t + d);
      chain(noise(t, t + d), bp, sus(t, t + d - .1, .12, .1, .1), S.fxWet);
    },
    lock(c) {
      chain(osc('sine', 1600, c.t, c.t + .1), perc(c.t, .14, .07), S.fx);
      chain(osc('sine', 2400, c.t + .07, c.t + .2), perc(c.t + .07, .14, .1), S.fx);
      FX.thump({ t: c.t });
    },
    type(c) { const n = c.n ?? 8; for (let i = 0; i < n; i++) FX.type1({ t: c.t + i * .032 + rnd() * .012, gain: .5 }); },
    type1(c) { chain(noise(c.t, c.t + .02), filt('bandpass', 3200 + rnd() * 1500, 1.5), perc(c.t, .3 * (c.gain ?? .5), .01), rnd() < .5 ? S.fxL : S.fxR); },
    damage(c) {
      const t = c.t, o = osc('sine', 130, t, t + .5); o.frequency.exponentialRampToValueAtTime(48, t + .25);
      chain(o, perc(t, .75, .32), S.fxDry);
      chain(noise(t, t + .3), filt('lowpass', 900), perc(t, .45, .16), S.fx);
      chain(noise(t, t + .2), filt('bandpass', 650, 2), perc(t, .3, .09), S.fx);
    },
    glug(c) {
      let t = c.t;
      for (let i = 0; i < 8; i++) {
        const f0 = 220 + rnd() * 120, o = osc('sine', f0, t, t + .12);
        o.frequency.exponentialRampToValueAtTime(f0 * (2.8 + rnd()), t + .06);
        chain(o, perc(t, .22, .07), S.fx);
        t += .06 + rnd() * .05;
      }
      chain(noise(c.t, c.t + .7), filt('lowpass', 800), sus(c.t, c.t + .5, .08, .05, .15), S.fx);
    },
    heal(c) {
      ['D5', 'F5', 'A5', 'D6', 'F6'].forEach((n, i) => bell(c.t + i * .075, mtof(nm(n)), .08, 1.3, S.fxWet, 2.0, 1.5));
      chain(noise(c.t, c.t + 1), filt('highpass', 6500), sus(c.t, c.t + .5, .06, .2, .4), S.fxWet);
    },
    shieldOn(c) {
      const t = c.t, d = c.dur ?? 4.1;
      FX.whoosh({ t: t - .2, gain: .45 });
      bell(t, 220, .12, 1.6, S.fxWet, 1.41, 3);
      const env = sus(t, t + d, .045, .4, .4);
      env.connect(S.fxWet);
      [330, 331.4, 495].forEach(f => osc('sine', f, t, t + d + .5).connect(env));
      const trem = osc('sine', 6, t, t + d + .5), tg = G(.02); trem.connect(tg); tg.connect(env.gain);
    },
    shieldHit(c) { bell(c.t, 420, .1, .7, S.fxWet, 2.31, 5); chain(noise(c.t, c.t + .2), filt('highpass', 3000), perc(c.t, .15, .08), S.fx); },
    shieldOff(c) {
      for (let i = 0; i < 16; i++) bell(c.t + rnd() * .25, 1500 + rnd() * 3500, .025, .5, S.fxWet, 1.7, 2);
      chain(noise(c.t, c.t + .6), filt('highpass', 4000), perc(c.t, .18, .4), S.fxWet);
    },
    click(c) {
      const p = c.pitch ?? 1;
      chain(noise(c.t, c.t + .03), filt('highpass', 3000 * p), perc(c.t, .35, .012), S.fx);
      chain(osc('sine', 1500 * p, c.t, c.t + .04), perc(c.t, .1, .02), S.fx);
    },
    shutter(c) {
      [0, .06].forEach(d => chain(noise(c.t + d, c.t + d + .05), filt('bandpass', 2200, 1.2), perc(c.t + d, .35, .03), S.fx));
      FX.thump({ t: c.t, gain: .5 });
    },
    blip(c) { chain(osc('triangle', 880 * (c.pitch ?? 1), c.t, c.t + .15), perc(c.t, .12, .1), S.fxWet); },
    legend(c) {
      const p = c.pitch ?? 1;
      bell(c.t, 660 * p, .1, 1.3, S.fxWet, 3.01, 4);
      bell(c.t + .02, 990 * p, .05, 1.0, S.fxWet, 2.0, 2);
      chain(osc('sine', 110, c.t, c.t + .4), perc(c.t, .25, .25), S.fx);
    },
    upgrade(c) {
      for (let i = 0; i < 8; i++) bell(c.t + i * .05, mtof(nm('A5') + [0, 2, 3, 5, 7, 9, 10, 12][i]), .045, .9, S.fxWet, 2.0, 1.5);
      FX.whoosh({ t: c.t - .1, gain: .35 });
    },
    soul(c) {
      const p = c.pitch ?? 1, o = osc('sine', 1250 * p, c.t, c.t + .3);
      o.frequency.exponentialRampToValueAtTime(1800 * p, c.t + .1);
      chain(o, perc(c.t, .06, .22), S.fxWet);
    },
    pause(c) {
      const o = osc('sawtooth', 320, c.t, c.t + .45); o.frequency.exponentialRampToValueAtTime(55, c.t + .38);
      chain(o, filt('lowpass', 1200), perc(c.t, .1, .4), S.fx);
      FX.thump({ t: c.t, gain: .5 });
    },
    resume(c) {
      const o = osc('sawtooth', 60, c.t, c.t + .3); o.frequency.exponentialRampToValueAtTime(320, c.t + .22);
      chain(o, filt('lowpass', 1400), sus(c.t, c.t + .18, .07, .03, .05), S.fx);
    },
    chime(c) { bell(c.t, c.f ?? 880, .1, 1.4, S.fxWet, 3.01, 3); },
    thump(c) {
      const g = c.gain ?? 1, o = osc('sine', 95, c.t, c.t + .35); o.frequency.exponentialRampToValueAtTime(48, c.t + .2);
      chain(o, perc(c.t, .45 * g, .25), S.fx);
      chain(noise(c.t, c.t + .1), filt('lowpass', 500), perc(c.t, .2 * g, .06), S.fx);
    },
    drop(c) {
      const bp = filt('bandpass', 2400, 1.5); bp.frequency.setValueAtTime(2400, c.t - .4); bp.frequency.exponentialRampToValueAtTime(300, c.t);
      chain(noise(c.t - .4, c.t + .05), bp, sus(c.t - .4, c.t - .05, .25, .3, .05), S.fxWet);
      FX.thump({ t: c.t });
    },
  };
  for (const c of CUES) { const f = FX[c.type]; if (f) f(c); else console.warn('未知音效', c.type); }

  return await ac.startRendering();
}

// AudioBuffer → 16-bit WAV（base64，分块取回）
function audioToWav(buf) {
  const ch = buf.numberOfChannels, n = buf.length, sr = buf.sampleRate;
  const data = new DataView(new ArrayBuffer(44 + n * ch * 2));
  const ws = (o, s) => { for (let i = 0; i < s.length; i++) data.setUint8(o + i, s.charCodeAt(i)); };
  ws(0, 'RIFF'); data.setUint32(4, 36 + n * ch * 2, true); ws(8, 'WAVE'); ws(12, 'fmt ');
  data.setUint32(16, 16, true); data.setUint16(20, 1, true); data.setUint16(22, ch, true);
  data.setUint32(24, sr, true); data.setUint32(28, sr * ch * 2, true); data.setUint16(32, ch * 2, true); data.setUint16(34, 16, true);
  ws(36, 'data'); data.setUint32(40, n * ch * 2, true);
  const chans = []; for (let c = 0; c < ch; c++) chans.push(buf.getChannelData(c));
  let o = 44;
  for (let i = 0; i < n; i++) for (let c = 0; c < ch; c++) {
    const v = Math.max(-1, Math.min(1, chans[c][i]));
    data.setInt16(o, v < 0 ? v * 32768 : v * 32767, true); o += 2;
  }
  return new Uint8Array(data.buffer);
}
let __wav = null;
async function renderAudioWav() { const b = await buildAudio(); __wav = audioToWav(b); return __wav.length; }
function wavChunk(i, size) {
  const part = __wav.subarray(i, i + size);
  let s = ''; for (let k = 0; k < part.length; k += 32768) s += String.fromCharCode.apply(null, part.subarray(k, k + 32768));
  return btoa(s);
}

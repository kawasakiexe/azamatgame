// ============================================================================
// ПЯТЬ НОЧЕЙ НА ПРОДЕ — Procedural Web Audio Engine & Jumpscare Synthesizer
// ============================================================================

class SoundEngine {
  constructor() {
    this.ctx = null;
    this.masterGain = null;
    this.ambientOsc = null;
    this.ambientGain = null;
    this.sirenInterval = null;
    this.muted = false;
    this.volume = 0.85;
  }

  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioCtx();
      this.masterGain = this.ctx.createGain();
      this.masterGain.gain.value = this.volume;
      this.masterGain.connect(this.ctx.destination);
    }
    if (this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  setVolume(val) {
    this.volume = Math.max(0, Math.min(1, val));
    if (this.masterGain && !this.muted) {
      this.masterGain.gain.setValueAtTime(this.volume, this.ctx.currentTime);
    }
  }

  toggleMute() {
    this.muted = !this.muted;
    if (this.masterGain) {
      this.masterGain.gain.setValueAtTime(this.muted ? 0 : this.volume, this.ctx.currentTime);
    }
    return this.muted;
  }

  // Mechanical heavy switch clack
  playSwitch(state = true) {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(state ? 190 : 140, now);
    osc.frequency.exponentialRampToValueAtTime(state ? 620 : 85, now + 0.045);

    gain.gain.setValueAtTime(0.35, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.055);

    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.06);

    // Click transient noise
    this._noiseBurst(0.025, 0.2, state ? 2200 : 1200);
  }

  // Heavy firewall gate slam
  playGateSlam(closed = true) {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(closed ? 150 : 90, now);
    osc.frequency.exponentialRampToValueAtTime(closed ? 32 : 220, now + 0.18);

    gain.gain.setValueAtTime(0.5, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.22);

    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.23);

    this._noiseBurst(0.14, 0.35, closed ? 400 : 900);
  }

  // Keyboard clack when coding patches
  playKeyClick() {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    const pitch = 700 + Math.random() * 500;

    osc.type = 'sine';
    osc.frequency.setValueAtTime(pitch, now);
    osc.frequency.exponentialRampToValueAtTime(180, now + 0.025);

    gain.gain.setValueAtTime(0.14, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);

    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.032);
  }

  // Port scanner ping sound (safe vs danger)
  playPing(danger = false) {
    this.init();
    const now = this.ctx.currentTime;
    if (!danger) {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(1040, now);
      osc.frequency.exponentialRampToValueAtTime(1320, now + 0.08);
      gain.gain.setValueAtTime(0.2, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(now);
      osc.stop(now + 0.13);
    } else {
      // Classic FNaF window stinger / danger chord!
      const freqs = [110, 116.5, 233, 311, 466];
      freqs.forEach((f) => {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(f, now);
        gain.gain.setValueAtTime(0.16, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.45);
        osc.connect(gain);
        gain.connect(this.masterGain);
        osc.start(now);
        osc.stop(now + 0.46);
      });
    }
  }

  // Alarm beep when dip-switch mutates or hack occurs
  playAlertBeep(urgent = false) {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'square';
    osc.frequency.setValueAtTime(urgent ? 880 : 587, now);
    if (urgent) {
      osc.frequency.setValueAtTime(1174, now + 0.07);
    }
    gain.gain.setValueAtTime(0.22, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.16);
    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.17);
  }

  // Steam hiss when cooling down chair / venting
  playSteamVent() {
    this.init();
    this._noiseBurst(0.22, 0.22, 1800);
  }

  // AI blocked thud at firewall door
  playBlockedThud() {
    this.init();
    const now = this.ctx.currentTime;
    for (let i = 0; i < 2; i++) {
      const offset = i * 0.16;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(95, now + offset);
      osc.frequency.exponentialRampToValueAtTime(28, now + offset + 0.14);
      gain.gain.setValueAtTime(0.65, now + offset);
      gain.gain.exponentialRampToValueAtTime(0.001, now + offset + 0.15);
      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(now + offset);
      osc.stop(now + offset + 0.16);
    }
  }

  // Foxy / DDoS sprint warning alarm!
  playSprintSiren() {
    this.init();
    const now = this.ctx.currentTime;
    for (let i = 0; i < 4; i++) {
      const t = now + i * 0.15;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(600, t);
      osc.frequency.linearRampToValueAtTime(1400, t + 0.12);
      gain.gain.setValueAtTime(0.32, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.14);
      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(t);
      osc.stop(t + 0.145);
    }
  }

  // Hack counter increment stinger
  playBreachGlitch() {
    this.init();
    const now = this.ctx.currentTime;
    const freqs = [92, 138, 185, 520, 1100];
    freqs.forEach((f) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(f, now);
      osc.frequency.linearRampToValueAtTime(f * 0.6, now + 0.35);
      gain.gain.setValueAtTime(0.18, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.38);
      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(now);
      osc.stop(now + 0.39);
    });
    this._noiseBurst(0.3, 0.45, 1500);
  }

  // ==========================================================================
  // RAZOR-SHARP JUMPSCARE SYNTHESIZER (СКРИМЕР)
  // Combines dissonant FM shriek, sub-bass explosion, and harsh white noise
  // ==========================================================================
  playJumpscare(type = 'ai') {
    this.init();
    const now = this.ctx.currentTime;
    const duration = 1.65;

    // 1. Dissonant multi-oscillator cyber-shriek with rapid FM modulation
    const baseFreqs = type === 'pukan'
      ? [75, 112, 295, 590, 888, 1340, 2100]
      : [105, 148, 370, 622, 940, 1580, 2450, 3120];

    // Modulator LFO for metallic screaming vibrato
    const lfo = this.ctx.createOscillator();
    const lfoGain = this.ctx.createGain();
    lfo.type = 'square';
    lfo.frequency.setValueAtTime(48, now);
    lfoGain.gain.setValueAtTime(260, now);
    lfo.connect(lfoGain);
    lfo.start(now);
    lfo.stop(now + duration);

    baseFreqs.forEach((freq, idx) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = idx % 2 === 0 ? 'sawtooth' : 'square';
      osc.frequency.setValueAtTime(freq, now);
      osc.frequency.exponentialRampToValueAtTime(freq * (idx % 2 === 0 ? 1.35 : 0.72), now + duration * 0.8);

      lfoGain.connect(osc.frequency);

      // Sharp immediate attack!
      gain.gain.setValueAtTime(0.32, now);
      gain.gain.setValueAtTime(0.35, now + 0.4);
      gain.gain.exponentialRampToValueAtTime(0.001, now + duration);

      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(now);
      osc.stop(now + duration);
    });

    // 2. Massive distorted noise roar / explosion
    this._noiseBurst(duration, 0.95, type === 'pukan' ? 950 : 2600);

    // 3. Sub-bass shockwave punch
    const sub = this.ctx.createOscillator();
    const subGain = this.ctx.createGain();
    sub.type = 'sine';
    sub.frequency.setValueAtTime(130, now);
    sub.frequency.exponentialRampToValueAtTime(24, now + 0.9);
    subGain.gain.setValueAtTime(0.95, now);
    subGain.gain.exponentialRampToValueAtTime(0.001, now + 1.1);
    sub.connect(subGain);
    subGain.connect(this.masterGain);
    sub.start(now);
    sub.stop(now + 1.15);
  }

  // Victory 06:00 AM Chime + Kids Cheering synth
  playVictoryChime() {
    this.init();
    const now = this.ctx.currentTime;
    const notes = [523.25, 659.25, 783.99, 1046.5]; // C5, E5, G5, C6
    notes.forEach((f, i) => {
      const t = now + i * 0.28;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(f, t);
      gain.gain.setValueAtTime(0.35, t);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.85);
      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(t);
      osc.stop(t + 0.88);
    });
  }

  // Helper: filtered white noise burst
  _noiseBurst(duration, amp = 0.3, filterFreq = 1400) {
    if (!this.ctx) return;
    const bufferSize = Math.floor(this.ctx.sampleRate * duration);
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = Math.random() * 2 - 1;
    }

    const noise = this.ctx.createBufferSource();
    noise.buffer = buffer;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.setValueAtTime(filterFreq, this.ctx.currentTime);
    filter.Q.setValueAtTime(0.8, this.ctx.currentTime);

    const gain = this.ctx.createGain();
    gain.gain.setValueAtTime(amp, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + duration);

    noise.connect(filter);
    filter.connect(gain);
    gain.connect(this.masterGain);
    noise.start();
  }
}

window.soundEngine = new SoundEngine();

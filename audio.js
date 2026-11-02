// ============================================================================
// ПЯТЬ НОЧЕЙ НА ПРОДЕ — Advanced Procedural Horror Audio Engine
// Real-time Web Audio API synthesis: Cozy crickets & rain from Alfred-Game,
// Low bowed cello dread notes, monster cues, gas leaks, and razor-sharp screamers.
// ============================================================================

class SoundEngine {
  constructor() {
    this.ctx = null;
    this.masterGain = null;
    this.ambientGain = null;
    this.cricketGain = null;
    this.rainSource = null;
    this.cricketInterval = null;
    this.celloInterval = null;
    this.muted = false;
    this.volume = 0.85;
    this.inBlackout = false;
  }

  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioCtx();
      this.masterGain = this.ctx.createGain();
      this.masterGain.gain.value = this.volume;
      this.masterGain.connect(this.ctx.destination);

      this.ambientGain = this.ctx.createGain();
      this.ambientGain.gain.setValueAtTime(0.14, this.ctx.currentTime);
      this.ambientGain.connect(this.masterGain);

      this.startAmbience();
      this.startCelloDreadLoop();
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

  // -------------------------------------------------------------------------
  // Cozy Ambience (Night Sky, Soft Rain/Breeze, and Crickets from Alfred-Game)
  // -------------------------------------------------------------------------
  startAmbience() {
    if (!this.ctx || this.rainSource) return;

    // Filtered pink noise for cozy rain / server room air conditioning
    const bufferSize = this.ctx.sampleRate * 2;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const data = buffer.getChannelData(0);

    let b0 = 0, b1 = 0, b2 = 0;
    for (let i = 0; i < bufferSize; i++) {
      const white = Math.random() * 2 - 1;
      b0 = 0.99886 * b0 + white * 0.0555179;
      b1 = 0.99332 * b1 + white * 0.0750759;
      b2 = 0.96900 * b2 + white * 0.1538520;
      data[i] = (b0 + b1 + b2) * 0.06;
    }

    const noise = this.ctx.createBufferSource();
    noise.buffer = buffer;
    noise.loop = true;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(850, this.ctx.currentTime);

    noise.connect(filter);
    filter.connect(this.ambientGain);
    noise.start();
    this.rainSource = noise;

    // Procedural crickets outside the window
    this.cricketInterval = setInterval(() => {
      if (!this.muted && !this.inBlackout && Math.random() < 0.65) {
        this._playCricketChirp();
      }
    }, 2800);
  }

  _playCricketChirp() {
    if (!this.ctx || this.inBlackout) return;
    const now = this.ctx.currentTime;
    const chirpCount = 2 + Math.floor(Math.random() * 3);

    for (let c = 0; c < chirpCount; c++) {
      const t = now + c * 0.085;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(4600 + Math.random() * 400, t);
      osc.frequency.linearRampToValueAtTime(4300, t + 0.045);

      gain.gain.setValueAtTime(0.0001, t);
      gain.gain.linearRampToValueAtTime(0.025, t + 0.015);
      gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.048);

      osc.connect(gain);
      gain.connect(this.ambientGain);
      osc.start(t);
      osc.stop(t + 0.05);
    }
  }

  // -------------------------------------------------------------------------
  // Low Bowed Cello / Violin Dread Tone (Every ~15s when lights are on)
  // -------------------------------------------------------------------------
  startCelloDreadLoop() {
    if (this.celloInterval) clearInterval(this.celloInterval);
    this.celloInterval = setInterval(() => {
      if (!this.muted && !this.inBlackout && Math.random() < 0.85) {
        this.playLowCelloNote();
      }
    }, 15000);
  }

  playLowCelloNote() {
    if (!this.ctx || this.inBlackout) return;
    const now = this.ctx.currentTime;
    const duration = 5.5;

    // C2, D#2, F2, or G2 dark cello notes
    const celloNotes = [65.41, 77.78, 87.31, 98.00];
    const freq = celloNotes[Math.floor(Math.random() * celloNotes.length)];

    const osc1 = this.ctx.createOscillator();
    const osc2 = this.ctx.createOscillator();
    const filter = this.ctx.createBiquadFilter();
    const gain = this.ctx.createGain();

    osc1.type = 'sawtooth';
    osc2.type = 'triangle';
    osc1.frequency.setValueAtTime(freq, now);
    osc2.frequency.setValueAtTime(freq * 1.004, now); // subtle chorusing

    // Vibrato LFO
    const lfo = this.ctx.createOscillator();
    const lfoGain = this.ctx.createGain();
    lfo.type = 'sine';
    lfo.frequency.setValueAtTime(4.8, now);
    lfoGain.gain.setValueAtTime(1.2, now);
    lfo.connect(lfoGain);
    lfoGain.connect(osc1.frequency);
    lfoGain.connect(osc2.frequency);
    lfo.start(now);
    lfo.stop(now + duration);

    // Warm resonant lowpass filter
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(280, now);
    filter.frequency.linearRampToValueAtTime(480, now + duration * 0.4);
    filter.frequency.exponentialRampToValueAtTime(160, now + duration);
    filter.Q.setValueAtTime(3.5, now);

    // Slow bowed envelope
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.linearRampToValueAtTime(0.08, now + 1.2);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + duration);

    osc1.connect(filter);
    osc2.connect(filter);
    filter.connect(gain);
    gain.connect(this.masterGain);

    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + duration);
    osc2.stop(now + duration);
  }

  // -------------------------------------------------------------------------
  // Blackout Silence & Creeping Tension
  // -------------------------------------------------------------------------
  setBlackout(state) {
    this.inBlackout = state;
    if (this.ambientGain) {
      const now = this.ctx ? this.ctx.currentTime : 0;
      this.ambientGain.gain.setTargetAtTime(state ? 0.015 : 0.14, now, 0.5);
    }
    if (state) {
      this.playBreakerTrip();
    }
  }

  playBreakerTrip() {
    this.init();
    const now = this.ctx.currentTime;
    // Spark and blackout powerdown drop
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(220, now);
    osc.frequency.exponentialRampToValueAtTime(18, now + 0.6);

    gain.gain.setValueAtTime(0.45, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.65);

    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.7);

    this._noiseBurst(0.18, 0.45, 900);
  }

  playBreakerReset() {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'square';
    osc.frequency.setValueAtTime(140, now);
    osc.frequency.exponentialRampToValueAtTime(540, now + 0.08);

    gain.gain.setValueAtTime(0.4, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);

    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.13);
  }

  // -------------------------------------------------------------------------
  // Monsters Audio (Distortion, Tadpole, Trojan, Burgundy Vent Stalker)
  // -------------------------------------------------------------------------
  playDistortionDrone() {
    this.init();
    const now = this.ctx.currentTime;
    const freqs = [55, 110, 165, 330];
    freqs.forEach((f) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(f, now);
      osc.frequency.linearRampToValueAtTime(f * (0.85 + Math.random() * 0.3), now + 0.9);

      gain.gain.setValueAtTime(0.08, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.95);

      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(now);
      osc.stop(now + 1.0);
    });
    this._noiseBurst(0.3, 0.25, 2400);
  }

  playVentClick() {
    this.init();
    const now = this.ctx.currentTime;
    for (let i = 0; i < 3; i++) {
      const t = now + i * 0.06;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(1800 + Math.random() * 600, t);
      osc.frequency.exponentialRampToValueAtTime(240, t + 0.015);

      gain.gain.setValueAtTime(0.2, t);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.018);

      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(t);
      osc.stop(t + 0.02);
    }
  }

  playTrojanCreak() {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(95, now);
    osc.frequency.linearRampToValueAtTime(240, now + 0.3);
    osc.frequency.linearRampToValueAtTime(80, now + 0.55);

    gain.gain.setValueAtTime(0.18, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.6);

    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.65);
  }

  playTadpoleSplat() {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(750, now);
    osc.frequency.exponentialRampToValueAtTime(60, now + 0.12);

    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.14);

    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.15);
    this._noiseBurst(0.08, 0.3, 1100);
  }

  playGasValveTurn() {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'square';
    osc.frequency.setValueAtTime(180, now);
    osc.frequency.exponentialRampToValueAtTime(85, now + 0.06);

    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.07);

    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.08);
    this._noiseBurst(0.12, 0.18, 3200); // steam hiss
  }

  playPrinterPrint() {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(640, now);
    osc.frequency.linearRampToValueAtTime(880, now + 0.1);

    gain.gain.setValueAtTime(0.1, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);

    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.13);
  }

  playPrinterDone() {
    this.init();
    const now = this.ctx.currentTime;
    const notes = [587.33, 783.99, 1046.5];
    notes.forEach((f, i) => {
      const t = now + i * 0.08;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(f, t);
      gain.gain.setValueAtTime(0.2, t);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(t);
      osc.stop(t + 0.19);
    });
  }

  // -------------------------------------------------------------------------
  // Classic FNaF Controls & Screamer Synthesizer
  // -------------------------------------------------------------------------
  playSwitch(state = true) {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(state ? 210 : 130, now);
    osc.frequency.exponentialRampToValueAtTime(state ? 640 : 75, now + 0.045);
    gain.gain.setValueAtTime(0.35, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.055);
    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.06);
    this._noiseBurst(0.025, 0.2, state ? 2200 : 1200);
  }

  playGateSlam(closed = true) {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(closed ? 160 : 85, now);
    osc.frequency.exponentialRampToValueAtTime(closed ? 28 : 240, now + 0.2);
    gain.gain.setValueAtTime(0.55, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.23);
    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.24);
    this._noiseBurst(0.14, 0.4, closed ? 380 : 920);
  }

  playKeyClick() {
    this.init();
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(750 + Math.random() * 450, now);
    osc.frequency.exponentialRampToValueAtTime(170, now + 0.025);
    gain.gain.setValueAtTime(0.12, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);
    osc.connect(gain);
    gain.connect(this.masterGain);
    osc.start(now);
    osc.stop(now + 0.032);
  }

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
      const freqs = [105, 114, 228, 305, 460];
      freqs.forEach((f) => {
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(f, now);
        gain.gain.setValueAtTime(0.18, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.48);
        osc.connect(gain);
        gain.connect(this.masterGain);
        osc.start(now);
        osc.stop(now + 0.5);
      });
    }
  }

  playSteamVent() {
    this.init();
    this._noiseBurst(0.26, 0.25, 1800);
  }

  playSprintSiren() {
    this.init();
    const now = this.ctx.currentTime;
    for (let i = 0; i < 4; i++) {
      const t = now + i * 0.14;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(620, t);
      osc.frequency.linearRampToValueAtTime(1450, t + 0.11);
      gain.gain.setValueAtTime(0.34, t);
      gain.gain.exponentialRampToValueAtTime(0.01, t + 0.13);
      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(t);
      osc.stop(t + 0.135);
    }
  }

  playJumpscare(type = 'ai') {
    this.init();
    const now = this.ctx.currentTime;
    const duration = 1.75;

    const baseFreqs = type === 'pukan'
      ? [70, 105, 280, 560, 840, 1300, 2050]
      : [98, 142, 360, 610, 920, 1540, 2400, 3180];

    const lfo = this.ctx.createOscillator();
    const lfoGain = this.ctx.createGain();
    lfo.type = 'square';
    lfo.frequency.setValueAtTime(52, now);
    lfoGain.gain.setValueAtTime(290, now);
    lfo.connect(lfoGain);
    lfo.start(now);
    lfo.stop(now + duration);

    baseFreqs.forEach((freq, idx) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = idx % 2 === 0 ? 'sawtooth' : 'square';
      osc.frequency.setValueAtTime(freq, now);
      osc.frequency.exponentialRampToValueAtTime(freq * (idx % 2 === 0 ? 1.4 : 0.7), now + duration * 0.85);

      lfoGain.connect(osc.frequency);

      gain.gain.setValueAtTime(0.36, now);
      gain.gain.setValueAtTime(0.38, now + 0.4);
      gain.gain.exponentialRampToValueAtTime(0.001, now + duration);

      osc.connect(gain);
      gain.connect(this.masterGain);
      osc.start(now);
      osc.stop(now + duration);
    });

    this._noiseBurst(duration, 0.98, type === 'pukan' ? 950 : 2700);

    const sub = this.ctx.createOscillator();
    const subGain = this.ctx.createGain();
    sub.type = 'sine';
    sub.frequency.setValueAtTime(140, now);
    sub.frequency.exponentialRampToValueAtTime(22, now + 0.9);
    subGain.gain.setValueAtTime(1.0, now);
    subGain.gain.exponentialRampToValueAtTime(0.001, now + 1.15);
    sub.connect(subGain);
    subGain.connect(this.masterGain);
    sub.start(now);
    sub.stop(now + 1.2);
  }

  playVictoryChime() {
    this.init();
    const now = this.ctx.currentTime;
    const notes = [523.25, 659.25, 783.99, 1046.5];
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
    filter.Q.setValueAtTime(0.85, this.ctx.currentTime);

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

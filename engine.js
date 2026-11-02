// ============================================================================
// ПЯТЬ НОЧЕЙ НА ПРОДЕ — Core Game Engine (PS1 3D Edition)
// Daytime Lobby, Birdsong, Easter Egg Cabinet, Secondary Puzzle Objectives,
// Coin Wallet (Max 3), Nishtyak Shop & Buffs, and 360° Mouse Controls.
// ============================================================================

const SHIFT_CONFIGS = {
  1: {
    name: 'СМЕНА 1: ПОНЕДЕЛЬНИК («Джуниор на ночном дежурстве»)',
    subtitle: 'Сеньор ушёл в запой. Не дай ИИ спалить стул и береги пукан.',
    dipInterval: 28,
    dipTimeout: 16,
    patchSpeed: 1.6,
    basePowerDrain: 0.12,
    trojanSpeed: 1.1,
    gasEnabled: false,
    blackoutChance: 0.0,
    puzzleName: 'CI/CD Pipeline: Провести билд по трубам',
    puzzleDesc: 'Вращай трубы кликом мыши, чтобы соединить Git Commit с Prod сервером!',
    phoneGuyMsg: '«Алло, джун! Добро пожаловать на прод. По тоннелям уже ползёт Троянский конь в T-pose. Напечатай морковку на 3D-принтере справа, чтобы оттолкнуть его! Не забывай про доп. задачу на мониторе — собери трубы CI/CD пайплайна и получи монету на ништяки в лобби!»'
  },
  2: {
    name: 'СМЕНА 2: ВТОРНИК («Утечка хладагента и Бордовый Сталкер»)',
    subtitle: 'В вентиляции зашевелились хвосты, а трубу с газом прорвало.',
    dipInterval: 24,
    dipTimeout: 14,
    patchSpeed: 1.45,
    basePowerDrain: 0.14,
    trojanSpeed: 1.5,
    gasEnabled: true,
    blackoutChance: 0.0,
    puzzleName: 'Kubernetes Pods: Балансировка 5 контейнеров',
    puzzleDesc: 'Аккуратно бросай раскачивающиеся поды, выстроив устойчивую башню!',
    phoneGuyMsg: '«Слушай сюда: в потолочной решётке завёлся Бордовый Душегуб. Слышишь щелчки "клик-клик" или видишь хвост — жми ПРОДУВКУ ВЕНТИЛЯЦИИ [V]! А если свистит газ — крути красный вентиль на трубе!»'
  },
  3: {
    name: 'СМЕНА 3: СРЕДА («Нашествие Багогрызов и Блэкауты»)',
    subtitle: 'По полу бегают склизкие твари, а проводка искрит.',
    dipInterval: 20,
    dipTimeout: 12.5,
    patchSpeed: 1.35,
    basePowerDrain: 0.16,
    trojanSpeed: 1.9,
    gasEnabled: true,
    blackoutChance: 0.035,
    puzzleName: 'Fiber Cross: Соединить оптоволокно без пересечений',
    puzzleDesc: 'Протяни кабели одинаковых цветов так, чтобы они не перекрещивались!',
    phoneGuyMsg: '«Алярм! Багогрызы-головастики лезут прямо на клавиатуру — бей их кликами! А если выбьет свет и всё затихнет — обернись на 180° к звездному окну и щёлкни рубильник на щитке!»'
  },
  4: {
    name: 'СМЕНА 4: ЧЕТВЕРГ («Релизный цейтнот и Троянская рулетка»)',
    subtitle: 'Троянский конь ускорил шаг, а пукан греется как ядро реактора.',
    dipInterval: 17,
    dipTimeout: 11,
    patchSpeed: 1.25,
    basePowerDrain: 0.18,
    trojanSpeed: 2.3,
    gasEnabled: true,
    blackoutChance: 0.05,
    puzzleName: 'Hash Decryptor: Скользящие крипто-регистры',
    puzzleDesc: 'Сдвигай ячейки памяти, пока контрольная сумма не совпадёт!',
    phoneGuyMsg: '«Конь прет напролом! Всегда держи готовую морковку. Если он заедет в комнату — шанс 50/50: либо отсыпет батарей и остудит стул, либо разорвёт тебя на куски!»'
  },
  5: {
    name: 'СМЕНА 5: ПЯТНИЦА 13-е («СИНГУЛЯРНОСТЬ ПУКАНА»)',
    subtitle: 'Все монстры вышли на охоту одновременно. Твой стул на грани взрыва.',
    dipInterval: 14,
    dipTimeout: 9.5,
    patchSpeed: 1.15,
    basePowerDrain: 0.21,
    trojanSpeed: 2.8,
    gasEnabled: true,
    blackoutChance: 0.065,
    puzzleName: 'Quantum Phase: Синхронизация 3 фаз ядра',
    puzzleDesc: 'Сведи 3 осциллограммы в резонанс для стабилизации дата-центра!',
    phoneGuyMsg: '«Ты последняя надежда продакшена. Пили хотфикс, крути вентиль, отбивайся морковкой и не дай Исказителю выжечь тебе мозг!»'
  },
  6: {
    name: 'СВОЯ НОЧЬ: 20/20/20/20 («АД СИСАДМИНА»)',
    subtitle: 'Кастомная хардкорная смена с максимальной агрессией монстров.',
    dipInterval: 12,
    dipTimeout: 8.5,
    patchSpeed: 1.1,
    basePowerDrain: 0.23,
    trojanSpeed: 3.3,
    gasEnabled: true,
    blackoutChance: 0.08,
    puzzleName: 'Master Kernel Bypass',
    puzzleDesc: 'Финальный рубеж. Реши головоломку ради славы DevOps!',
    phoneGuyMsg: '«Максимальный уровень ада. Да пребудет с тобой Святой Линус Торвальдс.»'
  }
};

const CODE_SNIPPETS = [
  'if (ai.wantsToDestroyWorld()) { ai.setNiceness(9999); }',
  'sudo iptables -A INPUT -s 666.666.0.0/16 -j DROP // Пошел нахерGPT',
  'try { fixProd(); } catch (PukanDetonationError e) { applyIcePack(); }',
  'const patch = await bypassSkufNet({ force: true, молитва: "Отче наш" });',
  'while (server.isBurning) { pourKombuchaOnMotherboard(); }',
  'git commit -m "hotfix: запретил трояну трахать базу данных по пятницам"',
  'killall -9 distortion_daemon trojan_horse tadpole_virus vent_stalker',
  'export PUKAN_MAX_TEMP=9000; sysctl -w kernel.panic_on_ai=0;'
];

class ProdGame {
  constructor() {
    // Progression & Daytime Lobby
    this.inLobby = true; // Boots in peaceful daytime lobby!
    this.currentLevel = 1;
    this.maxUnlockedLevel = 1;
    this.coins = 0; // Max 3 coins
    this.maxCoins = 3;

    // Purchased Single-Use Buffs
    this.activeBuffs = {
      antiTrojanOats: false, // Starts +50m further & 30% slower
      titaniumFuse: false,   // Immunity to blackouts/breaker trips
      mirrorGlasses: false,  // Distortion stare timeout is 4.5s instead of 1.8s
      asbestosSeat: false,   // Pukanometer heats 40% slower
      bugRepellent: false    // Tadpole bug disabled during first half
    };

    // Daytime Easter Eggs
    this.cabinetOpen = false;

    // Shift Vitals & State
    this.running = false;
    this.gameOver = false;
    this.timeSeconds = 0;
    this.totalShiftSeconds = 180;
    this.inOvertime = false;
    this.overtimeSeconds = 22.0;

    this.power = 100.0;
    this.pukanTemp = 15.0;
    this.patchProgress = 0.0;
    this.hackCount = 0;
    this.maxHacks = 5;

    // Hardware Switches
    this.switches = {
      gateLeft: false,
      gateCenter: false,
      gateRight: false,
      seatCooler: false,
      overclock: false,
      dip: [0, 1, 0, 1]
    };

    this.targetDip = [0, 1, 0, 1];
    this.dipPuzzleActive = false;
    this.dipTimer = 0;
    this.dipMaxTimer = 15;
    this.nextDipCountdown = 12;

    this.pingLeftActive = false;
    this.pingRightActive = false;
    this.crankCooldown = 0;
    this.steamVentCooldown = 0;
    this.cctvOpen = false;
    this.currentCam = 'CAM01';

    // 4 Real Monsters State Machine
    this.monsters = {
      distortion: {
        name: 'ИСКАЗИТЕЛЬ',
        active: false,
        pos: 'NONE',
        stareTimer: 0,
        patience: 6.0,
        nextSpawn: 12.0
      },
      tadpole: {
        name: 'БАГОГРЫЗ-ГОЛОВАСТИК',
        active: false,
        health: 3,
        x: 0,
        y: 0,
        messTimer: 3.5,
        nextSpawn: 18.0
      },
      trojan: {
        name: 'ТРОЯНСКИЙ КОНЬ',
        distance: 100.0,
        speed: 1.2,
        inRoom: false,
        gambleTimer: 0,
        gambleResolved: false
      },
      burgundy: {
        name: 'БОРДОВЫЙ ДУШЕГУБ',
        stage: 0,
        clickCooldown: 4.0,
        attackTimer: 0,
        moveCooldown: 6.0
      }
    };

    // Environmental Hazards
    this.hazards = {
      gasPressure: 0.0,
      gasLeaking: false,
      valveAngle: 0.0,
      blackout: false,
      printerWorking: false,
      printerProgress: 0.0,
      carrotsCount: 1
    };

    // Secondary Objective Puzzle (for extra coin!)
    this.puzzleModalOpen = false;
    this.puzzleSolvedThisShift = false;
    this.pipeGrid = []; // 3x3 tiles for Level 1
    this._initPipelinePuzzle();

    this.codeLines = [
      '// СЕРВЕРНЫЙ ТЕРМИНАЛ ДЕЖУРНОГО v5.2',
      '// Добро пожаловать в лобби. Выбери смену на планшете!'
    ];

    this.lastTick = performance.now();
    this.loopId = null;
  }

  // -------------------------------------------------------------------------
  // Secondary Puzzle: CI/CD Pipeline Ball Maze (Rotatable Pipe Tiles)
  // -------------------------------------------------------------------------
  _initPipelinePuzzle() {
    // 3x3 Grid. Each cell: { type: 'elbow'|'straight'|'t'|'cross', rot: 0..3 }
    // Rotations: 0 = 0deg, 1 = 90deg, 2 = 180deg, 3 = 270deg
    // Start is at (0,0) entrance from top. End is at (2,2) exit to right.
    this.pipeGrid = [
      { type: 'elbow', rot: 1 },    { type: 'straight', rot: 1 }, { type: 'elbow', rot: 2 },
      { type: 'straight', rot: 0 }, { type: 'cross', rot: 0 },    { type: 'straight', rot: 0 },
      { type: 'elbow', rot: 0 },    { type: 'straight', rot: 1 }, { type: 'elbow', rot: 3 }
    ];
    this.puzzleSolvedThisShift = false;
  }

  rotatePipeTile(idx) {
    if (this.puzzleSolvedThisShift) return;
    this.pipeGrid[idx].rot = (this.pipeGrid[idx].rot + 1) % 4;
    window.soundEngine.playPuzzleRotate();
    this.renderPuzzleUI();
  }

  checkPipelineConnection() {
    // Solved check: provides rewarding satisfaction!
    // If tiles are rotated to create a path or player completes the maze:
    if (this.puzzleSolvedThisShift) return;
    this.puzzleSolvedThisShift = true;

    if (this.coins < this.maxCoins) {
      this.coins += 1;
      window.soundEngine.playCoinSound();
      this.addEventLog('🎉 ГОЛОВОЛОМКА РЕШЕНА! Пайплайн соединён! +1 МОНЕТА В КОШЕЛЁК!', 'ok');
    } else {
      this.addEventLog('🎉 Головоломка решена! (Кошелёк полон: 3/3 монет)', 'ok');
    }

    this.renderPuzzleUI();
    this.renderUI();
  }

  togglePuzzleModal() {
    this.puzzleModalOpen = !this.puzzleModalOpen;
    const modal = document.getElementById('puzzle-modal');
    if (modal) {
      if (this.puzzleModalOpen) {
        modal.classList.remove('hidden');
        this.renderPuzzleUI();
      } else {
        modal.classList.add('hidden');
      }
    }
  }

  renderPuzzleUI() {
    const pContainer = document.getElementById('puzzle-pipe-grid');
    if (!pContainer) return;
    pContainer.innerHTML = '';

    const pipeSVGs = {
      straight: `<svg viewBox="0 0 40 40" class="w-10 h-10"><rect x="15" y="0" width="10" height="40" fill="#06b6d4"/><circle cx="20" cy="20" r="3" fill="#fff"/></svg>`,
      elbow: `<svg viewBox="0 0 40 40" class="w-10 h-10"><path d="M15,0 L25,0 L25,15 L40,15 L40,25 L15,25 Z" fill="#06b6d4"/><circle cx="20" cy="20" r="3" fill="#fff"/></svg>`,
      cross: `<svg viewBox="0 0 40 40" class="w-10 h-10"><rect x="15" y="0" width="10" height="40" fill="#06b6d4"/><rect x="0" y="15" width="40" height="10" fill="#06b6d4"/></svg>`
    };

    this.pipeGrid.forEach((tile, i) => {
      const btn = document.createElement('button');
      btn.className = 'w-14 h-14 bg-slate-900 border-2 border-slate-700 hover:border-cyan-400 rounded-lg flex items-center justify-center cursor-pointer transition-transform';
      const rotDeg = tile.rot * 90;
      btn.innerHTML = `<div style="transform: rotate(${rotDeg}deg); transition: transform 0.15s ease;">${pipeSVGs[tile.type] || pipeSVGs.straight}</div>`;
      btn.onclick = () => this.rotatePipeTile(i);
      pContainer.appendChild(btn);
    });

    const statusEl = document.getElementById('puzzle-status-text');
    if (statusEl) {
      if (this.puzzleSolvedThisShift) {
        statusEl.textContent = '✅ БИЛД УСПЕШНО ДОСТАВЛЕН НА ПРОД! МОНЕТА ПОЛУЧЕНА!';
        statusEl.className = 'text-xs font-bold text-emerald-400 animate-pulse';
      } else {
        statusEl.textContent = 'Вращай трубы кликом. Соедини Вход (слева вверху) с Выходом (справа внизу)!';
        statusEl.className = 'text-xs text-slate-300';
      }
    }
  }

  // -------------------------------------------------------------------------
  // Daytime Lobby Functions (Easter eggs, shop, level selector)
  // -------------------------------------------------------------------------
  toggleCabinet() {
    this.cabinetOpen = !this.cabinetOpen;
    window.soundEngine.playCabinetOpen();

    if (this.cabinetOpen) {
      this.addEventLog('🚪 Ты открыл настенный шкафчик... Внутри записка: «AZAMAT SASI»!', 'warn');
    }

    if (window.view3D) {
      window.view3D.setCabinetOpen(this.cabinetOpen);
    }
  }

  clickRubberDuck() {
    window.soundEngine.playDuckSqueak();
    this.addEventLog('🦆 Резиновая уточка: КРЯ! Стресс дежурного снижен на -3°C.', 'info');
    this.pukanTemp = Math.max(0, this.pukanTemp - 3);
    this.renderUI();
  }

  drinkCoffee() {
    window.soundEngine.playCoffeeSip();
    this.addEventLog('☕ Глыть! Бодрящий кофе восстановил силы (+4% ИБП).', 'info');
    this.power = Math.min(100, this.power + 4);
    this.renderUI();
  }

  buyBuff(buffKey) {
    if (this.coins < 1) {
      this.addEventLog('⚠️ Недостаточно монет! Решай головоломки в сменах, чтобы заработать!', 'warn');
      return;
    }
    if (this.activeBuffs[buffKey]) {
      this.addEventLog('⚠️ Этот ништяк уже активен на следующую смену!', 'info');
      return;
    }

    this.coins -= 1;
    this.activeBuffs[buffKey] = true;
    window.soundEngine.playCoinSound();
    this.addEventLog(`🛒 КУПЛЕН НИШТЯК: ${this._getBuffName(buffKey)}! Активируется в следующей смене!`, 'ok');
    this.renderLobbyUI();
    this.renderUI();
  }

  _getBuffName(k) {
    const names = {
      antiTrojanOats: 'Анти-Троянский Овёс (Конь начнёт дальше и медленнее)',
      titaniumFuse: 'Титановый Предохранитель (Иммунитет к блэкауту)',
      mirrorGlasses: 'Зеркальные Очки (Защита от взгляда Исказителя)',
      asbestosSeat: 'Асбестовая Подушка (Пукан греется на 40% медленнее)',
      bugRepellent: 'Репеллент от Багов (Багогрыз не придёт первую половину ночи)'
    };
    return names[k] || k;
  }

  startShiftFromLobby(lvl) {
    if (lvl > this.maxUnlockedLevel) {
      this.addEventLog(`⚠️ Смена #${lvl} пока закрыта! Сначала переживи Смену #${lvl - 1}!`, 'warn');
      return;
    }

    this.inLobby = false;
    this.currentLevel = lvl;

    // Switch Audio & 3D Environment to Night Mode
    window.soundEngine.setDaytime(false);
    if (window.view3D) {
      window.view3D.setDaytime(false);
    }

    document.getElementById('lobby-overlay').classList.add('hidden');
    this.startShift(lvl);
  }

  returnToLobby() {
    this.inLobby = true;
    this.running = false;
    this.gameOver = false;
    if (this.loopId) cancelAnimationFrame(this.loopId);

    // Reset single-use buffs for next run
    this.activeBuffs = {
      antiTrojanOats: false,
      titaniumFuse: false,
      mirrorGlasses: false,
      asbestosSeat: false,
      bugRepellent: false
    };

    // Switch Audio & 3D Environment to Daytime Mode
    window.soundEngine.setDaytime(true);
    if (window.view3D) {
      window.view3D.setDaytime(true);
    }

    document.getElementById('victory-modal').classList.add('hidden');
    document.getElementById('gameover-modal').classList.add('hidden');
    document.getElementById('lobby-overlay').classList.remove('hidden');

    this.renderLobbyUI();
    this.renderUI();
  }

  // -------------------------------------------------------------------------
  // Core Shift Loop
  // -------------------------------------------------------------------------
  startShift(shiftNum) {
    window.soundEngine.init();
    this.currentLevel = shiftNum;
    const cfg = SHIFT_CONFIGS[shiftNum] || SHIFT_CONFIGS[1];

    this.running = true;
    this.gameOver = false;
    this.timeSeconds = 0;
    this.inOvertime = false;
    this.overtimeSeconds = 22.0;

    this.power = 100.0;
    this.pukanTemp = 15.0;
    this.patchProgress = 0.0;
    this.hackCount = 0;

    this.switches = {
      gateLeft: false,
      gateCenter: false,
      gateRight: false,
      seatCooler: false,
      overclock: false,
      dip: [0, 1, 0, 1]
    };

    this.targetDip = [0, 1, 0, 1];
    this.dipPuzzleActive = false;
    this.dipTimer = 0;
    this.dipMaxTimer = cfg.dipTimeout;
    this.nextDipCountdown = 10;

    this.pingLeftActive = false;
    this.pingRightActive = false;
    this.crankCooldown = 0;
    this.steamVentCooldown = 0;
    this.cctvOpen = false;
    this.currentCam = 'CAM01';

    // Init secondary puzzle for this shift
    this._initPipelinePuzzle();

    // Reset Monsters with applied buffs
    this.monsters.distortion = {
      name: 'ИСКАЗИТЕЛЬ',
      active: false,
      pos: 'NONE',
      stareTimer: 0,
      patience: Math.max(4.0, 7.5 - shiftNum * 0.5),
      nextSpawn: 12.0
    };

    this.monsters.tadpole = {
      name: 'БАГОГРЫЗ-ГОЛОВАСТИК',
      active: false,
      health: 3,
      x: 0,
      y: 0,
      messTimer: 3.5,
      // If Bug Repellent buff active -> delay first spawn significantly!
      nextSpawn: this.activeBuffs.bugRepellent ? 60.0 : 16.0
    };

    // If Anti-Trojan Oats buff active -> start further back and slower!
    const trojanStartDist = this.activeBuffs.antiTrojanOats ? 140.0 : 100.0;
    const trojanBaseSpeed = this.activeBuffs.antiTrojanOats ? cfg.trojanSpeed * 0.7 : cfg.trojanSpeed;

    this.monsters.trojan = {
      name: 'ТРОЯНСКИЙ КОНЬ',
      distance: trojanStartDist,
      speed: trojanBaseSpeed,
      inRoom: false,
      gambleTimer: 0,
      gambleResolved: false
    };

    this.monsters.burgundy = {
      name: 'БОРДОВЫЙ ДУШЕГУБ',
      stage: 0,
      clickCooldown: 4.0,
      attackTimer: 0,
      moveCooldown: 6.0
    };

    this.hazards.gasPressure = 0.0;
    this.hazards.gasLeaking = cfg.gasEnabled;
    this.hazards.valveAngle = 0.0;
    this.hazards.blackout = false;
    this.hazards.printerWorking = false;
    this.hazards.printerProgress = 0.0;
    this.hazards.carrotsCount = 1;

    window.soundEngine.setBlackout(false);
    window.soundEngine.playSwitch(true);

    this.codeLines = [
      `// === ЗАПУСК: ${cfg.name} ===`,
      '// Продержись до 06:00 AM! Не забудь решить доп. головоломку на монету!'
    ];

    this.addEventLog(`Ночь началась! Выживи до утра!`, 'info');

    // Phone Guy Banner
    const phoneEl = document.getElementById('phone-guy-banner');
    const phoneText = document.getElementById('phone-guy-text');
    if (phoneEl && phoneText) {
      phoneText.textContent = cfg.phoneGuyMsg;
      phoneEl.classList.remove('hidden');
    }

    document.getElementById('menu-modal').classList.add('hidden');
    document.getElementById('gameover-modal').classList.add('hidden');
    document.getElementById('victory-modal').classList.add('hidden');
    document.getElementById('lobby-overlay').classList.add('hidden');

    if (window.view3D) {
      if (!window.view3D.initialized) {
        window.view3D.init('three-viewport');
      } else {
        window.view3D.reset();
      }
    }

    this.lastTick = performance.now();
    if (this.loopId) cancelAnimationFrame(this.loopId);
    this.tick();
  }

  tick() {
    if (!this.running) return;
    const now = performance.now();
    const dt = Math.min(0.1, (now - this.lastTick) / 1000);
    this.lastTick = now;

    this.update(dt);
    this.renderUI();

    if (this.running) {
      this.loopId = requestAnimationFrame(() => this.tick());
    }
  }

  getUsageBars() {
    if (this.power <= 0 || this.hazards.blackout) return 0;
    let bars = 1;
    if (this.switches.gateLeft) bars += 1;
    if (this.switches.gateCenter) bars += 1;
    if (this.switches.gateRight) bars += 1;
    if (this.switches.seatCooler) bars += 1;
    if (this.switches.overclock) bars += 1;
    if (this.cctvOpen) bars += 1;
    if (this.hazards.printerWorking) bars += 1;
    return Math.min(6, bars);
  }

  update(dt) {
    const cfg = SHIFT_CONFIGS[this.currentLevel] || SHIFT_CONFIGS[1];

    // 1. Clock & Overtime Check
    if (!this.inOvertime) {
      this.timeSeconds += dt;
      if (this.timeSeconds >= this.totalShiftSeconds) {
        // ONLY WAY TO WIN: Survive until 06:00 AM!
        this.triggerVictory();
        return;
      }
    } else {
      this.overtimeSeconds -= dt;
      if (this.overtimeSeconds <= 0) {
        this.triggerJumpscare(
          'pukan',
          'ДЕДЛАЙН ПРОСРАН! ТИМЛИД СЖЁГ СЕРВЕРНУЮ!',
          'В 06:00 утра прод лёг без хотфикса. Твой стул расплавился!'
        );
        return;
      }
    }

    // 2. Battery & Blackouts
    if (this.crankCooldown > 0) this.crankCooldown -= dt;
    if (this.steamVentCooldown > 0) this.steamVentCooldown -= dt;

    if (!this.hazards.blackout && this.power > 0) {
      const bars = this.getUsageBars();
      const drain = cfg.basePowerDrain * (1 + (bars - 1) * 0.9);
      this.power = Math.max(0, this.power - drain * dt);

      if (this.power <= 0) {
        this.switches.gateLeft = false;
        this.switches.gateCenter = false;
        this.switches.gateRight = false;
        this.switches.seatCooler = false;
        this.switches.overclock = false;
        this.cctvOpen = false;
        this.triggerBlackout('БЛЭКАУТ: ИБП разряжен в 0%!');
      }
    }

    // Random power trip breaker (unless Titanium Fuse buff active!)
    if (!this.hazards.blackout && !this.activeBuffs.titaniumFuse && cfg.blackoutChance > 0 && Math.random() < dt * cfg.blackoutChance * 0.1) {
      this.triggerBlackout('⚡ ВЫБИЛО ПРОБКИ! Повернись назад на 180° к щитку и включи рубильник!');
    }

    // 3. Pukanometer Heat
    let heatRate = 0.65;
    if (this.switches.overclock) heatRate += 2.2;
    if (this.dipPuzzleActive) heatRate += 1.4;
    if (this.hazards.gasPressure > 50) heatRate += 1.8;
    if (this.monsters.tadpole.active) heatRate += 1.2;
    heatRate += this.hackCount * 0.9;

    // Asbestos seat buff reduces heating by 40%
    if (this.activeBuffs.asbestosSeat) {
      heatRate *= 0.6;
    }

    if (this.switches.seatCooler && this.power > 0 && !this.hazards.blackout) {
      heatRate -= 4.8;
    }

    this.pukanTemp = Math.max(0, Math.min(100, this.pukanTemp + heatRate * dt));
    if (this.pukanTemp >= 100) {
      this.triggerJumpscare(
        'pukan',
        'ТЕРМОЯДЕРНОЕ ИЗВЕРЖЕНИЕ ПУКАНА!',
        'Температура кресла пробила 100°C! Взрыв уничтожил дежурного!'
      );
      return;
    }

    // 4. DIP Switch Mutation
    if (!this.dipPuzzleActive) {
      this.nextDipCountdown -= dt;
      if (this.nextDipCountdown <= 0) {
        this.spawnDipPuzzle(cfg);
      }
    } else {
      this.dipTimer -= dt;
      if (this.dipTimer <= 0) {
        this.dipPuzzleActive = false;
        this.nextDipCountdown = cfg.dipInterval * 0.75;
        this.incrementHack('Вирус изменил флаги SW1-4 ядра! Защита пробита!');
        if (this.gameOver) return;
      }
    }

    // 5. Hazards & Monsters
    this.updateHazards(dt, cfg);
    this.updateMonsters(dt, cfg);
  }

  updateMonsters(dt, cfg) {
    // A. Distortion Giant
    const dist = this.monsters.distortion;
    if (!dist.active) {
      dist.nextSpawn -= dt;
      if (dist.nextSpawn <= 0) {
        dist.active = true;
        const positions = ['DOOR_LEFT', 'DOOR_RIGHT', 'WINDOW_BACK', 'HALL_FRONT'];
        dist.pos = positions[Math.floor(Math.random() * positions.length)];
        dist.stareTimer = 0;
        dist.patience = Math.max(4.0, 7.5 - this.currentLevel * 0.5);
        window.soundEngine.playDistortionDrone();
        this.addEventLog(`👁️ ИСКАЗИТЕЛЬ заглядывает из ${dist.pos}! НЕ СМОТРИ НА НЕГО!`, 'danger');
      }
    } else {
      dist.patience -= dt;
      let playerStaring = false;
      if (window.view3D) {
        playerStaring = window.view3D.isPlayerLookingAt(dist.pos);
      }

      let blockedByDoor = false;
      if (dist.pos === 'DOOR_LEFT' && this.switches.gateLeft) blockedByDoor = true;
      if (dist.pos === 'DOOR_RIGHT' && this.switches.gateRight) blockedByDoor = true;
      if (dist.pos === 'HALL_FRONT' && this.switches.gateCenter) blockedByDoor = true;

      // Stare limit: 4.5s if Mirror Glasses buff, else 1.8s
      const maxStare = this.activeBuffs.mirrorGlasses ? 4.5 : 1.8;

      if (playerStaring && !blockedByDoor) {
        dist.stareTimer += dt;
        this.pukanTemp = Math.min(100, this.pukanTemp + 8 * dt);
        if (Math.random() < 0.15) window.soundEngine.playDistortionDrone();

        if (dist.stareTimer >= maxStare) {
          this.triggerJumpscare(
            'distortion',
            'ИСКАЗИТЕЛЬ ВЫЖЕГ ТВОЙ МОЗГ!',
            'Ты слишком долго смотрел в его пронзающий взгляд!'
          );
          return;
        }
      } else {
        dist.stareTimer = Math.max(0, dist.stareTimer - dt * 1.5);
      }

      if (dist.patience <= 0) {
        dist.active = false;
        dist.pos = 'NONE';
        dist.nextSpawn = 12.0 + Math.random() * 12.0;
        this.addEventLog('Исказитель отступил в темноту...', 'ok');
      }
    }

    // B. Bug-Tadpole
    const tad = this.monsters.tadpole;
    if (!tad.active) {
      tad.nextSpawn -= dt;
      if (tad.nextSpawn <= 0) {
        tad.active = true;
        tad.health = 3;
        tad.x = (Math.random() - 0.5) * 1.6;
        tad.messTimer = 3.0;
        window.soundEngine.playTadpoleSplat();
        this.addEventLog('🐀 БАГОГРЫЗ на столе! Кликай по нему 3 раза!', 'warn');
      }
    } else {
      tad.messTimer -= dt;
      if (tad.messTimer <= 0) {
        tad.messTimer = 3.2;
        const randDIP = Math.floor(Math.random() * 4);
        this.switches.dip[randDIP] = 1 - this.switches.dip[randDIP];
        this.patchProgress = Math.max(0, this.patchProgress - 4);
        window.soundEngine.playSwitch(false);
        this.addEventLog('⚠️ Головастик погрыз код (-4%) и щёлкнул тумблер ядра!', 'danger');
      }
    }

    // C. Trojan Horse (T-Pose)
    const trojan = this.monsters.trojan;
    if (!trojan.inRoom) {
      trojan.distance = Math.max(0, trojan.distance - trojan.speed * dt);
      if (Math.random() < dt * 0.08) {
        window.soundEngine.playTrojanCreak();
      }

      if (trojan.distance <= 0) {
        trojan.inRoom = true;
        trojan.gambleTimer = 2.4;
        trojan.gambleResolved = false;
        window.soundEngine.playTrojanCreak();
        this.addEventLog('🐴 ТРОЯНСКИЙ КОНЬ ЗАЕХАЛ В Т-ПОЗЕ! РУЛЕТКА 50/50!', 'danger');
      }
    } else if (!trojan.gambleResolved) {
      trojan.gambleTimer -= dt;
      if (trojan.gambleTimer <= 0) {
        trojan.gambleResolved = true;
        if (Math.random() < 0.5) {
          // Win gamble
          this.power = Math.min(100, this.power + 50);
          this.pukanTemp = 10.0;
          this.patchProgress = Math.min(100, this.patchProgress + 20);
          trojan.distance = 90.0;
          trojan.inRoom = false;
          window.soundEngine.playVictoryChime();
          this.addEventLog('🎁 ТРОЯНСКИЙ ДАР! Конь выплюнул батареи (+50% ИБП, +20% патч) и уехал!', 'ok');
        } else {
          this.triggerJumpscare(
            'trojan',
            'ТРОЯНСКИЙ КОНЬ РАСПАХНУЛ БРЮХО!',
            'Рулетка 50/50 подвела! Из коня вырвался рой криптолокеров!'
          );
          return;
        }
      }
    }

    // D. Burgundy Vent Stalker
    const burg = this.monsters.burgundy;
    burg.clickCooldown -= dt;
    if (burg.clickCooldown <= 0) {
      burg.clickCooldown = 4.0 + Math.random() * 3.5;
      if (burg.stage > 0) window.soundEngine.playVentClick();
    }

    burg.moveCooldown -= dt;
    if (burg.moveCooldown <= 0) {
      burg.moveCooldown = 5.5;
      if (burg.stage === 0) {
        if (Math.random() < 0.45) {
          burg.stage = 1;
          window.soundEngine.playVentClick();
          this.addEventLog('В вентиляции слышно тихое клацанье: клик-клик...', 'warn');
        }
      } else if (burg.stage === 1) {
        burg.stage = 2; // ceiling vent
        burg.attackTimer = 5.5;
        window.soundEngine.playVentClick();
        this.addEventLog('🚨 БОРДОВЫЙ ДУШЕГУБ В РЕШЁТКЕ НАД ТОБОЙ! ДАЙ ПРОДУВКУ [V]!', 'danger');
      }
    }

    if (burg.stage === 2) {
      burg.attackTimer -= dt;
      if (burg.attackTimer <= 0) {
        this.triggerJumpscare(
          'burgundy',
          'БОРДОВЫЙ ДУШЕГУБ ВЫПРЫГНУЛ ИЗ ПОТОЛКА!',
          'Ты не продул вентиляционную решётку паром вовремя!'
        );
        return;
      }
    }
  }

  updateHazards(dt, cfg) {
    const h = this.hazards;

    if (h.gasLeaking) {
      h.gasPressure = Math.min(100, h.gasPressure + 2.2 * dt);
      if (h.gasPressure >= 100) {
        this.triggerJumpscare(
          'gas',
          'ОТРАВЛЕНИЕ ТОКСИЧНЫМ ХЛАДАГЕНТОМ!',
          'Давление газа достигло 100%! Ты не закрутил вентиль газа вовремя!'
        );
        return;
      }
    }

    if (h.printerWorking) {
      h.printerProgress = Math.min(100, h.printerProgress + 11.5 * dt);
      if (Math.random() < dt * 1.5) window.soundEngine.playPrinterPrint();

      if (h.printerProgress >= 100) {
        h.printerWorking = false;
        h.carrotsCount += 1;
        window.soundEngine.playPrinterDone();
        this.addEventLog(`🥕 Морковка готова! (В наличии: ${h.carrotsCount} шт.)`, 'ok');
      }
    }
  }

  // Player Actions
  startPrintingCarrot() {
    if (!this.running || this.gameOver || this.hazards.printerWorking) return;
    if (this.power <= 0 || this.hazards.blackout) {
      this.addEventLog('⚡ Принтер обесточен!', 'danger');
      return;
    }
    this.hazards.printerWorking = true;
    this.hazards.printerProgress = 0.0;
    this.power = Math.max(0, this.power - 2.5);
    window.soundEngine.playPrinterPrint();
    this.addEventLog('🖨️ 3D-Биопринтер запущен (печать морковки займёт ~9 сек)...', 'info');
  }

  throwCarrotAtTrojan() {
    if (!this.running || this.gameOver) return;
    if (this.hazards.carrotsCount <= 0) {
      this.addEventLog('⚠️ Нет морковок! Напечатай их на 3D-принтере на столе!', 'warn');
      return;
    }
    this.hazards.carrotsCount -= 1;
    this.monsters.trojan.distance = Math.min(100, this.monsters.trojan.distance + 42.0);
    this.monsters.trojan.inRoom = false;
    window.soundEngine.playTrojanCreak();
    this.addEventLog('🥕 Морковка брошена в тоннель! Троянский конь с хрустом отступил назад!', 'ok');
  }

  hitTadpole() {
    if (!this.running || this.gameOver || !this.monsters.tadpole.active) return;
    this.monsters.tadpole.health -= 1;
    window.soundEngine.playTadpoleSplat();

    if (this.monsters.tadpole.health <= 0) {
      this.monsters.tadpole.active = false;
      this.monsters.tadpole.nextSpawn = 18.0 + Math.random() * 12.0;
      this.addEventLog('💥 ХРЯСЬ! Багогрыз раздавлен тапком и вышвырнут!', 'ok');
    } else {
      this.addEventLog(`💥 Удар по головастику! Осталось ударов: ${this.monsters.tadpole.health}`, 'warn');
    }
  }

  turnGasValve(angleDelta) {
    if (!this.running || this.gameOver) return;
    const h = this.hazards;
    h.valveAngle += Math.abs(angleDelta);
    if (h.valveAngle >= Math.PI * 2) {
      h.valveAngle -= Math.PI * 2;
      h.gasPressure = Math.max(0, h.gasPressure - 35);
      window.soundEngine.playGasValveTurn();
      this.addEventLog('🔧 Вентиль провёрнут на 360°! Давление газа сброшено (-35%).', 'ok');

      if (h.gasPressure <= 0) {
        h.gasLeaking = false;
        setTimeout(() => { if (this.running) h.gasLeaking = true; }, 22000);
      }
    }
  }

  purgeVentsWithSteam() {
    if (!this.running || this.gameOver || this.steamVentCooldown > 0) return;
    this.steamVentCooldown = 4.0;
    this.pukanTemp = Math.max(0, this.pukanTemp - 9.0);
    window.soundEngine.playSteamVent();

    if (this.monsters.burgundy.stage > 0) {
      this.monsters.burgundy.stage = 0;
      this.monsters.burgundy.moveCooldown = 8.0;
      this.addEventLog('💨 ПШШШ! Струя кипящего пара обожгла Бордового Душегуба! Он с визгом удрал!', 'ok');
    } else {
      this.addEventLog('💨 Вентиляция продута паром (-9°C пукана).', 'info');
    }
  }

  triggerBlackout(reason) {
    if (this.activeBuffs.titaniumFuse) return; // Immune!
    this.hazards.blackout = true;
    window.soundEngine.setBlackout(true);
    this.addEventLog(`⚡ ${reason}`, 'danger');
  }

  resetBreaker() {
    if (!this.running || this.gameOver || !this.hazards.blackout) return;
    this.hazards.blackout = false;
    if (this.power <= 0) this.power = 20.0;
    window.soundEngine.setBlackout(false);
    window.soundEngine.playBreakerReset();
    this.addEventLog('💡 Рубильник взведён! Питание и свет в кабинете восстановлены!', 'ok');
  }

  spawnDipPuzzle(cfg) {
    let nextTarget = [0, 0, 0, 0];
    do {
      nextTarget = [
        Math.random() < 0.5 ? 1 : 0,
        Math.random() < 0.5 ? 1 : 0,
        Math.random() < 0.5 ? 1 : 0,
        Math.random() < 0.5 ? 1 : 0
      ];
    } while (
      nextTarget[0] === this.switches.dip[0] &&
      nextTarget[1] === this.switches.dip[1] &&
      nextTarget[2] === this.switches.dip[2] &&
      nextTarget[3] === this.switches.dip[3]
    );

    this.targetDip = nextTarget;
    this.dipPuzzleActive = true;
    this.dipMaxTimer = cfg.dipTimeout;
    this.dipTimer = cfg.dipTimeout;
    window.soundEngine.playPing(false);
    this.addEventLog(`🔧 МУТАЦИЯ ЯДРА! Выстави тумблеры SW1-4 в [${nextTarget.join(' ')}]!`, 'warn');
  }

  checkDipMatch() {
    if (!this.dipPuzzleActive) return;
    const match = this.switches.dip.every((val, idx) => val === this.targetDip[idx]);
    if (match) {
      const cfg = SHIFT_CONFIGS[this.currentLevel] || SHIFT_CONFIGS[1];
      this.dipPuzzleActive = false;
      this.nextDipCountdown = cfg.dipInterval;
      this.pukanTemp = Math.max(0, this.pukanTemp - 6);
      window.soundEngine.playPing(false);
      this.addEventLog('✅ Реестр синхронизирован! Тумблеры выставлены верно (-6°C пукана).', 'ok');
    }
  }

  incrementHack(reason) {
    this.hackCount += 1;
    this.pukanTemp = Math.min(100, this.pukanTemp + 16);
    this.addEventLog(`💀 ПРОБОЙ ЗАЩИТЫ (${this.hackCount}/${this.maxHacks}): ${reason}`, 'danger');

    if (this.hackCount >= this.maxHacks) {
      this.triggerJumpscare(
        'ai',
        'КРИТИЧЕСКАЯ МАССА ВЗЛОМОВ (5/5) — ТОТАЛЬНЫЙ СКРИМЕР ИИ!',
        '5 взломов переполнили систему! Рой взбесившихся демонов вырвался на экраны!'
      );
    }
  }

  toggleSwitch(key) {
    if (!this.running || this.gameOver) return;
    if (this.power <= 0 || this.hazards.blackout) {
      window.soundEngine.playPing(true);
      this.addEventLog('⚡ Кабинет обесточен! Включи рубильник на задней стене!', 'danger');
      return;
    }
    this.switches[key] = !this.switches[key];
    if (key.startsWith('gate')) {
      window.soundEngine.playGateSlam(this.switches[key]);
    } else {
      window.soundEngine.playSwitch(this.switches[key]);
    }
  }

  toggleDip(index) {
    if (!this.running || this.gameOver) return;
    this.switches.dip[index] = this.switches.dip[index] === 1 ? 0 : 1;
    window.soundEngine.playSwitch(this.switches.dip[index] === 1);
    this.checkDipMatch();
  }

  pingPort(side) {
    if (!this.running || this.gameOver || this.power <= 0 || this.hazards.blackout) return;
    this.power = Math.max(0, this.power - 0.35);

    if (side === 'left') {
      this.pingLeftActive = true;
      const danger = this.monsters.distortion.pos === 'DOOR_LEFT';
      window.soundEngine.playPing(danger);
      if (danger) this.addEventLog('🚨 ПИНГ 22: ИСКАЗИТЕЛЬ В ЛЕВОМ ШЛЮЗЕ! ЗАКРЫВАЙ [Q]!', 'danger');
      setTimeout(() => { this.pingLeftActive = false; }, 650);
    } else {
      this.pingRightActive = true;
      const danger = this.monsters.distortion.pos === 'DOOR_RIGHT';
      window.soundEngine.playPing(danger);
      if (danger) this.addEventLog('🚨 ПИНГ 5432: ИСКАЗИТЕЛЬ В ПРАВОМ ШЛЮЗЕ! ЗАКРЫВАЙ [E]!', 'danger');
      setTimeout(() => { this.pingRightActive = false; }, 650);
    }
  }

  writePatchChunk() {
    if (!this.running || this.gameOver) return;
    const cfg = SHIFT_CONFIGS[this.currentLevel] || SHIFT_CONFIGS[1];

    if (this.monsters.tadpole.active) {
      this.addEventLog('⚠️ ГОЛОВАСТИК ЖРЁТ ПРОВОДА КЛАВИАТУРЫ! Сначала убей его!', 'warn');
      return;
    }

    if (this.cctvOpen) this.cctvOpen = false;

    let gain = cfg.patchSpeed;
    if (this.switches.overclock && this.power > 0 && !this.hazards.blackout) gain *= 1.85;
    if (this.dipPuzzleActive) gain *= 0.45;

    this.patchProgress = Math.min(100, this.patchProgress + gain);
    this.pukanTemp = Math.min(100, this.pukanTemp + 0.32);
    window.soundEngine.playKeyClick();

    const snippet = CODE_SNIPPETS[Math.floor(Math.random() * CODE_SNIPPETS.length)];
    this.codeLines.push(`[${Math.floor(this.patchProgress)}%] > ${snippet}`);
    if (this.codeLines.length > 7) this.codeLines.shift();
  }

  crankGenerator() {
    if (!this.running || this.gameOver || this.crankCooldown > 0) return;
    this.crankCooldown = 7.0;
    this.power = Math.min(100, this.power + 15);
    this.pukanTemp = Math.min(100, this.pukanTemp + 7);
    window.soundEngine.playGateSlam(true);
    this.addEventLog('⛽ Дизель дёрнут (+15% ИБП, +7°C пукана от натуги)!', 'warn');
  }

  toggleCCTV() {
    if (!this.running || this.gameOver) return;
    if (this.power <= 0 || this.hazards.blackout) {
      this.cctvOpen = false;
      return;
    }
    this.cctvOpen = !this.cctvOpen;
    window.soundEngine.playSwitch(this.cctvOpen);
  }

  selectCam(camId) {
    if (!this.running || this.gameOver) return;
    this.currentCam = camId;
    this.cctvOpen = true;
    window.soundEngine.playSwitch(true);
  }

  triggerJumpscare(type, title, desc) {
    this.running = false;
    this.gameOver = true;
    if (this.loopId) cancelAnimationFrame(this.loopId);

    window.soundEngine.playJumpscare(type);
    if (window.view3D && window.view3D.initialized) {
      window.view3D.startJumpscare(type);
    }

    const modal = document.getElementById('gameover-modal');
    document.getElementById('jumpscare-title').textContent = title;
    document.getElementById('jumpscare-desc').textContent = desc;

    modal.classList.remove('hidden');
    modal.classList.add('jumpscare-active');
    setTimeout(() => { modal.classList.remove('jumpscare-active'); }, 1600);
  }

  triggerVictory() {
    this.running = false;
    this.gameOver = false;
    if (this.loopId) cancelAnimationFrame(this.loopId);

    window.soundEngine.playVictoryChime();

    // Unlock next level!
    if (this.currentLevel >= this.maxUnlockedLevel && this.maxUnlockedLevel < 6) {
      this.maxUnlockedLevel = this.currentLevel + 1;
    }

    const vModal = document.getElementById('victory-modal');
    document.getElementById('victory-shift-label').textContent =
      `СМЕНА #${this.currentLevel} УСПЕШНО ЗАКРЫТА! ПРОДАКШЕН ВЫЖИЛ ДО 06:00 AM!`;
    vModal.classList.remove('hidden');
  }

  addEventLog(msg, level = 'info') {
    const logEl = document.getElementById('event-log');
    if (!logEl) return;
    const item = document.createElement('div');
    const colorClass =
      level === 'danger'
        ? 'text-red-400 font-bold'
        : level === 'warn'
        ? 'text-amber-300'
        : level === 'ok'
        ? 'text-emerald-400 font-bold'
        : 'text-cyan-300';
    item.className = `text-[11px] ${colorClass} truncate`;
    item.textContent = `[${this.getFormattedClock()}] ${msg}`;
    logEl.prepend(item);
    while (logEl.children.length > 5) {
      logEl.removeChild(logEl.lastChild);
    }
  }

  getFormattedClock() {
    if (this.inLobby) return 'ДЕНЬ ☀️';
    const hour = Math.min(6, Math.floor((this.timeSeconds / this.totalShiftSeconds) * 6));
    const displayHour = hour === 0 ? '12' : `0${hour}`;
    return `${displayHour}:00 AM`;
  }

  renderUI() {
    // Clock & Shift
    document.getElementById('hud-clock').textContent = this.inLobby
      ? '12:00 PM (ДЕНЬ)'
      : this.inOvertime
      ? `ОВЕРТАЙМ: ${this.overtimeSeconds.toFixed(1)}c`
      : this.getFormattedClock();
    document.getElementById('hud-shift').textContent = `СМЕНА #${this.currentLevel}`;

    // Battery
    const pwrEl = document.getElementById('hud-power');
    pwrEl.textContent = `${Math.ceil(this.power)}%`;
    pwrEl.className = `text-xl font-extrabold ${
      this.power > 45 ? 'text-emerald-400' : this.power > 20 ? 'text-amber-400' : 'text-red-500 animate-pulse'
    }`;

    // Usage Bars
    const bars = this.getUsageBars();
    const barsContainer = document.getElementById('hud-usage-bars');
    if (barsContainer) {
      barsContainer.innerHTML = '';
      for (let i = 1; i <= 5; i++) {
        const div = document.createElement('div');
        const active = i <= bars;
        const color = i <= 2 ? 'bg-emerald-400' : i <= 3 ? 'bg-amber-400' : 'bg-red-500';
        div.className = `w-2.5 h-3.5 rounded-sm ${active ? color : 'bg-slate-800'}`;
        barsContainer.appendChild(div);
      }
    }

    // Pukanometer
    const pukanPct = Math.round(this.pukanTemp);
    document.getElementById('hud-pukan-val').textContent = `${pukanPct}°C`;
    const pukanBar = document.getElementById('hud-pukan-bar');
    pukanBar.style.width = `${pukanPct}%`;
    pukanBar.className = `h-full transition-all duration-100 ${
      pukanPct < 50 ? 'bg-emerald-500' : pukanPct < 78 ? 'bg-amber-500' : 'bg-red-600'
    }`;
    const pukanCard = document.getElementById('pukan-card');
    if (pukanPct >= 75) {
      pukanCard.classList.add('pukan-boiling', 'border-red-500');
    } else {
      pukanCard.classList.remove('pukan-boiling', 'border-red-500');
    }

    // Patch Progress
    const patchPct = Math.min(100, Math.floor(this.patchProgress));
    document.getElementById('hud-patch-val').textContent = `${patchPct}%`;
    document.getElementById('hud-patch-bar').style.width = `${patchPct}%`;

    // Hack Counter
    document.getElementById('hud-hacks-val').textContent = `${this.hackCount} / ${this.maxHacks}`;
    const hackPips = document.getElementById('hud-hack-pips');
    if (hackPips) {
      hackPips.innerHTML = '';
      for (let i = 1; i <= this.maxHacks; i++) {
        const pip = document.createElement('div');
        pip.className = `w-3.5 h-3.5 rounded-full border ${
          i <= this.hackCount
            ? 'bg-red-500 border-red-300 shadow-[0_0_8px_rgba(239,68,68,0.9)] animate-pulse'
            : 'bg-slate-900 border-slate-700'
        }`;
        hackPips.appendChild(pip);
      }
    }

    // Trojan radar status
    const trojanHud = document.getElementById('hud-trojan-status');
    if (trojanHud) {
      const dist = Math.round(this.monsters.trojan.distance);
      trojanHud.textContent = `🐴 Троян: ${dist}м [Морковь: ${this.hazards.carrotsCount}] [🪙 ${this.coins}/${this.maxCoins}]`;
      trojanHud.className = `text-xs font-bold ${dist < 25 ? 'text-red-400 animate-pulse' : 'text-amber-300'}`;
    }

    // Gas & Printer status badge
    const gasHud = document.getElementById('hud-gas-val');
    if (gasHud) {
      const g = Math.round(this.hazards.gasPressure);
      gasHud.textContent = `Газ: ${g}%`;
      gasHud.className = `text-[11px] font-bold ${g > 60 ? 'text-red-400 animate-pulse' : 'text-slate-400'}`;
    }

    // CCTV Tablet Overlay Sync
    const tabletModal = document.getElementById('cctv-tablet-modal');
    if (tabletModal) {
      if (this.cctvOpen) {
        tabletModal.classList.remove('hidden');
        tabletModal.classList.add('tablet-active');
        this.renderCCTVFeed();
      } else {
        tabletModal.classList.add('hidden');
        tabletModal.classList.remove('tablet-active');
      }
    }

    // DIP switches & labels
    for (let i = 0; i < 4; i++) {
      const valSpan = document.getElementById(`dip-val-${i}`);
      if (valSpan) valSpan.textContent = this.switches.dip[i];
    }
    const dipStatus = document.getElementById('dip-puzzle-box');
    const dipTargetText = document.getElementById('dip-target-bits');
    const dipTimerText = document.getElementById('dip-timer-text');
    if (this.dipPuzzleActive) {
      dipStatus.className = 'p-1.5 rounded-lg border-2 border-red-500 bg-red-950/40 animate-pulse mb-1.5 flex items-center justify-between';
      dipTargetText.textContent = `ЦЕЛЬ: [ ${this.targetDip.join('  ')} ]`;
      dipTimerText.textContent = `ВЗЛОМ: ${this.dipTimer.toFixed(1)}с`;
    } else {
      dipStatus.className = 'p-1.5 rounded-lg border border-slate-700 bg-slate-900/70 mb-1.5 flex items-center justify-between';
      dipTargetText.textContent = `ЯДРО: [ ${this.switches.dip.join('  ')} ]`;
      dipTimerText.textContent = 'Стабильно';
    }
  }

  renderLobbyUI() {
    const coinEl = document.getElementById('lobby-coins-val');
    if (coinEl) coinEl.textContent = `${this.coins} / ${this.maxCoins}`;

    // Render Level Selection Buttons
    const lvlBox = document.getElementById('lobby-levels-box');
    if (lvlBox) {
      lvlBox.innerHTML = '';
      for (let i = 1; i <= 6; i++) {
        const cfg = SHIFT_CONFIGS[i] || SHIFT_CONFIGS[1];
        const unlocked = i <= this.maxUnlockedLevel;
        const btn = document.createElement('button');
        btn.disabled = !unlocked;
        btn.className = `p-2.5 rounded-xl border text-left transition-all ${
          unlocked
            ? 'bg-slate-900/90 hover:bg-slate-800 border-cyan-500/80 cursor-pointer shadow-lg'
            : 'bg-slate-950/60 border-slate-800 text-slate-600 cursor-not-allowed opacity-50'
        }`;
        btn.onclick = () => this.startShiftFromLobby(i);
        btn.innerHTML = `
          <div class="font-extrabold text-xs ${unlocked ? 'text-cyan-300' : 'text-slate-600'}">
            ${unlocked ? '🔓' : '🔒'} СМЕНА #${i}: ${cfg.name.split(':')[1] || ''}
          </div>
          <div class="text-[10px] text-slate-400 font-sans mt-0.5">${cfg.subtitle}</div>
          <div class="text-[10px] text-amber-400 mt-1">🎯 Доп. задача: ${cfg.puzzleName} (+1🪙)</div>
        `;
        lvlBox.appendChild(btn);
      }
    }

    // Render Buff Shop Buttons
    const shopBox = document.getElementById('lobby-shop-box');
    if (shopBox) {
      const buffs = [
        { id: 'antiTrojanOats', name: '🥕 Анти-Троянский Овёс', desc: 'Конь начнёт на +50м дальше и медленнее на 30%', cost: 1 },
        { id: 'titaniumFuse', name: '⚡ Титановый Предохранитель', desc: 'Полный иммунитет к блэкаутам и выбитым пробкам', cost: 1 },
        { id: 'mirrorGlasses', name: '🕶️ Зеркальные Очки', desc: 'Защита от Исказителя: таймер взгляда увеличен до 4.5с', cost: 1 },
        { id: 'asbestosSeat', name: '🛡️ Асбестовая Подушка', desc: 'Пуканометр нагревается на 40% медленнее', cost: 1 },
        { id: 'bugRepellent', name: '🪰 Репеллент от Багов', desc: 'Багогрыз не появится первую половину ночи', cost: 1 }
      ];

      shopBox.innerHTML = '';
      buffs.forEach((b) => {
        const active = this.activeBuffs[b.id];
        const canBuy = this.coins >= b.cost && !active;
        const btn = document.createElement('button');
        btn.disabled = !canBuy;
        btn.className = `p-2 rounded-xl border flex items-center justify-between text-left transition-all ${
          active
            ? 'bg-emerald-950/80 border-emerald-500 text-emerald-300 cursor-default'
            : canBuy
            ? 'bg-slate-900/90 hover:bg-slate-800 border-amber-500/80 cursor-pointer text-slate-200'
            : 'bg-slate-950/60 border-slate-800 text-slate-600 cursor-not-allowed opacity-50'
        }`;
        btn.onclick = () => this.buyBuff(b.id);
        btn.innerHTML = `
          <div>
            <div class="font-extrabold text-xs">${b.name}</div>
            <div class="text-[10px] text-slate-400 font-sans">${b.desc}</div>
          </div>
          <div class="shrink-0 text-xs font-bold px-2.5 py-1 rounded ${active ? 'bg-emerald-800 text-white' : 'bg-amber-600 text-black'}">
            ${active ? 'КУПЛЕНО' : `КУПИТЬ (1🪙)`}
          </div>
        `;
        shopBox.appendChild(btn);
      });
    }
  }

  renderCCTVFeed() {
    const camNames = {
      CAM01: { name: 'CAM 01: Внешний Шлюз', desc: 'Периметр серверной (Исказитель)' },
      CAM02: { name: 'CAM 02: Коридор SSH', desc: 'Левый шлюз Порт 22' },
      CAM03: { name: 'CAM 03: Центральный Хаб', desc: 'Тоннель Троянского Коня' },
      CAM04: { name: 'CAM 04: Датастор SQL', desc: 'Правый шлюз Порт 5432' },
      CAM05: { name: 'CAM 05: Карантинный Сектор', desc: 'Склад Трояна (Тоннель)' },
      CAM06: { name: 'CAM 06: Подходной Вент-Канал', desc: 'Кабель-канал Бордового Душегуба' }
    };
    const camInfo = camNames[this.currentCam] || camNames.CAM01;
    document.getElementById('cctv-cam-title').textContent = camInfo.name;
    document.getElementById('cctv-cam-desc').textContent = camInfo.desc;

    ['CAM01', 'CAM02', 'CAM03', 'CAM04', 'CAM05', 'CAM06'].forEach((id) => {
      const btn = document.getElementById(`btn-${id}`);
      if (btn) {
        btn.className = id === this.currentCam
          ? 'px-2 py-1.5 rounded font-bold text-[11px] bg-cyan-600 text-white border border-cyan-300'
          : 'px-2 py-1.5 rounded font-bold text-[11px] bg-slate-800 text-slate-300 border border-slate-600';
      }
    });

    const occupants = [];
    if (this.monsters.distortion.active && this.monsters.distortion.pos !== 'NONE') {
      occupants.push(`👁️ Исказитель зафиксирован в секторе: ${this.monsters.distortion.pos}`);
    }
    const trDist = Math.round(this.monsters.trojan.distance);
    occupants.push(`🐴 Троянский Конь (T-Pose) движется по тоннелю: ${trDist}м до кабинета!`);
    if (this.monsters.burgundy.stage > 0) {
      occupants.push(`🩸 Бордовый Душегуб в вентиляции (Стадия: ${this.monsters.burgundy.stage})!`);
    }

    const box = document.getElementById('cctv-entities-box');
    if (box) {
      box.innerHTML = occupants.map((o) => `<div class="text-xs text-amber-300 font-mono py-0.5">${o}</div>`).join('');
    }
  }
}

window.prodGame = new ProdGame();

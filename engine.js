// ============================================================================
// ПЯТЬ НОЧЕЙ НА ПРОДЕ — Core Game Engine (FNaF 3D Horror & IT Satire)
// 4 Unique Monsters (Distortion Giant, Bug-Tadpole, Trojan T-Pose, Burgundy Vent Stalker)
// Environmental Hazards (Gas Valve, Blackouts & Circuit Breaker, 3D Bio-Carrot Printer)
// ============================================================================

const SHIFT_CONFIGS = {
  1: {
    name: 'СМЕНА 1: ПОНЕДЕЛЬНИК («Джуниор на ночном дежурстве»)',
    subtitle: 'Сеньор ушёл в запой. Не дай ИИ спалить стул и береги пукан.',
    dipInterval: 28,
    dipTimeout: 16,
    patchSpeed: 1.6,
    basePowerDrain: 0.13,
    trojanSpeed: 1.2,
    gasEnabled: false,
    blackoutChance: 0.0,
    phoneGuyMsg: '«Алло, джун! Добро пожаловать в ад. По коридорам бродят не просто вирусы, а сущие твари. Если в окне покажется гигантский тёмный урод с дисторшеном — НЕ СМОТРИ ЕМУ В ГЛАЗА, сразу закрывай дверь или отворачивайся! А если услышишь глухой скрип — это Троянский Конь скользит в T-Pose по тоннелю. Запусти печать морковки на биопринтере, чтобы приманить и оттолкнуть его назад!»'
  },
  2: {
    name: 'СМЕНА 2: ВТОРНИК («Утечка хладагента и Бордовый Сталкер»)',
    subtitle: 'В вентиляции зашевелились хвосты, а трубу с газом прорвало.',
    dipInterval: 24,
    dipTimeout: 14,
    patchSpeed: 1.45,
    basePowerDrain: 0.15,
    trojanSpeed: 1.6,
    gasEnabled: true,
    blackoutChance: 0.0,
    phoneGuyMsg: '«Ты выжил?! Ох*еть. Слушай внимательно: сегодня активировался Бордовый Душегуб. Он никогда не ходит в двери — он шуршит по вентиляции над твоей головой! Если слышишь резкие кликающие звуки "клик-клик" или видишь, как трясётся решётка — жми ПРОДУВКУ ВЕНТИЛЯЦИИ паром! И следи за вентилем газа на стене: если начнёт травить — хватай мышкой и крути по часовой стрелке!»'
  },
  3: {
    name: 'СМЕНА 3: СРЕДА («Нашествие Багогрызов и Блэкауты»)',
    subtitle: 'По полу бегают склизкие твари, а проводка искрит.',
    dipInterval: 20,
    dipTimeout: 12.5,
    patchSpeed: 1.35,
    basePowerDrain: 0.17,
    trojanSpeed: 2.0,
    gasEnabled: true,
    blackoutChance: 0.035,
    phoneGuyMsg: '«Алярм! В дата-центре завелись Багогрызы — мерзкие головастики-крысы. Они прибегают в самый неподходящий момент, прыгают на стол и блочат компиляцию! Забей их нахрен кликами мышки! А если резко вырубит весь свет и настанет гробовая тишина — обернись назад на 180° к звездному окну и щёлкни рубильник на щитке!»'
  },
  4: {
    name: 'СМЕНА 4: ЧЕТВЕРГ («Релиз без тестов и Троянская рулетка»)',
    subtitle: 'Троянский конь ускорил шаг, а пукан греется как ядро Чернобыля.',
    dipInterval: 17,
    dipTimeout: 11,
    patchSpeed: 1.25,
    basePowerDrain: 0.19,
    trojanSpeed: 2.5,
    gasEnabled: true,
    blackoutChance: 0.05,
    phoneGuyMsg: '«Держись за стул, малой! Троян прет в T-pose как танк! Если он всё же заедет в твою комнату — шанс 50 на 50: либо он отсыпет батареек и сбросит температуру пукана, либо разорвёт тебя на куски! Всегда держи готовую морковку в кармане!»'
  },
  5: {
    name: 'СМЕНА 5: ПЯТНИЦА 13-е («СИНГУЛЯРНОСТЬ ПРОДАКШЕНА»)',
    subtitle: 'Все монстры вышли на охоту одновременно. Твой стул на грани взрыва.',
    dipInterval: 14,
    dipTimeout: 9.5,
    patchSpeed: 1.15,
    basePowerDrain: 0.22,
    trojanSpeed: 3.0,
    gasEnabled: true,
    blackoutChance: 0.065,
    phoneGuyMsg: '«Предыдущий дежурный испарился вместе с креслом. Ты последняя линия обороны интернета. Пили хотфикс, крути вентиль, отбивайся морковкой и не дай Исказителю сожрать твой рассудок!»'
  },
  6: {
    name: 'СВОЯ НОЧЬ: 20/20/20/20 («АД СИСАДМИНА»)',
    subtitle: 'Кастомная хардкорная смена с максимальной агрессией монстров.',
    dipInterval: 12,
    dipTimeout: 8.5,
    patchSpeed: 1.1,
    basePowerDrain: 0.24,
    trojanSpeed: 3.5,
    gasEnabled: true,
    blackoutChance: 0.08,
    phoneGuyMsg: '«Режим максимального безумия. Да пребудет с тобой Святой Линус Торвальдс.»'
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
    this.shift = 1;
    this.unlockedShift = 1;
    this.running = false;
    this.gameOver = false;

    // Shift Clock
    this.timeSeconds = 0; // 0 to 180s (12:00 AM to 06:00 AM)
    this.totalShiftSeconds = 180;
    this.inOvertime = false;
    this.overtimeSeconds = 22.0;

    // Vitals
    this.power = 100.0;       // UPS %
    this.pukanTemp = 15.0;    // Chair Thermal Core 0°C -> 100°C
    this.patchProgress = 0.0; // 0% -> 100%
    this.hackCount = 0;       // 0 -> 5
    this.maxHacks = 5;

    // Hardware Switches
    this.switches = {
      gateLeft: false,    // Port 22 SSH Firewall
      gateCenter: false,  // Center Blast Shutter
      gateRight: false,   // Port 5432 SQL Firewall
      seatCooler: false,  // Chair Bidet Cooler
      overclock: false,   // CPU Overclock
      dip: [0, 1, 0, 1]   // Binary DIP Switches SW1-SW4
    };

    // Target DIP Switches
    this.targetDip = [0, 1, 0, 1];
    this.dipPuzzleActive = false;
    this.dipTimer = 0;
    this.dipMaxTimer = 15;
    this.nextDipCountdown = 12;

    // Port Scanners
    this.pingLeftActive = false;
    this.pingRightActive = false;
    this.crankCooldown = 0;
    this.steamVentCooldown = 0;

    // CCTV Tablet
    this.cctvOpen = false;
    this.currentCam = 'CAM01';

    // =========================================================================
    // 4 REAL MONSTERS STATE MACHINE
    // =========================================================================
    this.monsters = {
      // 1. The Distortion Giant («Исказитель / Архитектор Хуйло»)
      distortion: {
        name: 'ИСКАЗИТЕЛЬ (АРХИТЕКТОР ХУЙЛО)',
        active: false,
        pos: 'NONE', // 'DOOR_LEFT', 'DOOR_RIGHT', 'WINDOW', 'HALL'
        stareTimer: 0, // > 1.8s direct stare -> JUMPSCARE!
        patience: 6.0,
        nextSpawn: 12.0
      },

      // 2. The Bug-Tadpole Virus («Багогрыз-Головастик»)
      tadpole: {
        name: 'БАГОГРЫЗ-ГОЛОВАСТИК',
        active: false,
        health: 3, // 3 clicks to kill
        x: 0,
        y: 0,
        scuttleTimer: 0,
        messTimer: 3.5, // messes with system every 3.5s
        nextSpawn: 18.0
      },

      // 3. Trojan Horse.exe («Троянский Конь в T-Pose»)
      trojan: {
        name: 'ТРОЯНСКИЙ КОНЬ (T-POSE.EXE)',
        distance: 100.0, // 100m -> 0m
        speed: 1.2,
        inRoom: false,
        gambleTimer: 0,
        gambleResolved: false
      },

      // 4. Burgundy Vent Stalker («Бордовый Душегуб / Вентиляционная Тварь»)
      burgundy: {
        name: 'БОРДОВЫЙ ДУШЕГУБ',
        stage: 0, // 0: deep pipes, 1: approach duct, 2: office ceiling vent grate, 3: lunging
        clickCooldown: 4.0,
        attackTimer: 0, // > 5.0s in stage 2 -> JUMPSCARE!
        moveCooldown: 6.0
      }
    };

    // =========================================================================
    // ENVIRONMENTAL HAZARDS (Gas Valve, Blackouts, 3D Bio-Printer, Minigame)
    // =========================================================================
    this.hazards = {
      // A. Toxic Gas Valve
      gasPressure: 0.0, // 0% -> 100%
      gasLeaking: false,
      valveAngle: 0.0,
      valveRotationsDone: 0,
      valveTargetRotations: 3,

      // B. Blackout Circuit Breaker
      blackout: false,
      blackoutTimer: 0,

      // C. Synthetic 3D Bioprinter (Carrots)
      printerWorking: false,
      printerProgress: 0.0, // 0% -> 100%
      carrotsCount: 1, // Start with 1 carrot

      // D. CRT Monitor Quick Minigame
      minigameActive: false,
      minigameType: 'memory', // 'memory', 'git', 'binary'
      minigameTimer: 0,
      minigameTarget: 0
    };

    this.codeLines = [
      '// СЕРВЕРНЫЙ ТЕРМИНАЛ ДЕЖУРНОГО v5.0 (PS1 3D EDITION)',
      '// Жми [ПРОБЕЛ] или кликай по монитору, чтобы пилить патч!'
    ];

    this.lastTick = performance.now();
    this.loopId = null;
  }

  startShift(shiftNum) {
    window.soundEngine.init();
    this.shift = shiftNum;
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

    // Reset Monsters
    this.monsters.distortion = {
      name: 'ИСКАЗИТЕЛЬ',
      active: false,
      pos: 'NONE',
      stareTimer: 0,
      patience: Math.max(3.8, 7.5 - shiftNum * 0.6),
      nextSpawn: 10.0
    };

    this.monsters.tadpole = {
      name: 'БАГОГРЫЗ-ГОЛОВАСТИК',
      active: false,
      health: 3,
      x: 0,
      y: 0,
      scuttleTimer: 0,
      messTimer: 3.5,
      nextSpawn: 14.0
    };

    this.monsters.trojan = {
      name: 'ТРОЯНСКИЙ КОНЬ',
      distance: 100.0,
      speed: cfg.trojanSpeed,
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

    // Reset Hazards
    this.hazards.gasPressure = 0.0;
    this.hazards.gasLeaking = cfg.gasEnabled;
    this.hazards.valveAngle = 0.0;
    this.hazards.valveRotationsDone = 0;
    this.hazards.blackout = false;
    this.hazards.printerWorking = false;
    this.hazards.printerProgress = 0.0;
    this.hazards.carrotsCount = 1;
    this.hazards.minigameActive = false;

    window.soundEngine.setBlackout(false);
    window.soundEngine.playSwitch(true);

    this.codeLines = [
      `// === ЗАПУСК: ${cfg.name} ===`,
      '// Пили патч до 100% и выживи до 06:00 AM!'
    ];

    this.addEventLog(`Смена #${shiftNum} началась! Не дай пукану рвануть!`, 'info');

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
    const cfg = SHIFT_CONFIGS[this.shift] || SHIFT_CONFIGS[1];

    // 1. Shift Clock & Overtime
    if (!this.inOvertime) {
      this.timeSeconds += dt;
      if (this.timeSeconds >= this.totalShiftSeconds) {
        if (this.patchProgress >= 100) {
          this.triggerVictory();
          return;
        } else {
          this.inOvertime = true;
          this.overtimeSeconds = 22.0;
          window.soundEngine.playSprintSiren();
          this.addEventLog('🚨 06:00 AM! ПАТЧ НЕ ДОПИЛЕН! ОВЕРТАЙМ 22 СЕК ИЛИ СМЕРТЬ!', 'danger');
        }
      }
    } else {
      this.overtimeSeconds -= dt;
      if (this.patchProgress >= 100) {
        this.triggerVictory();
        return;
      }
      if (this.overtimeSeconds <= 0) {
        this.triggerJumpscare(
          'pukan',
          'ДЕДЛАЙН ПРОСРАН! ТИМЛИД СЖЁГ СЕРВЕРНУЮ!',
          'В 06:00 утра прод лёг без патча. Тимлид и ИИ испекли твоё кресло!'
        );
        return;
      }
    }

    // 2. Battery & Blackout Handling
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

    // Random power trip breaker (Shifts 3+)
    if (!this.hazards.blackout && cfg.blackoutChance > 0 && Math.random() < dt * cfg.blackoutChance * 0.1) {
      this.triggerBlackout('⚡ ВЫБИЛО ПРОБКИ! Повернись назад на 180° к щитку и включи рубильник!');
    }

    // 3. Pukanometer Heat
    let heatRate = 0.65;
    if (this.switches.overclock) heatRate += 2.2;
    if (this.dipPuzzleActive) heatRate += 1.4;
    if (this.hazards.gasPressure > 50) heatRate += 1.8;
    if (this.monsters.tadpole.active) heatRate += 1.2;
    if (this.inOvertime) heatRate += 3.5;
    heatRate += this.hackCount * 0.9;

    if (this.switches.seatCooler && this.power > 0 && !this.hazards.blackout) {
      heatRate -= 4.8;
    }

    this.pukanTemp = Math.max(0, Math.min(100, this.pukanTemp + heatRate * dt));
    if (this.pukanTemp >= 100) {
      this.triggerJumpscare(
        'pukan',
        'ТЕРМОЯДЕРНОЕ ИЗВЕРЖЕНИЕ ПУКАНА!',
        'Температура кресла пробила 100°C! Взрыв уничтожил дежурного и продакшен!'
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

    // 5. Environmental Hazards Update
    this.updateHazards(dt, cfg);

    // 6. Monsters Update
    this.updateMonsters(dt, cfg);
  }

  // =========================================================================
  // MONSTERS BEHAVIORS
  // =========================================================================
  updateMonsters(dt, cfg) {
    // --- A. THE DISTORTION GIANT («Исказитель / Архитектор Хуйло») ---
    const dist = this.monsters.distortion;
    if (!dist.active) {
      dist.nextSpawn -= dt;
      if (dist.nextSpawn <= 0) {
        dist.active = true;
        const positions = ['DOOR_LEFT', 'DOOR_RIGHT', 'WINDOW_BACK', 'HALL_FRONT'];
        dist.pos = positions[Math.floor(Math.random() * positions.length)];
        dist.stareTimer = 0;
        dist.patience = Math.max(4.0, 7.5 - this.shift * 0.5);
        window.soundEngine.playDistortionDrone();
        this.addEventLog(`👁️ ИСКАЗИТЕЛЬ смотрит на тебя из ${dist.pos}! НЕ СМОТРИ НА НЕГО ДРЕЙФОМ!`, 'danger');
      }
    } else {
      dist.patience -= dt;
      // Check if player is directly staring at him in 3D
      let playerStaring = false;
      if (window.view3D) {
        playerStaring = window.view3D.isPlayerLookingAt(dist.pos);
      }

      // Check if door blocks his view
      let blockedByDoor = false;
      if (dist.pos === 'DOOR_LEFT' && this.switches.gateLeft) blockedByDoor = true;
      if (dist.pos === 'DOOR_RIGHT' && this.switches.gateRight) blockedByDoor = true;
      if (dist.pos === 'HALL_FRONT' && this.switches.gateCenter) blockedByDoor = true;

      if (playerStaring && !blockedByDoor) {
        dist.stareTimer += dt;
        this.pukanTemp = Math.min(100, this.pukanTemp + 8 * dt);
        if (Math.random() < 0.15) window.soundEngine.playDistortionDrone();

        if (dist.stareTimer >= 1.8) {
          this.triggerJumpscare(
            'distortion',
            'ИСКАЗИТЕЛЬ ВЫЖЕГ ТВОЙ МОЗГ!',
            'Ты слишком долго смотрел в его пронзающий искажённый взгляд!'
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
        this.addEventLog('Исказитель скрылся во тьме дата-центра...', 'ok');
      }
    }

    // --- B. THE BUG-TADPOLE («Багогрыз-Головастик») ---
    const tad = this.monsters.tadpole;
    if (!tad.active) {
      tad.nextSpawn -= dt;
      if (tad.nextSpawn <= 0) {
        tad.active = true;
        tad.health = 3;
        tad.x = (Math.random() - 0.5) * 1.6;
        tad.y = 1.05; // on desk
        tad.messTimer = 3.0;
        window.soundEngine.playTadpoleSplat();
        this.addEventLog('🐀 БАГОГРЫЗ-ГОЛОВАСТИК запрыгнул на стол! КЛИКАЙ ПО НЕМУ 3 РАЗА!', 'warn');
      }
    } else {
      tad.messTimer -= dt;
      if (tad.messTimer <= 0) {
        tad.messTimer = 3.2;
        // Causes disruption: flips DIP switch or inverts mouse or deletes patch %
        const randDIP = Math.floor(Math.random() * 4);
        this.switches.dip[randDIP] = 1 - this.switches.dip[randDIP];
        this.patchProgress = Math.max(0, this.patchProgress - 4);
        window.soundEngine.playSwitch(false);
        this.addEventLog('⚠️ Головастик переключил тумблер ядра и погрыз байты патча (-4%)!', 'danger');
      }
    }

    // --- C. TROJAN HORSE.EXE («Троянский Конь в T-Pose») ---
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
        this.addEventLog('🐴💀 ТРОЯНСКИЙ КОНЬ ЗАЕХАЛ В ТВОЙ КАБИНЕТ В T-POSE! РУЛЕТКА 50/50!', 'danger');
      }
    } else if (!trojan.gambleResolved) {
      trojan.gambleTimer -= dt;
      if (trojan.gambleTimer <= 0) {
        trojan.gambleResolved = true;
        if (Math.random() < 0.5) {
          // 50% Win Gamble!
          this.power = Math.min(100, this.power + 50);
          this.pukanTemp = 10.0;
          this.patchProgress = Math.min(100, this.patchProgress + 20);
          trojan.distance = 90.0;
          trojan.inRoom = false;
          window.soundEngine.playVictoryChime();
          this.addEventLog('🎁 ТРОЯНСКИЙ ДАР! Конь выплюнул батарейки (+50% ИБП, +20% патч) и уехал!', 'ok');
        } else {
          // 50% Death!
          this.triggerJumpscare(
            'trojan',
            'ТРОЯНСКИЙ КОНЬ РАСПАХНУЛ БРЮХО!',
            'Рулетка 50/50 подвела! Из коня вырвался рой криптолокеров и разорвал тебя!'
          );
          return;
        }
      }
    }

    // --- D. BURGUNDY VENT STALKER («Бордовый Душегуб») ---
    const burg = this.monsters.burgundy;
    burg.clickCooldown -= dt;
    if (burg.clickCooldown <= 0) {
      burg.clickCooldown = 4.0 + Math.random() * 3.5;
      if (burg.stage > 0) {
        window.soundEngine.playVentClick();
      }
    }

    burg.moveCooldown -= dt;
    if (burg.moveCooldown <= 0) {
      burg.moveCooldown = 5.5;
      if (burg.stage === 0) {
        if (Math.random() < 0.45) {
          burg.stage = 1; // approaching vent
          window.soundEngine.playVentClick();
          this.addEventLog('В вентиляции слышно тихое клацанье: клик-клик...', 'warn');
        }
      } else if (burg.stage === 1) {
        burg.stage = 2; // directly above office ceiling vent!
        burg.attackTimer = 5.5;
        window.soundEngine.playVentClick();
        this.addEventLog('🚨 БОРДОВЫЙ ДУШЕГУБ В РЕШЁТКЕ НАД ТОБОЙ! ДАЙ ПРОДУВКУ ПАРОМ [V]!', 'danger');
      }
    }

    if (burg.stage === 2) {
      burg.attackTimer -= dt;
      if (burg.attackTimer <= 0) {
        this.triggerJumpscare(
          'burgundy',
          'БОРДОВЫЙ ДУШЕГУБ ВЫПРЫГНУЛ ИЗ ВЕНТИЛЯЦИИ!',
          'Ты не продул вентиляционную решётку паром вовремя!'
        );
        return;
      }
    }
  }

  // =========================================================================
  // HAZARDS: GAS, BLACKOUT, PRINTER, MINIGAMES
  // =========================================================================
  updateHazards(dt, cfg) {
    const h = this.hazards;

    // A. Gas Leak
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

    // B. Bio-Printer (Carrot generator)
    if (h.printerWorking) {
      h.printerProgress = Math.min(100, h.printerProgress + 11.5 * dt);
      if (Math.random() < dt * 1.5) window.soundEngine.playPrinterPrint();

      if (h.printerProgress >= 100) {
        h.printerWorking = false;
        h.carrotsCount += 1;
        window.soundEngine.playPrinterDone();
        this.addEventLog(`🥕 Морковка напечатана на 3D-принтере! (В наличии: ${h.carrotsCount} шт.)`, 'ok');
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
      this.addEventLog('⚠️ У тебя нет морковки! Напечатай её на 3D-принтере!', 'warn');
      return;
    }
    this.hazards.carrotsCount -= 1;
    this.monsters.trojan.distance = Math.min(100, this.monsters.trojan.distance + 42.0);
    this.monsters.trojan.inRoom = false;
    window.soundEngine.playTrojanCreak();
    this.addEventLog('🥕 Морковка брошена в тоннель! Троянский конь с чавканьем отступил на 42 метра назад!', 'ok');
  }

  hitTadpole() {
    if (!this.running || this.gameOver || !this.monsters.tadpole.active) return;
    this.monsters.tadpole.health -= 1;
    window.soundEngine.playTadpoleSplat();

    if (this.monsters.tadpole.health <= 0) {
      this.monsters.tadpole.active = false;
      this.monsters.tadpole.nextSpawn = 18.0 + Math.random() * 12.0;
      this.addEventLog('💥 ХРЯСЬ! Багогрыз раздавлен тапком и вышвырнут из кабинета!', 'ok');
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
      h.valveRotationsDone += 1;
      h.gasPressure = Math.max(0, h.gasPressure - 35);
      window.soundEngine.playGasValveTurn();
      this.addEventLog(`🔧 Вентиль провёрнут на 360°! Давление газа сброшено (-35%).`, 'ok');

      if (h.gasPressure <= 0) {
        h.gasLeaking = false;
        setTimeout(() => {
          if (this.running) h.gasLeaking = true;
        }, 22000);
      }
    }
  }

  purgeVentsWithSteam() {
    if (!this.running || this.gameOver || this.steamVentCooldown > 0) return;
    this.steamVentCooldown = 4.0;
    this.pukanTemp = Math.max(0, this.pukanTemp - 9.0);
    window.soundEngine.playSteamVent();

    // If Burgundy stalker was in vent stage 1 or 2 -> Drive it back!
    if (this.monsters.burgundy.stage > 0) {
      this.monsters.burgundy.stage = 0;
      this.monsters.burgundy.moveCooldown = 8.0;
      this.addEventLog('💨 ПШШШ! Струя кипящего пара обожгла Бордового Душегуба! Он с визгом удрал вглубь труб!', 'ok');
    } else {
      this.addEventLog('💨 Вентиляция продута паром (-9°C пукана).', 'info');
    }
  }

  triggerBlackout(reason) {
    this.hazards.blackout = true;
    window.soundEngine.setBlackout(true);
    this.addEventLog(`⚡ ${reason}`, 'danger');
  }

  resetBreaker() {
    if (!this.running || this.gameOver || !this.hazards.blackout) return;
    this.hazards.blackout = false;
    if (this.power <= 0) {
      this.power = 20.0; // small emergency reserve
    }
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
      const cfg = SHIFT_CONFIGS[this.shift] || SHIFT_CONFIGS[1];
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
    const cfg = SHIFT_CONFIGS[this.shift] || SHIFT_CONFIGS[1];

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
    if (this.shift < 6 && this.unlockedShift <= this.shift) {
      this.unlockedShift = this.shift + 1;
    }

    const vModal = document.getElementById('victory-modal');
    document.getElementById('victory-shift-label').textContent =
      `СМЕНА #${this.shift} УСПЕШНО ЗАКРЫТА! ПРОДАКШЕН ВЫЖИЛ ДО 06:00 AM!`;
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
    const hour = Math.min(6, Math.floor((this.timeSeconds / this.totalShiftSeconds) * 6));
    const displayHour = hour === 0 ? '12' : `0${hour}`;
    return `${displayHour}:00 AM`;
  }

  renderUI() {
    // Clock & Shift
    document.getElementById('hud-clock').textContent = this.inOvertime
      ? `ОВЕРТАЙМ: ${this.overtimeSeconds.toFixed(1)}c`
      : this.getFormattedClock();
    document.getElementById('hud-shift').textContent = `СМЕНА #${this.shift}`;

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
      trojanHud.textContent = `🐴 Троян: ${dist}м [Морковок: ${this.hazards.carrotsCount}]`;
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

    // Mini-map buttons
    ['CAM01', 'CAM02', 'CAM03', 'CAM04', 'CAM05', 'CAM06'].forEach((id) => {
      const btn = document.getElementById(`btn-${id}`);
      if (btn) {
        btn.className = id === this.currentCam
          ? 'px-2 py-1.5 rounded font-bold text-[11px] bg-cyan-600 text-white border border-cyan-300'
          : 'px-2 py-1.5 rounded font-bold text-[11px] bg-slate-800 text-slate-300 border border-slate-600';
      }
    });

    // Occupants description
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

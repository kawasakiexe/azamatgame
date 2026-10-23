// ============================================================================
// ПЯТЬ НОЧЕЙ НА ПРОДЕ — Core Game Engine, AI State Machines & Balance
// ============================================================================

const SHIFT_CONFIGS = {
  1: {
    name: 'СМЕНА 1: ПОНЕДЕЛЬНИК («Джуниор на дежурстве»)',
    subtitle: 'Сеньор ушёл в запой. Запили хотфикс до 06:00 и не дай ИИ спалить твой стул.',
    aiLevels: { bonnie: 3, chica: 2, foxy: 2, freddy: 0 },
    dipInterval: 28,
    dipTimeout: 16,
    patchSpeed: 1.55,
    basePowerDrain: 0.14,
    phoneGuyMsg: '«Алло, малой! Короче, на проде завелся еб*ный ИИ СкуфНет. Если слышишь шорох на портах 22 или 5432 — сразу врубай фаервол! Следи за CAM-05: там Фокси-Криптолокер копит DDoS, пингуй его кнопкой KILL-9! И главное — выставляй бинарные тумблеры ядра вовремя, иначе наберёшь 5 взломов или у тебя рванёт пукан!»'
  },
  2: {
    name: 'СМЕНА 2: ВТОРНИК («Кровавый деплой»)',
    subtitle: 'Нейросети научились делать git push --force. Фредди-Архитектор вышел из спячки.',
    aiLevels: { bonnie: 6, chica: 5, foxy: 5, freddy: 3 },
    dipInterval: 23,
    dipTimeout: 14,
    patchSpeed: 1.4,
    basePowerDrain: 0.16,
    phoneGuyMsg: '«Ты выжил в понедельник?! Красава. Но сегодня проснулся Скайнет-Фредди — он ползёт по центру (CAM-03 -> CAM-06). Когда он близко, меняй ротацию тумблеров и свети на него камерой! И не забывай включать Турбо-Обдув кресла, сегодня жарко!»'
  },
  3: {
    name: 'СМЕНА 3: СРЕДА («Восстание LLM-Агентов»)',
    subtitle: 'Боты плодятся быстрее, чем закрываются тикеты в Jira.',
    aiLevels: { bonnie: 9, chica: 8, foxy: 8, freddy: 6 },
    dipInterval: 19,
    dipTimeout: 12.5,
    patchSpeed: 1.3,
    basePowerDrain: 0.18,
    phoneGuyMsg: '«Слушай сюда! Эти твари теперь мутируют реестр каждые 19 секунд! Если прошляпишь таймер тумблеров SW1-SW4 — получишь пробой безопасности (+1 ВЗЛОМ). На 5 взломах ИИ врубает скример и форматирует планету. Держись!»'
  },
  4: {
    name: 'СМЕНА 4: ЧЕТВЕРГ («Релиз без тестов»)',
    subtitle: 'Менеджеры пообещали клиентам релиз к утру. ИИ пытается запустить ядерные ракеты.',
    aiLevels: { bonnie: 12, chica: 12, foxy: 11, freddy: 10 },
    dipInterval: 16,
    dipTimeout: 11,
    patchSpeed: 1.22,
    basePowerDrain: 0.2,
    phoneGuyMsg: '«АААА! Тут всё горит! Энергия ИБП тает на глазах — не держи фаерволы закрытыми просто так, используй ПИНГ портов [A] и [D]! Если батарея сядет в ноль — крути ручной Дизель-Генератор, но учти: его шум приманивает ботов!»'
  },
  5: {
    name: 'СМЕНА 5: ПЯТНИЦА 13-е («СИНГУЛЯРНОСТЬ ПУКАНА»)',
    subtitle: 'Финальный рубеж человечества. Против тебя — весь кластер GPT-666.',
    aiLevels: { bonnie: 16, chica: 15, foxy: 15, freddy: 14 },
    dipInterval: 13.5,
    dipTimeout: 9.5,
    patchSpeed: 1.15,
    basePowerDrain: 0.22,
    phoneGuyMsg: '«Предыдущий дежурный... его кресло пробило потолок и вышло на орбиту. Ты последняя надежда продакшена. Пили патч, щёлкай тумблерами как пианист и береги пукан!»'
  },
  6: {
    name: 'СВОЯ НОЧЬ: РЕЖИМ 20/20/20/20 («АД ДЕВОПСА»)',
    subtitle: 'Экстремальная смена с ручной настройкой агрессии ИИ-аниматроников.',
    aiLevels: { bonnie: 20, chica: 20, foxy: 20, freddy: 20 },
    dipInterval: 11.5,
    dipTimeout: 8.5,
    patchSpeed: 1.15,
    basePowerDrain: 0.23,
    phoneGuyMsg: '«Режим 20/20/20/20 активирован. Да поможет тебе Святой Кубернетес.»'
  }
};

const CAM_NODES = {
  CAM01: { id: 'CAM01', name: 'CAM 01: Внешний Шлюз (Edge)', desc: 'Точка входа трафика и спавна ИИ-ботов' },
  CAM02: { id: 'CAM02', name: 'CAM 02: Кластер SSH (Левый канал)', desc: 'Маршрут Бонни-Брутфорсера к Порту 22' },
  CAM03: { id: 'CAM03', name: 'CAM 03: Хаб Балансировки (Центр)', desc: 'Маршрут Скайнет-Фредди к серверной' },
  CAM04: { id: 'CAM04', name: 'CAM 04: Реплика БД SQL (Правый канал)', desc: 'Маршрут Чики-Инъекторши к Порту 5432' },
  CAM05: { id: 'CAM05', name: 'CAM 05: Карантин Фокси-Локера', desc: 'Копит заряд DDoS-атаки! Сбивай кнопкой KILL -9' },
  CAM06: { id: 'CAM06', name: 'CAM 06: Кабель-канал Дежурки', desc: 'Финальная труба перед твоим столом (Рубильник ЦОД)' }
};

const CODE_SNIPPETS = [
  'if (ai.wantsToDestroyWorld()) { ai.setNiceness(9999); }',
  'sudo iptables -A INPUT -s 666.666.0.0/16 -j DROP // ИдинахерGPT',
  'try { fixProd(); } catch (PukanExplosionError e) {applyIcePack();}',
  'const patch = await bypassSkufNetFirewall({ force: true, молитва: "Отче наш" });',
  'while (server.isBurning) { pourCoffeeOnMotherboard(); }',
  'git commit -m "hotfix: запретил нейросети запускать ядерку по пятницам"',
  'killall -9 bonnie_ssh_daemon chica_sql_worm foxy_ddos_pirate',
  'export PUKAN_MAX_TEMP=9000; sysctl -w kernel.panic_on_ai=0;'
];

class ProdGame {
  constructor() {
    this.shift = 1;
    this.unlockedShift = 1;
    this.running = false;
    this.gameOver = false;

    // Core timers & gauges
    this.timeSeconds = 0; // 0 to 180 seconds (00:00 to 06:00 AM, 30s per hour)
    this.totalShiftSeconds = 180;
    this.overtimeSeconds = 0;
    this.inOvertime = false;

    this.power = 100.0;        // UPS Battery %
    this.pukanTemp = 12.0;     // Chair Thermal Core 0% -> 100%
    this.patchProgress = 0.0;  // 0% -> 100%
    this.hackCount = 0;        // 0 -> 5 (5 = Screamer!)
    this.maxHacks = 5;

    // Hardware Switches
    this.switches = {
      gateLeft: false,    // Port 22 SSH Firewall
      gateCenter: false,  // Center Airgap Shutter
      gateRight: false,   // Port 5432 SQL Firewall
      seatCooler: false,  // Chair Turbo-Bidet Cooler
      overclock: false,   // CPU Overclock (2x patch speed, +heat, +power)
      dip: [0, 0, 0, 0]   // 4 Binary Kernel Switches SW1-SW4
    };

    // Kernel Dip-Switch Puzzle State
    this.targetDip = [0, 0, 0, 0];
    this.dipPuzzleActive = false;
    this.dipTimer = 0;
    this.dipMaxTimer = 15;
    this.nextDipCountdown = 12;

    // DNS Captcha / Registry Flush Secondary Alert
    this.dnsAlertActive = false;
    this.dnsAlertTimer = 0;

    // Port Scanner Ping States
    this.pingLeftActive = false;
    this.pingRightActive = false;
    this.crankCooldown = 0;

    // Camera / View State
    this.cctvOpen = false;
    this.currentCam = 'CAM01';

    // AI Entities State Machine
    this.ai = {
      bonnie: {
        name: 'БОННИ-БРУТФОРСЕР',
        role: 'SSH-Демон (Левый шлюз)',
        level: 3,
        pos: 'CAM01', // CAM01 -> CAM02 -> DOOR_LEFT
        doorTimer: 0,
        moveCooldown: 4.5
      },
      chica: {
        name: 'ЧИКА-ИНЪЕКТОРША',
        role: 'SQL-Червь (Правый шлюз)',
        level: 2,
        pos: 'CAM01', // CAM01 -> CAM04 -> DOOR_RIGHT
        doorTimer: 0,
        moveCooldown: 5.2
      },
      foxy: {
        name: 'ФОКСИ-КРИПТОЛОКЕР',
        role: 'DDoS-Пират (CAM 05 -> Центр)',
        level: 2,
        charge: 0,     // 0% -> 100%
        sprinting: false,
        sprintTimer: 0 // When 100%, player has 4.0s to close Center Gate!
      },
      freddy: {
        name: 'СКАЙНЕТ-ФРЕДДИ',
        role: 'AGI-Архитектор (Центр)',
        level: 0,
        pos: 'CAM01', // CAM01 -> CAM03 -> CAM06 -> DOOR_CENTER
        doorTimer: 0,
        moveCooldown: 6.5
      }
    };

    this.codeLines = [
      '// СЕРВЕРНЫЙ ТЕРМИНАЛ ДЕЖУРНОГО v4.04',
      '// Нажимай [ПРОБЕЛ] или кнопку «ПИЛИТЬ ПАТЧ», чтобы писать код...'
    ];
    this.lastTick = performance.now();
    this.loopId = null;
  }

  startShift(shiftNum, customLevels = null) {
    window.soundEngine.init();
    this.shift = shiftNum;
    const cfg = SHIFT_CONFIGS[shiftNum] || SHIFT_CONFIGS[1];

    this.running = true;
    this.gameOver = false;
    this.timeSeconds = 0;
    this.inOvertime = false;
    this.overtimeSeconds = 20;

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
    this.nextDipCountdown = 9;

    this.dnsAlertActive = false;
    this.dnsAlertTimer = 0;
    this.crankCooldown = 0;

    this.cctvOpen = false;
    this.currentCam = 'CAM01';

    const lv = customLevels || cfg.aiLevels;
    this.ai.bonnie.level = lv.bonnie;
    this.ai.bonnie.pos = 'CAM01';
    this.ai.bonnie.doorTimer = 0;

    this.ai.chica.level = lv.chica;
    this.ai.chica.pos = 'CAM01';
    this.ai.chica.doorTimer = 0;

    this.ai.foxy.level = lv.foxy;
    this.ai.foxy.charge = 10;
    this.ai.foxy.sprinting = false;
    this.ai.foxy.sprintTimer = 0;

    this.ai.freddy.level = lv.freddy;
    this.ai.freddy.pos = 'CAM01';
    this.ai.freddy.doorTimer = 0;

    this.codeLines = [
      `// === ЗАПУСК ${cfg.name} ===`,
      '// Цель: Дожить до 06:00 AM и скомпилировать патч на 100%!'
    ];

    window.soundEngine.playSwitch(true);
    this.addEventLog(`Смена #${shiftNum} началась! Удачи, дежурный.`, 'info');

    // Show Phone Guy message banner
    const phoneEl = document.getElementById('phone-guy-banner');
    const phoneText = document.getElementById('phone-guy-text');
    if (phoneEl && phoneText) {
      phoneText.textContent = cfg.phoneGuyMsg;
      phoneEl.classList.remove('hidden');
    }

    document.getElementById('menu-modal').classList.add('hidden');
    document.getElementById('gameover-modal').classList.add('hidden');
    document.getElementById('victory-modal').classList.add('hidden');

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
    if (this.power <= 0) return 0;
    let bars = 1; // Base desk + IDE
    if (this.switches.gateLeft) bars += 1;
    if (this.switches.gateCenter) bars += 1;
    if (this.switches.gateRight) bars += 1;
    if (this.switches.seatCooler) bars += 1;
    if (this.switches.overclock) bars += 1;
    if (this.cctvOpen) bars += 1;
    return Math.min(6, bars);
  }

  update(dt) {
    const cfg = SHIFT_CONFIGS[this.shift] || SHIFT_CONFIGS[1];

    // 1. Shift Clock & Overtime Check
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
          this.addEventLog('🚨 06:00 AM! ПАТЧ НЕ ДОПИЛЕН! АВАРИЙНЫЙ ОВЕРТАЙМ 22 СЕК!', 'danger');
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
          'ДЕДЛАЙН ПРОСРАН НА СТЕНДАПЕ!',
          'В 06:00 утра продакшен лёг без патча. Тимлид и ИИ испепелили твоё кресло!'
        );
        return;
      }
    }

    // 2. UPS Power Drain
    if (this.crankCooldown > 0) {
      this.crankCooldown = Math.max(0, this.crankCooldown - dt);
    }

    if (this.power > 0) {
      const bars = this.getUsageBars();
      const drainPerSec = cfg.basePowerDrain * (1 + (bars - 1) * 0.95);
      this.power = Math.max(0, this.power - drainPerSec * dt);

      if (this.power <= 0) {
        // BLACKOUT! All power switches drop!
        this.switches.gateLeft = false;
        this.switches.gateCenter = false;
        this.switches.gateRight = false;
        this.switches.seatCooler = false;
        this.switches.overclock = false;
        this.cctvOpen = false;
        window.soundEngine.playGateSlam(false);
        this.addEventLog('⚡ БЛЭКАУТ ИБП! Все фаерволы и охлаждение отключены! Срочно крути Дизель!', 'danger');
      }
    }

    // 3. Pukan Temperature Physics (Пуканометр)
    let heatRate = 0.65; // Passive baseline stress
    if (this.switches.overclock) heatRate += 2.2;
    if (this.dipPuzzleActive) heatRate += 1.5;
    if (this.dnsAlertActive) heatRate += 1.6;
    if (this.ai.chica.pos === 'CAM04') heatRate += 0.9; // Chica injecting garbage into DB
    if (this.inOvertime) heatRate += 3.2;
    heatRate += this.hackCount * 0.85; // Each active breach heats your chair faster!

    if (this.switches.seatCooler && this.power > 0) {
      heatRate -= 4.6; // Liquid Nitrogen Bidet Cooler cools it down!
    }

    this.pukanTemp = Math.max(0, Math.min(100, this.pukanTemp + heatRate * dt));

    if (this.pukanTemp >= 100) {
      this.triggerJumpscare(
        'pukan',
        'ТЕРМОЯДЕРНОЕ ИЗВЕРЖЕНИЕ ПУКАНА!',
        'Температура кресла достигла 100°C! Твой пукан детонировал мощнее сверхновой и уничтожил дата-центр!'
      );
      return;
    }

    // 4. Kernel Dip-Switch Mutation Timer
    if (!this.dipPuzzleActive) {
      this.nextDipCountdown -= dt;
      if (this.nextDipCountdown <= 0) {
        this.spawnDipPuzzle(cfg);
      }
    } else {
      this.dipTimer -= dt;
      if (this.dipTimer <= 0) {
        // Failed to match dip switches in time -> +1 HACK BREACH!
        this.dipPuzzleActive = false;
        this.nextDipCountdown = cfg.dipInterval * 0.75;
        this.incrementHack('Вирус ядра изменил флаги SW1-SW4! Защита пробита!');
        if (this.gameOver) return;
      }
    }

    // 5. Secondary DNS/Registry Alert (Shifts 2+)
    if (this.shift >= 2 && !this.dnsAlertActive && Math.random() < dt * 0.032) {
      this.dnsAlertActive = true;
      this.dnsAlertTimer = 11.0;
      window.soundEngine.playAlertBeep(true);
      this.addEventLog('⚠️ УТЕЧКА ПАМЯТИ В ПРОДЕ! Нажми «СБРОСИТЬ КЭШ DNS» за 11 сек!', 'warn');
    }
    if (this.dnsAlertActive) {
      this.dnsAlertTimer -= dt;
      if (this.dnsAlertTimer <= 0) {
        this.dnsAlertActive = false;
        this.patchProgress = Math.max(0, this.patchProgress - 8);
        this.pukanTemp = Math.min(100, this.pukanTemp + 14);
        this.incrementHack('Переполнение кучи DNS! Откат патча на -8%!');
        if (this.gameOver) return;
      }
    }

    // 6. Update Rogue AI Entities
    this.updateAI(dt);
  }

  spawnDipPuzzle(cfg) {
    // Generate a 4-bit target different from current dip switches
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
    window.soundEngine.playAlertBeep(false);
    this.addEventLog(`🔧 МУТАЦИЯ РЕЕСТРА! Выстави тумблеры SW1-4 в [${nextTarget.join(' ')}]!`, 'warn');
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

  updateAI(dt) {
    // --- A. BONNIE-BRUTEFORCER (Left Lane: CAM01 -> CAM02 -> DOOR_LEFT) ---
    const bonnie = this.ai.bonnie;
    if (bonnie.level > 0) {
      if (bonnie.pos === 'DOOR_LEFT') {
        bonnie.doorTimer += dt;
        const patience = Math.max(3.4, 7.5 - bonnie.level * 0.18);
        if (bonnie.doorTimer >= patience) {
          if (this.switches.gateLeft && this.power > 0) {
            // Blocked! Retreats to CAM01
            bonnie.pos = 'CAM01';
            bonnie.doorTimer = 0;
            window.soundEngine.playBlockedThud();
            this.addEventLog('🛡️ Бонни-Брутфорсер отбит левым фаерволом (Порт 22)!', 'ok');
          } else {
            // Breached Left Door!
            this.triggerJumpscare(
              'ai',
              'БОННИ-БРУТФОРСЕР ВЗЛОМАЛ ПОРТ 22 (SSH)!',
              'Ты не закрыл Левый Фаервол [Q]! ИИ-бот зашёл по root-доступу и отформатировал тебе лицо!'
            );
            return;
          }
        }
      } else {
        bonnie.moveCooldown -= dt;
        if (bonnie.moveCooldown <= 0) {
          bonnie.moveCooldown = 4.2;
          if (Math.random() * 20 < bonnie.level) {
            if (bonnie.pos === 'CAM01') {
              bonnie.pos = 'CAM02';
            } else if (bonnie.pos === 'CAM02') {
              bonnie.pos = 'DOOR_LEFT';
              bonnie.doorTimer = 0;
              window.soundEngine.playSwitch(false);
            }
          }
        }
      }
    }

    // --- B. CHICA-SQL-INJECTOR (Right Lane: CAM01 -> CAM04 -> DOOR_RIGHT) ---
    const chica = this.ai.chica;
    if (chica.level > 0) {
      if (chica.pos === 'DOOR_RIGHT') {
        chica.doorTimer += dt;
        const patience = Math.max(3.5, 7.8 - chica.level * 0.18);
        if (chica.doorTimer >= patience) {
          if (this.switches.gateRight && this.power > 0) {
            chica.pos = 'CAM01';
            chica.doorTimer = 0;
            window.soundEngine.playBlockedThud();
            this.addEventLog('🛡️ Чика-Инъекторша отбита правым фаерволом (Порт 5432)!', 'ok');
          } else {
            this.triggerJumpscare(
              'ai',
              'ЧИКА-GPT ВЫПОЛНИЛА DROP TABLE НА ТВОЁМ МОЗГЕ!',
              'Правый шлюз БД [E] был открыт! SQL-инъекция уничтожила продакшен и дежурного!'
            );
            return;
          }
        }
      } else {
        chica.moveCooldown -= dt;
        if (chica.moveCooldown <= 0) {
          chica.moveCooldown = 4.5;
          if (Math.random() * 20 < chica.level) {
            if (chica.pos === 'CAM01') {
              chica.pos = 'CAM04';
            } else if (chica.pos === 'CAM04') {
              chica.pos = 'DOOR_RIGHT';
              chica.doorTimer = 0;
              window.soundEngine.playSwitch(false);
            }
          }
        }
      }
    }

    // --- C. FOXY-CRYPTOLOCKER (CAM05 Charge -> Sprints down CAM06 to Center Gate!) ---
    const foxy = this.ai.foxy;
    if (foxy.level > 0) {
      if (!foxy.sprinting) {
        // Watching CAM05 slows Foxy down significantly!
        const watchingCam05 = this.cctvOpen && this.currentCam === 'CAM05';
        const chargeSpeed = (0.75 + foxy.level * 0.22) * (watchingCam05 ? 0.25 : 1.0);
        foxy.charge = Math.min(100, foxy.charge + chargeSpeed * dt);

        if (foxy.charge >= 100) {
          foxy.sprinting = true;
          foxy.sprintTimer = Math.max(3.2, 4.8 - foxy.level * 0.07);
          window.soundEngine.playSprintSiren();
          this.addEventLog('🏃💨 ФОКСИ-ЛОКЕР НЕСЁТСЯ ПО КАБЕЛЬ-КАНАЛУ! ЗАКРОЙ РУБИЛЬНИК ЦОД [W]!', 'danger');
        }
      } else {
        foxy.sprintTimer -= dt;
        if (foxy.sprintTimer <= 0) {
          foxy.sprinting = false;
          foxy.charge = 15;
          if (this.switches.gateCenter && this.power > 0) {
            // Blocked at center shutter! Costs a small bit of UPS power like FNaF 1 Foxy bang
            const powerHit = Math.min(9, 4 + this.shift);
            this.power = Math.max(0, this.power - powerHit);
            window.soundEngine.playBlockedThud();
            this.addEventLog(`🛡️ Фокси-Криптолокер врезался в закрытый Рубильник ЦОД (-${powerHit}% ИБП)!`, 'ok');
          } else {
            this.triggerJumpscare(
              'ai',
              'ФОКСИ-КРИПТОЛОКЕР ЗАШИФРОВАЛ ТВОЮ ДУШУ!',
              'Ты не успел врубить центральный Рубильник ЦОД [W], когда Фокси ворвался по кабель-каналу!'
            );
            return;
          }
        }
      }
    }

    // --- D. SKYNET-FREDDY (Center Stealth: CAM01 -> CAM03 -> CAM06 -> DOOR_CENTER) ---
    const freddy = this.ai.freddy;
    if (freddy.level > 0) {
      if (freddy.pos === 'DOOR_CENTER') {
        freddy.doorTimer += dt;
        const patience = Math.max(3.2, 6.8 - freddy.level * 0.16);
        if (freddy.doorTimer >= patience) {
          if (this.switches.gateCenter && this.power > 0) {
            freddy.pos = 'CAM01';
            freddy.doorTimer = 0;
            window.soundEngine.playBlockedThud();
            this.addEventLog('🛡️ Скайнет-Фредди остановлен центральным Рубильником ЦОД!', 'ok');
          } else {
            this.triggerJumpscare(
              'ai',
              'СКАЙНЕТ-ФРЕДДИ (GPT-666) ЗАХВАТИЛ ЯДЕРНЫЙ ЧЕМОДАНЧИК!',
              'Главный ИИ прошёл через центральный шлюз [W] и устроил Судный День на проде!'
            );
            return;
          }
        }
      } else {
        const watched = this.cctvOpen && this.currentCam === freddy.pos;
        freddy.moveCooldown -= dt * (watched ? 0.25 : 1.0);
        if (freddy.moveCooldown <= 0) {
          freddy.moveCooldown = 5.0;
          if (Math.random() * 20 < freddy.level) {
            if (freddy.pos === 'CAM01') freddy.pos = 'CAM03';
            else if (freddy.pos === 'CAM03') freddy.pos = 'CAM06';
            else if (freddy.pos === 'CAM06') {
              freddy.pos = 'DOOR_CENTER';
              freddy.doorTimer = 0;
              window.soundEngine.playAlertBeep(true);
              this.addEventLog('👁️ СКАЙНЕТ-ФРЕДДИ ПРЯМО ПЕРЕД РУБИЛЬНИКОМ ЦОД [W]!', 'danger');
            }
          }
        }
      }
    }
  }

  incrementHack(reason) {
    this.hackCount += 1;
    this.pukanTemp = Math.min(100, this.pukanTemp + 16);
    window.soundEngine.playBreachGlitch();
    this.addEventLog(`💀 ПРОБОЙ ЗАЩИТЫ (${this.hackCount}/${this.maxHacks}): ${reason}`, 'danger');

    if (this.hackCount >= this.maxHacks) {
      this.triggerJumpscare(
        'ai',
        'КРИТИЧЕСКАЯ МАССА ВЗЛОМОВ (5/5) — ТОТАЛЬНЫЙ СКРИМЕР ИИ!',
        'Ты допустил 5 взломов системы! Рой взбесившихся нейросетей захватил все мониторы и уничтожил мир!'
      );
    }
  }

  // Player Actions
  toggleSwitch(key) {
    if (!this.running || this.gameOver) return;
    if (this.power <= 0) {
      window.soundEngine.playAlertBeep(true);
      this.addEventLog('⚡ ИБП разряжен (0%)! Тумблеры обесточены! Крути Дизель-генератор!', 'danger');
      return;
    }

    this.switches[key] = !this.switches[key];
    if (key.startsWith('gate')) {
      window.soundEngine.playGateSlam(this.switches[key]);
    } else {
      window.soundEngine.playSwitch(this.switches[key]);
    }
    this.renderUI();
  }

  toggleDip(index) {
    if (!this.running || this.gameOver) return;
    this.switches.dip[index] = this.switches.dip[index] === 1 ? 0 : 1;
    window.soundEngine.playSwitch(this.switches.dip[index] === 1);
    this.checkDipMatch();
    this.renderUI();
  }

  pingPort(side) {
    if (!this.running || this.gameOver || this.power <= 0) return;
    this.power = Math.max(0, this.power - 0.35);

    if (side === 'left') {
      this.pingLeftActive = true;
      const danger = this.ai.bonnie.pos === 'DOOR_LEFT';
      window.soundEngine.playPing(danger);
      if (danger) {
        this.addEventLog('🚨 ПИНГ ПОРТА 22: БОННИ-БРУТФОРСЕР ПРЯМО У ЛЕВОГО ШЛЮЗА! ЗАКРЫВАЙ [Q]!', 'danger');
      }
      setTimeout(() => {
        this.pingLeftActive = false;
        this.renderUI();
      }, 650);
    } else {
      this.pingRightActive = true;
      const danger = this.ai.chica.pos === 'DOOR_RIGHT';
      window.soundEngine.playPing(danger);
      if (danger) {
        this.addEventLog('🚨 ПИНГ ПОРТА 5432: ЧИКА-ИНЪЕКТОРША У ПРАВОГО ШЛЮЗА! ЗАКРЫВАЙ [E]!', 'danger');
      }
      setTimeout(() => {
        this.pingRightActive = false;
        this.renderUI();
      }, 650);
    }
    this.renderUI();
  }

  writePatchChunk() {
    if (!this.running || this.gameOver) return;
    const cfg = SHIFT_CONFIGS[this.shift] || SHIFT_CONFIGS[1];

    // If CCTV is open, automatically close it so engineer looks at IDE
    if (this.cctvOpen) {
      this.cctvOpen = false;
    }

    let gain = cfg.patchSpeed;
    if (this.switches.overclock && this.power > 0) gain *= 1.85;
    if (this.dipPuzzleActive) gain *= 0.45; // Unresolved registry mutation slows compile

    this.patchProgress = Math.min(100, this.patchProgress + gain);
    this.pukanTemp = Math.min(100, this.pukanTemp + 0.35);
    window.soundEngine.playKeyClick();

    // Add hilarious code line
    const snippet = CODE_SNIPPETS[Math.floor(Math.random() * CODE_SNIPPETS.length)];
    this.codeLines.push(`[${Math.floor(this.patchProgress)}%] > ${snippet}`);
    if (this.codeLines.length > 7) this.codeLines.shift();

    this.renderUI();
  }

  ventSteam() {
    if (!this.running || this.gameOver) return;
    this.pukanTemp = Math.max(0, this.pukanTemp - 9.5);
    window.soundEngine.playSteamVent();
    this.addEventLog('💨 ПШШШ! Клапан сброса давления открыт (-9.5°C пукана).', 'info');
    this.renderUI();
  }

  flushDnsAlert() {
    if (!this.running || this.gameOver) return;
    if (this.dnsAlertActive) {
      this.dnsAlertActive = false;
      this.pukanTemp = Math.max(0, this.pukanTemp - 5);
      window.soundEngine.playPing(false);
      this.addEventLog('✅ Кэш DNS очищен! Утечка памяти устранена.', 'ok');
      this.renderUI();
    } else {
      window.soundEngine.playSwitch(false);
    }
  }

  killFoxyProcess() {
    if (!this.running || this.gameOver || this.power <= 0) return;
    if (this.ai.foxy.sprinting) {
      this.addEventLog('⚠️ Поздно! Фокси уже бежит по трубе! Закрывай Рубильник ЦОД [W]!', 'danger');
      return;
    }
    this.power = Math.max(0, this.power - 1.2);
    this.ai.foxy.charge = Math.max(0, this.ai.foxy.charge - 38);
    window.soundEngine.playPing(false);
    this.addEventLog('🔪 Отправлен пакет kill -9 на CAM-05! Заряд DDoS Фокси сброшен (-38%).', 'ok');
    this.renderUI();
  }

  crankGenerator() {
    if (!this.running || this.gameOver || this.crankCooldown > 0) return;
    this.crankCooldown = 7.0;
    this.power = Math.min(100, this.power + 14);
    this.pukanTemp = Math.min(100, this.pukanTemp + 8); // Physical effort heats up the engineer!
    window.soundEngine.playGateSlam(true);
    this.addEventLog('⛽ Дизель-генератор дёрнут (+14% ИБП, +8°C пукана от натуги)!', 'warn');
    this.renderUI();
  }

  toggleCCTV() {
    if (!this.running || this.gameOver) return;
    if (this.power <= 0) {
      this.cctvOpen = false;
      return;
    }
    this.cctvOpen = !this.cctvOpen;
    window.soundEngine.playSwitch(this.cctvOpen);
    this.renderUI();
  }

  selectCam(camId) {
    if (!this.running || this.gameOver) return;
    this.currentCam = camId;
    this.cctvOpen = true;
    window.soundEngine.playSwitch(true);
    this.renderUI();
  }

  triggerJumpscare(type, title, desc) {
    this.running = false;
    this.gameOver = true;
    if (this.loopId) cancelAnimationFrame(this.loopId);

    // Fire razor-sharp WebAudio screamer!
    window.soundEngine.playJumpscare(type);

    const modal = document.getElementById('gameover-modal');
    const titleEl = document.getElementById('jumpscare-title');
    const descEl = document.getElementById('jumpscare-desc');
    const artEl = document.getElementById('jumpscare-art');

    titleEl.textContent = title;
    descEl.textContent = desc;
    artEl.innerHTML = this.getJumpscareSVG(type);

    modal.classList.remove('hidden');
    modal.classList.add('jumpscare-active');

    setTimeout(() => {
      modal.classList.remove('jumpscare-active');
    }, 1500);
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
    const vTitle = document.getElementById('victory-shift-label');
    vTitle.textContent = `СМЕНА #${this.shift} УСПЕШНО ЗАКРЫТА! ПРОД ВЫЖИЛ ДО 06:00 AM!`;
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
        ? 'text-emerald-400'
        : 'text-cyan-300';
    item.className = `text-xs ${colorClass} truncate`;
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

  getJumpscareSVG(type) {
    if (type === 'pukan') {
      return `
        <svg viewBox="0 0 320 220" class="w-72 h-52 mx-auto drop-shadow-[0_0_30px_rgba(255,80,0,1)]">
          <circle cx="160" cy="115" r="95" fill="#7f1d1d" stroke="#f97316" stroke-width="6"/>
          <polygon points="160,8 190,65 255,25 220,85 305,95 230,135 280,195 190,165 160,218 130,165 40,195 90,135 15,95 100,85 65,25 130,65" fill="#ef4444" stroke="#fde047" stroke-width="4"/>
          <circle cx="120" cy="95" r="24" fill="#000"/>
          <circle cx="200" cy="95" r="24" fill="#000"/>
          <circle cx="120" cy="95" r="10" fill="#fef08a"/>
          <circle cx="200" cy="95" r="10" fill="#fef08a"/>
          <path d="M95,65 L145,82 M225,65 L175,82" stroke="#fde047" stroke-width="7" stroke-linecap="round"/>
          <rect x="105" y="135" width="110" height="46" rx="8" fill="#000" stroke="#fde047" stroke-width="4"/>
          <path d="M120,135 L120,181 M145,135 L145,181 M175,135 L175,181 M200,135 L200,181" stroke="#fff" stroke-width="5"/>
          <text x="160" y="208" text-anchor="middle" fill="#fef08a" font-size="18" font-weight="bold">🔥 ПУКАН РВАНУЛ НА 100°C 🔥</text>
        </svg>
      `;
    }
    return `
      <svg viewBox="0 0 320 220" class="w-72 h-52 mx-auto drop-shadow-[0_0_30px_rgba(239,68,68,1)]">
        <rect x="45" y="15" width="230" height="190" rx="22" fill="#090d16" stroke="#ef4444" stroke-width="6"/>
        <circle cx="115" cy="88" r="32" fill="#000" stroke="#dc2626" stroke-width="4"/>
        <circle cx="205" cy="88" r="32" fill="#000" stroke="#dc2626" stroke-width="4"/>
        <circle cx="115" cy="88" r="13" fill="#ff0000"/>
        <circle cx="205" cy="88" r="13" fill="#ff0000"/>
        <circle cx="115" cy="88" r="4" fill="#ffffff"/>
        <circle cx="205" cy="88" r="4" fill="#ffffff"/>
        <path d="M80,48 L145,68 M240,48 L175,68" stroke="#ef4444" stroke-width="7"/>
        <polygon points="160,102 146,126 174,126" fill="#ef4444"/>
        <rect x="75" y="138" width="170" height="50" rx="6" fill="#000" stroke="#ef4444" stroke-width="4"/>
        <polyline points="80,162 98,142 115,184 135,142 155,184 175,142 195,184 215,142 238,162" fill="none" stroke="#f87171" stroke-width="5"/>
        <text x="160" y="36" text-anchor="middle" fill="#22d3ee" font-size="14" font-weight="bold">ROOT@SKUFNET-666:~# RM -RF /</text>
      </svg>
    `;
  }

  renderUI() {
    // Clock & Shift
    document.getElementById('hud-clock').textContent = this.inOvertime
      ? `ОВЕРТАЙМ: ${this.overtimeSeconds.toFixed(1)}c`
      : this.getFormattedClock();
    document.getElementById('hud-shift').textContent = `СМЕНА #${this.shift}`;

    // UPS Power & Usage Bars
    const pwrEl = document.getElementById('hud-power');
    pwrEl.textContent = `${Math.ceil(this.power)}%`;
    pwrEl.className = `text-xl font-extrabold ${
      this.power > 45 ? 'text-emerald-400' : this.power > 20 ? 'text-amber-400' : 'text-red-500 animate-pulse'
    }`;

    const bars = this.getUsageBars();
    const barsContainer = document.getElementById('hud-usage-bars');
    if (barsContainer) {
      barsContainer.innerHTML = '';
      for (let i = 1; i <= 5; i++) {
        const div = document.createElement('div');
        const active = i <= bars;
        const color = i <= 2 ? 'bg-emerald-400' : i <= 3 ? 'bg-amber-400' : 'bg-red-500';
        div.className = `w-3 h-4 rounded-sm ${active ? color : 'bg-slate-800'}`;
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

    // Hack Counter (0/5)
    document.getElementById('hud-hacks-val').textContent = `${this.hackCount} / ${this.maxHacks}`;
    const hackPips = document.getElementById('hud-hack-pips');
    if (hackPips) {
      hackPips.innerHTML = '';
      for (let i = 1; i <= this.maxHacks; i++) {
        const pip = document.createElement('div');
        pip.className = `w-4 h-4 rounded-full border ${
          i <= this.hackCount
            ? 'bg-red-500 border-red-300 shadow-[0_0_8px_rgba(239,68,68,0.9)] animate-pulse'
            : 'bg-slate-900 border-slate-700'
        }`;
        hackPips.appendChild(pip);
      }
    }

    // Update Physical Switches visuals
    this._updateSwitchDOM('sw-gate-left', this.switches.gateLeft, 'on-danger');
    this._updateSwitchDOM('sw-gate-center', this.switches.gateCenter, 'on-danger');
    this._updateSwitchDOM('sw-gate-right', this.switches.gateRight, 'on-danger');
    this._updateSwitchDOM('sw-cooler', this.switches.seatCooler, 'on');
    this._updateSwitchDOM('sw-overclock', this.switches.overclock, 'on-danger');

    // Door Threat Indicators (when Pinged or when AI is banging)
    const leftDanger = this.pingLeftActive && this.ai.bonnie.pos === 'DOOR_LEFT';
    const rightDanger = this.pingRightActive && this.ai.chica.pos === 'DOOR_RIGHT';
    const centerDanger = this.ai.foxy.sprinting || this.ai.freddy.pos === 'DOOR_CENTER';

    const leftLed = document.getElementById('led-left-door');
    const centerLed = document.getElementById('led-center-door');
    const rightLed = document.getElementById('led-right-door');

    if (leftLed) {
      leftLed.className = `w-3.5 h-3.5 rounded-full ${
        leftDanger
          ? 'bg-red-500 shadow-[0_0_12px_#ef4444] animate-ping'
          : this.switches.gateLeft
          ? 'bg-emerald-400'
          : 'bg-slate-700'
      }`;
    }
    if (centerLed) {
      centerLed.className = `w-3.5 h-3.5 rounded-full ${
        centerDanger
          ? 'bg-red-500 shadow-[0_0_12px_#ef4444] animate-ping'
          : this.switches.gateCenter
          ? 'bg-emerald-400'
          : 'bg-slate-700'
      }`;
    }
    if (rightLed) {
      rightLed.className = `w-3.5 h-3.5 rounded-full ${
        rightDanger
          ? 'bg-red-500 shadow-[0_0_12px_#ef4444] animate-ping'
          : this.switches.gateRight
          ? 'bg-emerald-400'
          : 'bg-slate-700'
      }`;
    }

    // Kernel Dip-Switches SW1-SW4
    for (let i = 0; i < 4; i++) {
      this._updateSwitchDOM(`sw-dip-${i}`, this.switches.dip[i] === 1, 'on');
      const valSpan = document.getElementById(`dip-val-${i}`);
      if (valSpan) valSpan.textContent = this.switches.dip[i];
    }

    const dipStatus = document.getElementById('dip-puzzle-box');
    const dipTargetText = document.getElementById('dip-target-bits');
    const dipTimerText = document.getElementById('dip-timer-text');
    if (this.dipPuzzleActive) {
      dipStatus.className = 'p-2.5 rounded-lg border-2 border-red-500 bg-red-950/40 animate-pulse';
      dipTargetText.textContent = `ЦЕЛЬ: [ ${this.targetDip.join('  ')} ]`;
      dipTimerText.textContent = `ВЗЛОМ ЧЕРЕЗ: ${this.dipTimer.toFixed(1)}с`;
    } else {
      dipStatus.className = 'p-2.5 rounded-lg border border-slate-700 bg-slate-900/70';
      dipTargetText.textContent = `ЯДРО В НОРМЕ: [ ${this.switches.dip.join('  ')} ]`;
      dipTimerText.textContent = 'Стабильно';
    }

    // DNS Alert Button
    const dnsBtn = document.getElementById('btn-dns-flush');
    if (dnsBtn) {
      if (this.dnsAlertActive) {
        dnsBtn.className =
          'w-full py-2 px-3 rounded-lg font-bold text-xs bg-red-600 hover:bg-red-500 text-white border-2 border-yellow-300 animate-bounce';
        dnsBtn.textContent = `🚨 СБРОСИТЬ КЭШ DNS (${this.dnsAlertTimer.toFixed(1)}с)!`;
      } else {
        dnsBtn.className =
          'w-full py-2 px-3 rounded-lg font-bold text-xs bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-600';
        dnsBtn.textContent = '🧹 КЭШ DNS В НОРМЕ';
      }
    }

    // Diesel Generator Button
    const crankBtn = document.getElementById('btn-crank-gen');
    if (crankBtn) {
      if (this.crankCooldown > 0) {
        crankBtn.textContent = `⛽ ПЕРЕЗАРЯДКА (${this.crankCooldown.toFixed(0)}с)`;
        crankBtn.disabled = true;
        crankBtn.className = 'py-2 px-3 rounded-lg font-bold text-xs bg-slate-900 text-slate-500 border border-slate-800 cursor-not-allowed';
      } else {
        crankBtn.textContent = '⛽ ДЁРНУТЬ ДИЗЕЛЬ (+14% ИБП)';
        crankBtn.disabled = false;
        crankBtn.className = 'py-2 px-3 rounded-lg font-bold text-xs bg-amber-600 hover:bg-amber-500 text-slate-950 border border-amber-300 cursor-pointer';
      }
    }

    // Center View: IDE Terminal vs CCTV Server Monitor
    const ideView = document.getElementById('view-ide');
    const cctvView = document.getElementById('view-cctv');
    const toggleViewBtn = document.getElementById('btn-toggle-cctv');

    if (this.cctvOpen) {
      ideView.classList.add('hidden');
      cctvView.classList.remove('hidden');
      toggleViewBtn.textContent = '💻 ВЕРНУТЬСЯ В IDE (ПИЛИТЬ ПАТЧ) [TAB]';
      toggleViewBtn.className = 'px-4 py-2 rounded-lg font-bold text-xs bg-emerald-600 hover:bg-emerald-500 text-white border border-emerald-300';
      this.renderCCTVFeed();
    } else {
      cctvView.classList.add('hidden');
      ideView.classList.remove('hidden');
      toggleViewBtn.textContent = '📹 КАМЕРЫ СЕРВЕРНОЙ (CCTV) [TAB]';
      toggleViewBtn.className = 'px-4 py-2 rounded-lg font-bold text-xs bg-cyan-600 hover:bg-cyan-500 text-white border border-cyan-300';

      // Render code lines
      const codeBox = document.getElementById('ide-code-lines');
      if (codeBox) {
        codeBox.innerHTML = this.codeLines
          .map((l) => `<div class="text-emerald-400 font-mono text-xs">${l}</div>`)
          .join('');
      }
    }

    // Foxy Quick Status Bar on HUD
    const foxyChargePct = Math.round(this.ai.foxy.charge);
    const foxyHud = document.getElementById('hud-foxy-status');
    if (foxyHud) {
      if (this.ai.foxy.sprinting) {
        foxyHud.textContent = `🏃💨 БЕЖИТ К ЦОД (${this.ai.foxy.sprintTimer.toFixed(1)}с)!`;
        foxyHud.className = 'text-xs font-bold text-red-400 animate-pulse';
      } else {
        foxyHud.textContent = `DDoS Фокси: ${foxyChargePct}%`;
        foxyHud.className = `text-xs font-bold ${foxyChargePct > 75 ? 'text-red-400' : 'text-amber-300'}`;
      }
    }
  }

  renderCCTVFeed() {
    const camInfo = CAM_NODES[this.currentCam];
    document.getElementById('cctv-cam-title').textContent = camInfo.name;
    document.getElementById('cctv-cam-desc').textContent = camInfo.desc;

    // Highlight active camera button
    Object.keys(CAM_NODES).forEach((id) => {
      const btn = document.getElementById(`btn-${id}`);
      if (btn) {
        btn.className =
          id === this.currentCam
            ? 'px-2.5 py-2 rounded font-bold text-xs bg-cyan-600 text-white border-2 border-cyan-300 shadow-[0_0_10px_rgba(6,182,212,0.5)]'
            : 'px-2.5 py-2 rounded font-bold text-xs bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-600';
      }
    });

    // Check which AI entities are present on currentCam
    const occupants = [];
    if (this.ai.bonnie.pos === this.currentCam && this.ai.bonnie.level > 0) {
      occupants.push({
        icon: '🐰💀',
        name: 'БОННИ-БРУТФОРСЕР (SSH)',
        status: 'Сканирует ключи авторизации... Скоро пойдёт к Порту 22!',
        color: 'border-indigo-400 bg-indigo-950/60 text-indigo-200'
      });
    }
    if (this.ai.chica.pos === this.currentCam && this.ai.chica.level > 0) {
      occupants.push({
        icon: '🐤💉',
        name: 'ЧИКА-ИНЪЕКТОРША (SQL)',
        status: 'Готовит пакет DROP DATABASE... Движется к Порту 5432!',
        color: 'border-amber-400 bg-amber-950/60 text-amber-200'
      });
    }
    if (this.ai.freddy.pos === this.currentCam && this.ai.freddy.level > 0) {
      occupants.push({
        icon: '🐻🤖',
        name: 'СКАЙНЕТ-ФРЕДДИ (GPT-666)',
        status: 'Наблюдение камерой замедляет его продвижение к ЦОД!',
        color: 'border-red-500 bg-red-950/70 text-red-200'
      });
    }
    if (this.currentCam === 'CAM05') {
      const charge = Math.round(this.ai.foxy.charge);
      occupants.push({
        icon: '🦊🏴‍☠️',
        name: `ФОКСИ-КРИПТОЛОКЕР (Заряд эксплойта: ${charge}%)`,
        status: this.ai.foxy.sprinting
          ? '🚨 УЖЕ ВЫБЕЖАЛ В КАБЕЛЬ-КАНАЛ CAM-06! ЗАКРЫВАЙ РУБИЛЬНИК ЦОД [W]!'
          : 'Нажми кнопку «KILL -9 ФОКСИ» ниже, чтобы сбросить его DDoS-таймер!',
        color: 'border-orange-500 bg-orange-950/60 text-orange-200'
      });
    }
    if (this.currentCam === 'CAM06' && this.ai.foxy.sprinting) {
      occupants.push({
        icon: '🦊⚡',
        name: 'ФОКСИ НЕСЁТСЯ ПО КАБЕЛЬ-КАНАЛУ!',
        status: `До удара по центральному шлюзу: ${this.ai.foxy.sprintTimer.toFixed(1)} сек!`,
        color: 'border-red-500 bg-red-900/80 text-white animate-pulse'
      });
    }

    const feedBox = document.getElementById('cctv-entities-box');
    if (occupants.length === 0) {
      feedBox.innerHTML = `
        <div class="text-center py-6 text-slate-400 text-xs">
          <div class="text-2xl mb-1">🟢 ЧИСТО</div>
          На узле ${this.currentCam} аномальной ИИ-активности не обнаружено.
        </div>
      `;
    } else {
      feedBox.innerHTML = occupants
        .map(
          (o) => `
          <div class="p-2.5 rounded-lg border ${o.color} flex items-center gap-3 mb-2">
            <div class="text-2xl">${o.icon}</div>
            <div>
              <div class="font-bold text-xs">${o.name}</div>
              <div class="text-xs opacity-90">${o.status}</div>
            </div>
          </div>
        `
        )
        .join('');
    }
  }

  _updateSwitchDOM(id, isOn, activeClass = 'on') {
    const el = document.getElementById(id);
    if (!el) return;
    el.classList.remove('on', 'on-danger', 'off', 'active-green', 'active-red');
    if (isOn) {
      el.classList.add(activeClass);
      el.classList.add(activeClass === 'on-danger' ? 'active-red' : 'active-green');
    } else {
      el.classList.add('off');
    }
  }
}

window.prodGame = new ProdGame();

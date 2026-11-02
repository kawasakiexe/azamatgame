// ============================================================================
// ПЯТЬ НОЧЕЙ НА ПРОДЕ — 3D WebGL Engine & FNaF Office Experience
// High-performance Three.js procedural 3D world with interactive raycasting,
// smooth camera panning, CCTV security cameras, 3D animatronics & jumpscares.
// ============================================================================

class View3D {
  constructor() {
    this.container = null;
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.clock = new THREE.Clock();

    // Mouse / Camera Pan controls (FNaF-style head rotation)
    this.mouseX = 0.5; // 0 (left) to 1 (right)
    this.mouseY = 0.5;
    this.targetYaw = 0;
    this.currentYaw = 0;
    this.targetPitch = 0;
    this.currentPitch = 0;
    this.isPanning = true;

    // Interactive Raycaster
    this.raycaster = new THREE.Raycaster();
    this.mouseVec = new THREE.Vector2();
    this.interactables = [];
    this.hoveredObject = null;

    // 3D Scene Components
    this.officeGroup = null;
    this.leftDoorMesh = null;
    this.rightDoorMesh = null;
    this.centerDoorMesh = null;
    this.fanBlades = null;
    this.crtScreenMesh = null;
    this.crtCanvas = null;
    this.crtTexture = null;
    this.pukanDialNeedle = null;
    this.steamParticles = null;

    // DIP Switches (3D levers)
    this.dipLevers = [];
    this.dipLeds = [];

    // Lighting
    this.officeLight = null;
    this.leftSpotlight = null;
    this.rightSpotlight = null;
    this.alarmStrobe = null;
    this.leftHallLight = null;
    this.rightHallLight = null;

    // 3D Animatronic Entity Models
    this.entities = {
      bonnie: null,
      chica: null,
      foxy: null,
      freddy: null
    };

    // CCTV Security Camera Positions
    this.camPositions = {
      CAM01: { pos: new THREE.Vector3(0, 3.8, -14.5), lookAt: new THREE.Vector3(0, 1.5, -24) },   // Gateway
      CAM02: { pos: new THREE.Vector3(-7.5, 3.5, -4.5), lookAt: new THREE.Vector3(-7.5, 1.2, 0) }, // Left SSH
      CAM03: { pos: new THREE.Vector3(0, 4.0, -8.0), lookAt: new THREE.Vector3(0, 1.2, -14) },    // Center Hub
      CAM04: { pos: new THREE.Vector3(7.5, 3.5, -4.5), lookAt: new THREE.Vector3(7.5, 1.2, 0) },  // Right SQL
      CAM05: { pos: new THREE.Vector3(0, 3.2, -18.5), lookAt: new THREE.Vector3(0, 1.5, -23) },   // Pirate Cove
      CAM06: { pos: new THREE.Vector3(0, 2.8, -4.5), lookAt: new THREE.Vector3(0, 1.5, 0) }       // Approach Vent
    };

    // Jumpscare Animation State
    this.jumpscareActive = false;
    this.jumpscareEntity = null;
    this.jumpscareTimer = 0;
    this.jumpscareType = 'ai';

    // Materials and procedural textures cache
    this.materials = {};
    this.textures = {};

    this.initialized = false;
  }

  init(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container || typeof THREE === 'undefined') return;

    const width = this.container.clientWidth || window.innerWidth;
    const height = this.container.clientHeight || window.innerHeight;

    // 1. Scene & Camera
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x05070a);
    this.scene.fog = new THREE.FogExp2(0x05070a, 0.045);

    this.camera = new THREE.PerspectiveCamera(68, width / height, 0.1, 80);
    this.camera.position.set(0, 1.65, 0.35); // Eye height sitting at desk

    // 2. WebGL Renderer
    this.renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
    this.renderer.setSize(width, height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.1;

    this.container.innerHTML = '';
    this.container.appendChild(this.renderer.domElement);

    // 3. Build Textures & Materials
    this._initProceduralTextures();

    // 4. Build 3D World (Office, Doors, Corridors, Desks, Animatronics)
    this._buildOffice();
    this._buildAnimatronics();
    this._setupLighting();

    // 5. Setup Events (Mouse Look, Clicks, Window Resize)
    this._setupListeners();

    this.initialized = true;
    this.animate();
  }

  // Generate procedural canvas textures to ensure 100% offline self-contained operation
  _initProceduralTextures() {
    // A. Metal Grate / Tile Floor
    const floorCanvas = document.createElement('canvas');
    floorCanvas.width = 256;
    floorCanvas.height = 256;
    const fctx = floorCanvas.getContext('2d');
    fctx.fillStyle = '#151a22';
    fctx.fillRect(0, 0, 256, 256);
    fctx.strokeStyle = '#222b38';
    fctx.lineWidth = 4;
    for (let i = 0; i < 256; i += 32) {
      fctx.strokeRect(i, 0, 32, 256);
      fctx.strokeRect(0, i, 256, 32);
    }
    fctx.fillStyle = '#0f131a';
    for (let x = 4; x < 256; x += 32) {
      for (let y = 4; y < 256; y += 32) {
        fctx.fillRect(x, y, 24, 24);
      }
    }
    this.textures.floor = new THREE.CanvasTexture(floorCanvas);
    this.textures.floor.wrapS = THREE.RepeatWrapping;
    this.textures.floor.wrapT = THREE.RepeatWrapping;
    this.textures.floor.repeat.set(8, 8);

    // B. Hazard Stripes (Black & Yellow)
    const hazardCanvas = document.createElement('canvas');
    hazardCanvas.width = 128;
    hazardCanvas.height = 128;
    const hctx = hazardCanvas.getContext('2d');
    hctx.fillStyle = '#111';
    hctx.fillRect(0, 0, 128, 128);
    hctx.fillStyle = '#eab308';
    hctx.beginPath();
    for (let i = -128; i < 256; i += 32) {
      hctx.moveTo(i, 0);
      hctx.lineTo(i + 16, 0);
      hctx.lineTo(i + 48, 128);
      hctx.lineTo(i + 32, 128);
      hctx.closePath();
    }
    hctx.fill();
    this.textures.hazard = new THREE.CanvasTexture(hazardCanvas);
    this.textures.hazard.wrapS = THREE.RepeatWrapping;
    this.textures.hazard.wrapT = THREE.RepeatWrapping;
    this.textures.hazard.repeat.set(4, 1);

    // C. CRT IDE Terminal Texture (Live Render)
    this.crtCanvas = document.createElement('canvas');
    this.crtCanvas.width = 512;
    this.crtCanvas.height = 384;
    this.crtTexture = new THREE.CanvasTexture(this.crtCanvas);
    this._updateCRTTexture();

    // D. Metal Wall Texture
    const wallCanvas = document.createElement('canvas');
    wallCanvas.width = 128;
    wallCanvas.height = 128;
    const wctx = wallCanvas.getContext('2d');
    wctx.fillStyle = '#181f2b';
    wctx.fillRect(0, 0, 128, 128);
    wctx.strokeStyle = '#263142';
    wctx.strokeRect(2, 2, 124, 124);
    // Rivets
    wctx.fillStyle = '#64748b';
    wctx.fillRect(8, 8, 4, 4);
    wctx.fillRect(116, 8, 4, 4);
    wctx.fillRect(8, 116, 4, 4);
    wctx.fillRect(116, 116, 4, 4);
    this.textures.wall = new THREE.CanvasTexture(wallCanvas);
    this.textures.wall.wrapS = THREE.RepeatWrapping;
    this.textures.wall.wrapT = THREE.RepeatWrapping;
    this.textures.wall.repeat.set(4, 2);
  }

  _buildOffice() {
    this.officeGroup = new THREE.Group();
    this.scene.add(this.officeGroup);

    // Floor
    const floorGeo = new THREE.PlaneGeometry(16, 16);
    const floorMat = new THREE.MeshStandardMaterial({
      map: this.textures.floor,
      roughness: 0.75,
      metalness: 0.35
    });
    const floor = new THREE.Mesh(floorGeo, floorMat);
    floor.rotation.x = -Math.PI / 2;
    floor.receiveShadow = true;
    this.officeGroup.add(floor);

    // Ceiling
    const ceilingMat = new THREE.MeshStandardMaterial({ color: 0x111620, roughness: 0.9 });
    const ceiling = new THREE.Mesh(floorGeo, ceilingMat);
    ceiling.position.y = 4.2;
    ceiling.rotation.x = Math.PI / 2;
    this.officeGroup.add(ceiling);

    // Back Wall (behind player)
    const backWallGeo = new THREE.PlaneGeometry(16, 4.2);
    const wallMat = new THREE.MeshStandardMaterial({ map: this.textures.wall, roughness: 0.8 });
    const backWall = new THREE.Mesh(backWallGeo, wallMat);
    backWall.position.set(0, 2.1, 3.2);
    backWall.rotation.y = Math.PI;
    this.officeGroup.add(backWall);

    // Celebrate Poster on back wall
    const posterCanvas = document.createElement('canvas');
    posterCanvas.width = 256;
    posterCanvas.height = 160;
    const pctx = posterCanvas.getContext('2d');
    pctx.fillStyle = '#1e293b';
    pctx.fillRect(0, 0, 256, 160);
    pctx.strokeStyle = '#ef4444';
    pctx.lineWidth = 6;
    pctx.strokeRect(4, 4, 248, 152);
    pctx.fillStyle = '#f59e0b';
    pctx.font = 'bold 22px Courier New';
    pctx.fillText('CELEBRATE!', 60, 45);
    pctx.fillStyle = '#38bdf8';
    pctx.font = 'bold 15px Courier New';
    pctx.fillText('DEPLOY ON FRIDAY', 42, 85);
    pctx.fillStyle = '#ef4444';
    pctx.font = 'bold 13px Courier New';
    pctx.fillText('СКУФНЕТ-666 СЛЕДИТ ЗА ТОБОЙ', 15, 125);
    const posterTex = new THREE.CanvasTexture(posterCanvas);
    const poster = new THREE.Mesh(
      new THREE.PlaneGeometry(2.4, 1.5),
      new THREE.MeshStandardMaterial({ map: posterTex })
    );
    poster.position.set(0, 2.3, 3.18);
    poster.rotation.y = Math.PI;
    this.officeGroup.add(poster);

    // Front Wall (in front of desk with center corridor arch)
    const frontWallL = new THREE.Mesh(new THREE.BoxGeometry(5.5, 4.2, 0.4), wallMat);
    frontWallL.position.set(-4.5, 2.1, -3.2);
    this.officeGroup.add(frontWallL);

    const frontWallR = new THREE.Mesh(new THREE.BoxGeometry(5.5, 4.2, 0.4), wallMat);
    frontWallR.position.set(4.5, 2.1, -3.2);
    this.officeGroup.add(frontWallR);

    const frontWallTop = new THREE.Mesh(new THREE.BoxGeometry(5.0, 1.4, 0.4), wallMat);
    frontWallTop.position.set(0, 3.5, -3.2);
    this.officeGroup.add(frontWallTop);

    // Center Shutter Door (Рубильник ЦОД)
    const centerDoorGeo = new THREE.BoxGeometry(4.4, 3.0, 0.15);
    const doorMat = new THREE.MeshStandardMaterial({
      color: 0x334155,
      metalness: 0.8,
      roughness: 0.35,
      map: this.textures.hazard
    });
    this.centerDoorMesh = new THREE.Mesh(centerDoorGeo, doorMat);
    this.centerDoorMesh.position.set(0, 4.5, -3.15); // Stored up in ceiling when open
    this.officeGroup.add(this.centerDoorMesh);

    // Left Wall with Doorway (Port 22 SSH)
    this._buildLeftDoorway();

    // Right Wall with Doorway (Port 5432 SQL)
    this._buildRightDoorway();

    // The Central DevOps Desk & Props
    this._buildDesk();

    // Corridors stretching outside left and right
    this._buildHallways();
  }

  _buildLeftDoorway() {
    const wallMat = new THREE.MeshStandardMaterial({ map: this.textures.wall, roughness: 0.8 });

    // Doorway frame on left wall (X = -5.0)
    const leftDoorL = new THREE.Mesh(new THREE.BoxGeometry(0.4, 4.2, 3.5), wallMat);
    leftDoorL.position.set(-5.0, 2.1, 1.4);
    this.officeGroup.add(leftDoorL);

    const leftDoorR = new THREE.Mesh(new THREE.BoxGeometry(0.4, 4.2, 3.5), wallMat);
    leftDoorR.position.set(-5.0, 2.1, -2.4);
    this.officeGroup.add(leftDoorR);

    const leftDoorTop = new THREE.Mesh(new THREE.BoxGeometry(0.4, 1.4, 2.6), wallMat);
    leftDoorTop.position.set(-5.0, 3.5, -0.5);
    this.officeGroup.add(leftDoorTop);

    // Left Blast Door (Sliding heavy steel gate)
    const blastDoorGeo = new THREE.BoxGeometry(0.18, 2.9, 2.4);
    const doorMat = new THREE.MeshStandardMaterial({
      color: 0x475569,
      metalness: 0.85,
      roughness: 0.3,
      map: this.textures.hazard
    });
    this.leftDoorMesh = new THREE.Mesh(blastDoorGeo, doorMat);
    this.leftDoorMesh.position.set(-5.0, 4.4, -0.5); // Open: hidden in ceiling
    this.officeGroup.add(this.leftDoorMesh);

    // Left Button Console Panel (on wall next to door: Red Door Button & White Light Button)
    const panelBox = new THREE.Mesh(
      new THREE.BoxGeometry(0.12, 0.75, 0.45),
      new THREE.MeshStandardMaterial({ color: 0x1e293b, metalness: 0.7 })
    );
    panelBox.position.set(-4.75, 1.6, -1.9);
    this.officeGroup.add(panelBox);

    // Red Door Button
    const btnDoorGeo = new THREE.CylinderGeometry(0.08, 0.08, 0.08, 16);
    btnDoorGeo.rotateZ(Math.PI / 2);
    const btnDoorMat = new THREE.MeshStandardMaterial({ color: 0xef4444, roughness: 0.3 });
    const leftDoorBtn = new THREE.Mesh(btnDoorGeo, btnDoorMat);
    leftDoorBtn.position.set(-4.68, 1.8, -1.9);
    leftDoorBtn.userData = { action: 'toggleGateLeft', hint: 'Шлюз Порт 22 [Q]' };
    this.officeGroup.add(leftDoorBtn);
    this.interactables.push(leftDoorBtn);

    // White/Cyan Light Button
    const btnLightMat = new THREE.MeshStandardMaterial({ color: 0x38bdf8, roughness: 0.3 });
    const leftLightBtn = new THREE.Mesh(btnDoorGeo, btnLightMat);
    leftLightBtn.position.set(-4.68, 1.45, -1.9);
    leftLightBtn.userData = { action: 'pingLeft', hint: 'Пинг Шлюза 22 [A]' };
    this.officeGroup.add(leftLightBtn);
    this.interactables.push(leftLightBtn);
  }

  _buildRightDoorway() {
    const wallMat = new THREE.MeshStandardMaterial({ map: this.textures.wall, roughness: 0.8 });

    // Doorway frame on right wall (X = 5.0)
    const rightDoorL = new THREE.Mesh(new THREE.BoxGeometry(0.4, 4.2, 3.5), wallMat);
    rightDoorL.position.set(5.0, 2.1, 1.4);
    this.officeGroup.add(rightDoorL);

    const rightDoorR = new THREE.Mesh(new THREE.BoxGeometry(0.4, 4.2, 3.5), wallMat);
    rightDoorR.position.set(5.0, 2.1, -2.4);
    this.officeGroup.add(rightDoorR);

    const rightDoorTop = new THREE.Mesh(new THREE.BoxGeometry(0.4, 1.4, 2.6), wallMat);
    rightDoorTop.position.set(5.0, 3.5, -0.5);
    this.officeGroup.add(rightDoorTop);

    // Right Blast Door
    const blastDoorGeo = new THREE.BoxGeometry(0.18, 2.9, 2.4);
    const doorMat = new THREE.MeshStandardMaterial({
      color: 0x475569,
      metalness: 0.85,
      roughness: 0.3,
      map: this.textures.hazard
    });
    this.rightDoorMesh = new THREE.Mesh(blastDoorGeo, doorMat);
    this.rightDoorMesh.position.set(5.0, 4.4, -0.5); // Open in ceiling
    this.officeGroup.add(this.rightDoorMesh);

    // Right Button Console Panel
    const panelBox = new THREE.Mesh(
      new THREE.BoxGeometry(0.12, 0.75, 0.45),
      new THREE.MeshStandardMaterial({ color: 0x1e293b, metalness: 0.7 })
    );
    panelBox.position.set(4.75, 1.6, -1.9);
    this.officeGroup.add(panelBox);

    // Red Door Button
    const btnDoorGeo = new THREE.CylinderGeometry(0.08, 0.08, 0.08, 16);
    btnDoorGeo.rotateZ(Math.PI / 2);
    const rightDoorBtn = new THREE.Mesh(
      btnDoorGeo,
      new THREE.MeshStandardMaterial({ color: 0xef4444, roughness: 0.3 })
    );
    rightDoorBtn.position.set(4.68, 1.8, -1.9);
    rightDoorBtn.userData = { action: 'toggleGateRight', hint: 'Шлюз Порт 5432 [E]' };
    this.officeGroup.add(rightDoorBtn);
    this.interactables.push(rightDoorBtn);

    // White/Cyan Light Button
    const rightLightBtn = new THREE.Mesh(
      btnDoorGeo,
      new THREE.MeshStandardMaterial({ color: 0x38bdf8, roughness: 0.3 })
    );
    rightLightBtn.position.set(4.68, 1.45, -1.9);
    rightLightBtn.userData = { action: 'pingRight', hint: 'Пинг Шлюза 5432 [D]' };
    this.officeGroup.add(rightLightBtn);
    this.interactables.push(rightLightBtn);
  }

  _buildDesk() {
    const deskGroup = new THREE.Group();
    deskGroup.position.set(0, 0, -1.45);
    this.officeGroup.add(deskGroup);

    // Desk Table Top (heavy industrial dark wood & steel)
    const topGeo = new THREE.BoxGeometry(4.2, 0.12, 1.6);
    const topMat = new THREE.MeshStandardMaterial({ color: 0x1a212d, roughness: 0.6, metalness: 0.4 });
    const deskTop = new THREE.Mesh(topGeo, topMat);
    deskTop.position.set(0, 0.95, 0);
    deskTop.receiveShadow = true;
    deskGroup.add(deskTop);

    // Desk Legs
    const legGeo = new THREE.CylinderGeometry(0.05, 0.05, 0.95, 8);
    const legMat = new THREE.MeshStandardMaterial({ color: 0x0f172a, metalness: 0.8 });
    [
      [-1.9, 0.47, -0.65],
      [1.9, 0.47, -0.65],
      [-1.9, 0.47, 0.65],
      [1.9, 0.47, 0.65]
    ].forEach(([x, y, z]) => {
      const leg = new THREE.Mesh(legGeo, legMat);
      leg.position.set(x, y, z);
      deskGroup.add(leg);
    });

    // A. CRT Terminal Monitor (Center)
    const monitorGroup = new THREE.Group();
    monitorGroup.position.set(0, 1.01, -0.15);
    deskGroup.add(monitorGroup);

    // Monitor Case
    const caseGeo = new THREE.BoxGeometry(1.2, 0.85, 0.65);
    const caseMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.5 });
    const monitorCase = new THREE.Mesh(caseGeo, caseMat);
    monitorCase.position.set(0, 0.52, 0);
    monitorGroup.add(monitorCase);

    // Monitor Screen (Curved CRT Front)
    const screenGeo = new THREE.PlaneGeometry(1.0, 0.68);
    const screenMat = new THREE.MeshBasicMaterial({ map: this.crtTexture });
    this.crtScreenMesh = new THREE.Mesh(screenGeo, screenMat);
    this.crtScreenMesh.position.set(0, 0.52, 0.33);
    this.crtScreenMesh.userData = { action: 'writePatch', hint: 'Пилить патч [ПРОБЕЛ]' };
    monitorGroup.add(this.crtScreenMesh);
    this.interactables.push(this.crtScreenMesh);

    // Keyboard
    const kbGeo = new THREE.BoxGeometry(0.85, 0.04, 0.32);
    const kbMat = new THREE.MeshStandardMaterial({ color: 0x090d16, roughness: 0.6 });
    const kb = new THREE.Mesh(kbGeo, kbMat);
    kb.position.set(0, 1.03, 0.38);
    kb.userData = { action: 'writePatch', hint: 'Печатать код [ПРОБЕЛ]' };
    deskGroup.add(kb);
    this.interactables.push(kb);

    // B. Retro Desk Fan (Rotating Blades on Left side of desk)
    const fanGroup = new THREE.Group();
    fanGroup.position.set(-1.45, 1.01, -0.1);
    deskGroup.add(fanGroup);

    // Fan Base & Stand
    const fanBase = new THREE.Mesh(
      new THREE.CylinderGeometry(0.18, 0.22, 0.06, 16),
      new THREE.MeshStandardMaterial({ color: 0x0f172a, metalness: 0.8 })
    );
    fanBase.position.y = 0.03;
    fanGroup.add(fanBase);

    const fanPole = new THREE.Mesh(
      new THREE.CylinderGeometry(0.025, 0.025, 0.35, 8),
      new THREE.MeshStandardMaterial({ color: 0x334155, metalness: 0.9 })
    );
    fanPole.position.y = 0.2;
    fanGroup.add(fanPole);

    // Fan Cage & Center Motor
    const fanMotor = new THREE.Mesh(
      new THREE.SphereGeometry(0.09, 12, 12),
      new THREE.MeshStandardMaterial({ color: 0x1e293b })
    );
    fanMotor.position.y = 0.38;
    fanGroup.add(fanMotor);

    // Fan Blades (Rotated in animation loop)
    this.fanBlades = new THREE.Group();
    this.fanBlades.position.set(0, 0.38, 0.07);
    for (let b = 0; b < 3; b++) {
      const blade = new THREE.Mesh(
        new THREE.BoxGeometry(0.08, 0.32, 0.015),
        new THREE.MeshStandardMaterial({ color: 0x64748b, metalness: 0.7 })
      );
      blade.rotation.z = (b * Math.PI * 2) / 3;
      blade.position.y = 0.08;
      this.fanBlades.add(blade);
    }
    fanGroup.add(this.fanBlades);

    // C. Kernel DIP Switches Metal Box (Right side of desk)
    const dipBoxGroup = new THREE.Group();
    dipBoxGroup.position.set(1.3, 1.01, 0.0);
    deskGroup.add(dipBoxGroup);

    const dipBox = new THREE.Mesh(
      new THREE.BoxGeometry(0.9, 0.12, 0.55),
      new THREE.MeshStandardMaterial({ color: 0x1e293b, metalness: 0.75 })
    );
    dipBox.position.y = 0.06;
    dipBoxGroup.add(dipBox);

    // 4 Toggle Levers + 4 Target LEDs
    this.dipLevers = [];
    this.dipLeds = [];
    for (let i = 0; i < 4; i++) {
      const lx = -0.32 + i * 0.21;

      // Lever Base
      const lBase = new THREE.Mesh(
        new THREE.CylinderGeometry(0.035, 0.045, 0.04, 8),
        new THREE.MeshStandardMaterial({ color: 0x0f172a })
      );
      lBase.position.set(lx, 0.14, 0.06);
      dipBoxGroup.add(lBase);

      // Lever Handle (Pivots forward/backward)
      const leverHandle = new THREE.Mesh(
        new THREE.CylinderGeometry(0.015, 0.02, 0.14, 8),
        new THREE.MeshStandardMaterial({ color: 0x22c55e, metalness: 0.9 })
      );
      leverHandle.position.set(lx, 0.21, 0.06);
      leverHandle.userData = { action: `toggleDip_${i}`, hint: `Тумблер Ядра SW-${i + 1} [${i + 1}]` };
      dipBoxGroup.add(leverHandle);
      this.dipLevers.push(leverHandle);
      this.interactables.push(leverHandle);

      // Target LED on box
      const led = new THREE.Mesh(
        new THREE.SphereGeometry(0.025, 8, 8),
        new THREE.MeshBasicMaterial({ color: 0x475569 })
      );
      led.position.set(lx, 0.14, -0.14);
      dipBoxGroup.add(led);
      this.dipLeds.push(led);
    }

    // D. Pukanometer Analog Dial Gauge
    const gaugeGroup = new THREE.Group();
    gaugeGroup.position.set(0.72, 1.01, 0.32);
    deskGroup.add(gaugeGroup);

    const gaugeBody = new THREE.Mesh(
      new THREE.CylinderGeometry(0.16, 0.18, 0.06, 16),
      new THREE.MeshStandardMaterial({ color: 0x0f172a, metalness: 0.8 })
    );
    gaugeBody.position.y = 0.03;
    gaugeGroup.add(gaugeBody);

    // Gauge Face (Canvas with gradient green->red dial)
    const dialCanvas = document.createElement('canvas');
    dialCanvas.width = 128;
    dialCanvas.height = 128;
    const dctx = dialCanvas.getContext('2d');
    dctx.fillStyle = '#111';
    dctx.fillRect(0, 0, 128, 128);
    dctx.beginPath();
    dctx.arc(64, 64, 52, Math.PI * 0.75, Math.PI * 2.25);
    dctx.lineWidth = 10;
    dctx.strokeStyle = '#ef4444';
    dctx.stroke();
    dctx.fillStyle = '#fff';
    dctx.font = 'bold 12px monospace';
    dctx.fillText('°C PUKAN', 38, 72);
    const dialTex = new THREE.CanvasTexture(dialCanvas);

    const gaugeFace = new THREE.Mesh(
      new THREE.CircleGeometry(0.14, 16),
      new THREE.MeshBasicMaterial({ map: dialTex })
    );
    gaugeFace.rotation.x = -Math.PI / 2;
    gaugeFace.position.y = 0.065;
    gaugeGroup.add(gaugeFace);

    // Needle
    this.pukanDialNeedle = new THREE.Mesh(
      new THREE.BoxGeometry(0.015, 0.11, 0.01),
      new THREE.MeshBasicMaterial({ color: 0xf59e0b })
    );
    this.pukanDialNeedle.position.set(0, 0.075, 0);
    this.pukanDialNeedle.rotation.x = -Math.PI / 2;
    gaugeGroup.add(this.pukanDialNeedle);

    // Coffee Mug
    const mug = new THREE.Mesh(
      new THREE.CylinderGeometry(0.06, 0.055, 0.12, 12),
      new THREE.MeshStandardMaterial({ color: 0x3b82f6, roughness: 0.3 })
    );
    mug.position.set(-0.75, 1.07, 0.35);
    deskGroup.add(mug);
  }

  _buildHallways() {
    const wallMat = new THREE.MeshStandardMaterial({ map: this.textures.wall, roughness: 0.85 });

    // Left Corridor (Port 22 SSH) leading past left door
    const leftHallFloor = new THREE.Mesh(
      new THREE.PlaneGeometry(8, 12),
      new THREE.MeshStandardMaterial({ map: this.textures.floor, roughness: 0.8 })
    );
    leftHallFloor.rotation.x = -Math.PI / 2;
    leftHallFloor.position.set(-9.0, 0, -0.5);
    this.scene.add(leftHallFloor);

    const leftHallWall = new THREE.Mesh(new THREE.BoxGeometry(8, 4.2, 0.3), wallMat);
    leftHallWall.position.set(-9.0, 2.1, -6.5);
    this.scene.add(leftHallWall);

    // Right Corridor (Port 5432 SQL) leading past right door
    const rightHallFloor = new THREE.Mesh(
      new THREE.PlaneGeometry(8, 12),
      new THREE.MeshStandardMaterial({ map: this.textures.floor, roughness: 0.8 })
    );
    rightHallFloor.rotation.x = -Math.PI / 2;
    rightHallFloor.position.set(9.0, 0, -0.5);
    this.scene.add(rightHallFloor);

    const rightHallWall = new THREE.Mesh(new THREE.BoxGeometry(8, 4.2, 0.3), wallMat);
    rightHallWall.position.set(9.0, 2.1, -6.5);
    this.scene.add(rightHallWall);

    // Central Server Room (Behind front wall)
    const serverHallFloor = new THREE.Mesh(
      new THREE.PlaneGeometry(14, 24),
      new THREE.MeshStandardMaterial({ map: this.textures.floor, roughness: 0.8 })
    );
    serverHallFloor.rotation.x = -Math.PI / 2;
    serverHallFloor.position.set(0, 0, -15);
    this.scene.add(serverHallFloor);

    // Server Racks in Central Hall
    const rackGeo = new THREE.BoxGeometry(1.2, 3.2, 1.4);
    const rackMat = new THREE.MeshStandardMaterial({ color: 0x090d16, roughness: 0.7, metalness: 0.5 });
    for (let z = -6; z >= -22; z -= 3.5) {
      const rackL = new THREE.Mesh(rackGeo, rackMat);
      rackL.position.set(-3.2, 1.6, z);
      this.scene.add(rackL);

      const rackR = new THREE.Mesh(rackGeo, rackMat);
      rackR.position.set(3.2, 1.6, z);
      this.scene.add(rackR);
    }
  }

  // =========================================================================
  // 3D Procedural Animatronic Entities (Bonnie, Chica, Foxy, Skynet-Freddy)
  // =========================================================================
  _buildAnimatronics() {
    // 1. BONNIE THE BRUTEFORCER (Purple metallic bunny with glowing red eyes)
    this.entities.bonnie = this._createBonnieMesh();
    this.scene.add(this.entities.bonnie);

    // 2. CHICA THE SQL-INJECTOR (Yellow cyber-bird with orange cyber-beak)
    this.entities.chica = this._createChicaMesh();
    this.scene.add(this.entities.chica);

    // 3. FOXY THE CRYPTOLOCKER (Crimson cyber-fox with pirate hook & eyepatch)
    this.entities.foxy = this._createFoxyMesh();
    this.scene.add(this.entities.foxy);

    // 4. SKYNET-FREDDY (Dark bronze AGI bear with top hat & blue optics)
    this.entities.freddy = this._createFreddyMesh();
    this.scene.add(this.entities.freddy);

    // Initial positions away in darkness
    this._updateAnimatronicPositions();
  }

  _createBonnieMesh() {
    const group = new THREE.Group();
    const chassisMat = new THREE.MeshStandardMaterial({
      color: 0x4338ca,
      metalness: 0.8,
      roughness: 0.35
    });
    const jointMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, metalness: 0.9 });
    const eyeMat = new THREE.MeshBasicMaterial({ color: 0xef4444 });

    // Torso
    const torso = new THREE.Mesh(new THREE.BoxGeometry(0.85, 1.2, 0.5), chassisMat);
    torso.position.y = 1.35;
    group.add(torso);

    // Head
    const head = new THREE.Mesh(new THREE.BoxGeometry(0.65, 0.65, 0.6), chassisMat);
    head.position.y = 2.25;
    group.add(head);

    // Snout & Jaw
    const snout = new THREE.Mesh(new THREE.BoxGeometry(0.45, 0.22, 0.3), chassisMat);
    snout.position.set(0, 2.12, 0.36);
    group.add(snout);

    // Glowing Red Eyes
    const eyeL = new THREE.Mesh(new THREE.SphereGeometry(0.08, 12, 12), eyeMat);
    eyeL.position.set(-0.18, 2.32, 0.32);
    group.add(eyeL);

    const eyeR = new THREE.Mesh(new THREE.SphereGeometry(0.08, 12, 12), eyeMat);
    eyeR.position.set(0.18, 2.32, 0.32);
    group.add(eyeR);

    // Bunny Ears (2 jointed ears)
    for (let s of [-0.22, 0.22]) {
      const ear1 = new THREE.Mesh(new THREE.BoxGeometry(0.14, 0.35, 0.08), chassisMat);
      ear1.position.set(s, 2.75, 0);
      group.add(ear1);

      const ear2 = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.42, 0.08), chassisMat);
      ear2.position.set(s, 3.12, 0);
      group.add(ear2);
    }

    // Legs
    for (let s of [-0.25, 0.25]) {
      const leg = new THREE.Mesh(new THREE.CylinderGeometry(0.1, 0.1, 0.8, 8), jointMat);
      leg.position.set(s, 0.45, 0);
      group.add(leg);
    }

    group.userData = { id: 'bonnie', name: 'Бонни-Брутфорсер' };
    return group;
  }

  _createChicaMesh() {
    const group = new THREE.Group();
    const chassisMat = new THREE.MeshStandardMaterial({
      color: 0xeab308,
      metalness: 0.75,
      roughness: 0.35
    });
    const beakMat = new THREE.MeshStandardMaterial({ color: 0xf97316, metalness: 0.6 });
    const eyeMat = new THREE.MeshBasicMaterial({ color: 0xa855f7 });

    // Torso with Bib ("LET'S CRASH")
    const torso = new THREE.Mesh(new THREE.CylinderGeometry(0.48, 0.42, 1.25, 12), chassisMat);
    torso.position.y = 1.35;
    group.add(torso);

    // Head
    const head = new THREE.Mesh(new THREE.SphereGeometry(0.4, 16, 16), chassisMat);
    head.position.y = 2.25;
    group.add(head);

    // Cyber Beak
    const beak = new THREE.Mesh(new THREE.ConeGeometry(0.24, 0.45, 4), beakMat);
    beak.rotation.x = Math.PI / 2;
    beak.position.set(0, 2.15, 0.42);
    group.add(beak);

    // Glowing Eyes
    const eyeL = new THREE.Mesh(new THREE.SphereGeometry(0.08, 12, 12), eyeMat);
    eyeL.position.set(-0.18, 2.32, 0.3);
    group.add(eyeL);

    const eyeR = new THREE.Mesh(new THREE.SphereGeometry(0.08, 12, 12), eyeMat);
    eyeR.position.set(0.18, 2.32, 0.3);
    group.add(eyeR);

    // Feather Tufts
    const tuft = new THREE.Mesh(new THREE.ConeGeometry(0.1, 0.35, 4), chassisMat);
    tuft.position.set(0, 2.75, 0);
    group.add(tuft);

    group.userData = { id: 'chica', name: 'Чика-Инъекторша' };
    return group;
  }

  _createFoxyMesh() {
    const group = new THREE.Group();
    const chassisMat = new THREE.MeshStandardMaterial({
      color: 0xb91c1c,
      metalness: 0.85,
      roughness: 0.3
    });
    const chromeMat = new THREE.MeshStandardMaterial({ color: 0x94a3b8, metalness: 0.95 });
    const eyeMat = new THREE.MeshBasicMaterial({ color: 0xfacc15 });

    // Torso (Lean, mechanical exposed ribs)
    const torso = new THREE.Mesh(new THREE.BoxGeometry(0.72, 1.15, 0.42), chassisMat);
    torso.position.y = 1.35;
    group.add(torso);

    // Head
    const head = new THREE.Mesh(new THREE.ConeGeometry(0.42, 0.72, 5), chassisMat);
    head.rotation.x = Math.PI / 2;
    head.position.set(0, 2.25, 0.1);
    group.add(head);

    // Glowing Eye + Eyepatch Sensor
    const eyeR = new THREE.Mesh(new THREE.SphereGeometry(0.08, 12, 12), eyeMat);
    eyeR.position.set(0.18, 2.25, 0.34);
    group.add(eyeR);

    const eyepatch = new THREE.Mesh(
      new THREE.CylinderGeometry(0.09, 0.09, 0.04, 12),
      new THREE.MeshStandardMaterial({ color: 0x090d16 })
    );
    eyepatch.rotation.x = Math.PI / 2;
    eyepatch.position.set(-0.18, 2.25, 0.34);
    group.add(eyepatch);

    // Fox Ears
    for (let s of [-0.28, 0.28]) {
      const ear = new THREE.Mesh(new THREE.ConeGeometry(0.12, 0.38, 4), chassisMat);
      ear.position.set(s, 2.75, -0.05);
      group.add(ear);
    }

    // Pirate Hook on Right Hand
    const hook = new THREE.Mesh(new THREE.TorusGeometry(0.12, 0.035, 8, 16, Math.PI * 1.3), chromeMat);
    hook.position.set(0.55, 1.1, 0.3);
    group.add(hook);

    group.userData = { id: 'foxy', name: 'Фокси-Криптолокер' };
    return group;
  }

  _createFreddyMesh() {
    const group = new THREE.Group();
    const chassisMat = new THREE.MeshStandardMaterial({
      color: 0x451a03,
      metalness: 0.8,
      roughness: 0.4
    });
    const hatMat = new THREE.MeshStandardMaterial({ color: 0x090d16, roughness: 0.5 });
    const eyeMat = new THREE.MeshBasicMaterial({ color: 0x38bdf8 });

    // Heavy Torso
    const torso = new THREE.Mesh(new THREE.BoxGeometry(1.0, 1.3, 0.6), chassisMat);
    torso.position.y = 1.35;
    group.add(torso);

    // Head
    const head = new THREE.Mesh(new THREE.BoxGeometry(0.75, 0.75, 0.65), chassisMat);
    head.position.y = 2.25;
    group.add(head);

    // Snout
    const snout = new THREE.Mesh(new THREE.BoxGeometry(0.5, 0.28, 0.35), chassisMat);
    snout.position.set(0, 2.1, 0.4);
    group.add(snout);

    // Glowing Blue Optics
    const eyeL = new THREE.Mesh(new THREE.SphereGeometry(0.08, 12, 12), eyeMat);
    eyeL.position.set(-0.2, 2.35, 0.35);
    group.add(eyeL);

    const eyeR = new THREE.Mesh(new THREE.SphereGeometry(0.08, 12, 12), eyeMat);
    eyeR.position.set(0.2, 2.35, 0.35);
    group.add(eyeR);

    // Top Hat
    const hatBase = new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.3, 0.04, 16), hatMat);
    hatBase.position.set(0, 2.65, 0);
    group.add(hatBase);

    const hatTop = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.22, 0.35, 16), hatMat);
    hatTop.position.set(0, 2.82, 0);
    group.add(hatTop);

    // Bear Ears
    for (let s of [-0.38, 0.38]) {
      const ear = new THREE.Mesh(new THREE.SphereGeometry(0.12, 10, 10), chassisMat);
      ear.position.set(s, 2.65, 0);
      group.add(ear);
    }

    group.userData = { id: 'freddy', name: 'Скайнет-Фредди' };
    return group;
  }

  _setupLighting() {
    // Ambient office light
    const ambient = new THREE.AmbientLight(0x0f172a, 0.65);
    this.scene.add(ambient);

    // Overhead fluorescent tube (PointLight)
    this.officeLight = new THREE.PointLight(0xe0f2fe, 1.4, 12, 1.8);
    this.officeLight.position.set(0, 3.8, 0);
    this.officeLight.castShadow = true;
    this.scene.add(this.officeLight);

    // CRT Screen glow
    const crtGlow = new THREE.PointLight(0x22c55e, 0.9, 3.5, 2);
    crtGlow.position.set(0, 1.6, -1.2);
    this.scene.add(crtGlow);

    // Left Hallway Spotlight (enabled during ping or light)
    this.leftSpotlight = new THREE.SpotLight(0xffffff, 0, 16, Math.PI / 4, 0.45);
    this.leftSpotlight.position.set(-4.8, 2.8, -0.5);
    this.leftSpotlight.target.position.set(-10, 1.2, -0.5);
    this.scene.add(this.leftSpotlight);
    this.scene.add(this.leftSpotlight.target);

    // Right Hallway Spotlight
    this.rightSpotlight = new THREE.SpotLight(0xffffff, 0, 16, Math.PI / 4, 0.45);
    this.rightSpotlight.position.set(4.8, 2.8, -0.5);
    this.rightSpotlight.target.position.set(10, 1.2, -0.5);
    this.scene.add(this.rightSpotlight);
    this.scene.add(this.rightSpotlight.target);

    // Red Emergency Strobe (Flashes when pukan boiling or alarm)
    this.alarmStrobe = new THREE.PointLight(0xef4444, 0, 18, 1.5);
    this.alarmStrobe.position.set(0, 3.5, -0.5);
    this.scene.add(this.alarmStrobe);
  }

  _setupListeners() {
    // Mouse movement inside 3D viewport for FNaF-style camera panning & hover tooltips
    window.addEventListener('mousemove', (e) => {
      this.mouseX = e.clientX / window.innerWidth;
      this.mouseY = e.clientY / window.innerHeight;

      // Update raycaster mouse vector
      const rect = this.container.getBoundingClientRect();
      this.mouseVec.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
      this.mouseVec.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;

      // Check hover over 3D interactable items
      if (this.interactables && this.camera && window.prodGame && !window.prodGame.cctvOpen) {
        this.raycaster.setFromCamera(this.mouseVec, this.camera);
        const hits = this.raycaster.intersectObjects(this.interactables, true);
        const tooltip = document.getElementById('interact-tooltip');
        if (hits.length > 0) {
          let obj = hits[0].object;
          while (obj && !obj.userData?.hint && obj.parent) obj = obj.parent;
          if (obj && obj.userData?.hint && tooltip) {
            tooltip.textContent = `🎯 ${obj.userData.hint}`;
            tooltip.classList.remove('hidden');
            this.container.style.cursor = 'pointer';
          }
        } else if (tooltip) {
          tooltip.classList.add('hidden');
          this.container.style.cursor = 'crosshair';
        }
      }
    });

    // Window Resize
    window.addEventListener('resize', () => {
      if (!this.container || !this.renderer || !this.camera) return;
      const w = this.container.clientWidth;
      const h = this.container.clientHeight;
      this.camera.aspect = w / h;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(w, h);
    });

    // Click on 3D interactive objects (buttons, DIP switches, terminal)
    this.container.addEventListener('click', () => {
      if (!window.prodGame || !window.prodGame.running || window.prodGame.cctvOpen) return;
      this.raycaster.setFromCamera(this.mouseVec, this.camera);
      const hits = this.raycaster.intersectObjects(this.interactables, true);
      if (hits.length > 0) {
        let obj = hits[0].object;
        while (obj && !obj.userData?.action && obj.parent) {
          obj = obj.parent;
        }
        if (obj && obj.userData?.action) {
          this._handleInteractAction(obj.userData.action);
        }
      }
    });
  }

  _handleInteractAction(action) {
    if (!window.prodGame) return;
    if (action === 'toggleGateLeft') window.prodGame.toggleSwitch('gateLeft');
    else if (action === 'toggleGateRight') window.prodGame.toggleSwitch('gateRight');
    else if (action === 'pingLeft') window.prodGame.pingPort('left');
    else if (action === 'pingRight') window.prodGame.pingPort('right');
    else if (action === 'writePatch') window.prodGame.writePatchChunk();
    else if (action.startsWith('toggleDip_')) {
      const idx = parseInt(action.split('_')[1], 10);
      window.prodGame.toggleDip(idx);
    }
  }

  // Update live CRT terminal canvas texture
  _updateCRTTexture() {
    if (!this.crtCanvas) return;
    const ctx = this.crtCanvas.getContext('2d');
    ctx.fillStyle = '#060a0f';
    ctx.fillRect(0, 0, 512, 384);

    // Scanlines
    ctx.fillStyle = 'rgba(0, 0, 0, 0.25)';
    for (let y = 0; y < 384; y += 4) {
      ctx.fillRect(0, y, 512, 2);
    }

    // Top status
    ctx.fillStyle = '#10b981';
    ctx.font = 'bold 16px Courier New, monospace';
    const pct = window.prodGame ? Math.floor(window.prodGame.patchProgress) : 0;
    ctx.fillText(`HOTFIX_PROD.JS [ПАТЧ: ${pct}%]`, 20, 32);

    // Code lines
    ctx.font = '14px Courier New, monospace';
    const lines = window.prodGame ? window.prodGame.codeLines : [];
    const displayLines = lines.slice(-6);
    displayLines.forEach((line, i) => {
      ctx.fillStyle = i === displayLines.length - 1 ? '#38bdf8' : '#22c55e';
      ctx.fillText(line, 20, 75 + i * 44);
    });

    if (this.crtTexture) this.crtTexture.needsUpdate = true;
  }

  // Update animatronics 3D positions based on current AI state in engine.js
  _updateAnimatronicPositions() {
    if (!window.prodGame) return;
    const ai = window.prodGame.ai;

    // BONNIE (Port 22 SSH / Left Lane)
    if (this.entities.bonnie) {
      if (ai.bonnie.pos === 'DOOR_LEFT') {
        // Outside the left door window!
        this.entities.bonnie.position.set(-6.2, 0, -0.5);
        this.entities.bonnie.rotation.y = Math.PI / 2;
        this.entities.bonnie.visible = true;
      } else if (ai.bonnie.pos === 'CAM02') {
        this.entities.bonnie.position.set(-8.5, 0, -2.5);
        this.entities.bonnie.rotation.y = 0;
        this.entities.bonnie.visible = true;
      } else if (ai.bonnie.pos === 'CAM01') {
        this.entities.bonnie.position.set(-1.8, 0, -18);
        this.entities.bonnie.rotation.y = 0;
        this.entities.bonnie.visible = true;
      } else {
        this.entities.bonnie.visible = false;
      }
    }

    // CHICA (Port 5432 SQL / Right Lane)
    if (this.entities.chica) {
      if (ai.chica.pos === 'DOOR_RIGHT') {
        // Outside right door window!
        this.entities.chica.position.set(6.2, 0, -0.5);
        this.entities.chica.rotation.y = -Math.PI / 2;
        this.entities.chica.visible = true;
      } else if (ai.chica.pos === 'CAM04') {
        this.entities.chica.position.set(8.5, 0, -2.5);
        this.entities.chica.rotation.y = 0;
        this.entities.chica.visible = true;
      } else if (ai.chica.pos === 'CAM01') {
        this.entities.chica.position.set(1.8, 0, -18);
        this.entities.chica.rotation.y = 0;
        this.entities.chica.visible = true;
      } else {
        this.entities.chica.visible = false;
      }
    }

    // FOXY (Quarantine Cove -> Sprints Center)
    if (this.entities.foxy) {
      if (ai.foxy.sprinting) {
        // Sprinting down central approach tunnel!
        this.entities.foxy.position.set(0, 0, -2.5 - (ai.foxy.sprintTimer * 1.5));
        this.entities.foxy.rotation.y = 0;
        this.entities.foxy.visible = true;
      } else {
        // Inside CAM05 Cove
        this.entities.foxy.position.set(0, 0, -21);
        this.entities.foxy.rotation.y = 0;
        this.entities.foxy.visible = true;
      }
    }

    // SKYNET-FREDDY (Center Hub)
    if (this.entities.freddy) {
      if (ai.freddy.pos === 'DOOR_CENTER') {
        this.entities.freddy.position.set(0, 0, -4.5);
        this.entities.freddy.rotation.y = 0;
        this.entities.freddy.visible = true;
      } else if (ai.freddy.pos === 'CAM06') {
        this.entities.freddy.position.set(0, 0, -8.5);
        this.entities.freddy.rotation.y = 0;
        this.entities.freddy.visible = true;
      } else if (ai.freddy.pos === 'CAM03') {
        this.entities.freddy.position.set(0, 0, -12);
        this.entities.freddy.rotation.y = 0;
        this.entities.freddy.visible = true;
      } else if (ai.freddy.pos === 'CAM01') {
        this.entities.freddy.position.set(0, 0, -16);
        this.entities.freddy.rotation.y = 0;
        this.entities.freddy.visible = true;
      } else {
        this.entities.freddy.visible = false;
      }
    }
  }

  // Jumpscare Animation Sequence in 3D
  startJumpscare(type = 'ai') {
    this.jumpscareActive = true;
    this.jumpscareType = type;
    this.jumpscareTimer = 0;

    // Pick jumpscare model
    if (type === 'pukan') {
      this.jumpscareEntity = null;
    } else {
      // Pick closest attacking animatronic
      const ai = window.prodGame ? window.prodGame.ai : null;
      if (ai && ai.foxy.sprinting) this.jumpscareEntity = this.entities.foxy;
      else if (ai && ai.bonnie.pos === 'DOOR_LEFT') this.jumpscareEntity = this.entities.bonnie;
      else if (ai && ai.chica.pos === 'DOOR_RIGHT') this.jumpscareEntity = this.entities.chica;
      else this.jumpscareEntity = this.entities.freddy || this.entities.bonnie;

      if (this.jumpscareEntity) {
        this.jumpscareEntity.visible = true;
        this.jumpscareEntity.position.set(0, 0.4, -2.5);
        this.jumpscareEntity.rotation.set(0, 0, 0);
      }
    }
  }

  animate() {
    requestAnimationFrame(() => this.animate());
    const dt = this.clock.getDelta();
    const time = this.clock.getElapsedTime();

    if (!this.initialized) return;

    // 1. Fan blades spinning
    if (this.fanBlades) {
      this.fanBlades.rotation.z += dt * 26;
    }

    // 2. Blast doors sliding animation
    if (window.prodGame) {
      const leftTargetY = window.prodGame.switches.gateLeft ? 1.45 : 4.4;
      this.leftDoorMesh.position.y += (leftTargetY - this.leftDoorMesh.position.y) * 0.18;

      const rightTargetY = window.prodGame.switches.gateRight ? 1.45 : 4.4;
      this.rightDoorMesh.position.y += (rightTargetY - this.rightDoorMesh.position.y) * 0.18;

      const centerTargetY = window.prodGame.switches.gateCenter ? 1.5 : 4.5;
      this.centerDoorMesh.position.y += (centerTargetY - this.centerDoorMesh.position.y) * 0.18;

      // Spotlights for Door Pings / Lights
      const leftLightOn = window.prodGame.pingLeftActive || (!window.prodGame.switches.gateLeft && window.prodGame.power > 0);
      this.leftSpotlight.intensity = leftLightOn ? 3.5 : 0;

      const rightLightOn = window.prodGame.pingRightActive || (!window.prodGame.switches.gateRight && window.prodGame.power > 0);
      this.rightSpotlight.intensity = rightLightOn ? 3.5 : 0;

      // Pukanometer needle
      if (this.pukanDialNeedle) {
        const heat = window.prodGame.pukanTemp;
        const targetRot = -Math.PI * 0.75 + (heat / 100) * (Math.PI * 1.5);
        this.pukanDialNeedle.rotation.z += (targetRot - this.pukanDialNeedle.rotation.z) * 0.1;
      }

      // DIP Switches Levers orientation
      for (let i = 0; i < 4; i++) {
        const bit = window.prodGame.switches.dip[i];
        const targetRotX = bit === 1 ? -0.45 : 0.45;
        this.dipLevers[i].rotation.x += (targetRotX - this.dipLevers[i].rotation.x) * 0.2;

        // Target LED illumination
        const targetBit = window.prodGame.targetDip[i];
        const active = window.prodGame.dipPuzzleActive;
        this.dipLeds[i].material.color.setHex(active ? (targetBit === 1 ? 0xef4444 : 0x06b6d4) : 0x22c55e);
      }

      // Emergency strobe light if boiling or hacked
      if (window.prodGame.pukanTemp > 75 || window.prodGame.hackCount > 2) {
        this.alarmStrobe.intensity = Math.sin(time * 16) > 0 ? 2.5 : 0;
      } else {
        this.alarmStrobe.intensity = 0;
      }

      // Fluorescent ceiling light slight hum flicker
      if (Math.random() < 0.02) {
        this.officeLight.intensity = 0.5 + Math.random() * 0.9;
      } else {
        this.officeLight.intensity = 1.35;
      }
    }

    // 3. Jumpscare State vs CCTV vs Normal Office Camera
    if (this.jumpscareActive) {
      this.jumpscareTimer += dt;
      // Violent 3D lunging & jaw shaking
      if (this.jumpscareEntity) {
        // Lunge straight into camera face!
        this.jumpscareEntity.position.z += ((-1.05) - this.jumpscareEntity.position.z) * 0.22;
        this.jumpscareEntity.position.x = (Math.random() - 0.5) * 0.18;
        this.jumpscareEntity.position.y = 0.35 + (Math.random() - 0.5) * 0.18;
        this.jumpscareEntity.rotation.z = (Math.random() - 0.5) * 0.25;
      }
      // Camera shake
      this.camera.position.x = (Math.random() - 0.5) * 0.12;
      this.camera.position.y = 1.65 + (Math.random() - 0.5) * 0.12;
      this.alarmStrobe.intensity = Math.random() > 0.4 ? 4.5 : 0;
      this.alarmStrobe.color.setHex(Math.random() > 0.5 ? 0xff0000 : 0xffffff);

      if (this.jumpscareTimer > 1.6) {
        this.jumpscareActive = false;
      }
    } else if (window.prodGame && window.prodGame.cctvOpen) {
      // CCTV Security Camera View Mode
      const camKey = window.prodGame.currentCam || 'CAM01';
      const cfg = this.camPositions[camKey] || this.camPositions.CAM01;

      // Place camera at security mount
      this.camera.position.copy(cfg.pos);
      // Slight CCTV pan bob
      const camSway = Math.sin(time * 0.7) * 0.08;
      const targetLook = cfg.lookAt.clone();
      targetLook.x += camSway;
      this.camera.lookAt(targetLook);

      this._updateAnimatronicPositions();
    } else {
      // Normal First-Person Office Panning (FNaF Scott Cawthon style)
      this.camera.position.set(0, 1.65, 0.35);

      // Mouse X: 0 (left door) to 1 (right door) -> Yaw -55deg to +55deg
      this.targetYaw = (0.5 - this.mouseX) * (Math.PI * 0.65);
      this.currentYaw += (this.targetYaw - this.currentYaw) * 0.09;

      // Mouse Y: subtle vertical tilt
      this.targetPitch = (0.5 - this.mouseY) * 0.35;
      this.currentPitch += (this.targetPitch - this.currentPitch) * 0.09;

      // Gentle natural breathing sway
      const breathX = Math.sin(time * 1.5) * 0.003;
      const breathY = Math.cos(time * 3.0) * 0.004;

      this.camera.rotation.set(this.currentPitch + breathY, this.currentYaw + breathX, 0, 'YXZ');

      this._updateAnimatronicPositions();
    }

    // Refresh live code screen periodically
    if (Math.random() < 0.25) {
      this._updateCRTTexture();
    }

    this.renderer.render(this.scene, this.camera);
  }
}

window.view3D = new View3D();

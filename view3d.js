// ============================================================================
// DEVOPS NIGHTMARE — 3D PS1 Retro Horror Engine & 360° Office Experience
// Authentic PS1 low-poly aesthetic, 360° panoramic view, Starry back window,
// 4 Unique Monsters, Draggable Gas Valve, 3D Bio-Printer, and CCTV Tablet.
// ============================================================================

class View3D {
  constructor() {
    this.container = null;
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.clock = new THREE.Clock();

    // 360-degree Mouse Pan
    this.yaw = 0; // 0 to 2*PI (full 360 rotation!)
    this.pitch = 0; // -0.5 to +0.5
    this.targetYaw = 0;
    this.targetPitch = 0;
    this.isDragging = false;
    this.prevMouseX = 0;
    this.prevMouseY = 0;

    // Interactive Raycaster
    this.raycaster = new THREE.Raycaster();
    this.mouseVec = new THREE.Vector2();
    this.interactables = [];

    // Valve dragging state
    this.isDraggingValve = false;
    this.valveLastAngle = 0;

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

    // Gas Valve 3D Wheel
    this.gasValveWheel = null;
    this.gasPipe = null;

    // 3D Bio-Printer (Carrot generator)
    this.printerMesh = null;
    this.carrotHologram = null;

    // Breaker Panel (Back Wall)
    this.breakerLever = null;

    // Ceiling Vent Grate & Tail
    this.ventGrate = null;
    this.burgundyTail = null;

    // Interactive Cabinet ("AZAMAT SASI")
    this.cabinetGroup = null;
    this.cabinetDoorGroup = null;
    this.cabinetOpen = false;
    this.targetCabinetAngle = 0;

    // Desk Props (Easter Eggs)
    this.rubberDuck = null;
    this.coffeeMug = null;

    // Daytime Lobby vs Night Environment
    this.isDaytime = true;
    this.daySkyPlane = null;
    this.nightSkyPlane = null;
    this.ambientLight = null;
    this.sunLight = null;

    // Lighting
    this.officeLight = null;
    this.leftSpotlight = null;
    this.rightSpotlight = null;
    this.alarmStrobe = null;
    this.nightSkyLight = null;

    // 4 Monsters 3D Meshes
    this.monsters3D = {
      distortion: null, // Giant with bright eyes & distortion
      tadpole: null,    // Small rat-tadpole hybrid
      trojan: null,     // Static wooden horse in pure T-pose
      burgundy: null    // Crimson vent stalker
    };

    // CCTV Security Camera Positions
    this.camPositions = {
      CAM01: { pos: new THREE.Vector3(0, 3.8, -14.5), lookAt: new THREE.Vector3(0, 1.5, -24) },   // Gateway
      CAM02: { pos: new THREE.Vector3(-7.5, 3.5, -4.5), lookAt: new THREE.Vector3(-7.5, 1.2, 0) }, // Left SSH
      CAM03: { pos: new THREE.Vector3(0, 4.0, -8.0), lookAt: new THREE.Vector3(0, 1.2, -14) },    // Center Hub (Trojan tunnel)
      CAM04: { pos: new THREE.Vector3(7.5, 3.5, -4.5), lookAt: new THREE.Vector3(7.5, 1.2, 0) },  // Right SQL
      CAM05: { pos: new THREE.Vector3(0, 3.2, -18.5), lookAt: new THREE.Vector3(0, 1.5, -23) },   // Trojan Stash
      CAM06: { pos: new THREE.Vector3(0, 2.8, -4.5), lookAt: new THREE.Vector3(0, 1.5, 0) }       // Approach Vent
    };

    // Jumpscare Animation
    this.jumpscareActive = false;
    this.jumpscareType = 'ai';
    this.jumpscareTimer = 0;
    this.jumpscareEntity = null;

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
    this.scene.background = new THREE.Color(0x040608);
    this.scene.fog = new THREE.FogExp2(0x040608, 0.04);

    this.camera = new THREE.PerspectiveCamera(70, width / height, 0.1, 90);
    this.camera.position.set(0, 1.62, 0.15); // eye level at office chair

    // 2. WebGL Renderer with PS1 Low-Res Crunchy Look
    this.renderer = new THREE.WebGLRenderer({ antialias: false, powerPreference: 'high-performance' });
    // PS1 style: render at 640x384 scaled up with pixelated canvas!
    this.renderer.setSize(width, height);
    this.renderer.setPixelRatio(0.85); // Crunchy retro pixel density!
    this.renderer.domElement.style.imageRendering = 'pixelated';
    this.renderer.shadowMap.enabled = false; // PS1 did not have soft dynamic shadow maps!

    this.container.innerHTML = '';
    this.container.appendChild(this.renderer.domElement);

    // 3. Textures
    this._initTextures();

    // 4. Build 360 Office Room, Starry Sky Window, Desk, Doors & Monsters
    this._buildOffice();
    this._buildStarryBackWindow();
    this._buildInteractiveCabinet();
    this._buildDesk();
    this._buildMonsters();
    this._setupLighting();

    // 5. Setup Listeners
    this._setupListeners();

    // 6. Set initial daytime/lobby environment
    const isDay = window.prodGame ? window.prodGame.inLobby : true;
    this.setDaytime(isDay);

    this.initialized = true;
    this.animate();
  }

  reset() {
    this.targetYaw = 0;
    this.targetPitch = 0;
    this.yaw = 0;
    this.pitch = 0;
    this.jumpscareActive = false;
  }

  _initTextures() {
    // A. PS1 Metal Floor Tiles
    const floorC = document.createElement('canvas');
    floorC.width = 128;
    floorC.height = 128;
    const fctx = floorC.getContext('2d');
    fctx.fillStyle = '#141a24';
    fctx.fillRect(0, 0, 128, 128);
    fctx.strokeStyle = '#252f3d';
    fctx.lineWidth = 3;
    fctx.strokeRect(2, 2, 60, 60);
    fctx.strokeRect(66, 2, 60, 60);
    fctx.strokeRect(2, 66, 60, 60);
    fctx.strokeRect(66, 66, 60, 60);
    this.textures.floor = new THREE.CanvasTexture(floorC);
    this.textures.floor.wrapS = THREE.RepeatWrapping;
    this.textures.floor.wrapT = THREE.RepeatWrapping;
    this.textures.floor.repeat.set(8, 8);
    this.textures.floor.magFilter = THREE.NearestFilter;
    this.textures.floor.minFilter = THREE.NearestFilter;

    // B. Hazard Warning Stripes
    const hazC = document.createElement('canvas');
    hazC.width = 64;
    hazC.height = 64;
    const hctx = hazC.getContext('2d');
    hctx.fillStyle = '#0f172a';
    hctx.fillRect(0, 0, 64, 64);
    hctx.fillStyle = '#eab308';
    hctx.beginPath();
    for (let i = -64; i < 128; i += 24) {
      hctx.moveTo(i, 0);
      hctx.lineTo(i + 12, 0);
      hctx.lineTo(i + 36, 64);
      hctx.lineTo(i + 24, 64);
      hctx.closePath();
    }
    hctx.fill();
    this.textures.hazard = new THREE.CanvasTexture(hazC);
    this.textures.hazard.wrapS = THREE.RepeatWrapping;
    this.textures.hazard.wrapT = THREE.RepeatWrapping;
    this.textures.hazard.repeat.set(4, 1);
    this.textures.hazard.magFilter = THREE.NearestFilter;

    // C. Live CRT IDE Texture
    this.crtCanvas = document.createElement('canvas');
    this.crtCanvas.width = 512;
    this.crtCanvas.height = 384;
    this.crtTexture = new THREE.CanvasTexture(this.crtCanvas);
    this.crtTexture.magFilter = THREE.NearestFilter;
    this._updateCRTTexture();
  }

  _buildOffice() {
    this.officeGroup = new THREE.Group();
    this.scene.add(this.officeGroup);

    // Floor
    const floorGeo = new THREE.PlaneGeometry(16, 16);
    const floorMat = new THREE.MeshLambertMaterial({ map: this.textures.floor });
    const floor = new THREE.Mesh(floorGeo, floorMat);
    floor.rotation.x = -Math.PI / 2;
    this.officeGroup.add(floor);

    // Ceiling with Ventilation Grate
    const ceilingMat = new THREE.MeshLambertMaterial({ color: 0x0f1520 });
    const ceiling = new THREE.Mesh(floorGeo, ceilingMat);
    ceiling.position.y = 4.0;
    ceiling.rotation.x = Math.PI / 2;
    this.officeGroup.add(ceiling);

    // Ceiling Vent Hole right above the office desk (for Burgundy Stalker!)
    const ventFrame = new THREE.Mesh(
      new THREE.BoxGeometry(1.6, 0.15, 1.6),
      new THREE.MeshLambertMaterial({ color: 0x1e293b })
    );
    ventFrame.position.set(0, 3.95, -0.8);
    this.officeGroup.add(ventFrame);

    // Rattling Vent Grate
    const grateGeo = new THREE.BoxGeometry(1.4, 0.05, 1.4);
    const grateMat = new THREE.MeshLambertMaterial({ color: 0x475569, wireframe: true });
    this.ventGrate = new THREE.Mesh(grateGeo, grateMat);
    this.ventGrate.position.set(0, 3.9, -0.8);
    this.ventGrate.userData = { action: 'purgeSteam', hint: 'Продуть решётку паром [V]' };
    this.officeGroup.add(this.ventGrate);
    this.interactables.push(this.ventGrate);

    // Burgundy Alien Tail (Twitches inside the vent grate!)
    this.burgundyTail = new THREE.Group();
    this.burgundyTail.position.set(0, 3.82, -0.8);
    const tailMesh = new THREE.Mesh(
      new THREE.ConeGeometry(0.12, 0.75, 5),
      new THREE.MeshLambertMaterial({ color: 0x881337 }) // злобно-бордовый
    );
    tailMesh.rotation.x = Math.PI * 0.85;
    this.burgundyTail.add(tailMesh);
    this.burgundyTail.visible = false;
    this.officeGroup.add(this.burgundyTail);

    // Front Wall (Z = -4.5) with Central Gateway Arch
    const wallMat = new THREE.MeshLambertMaterial({ color: 0x18202c });
    const frontL = new THREE.Mesh(new THREE.BoxGeometry(5.5, 4.0, 0.4), wallMat);
    frontL.position.set(-4.5, 2.0, -4.5);
    this.officeGroup.add(frontL);

    const frontR = new THREE.Mesh(new THREE.BoxGeometry(5.5, 4.0, 0.4), wallMat);
    frontR.position.set(4.5, 2.0, -4.5);
    this.officeGroup.add(frontR);

    const frontTop = new THREE.Mesh(new THREE.BoxGeometry(5.0, 1.2, 0.4), wallMat);
    frontTop.position.set(0, 3.4, -4.5);
    this.officeGroup.add(frontTop);

    // Center Blast Shutter
    const cDoorGeo = new THREE.BoxGeometry(4.2, 2.9, 0.15);
    const doorMat = new THREE.MeshLambertMaterial({ color: 0x334155, map: this.textures.hazard });
    this.centerDoorMesh = new THREE.Mesh(cDoorGeo, doorMat);
    this.centerDoorMesh.position.set(0, 4.2, -4.45);
    this.officeGroup.add(this.centerDoorMesh);

    // Left Doorway (Port 22 SSH) at X = -5.5
    this._buildLeftDoorway();

    // Right Doorway (Port 5432 SQL) at X = 5.5
    this._buildRightDoorway();
  }

  // =========================================================================
  // PANORAMIC BACK WINDOW (360° View): Dark Night Sky, Stars & Breaker Box
  // =========================================================================
  _buildStarryBackWindow() {
    const wallMat = new THREE.MeshLambertMaterial({ color: 0x18202c });

    // Back Wall (Z = +4.5) with large window cutout
    const backL = new THREE.Mesh(new THREE.BoxGeometry(4.0, 4.0, 0.4), wallMat);
    backL.position.set(-5.0, 2.0, 4.5);
    this.officeGroup.add(backL);

    const backR = new THREE.Mesh(new THREE.BoxGeometry(4.0, 4.0, 0.4), wallMat);
    backR.position.set(5.0, 2.0, 4.5);
    this.officeGroup.add(backR);

    const backTop = new THREE.Mesh(new THREE.BoxGeometry(8.0, 1.0, 0.4), wallMat);
    backTop.position.set(0, 3.5, 4.5);
    this.officeGroup.add(backTop);

    const backBottom = new THREE.Mesh(new THREE.BoxGeometry(8.0, 1.0, 0.4), wallMat);
    backBottom.position.set(0, 0.5, 4.5);
    this.officeGroup.add(backBottom);

    // Big Glass Window Frame
    const frameMat = new THREE.MeshLambertMaterial({ color: 0x090d16 });
    const winFrame = new THREE.Mesh(new THREE.BoxGeometry(7.8, 2.2, 0.1), frameMat);
    winFrame.position.set(0, 2.0, 4.55);
    this.officeGroup.add(winFrame);

    // Glass pane with subtle transparency
    const glass = new THREE.Mesh(
      new THREE.PlaneGeometry(7.6, 2.0),
      new THREE.MeshLambertMaterial({ color: 0x1e3a5f, transparent: true, opacity: 0.25 })
    );
    glass.position.set(0, 2.0, 4.58);
    glass.rotation.y = Math.PI;
    this.officeGroup.add(glass);

    // Deep Night Sky Backdrop outside window (Stars, Moon, Trees)
    const skyCanvas = document.createElement('canvas');
    skyCanvas.width = 512;
    skyCanvas.height = 256;
    const sctx = skyCanvas.getContext('2d');
    // Dark starry night gradient
    const grad = sctx.createLinearGradient(0, 0, 0, 256);
    grad.addColorStop(0, '#020617');
    grad.addColorStop(0.7, '#070f26');
    grad.addColorStop(1, '#0f172a');
    sctx.fillStyle = grad;
    sctx.fillRect(0, 0, 512, 256);

    // Twinkling Stars
    sctx.fillStyle = '#ffffff';
    for (let i = 0; i < 90; i++) {
      const sx = Math.random() * 512;
      const sy = Math.random() * 190;
      const r = Math.random() > 0.85 ? 2.5 : 1.2;
      sctx.beginPath();
      sctx.arc(sx, sy, r, 0, Math.PI * 2);
      sctx.fill();
    }

    // Glowing Full Moon
    sctx.fillStyle = '#fef08a';
    sctx.beginPath();
    sctx.arc(380, 75, 32, 0, Math.PI * 2);
    sctx.fill();

    // Silhouettes of distant antenna towers & pines
    sctx.fillStyle = '#010409';
    sctx.beginPath();
    sctx.moveTo(0, 256);
    for (let x = 0; x <= 512; x += 32) {
      const h = 20 + Math.sin(x * 0.1) * 15 + Math.random() * 10;
      sctx.lineTo(x, 256 - h);
    }
    sctx.lineTo(512, 256);
    sctx.closePath();
    sctx.fill();

    const skyTex = new THREE.CanvasTexture(skyCanvas);
    this.nightSkyPlane = new THREE.Mesh(
      new THREE.PlaneGeometry(16, 7),
      new THREE.MeshBasicMaterial({ map: skyTex })
    );
    this.nightSkyPlane.position.set(0, 2.5, 7.5); // outside in the distance
    this.nightSkyPlane.rotation.y = Math.PI;
    this.nightSkyPlane.visible = false;
    this.scene.add(this.nightSkyPlane);

    // B. Bright Daytime Sky Backdrop outside window (Sun, Clouds, Green trees)
    const dayCanvas = document.createElement('canvas');
    dayCanvas.width = 512;
    dayCanvas.height = 256;
    const dctx = dayCanvas.getContext('2d');
    const dGrad = dctx.createLinearGradient(0, 0, 0, 256);
    dGrad.addColorStop(0, '#0284c7');
    dGrad.addColorStop(0.5, '#38bdf8');
    dGrad.addColorStop(0.85, '#bae6fd');
    dGrad.addColorStop(1, '#f0f9ff');
    dctx.fillStyle = dGrad;
    dctx.fillRect(0, 0, 512, 256);

    // Radiant Morning Sun
    const sunGrad = dctx.createRadialGradient(160, 60, 5, 160, 60, 55);
    sunGrad.addColorStop(0, '#ffffff');
    sunGrad.addColorStop(0.35, '#fef08a');
    sunGrad.addColorStop(1, 'rgba(254, 240, 138, 0)');
    dctx.fillStyle = sunGrad;
    dctx.beginPath();
    dctx.arc(160, 60, 55, 0, Math.PI * 2);
    dctx.fill();

    // Fluffy PS1-style Clouds
    dctx.fillStyle = 'rgba(255, 255, 255, 0.9)';
    const drawCloud = (cx, cy, s) => {
      dctx.beginPath();
      dctx.arc(cx, cy, 22 * s, 0, Math.PI * 2);
      dctx.arc(cx + 25 * s, cy - 8 * s, 28 * s, 0, Math.PI * 2);
      dctx.arc(cx + 55 * s, cy - 4 * s, 24 * s, 0, Math.PI * 2);
      dctx.arc(cx + 75 * s, cy + 5 * s, 18 * s, 0, Math.PI * 2);
      dctx.fill();
    };
    drawCloud(60, 95, 0.8);
    drawCloud(280, 75, 1.1);
    drawCloud(420, 110, 0.7);

    // Lush Green Hills & Pines on the horizon
    dctx.fillStyle = '#15803d';
    dctx.beginPath();
    dctx.moveTo(0, 256);
    for (let x = 0; x <= 512; x += 24) {
      const h = 35 + Math.sin(x * 0.05) * 18 + Math.cos(x * 0.1) * 8;
      dctx.lineTo(x, 256 - h);
    }
    dctx.lineTo(512, 256);
    dctx.closePath();
    dctx.fill();

    const dayTex = new THREE.CanvasTexture(dayCanvas);
    this.daySkyPlane = new THREE.Mesh(
      new THREE.PlaneGeometry(16, 7),
      new THREE.MeshBasicMaterial({ map: dayTex })
    );
    this.daySkyPlane.position.set(0, 2.5, 7.5);
    this.daySkyPlane.rotation.y = Math.PI;
    this.daySkyPlane.visible = true;
    this.scene.add(this.daySkyPlane);

    // =======================================================================
    // ELECTRICAL CIRCUIT BREAKER BOX (On back wall, for blackout repairs!)
    // =======================================================================
    const breakerBoxGroup = new THREE.Group();
    breakerBoxGroup.position.set(4.4, 2.0, 4.25);
    breakerBoxGroup.rotation.y = Math.PI;
    this.officeGroup.add(breakerBoxGroup);

    // Metal box with hazard stripes
    const bBox = new THREE.Mesh(
      new THREE.BoxGeometry(0.85, 1.2, 0.25),
      new THREE.MeshLambertMaterial({ color: 0x1e293b, map: this.textures.hazard })
    );
    breakerBoxGroup.add(bBox);

    // Breaker Main Handle (Clicks up/down)
    this.breakerLever = new THREE.Mesh(
      new THREE.BoxGeometry(0.18, 0.35, 0.18),
      new THREE.MeshLambertMaterial({ color: 0xef4444 })
    );
    this.breakerLever.position.set(0, 0.05, 0.15);
    this.breakerLever.userData = { action: 'flipBreaker', hint: 'Врубить рубильник [КЛИК]' };
    breakerBoxGroup.add(this.breakerLever);
    this.interactables.push(this.breakerLever);
  }

  // =========================================================================
  // INTERACTIVE LOCKER / CABINET WITH "AZAMAT SASI" EASTER EGG NOTE
  // =========================================================================
  _buildInteractiveCabinet() {
    this.cabinetGroup = new THREE.Group();
    // Positioned on the back wall to the left of the window (x = -4.2, y = 1.35, z = 4.15)
    this.cabinetGroup.position.set(-4.2, 1.35, 4.15);
    this.cabinetGroup.rotation.y = Math.PI;
    this.officeGroup.add(this.cabinetGroup);

    // Cabinet Outer Metal Frame / Locker Shell
    const lockerMat = new THREE.MeshLambertMaterial({ color: 0x1e293b });
    const lockerBack = new THREE.Mesh(new THREE.BoxGeometry(0.88, 2.65, 0.04), lockerMat);
    lockerBack.position.set(0, 0, 0.3);
    this.cabinetGroup.add(lockerBack);

    const lockerTop = new THREE.Mesh(new THREE.BoxGeometry(0.88, 0.04, 0.62), lockerMat);
    lockerTop.position.set(0, 1.31, 0);
    this.cabinetGroup.add(lockerTop);

    const lockerBottom = new THREE.Mesh(new THREE.BoxGeometry(0.88, 0.04, 0.62), lockerMat);
    lockerBottom.position.set(0, -1.31, 0);
    this.cabinetGroup.add(lockerBottom);

    const lockerSideL = new THREE.Mesh(new THREE.BoxGeometry(0.04, 2.65, 0.62), lockerMat);
    lockerSideL.position.set(-0.43, 0, 0);
    this.cabinetGroup.add(lockerSideL);

    const lockerSideR = new THREE.Mesh(new THREE.BoxGeometry(0.04, 2.65, 0.62), lockerMat);
    lockerSideR.position.set(0.43, 0, 0);
    this.cabinetGroup.add(lockerSideR);

    // Middle shelf
    const lockerShelf = new THREE.Mesh(new THREE.BoxGeometry(0.86, 0.03, 0.58), lockerMat);
    lockerShelf.position.set(0, -0.2, 0);
    this.cabinetGroup.add(lockerShelf);

    // Pinned Note: "AZAMAT SASI" with funny smiley and red pin
    const noteCanvas = document.createElement('canvas');
    noteCanvas.width = 256;
    noteCanvas.height = 256;
    const nctx = noteCanvas.getContext('2d');
    nctx.fillStyle = '#fef9c3'; // light yellow sticky/crumpled paper
    nctx.fillRect(0, 0, 256, 256);
    nctx.strokeStyle = '#ca8a04';
    nctx.lineWidth = 6;
    nctx.strokeRect(6, 6, 244, 244);

    // Red push pin
    nctx.fillStyle = '#ef4444';
    nctx.beginPath();
    nctx.arc(128, 26, 12, 0, Math.PI * 2);
    nctx.fill();

    // Bold text
    nctx.fillStyle = '#dc2626';
    nctx.font = 'bold 36px monospace';
    nctx.textAlign = 'center';
    nctx.fillText('AZAMAT', 128, 90);
    nctx.fillText('SASI', 128, 140);

    nctx.fillStyle = '#0f172a';
    nctx.font = 'bold 26px sans-serif';
    nctx.fillText('( ͡° ͜ʖ ͡°)', 128, 188);

    nctx.fillStyle = '#475569';
    nctx.font = 'bold 15px monospace';
    nctx.fillText('ПРОД НЕ УПАДЁТ!', 128, 228);

    const noteTex = new THREE.CanvasTexture(noteCanvas);
    const noteMesh = new THREE.Mesh(
      new THREE.PlaneGeometry(0.58, 0.58),
      new THREE.MeshBasicMaterial({ map: noteTex })
    );
    noteMesh.position.set(0, 0.45, 0.27);
    this.cabinetGroup.add(noteMesh);

    // Hinged Cabinet Door (Pivots from left hinge at x = -0.42, z = -0.3)
    this.cabinetDoorGroup = new THREE.Group();
    this.cabinetDoorGroup.position.set(-0.43, 0, -0.3);
    this.cabinetGroup.add(this.cabinetDoorGroup);

    const doorMat = new THREE.MeshLambertMaterial({ color: 0x334155 });
    const doorLeaf = new THREE.Mesh(new THREE.BoxGeometry(0.85, 2.6, 0.04), doorMat);
    doorLeaf.position.set(0.425, 0, 0); // leaf offset relative to hinge
    this.cabinetDoorGroup.add(doorLeaf);

    // Door Handle
    const handleMat = new THREE.MeshLambertMaterial({ color: 0x94a3b8 });
    const handle = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.28, 0.08), handleMat);
    handle.position.set(0.8, 0, -0.04);
    doorLeaf.add(handle);

    // Click target on cabinet door
    doorLeaf.userData = { action: 'toggleCabinet', hint: '🚪 Шкафчик дежурного [КЛИК]' };
    this.interactables.push(doorLeaf);
  }

  setCabinetOpen(isOpen) {
    this.cabinetOpen = !!isOpen;
    this.targetCabinetAngle = this.cabinetOpen ? -Math.PI * 0.58 : 0;
  }

  _buildLeftDoorway() {
    const wallMat = new THREE.MeshLambertMaterial({ color: 0x18202c });

    // Left door frame
    const leftDoorL = new THREE.Mesh(new THREE.BoxGeometry(0.4, 4.0, 3.2), wallMat);
    leftDoorL.position.set(-5.5, 2.0, 1.4);
    this.officeGroup.add(leftDoorL);

    const leftDoorR = new THREE.Mesh(new THREE.BoxGeometry(0.4, 4.0, 3.2), wallMat);
    leftDoorR.position.set(-5.5, 2.0, -2.4);
    this.officeGroup.add(leftDoorR);

    const leftDoorTop = new THREE.Mesh(new THREE.BoxGeometry(0.4, 1.2, 2.6), wallMat);
    leftDoorTop.position.set(-5.5, 3.4, -0.5);
    this.officeGroup.add(leftDoorTop);

    // Left Blast Door
    const bDoorGeo = new THREE.BoxGeometry(0.18, 2.8, 2.4);
    const doorMat = new THREE.MeshLambertMaterial({ color: 0x475569, map: this.textures.hazard });
    this.leftDoorMesh = new THREE.Mesh(bDoorGeo, doorMat);
    this.leftDoorMesh.position.set(-5.5, 4.2, -0.5);
    this.officeGroup.add(this.leftDoorMesh);

    // Left Button Panel (Door red button, Light white button)
    const btnBox = new THREE.Mesh(
      new THREE.BoxGeometry(0.1, 0.75, 0.4),
      new THREE.MeshLambertMaterial({ color: 0x0f172a })
    );
    btnBox.position.set(-5.25, 1.6, -1.8);
    this.officeGroup.add(btnBox);

    // Red Door Button
    const btnDoor = new THREE.Mesh(
      new THREE.CylinderGeometry(0.08, 0.08, 0.08, 8),
      new THREE.MeshLambertMaterial({ color: 0xef4444 })
    );
    btnDoor.rotation.z = Math.PI / 2;
    btnDoor.position.set(-5.18, 1.78, -1.8);
    btnDoor.userData = { action: 'toggleGateLeft', hint: 'Шлюз Порт 22 [Q]' };
    this.officeGroup.add(btnDoor);
    this.interactables.push(btnDoor);

    // Light Button
    const btnLight = new THREE.Mesh(
      new THREE.CylinderGeometry(0.08, 0.08, 0.08, 8),
      new THREE.MeshLambertMaterial({ color: 0x38bdf8 })
    );
    btnLight.rotation.z = Math.PI / 2;
    btnLight.position.set(-5.18, 1.45, -1.8);
    btnLight.userData = { action: 'pingLeft', hint: 'Пинг Шлюза 22 [A]' };
    this.officeGroup.add(btnLight);
    this.interactables.push(btnLight);
  }

  _buildRightDoorway() {
    const wallMat = new THREE.MeshLambertMaterial({ color: 0x18202c });

    const rightDoorL = new THREE.Mesh(new THREE.BoxGeometry(0.4, 4.0, 3.2), wallMat);
    rightDoorL.position.set(5.5, 2.0, 1.4);
    this.officeGroup.add(rightDoorL);

    const rightDoorR = new THREE.Mesh(new THREE.BoxGeometry(0.4, 4.0, 3.2), wallMat);
    rightDoorR.position.set(5.5, 2.0, -2.4);
    this.officeGroup.add(rightDoorR);

    const rightDoorTop = new THREE.Mesh(new THREE.BoxGeometry(0.4, 1.2, 2.6), wallMat);
    rightDoorTop.position.set(5.5, 3.4, -0.5);
    this.officeGroup.add(rightDoorTop);

    // Right Blast Door
    const bDoorGeo = new THREE.BoxGeometry(0.18, 2.8, 2.4);
    const doorMat = new THREE.MeshLambertMaterial({ color: 0x475569, map: this.textures.hazard });
    this.rightDoorMesh = new THREE.Mesh(bDoorGeo, doorMat);
    this.rightDoorMesh.position.set(5.5, 4.2, -0.5);
    this.officeGroup.add(this.rightDoorMesh);

    // Right Button Panel
    const btnBox = new THREE.Mesh(
      new THREE.BoxGeometry(0.1, 0.75, 0.4),
      new THREE.MeshLambertMaterial({ color: 0x0f172a })
    );
    btnBox.position.set(5.25, 1.6, -1.8);
    this.officeGroup.add(btnBox);

    const btnDoor = new THREE.Mesh(
      new THREE.CylinderGeometry(0.08, 0.08, 0.08, 8),
      new THREE.MeshLambertMaterial({ color: 0xef4444 })
    );
    btnDoor.rotation.z = Math.PI / 2;
    btnDoor.position.set(5.18, 1.78, -1.8);
    btnDoor.userData = { action: 'toggleGateRight', hint: 'Шлюз Порт 5432 [E]' };
    this.officeGroup.add(btnDoor);
    this.interactables.push(btnDoor);

    const btnLight = new THREE.Mesh(
      new THREE.CylinderGeometry(0.08, 0.08, 0.08, 8),
      new THREE.MeshLambertMaterial({ color: 0x38bdf8 })
    );
    btnLight.rotation.z = Math.PI / 2;
    btnLight.position.set(5.18, 1.45, -1.8);
    btnLight.userData = { action: 'pingRight', hint: 'Пинг Шлюза 5432 [D]' };
    this.officeGroup.add(btnLight);
    this.interactables.push(btnLight);
  }

  _buildDesk() {
    const deskGroup = new THREE.Group();
    deskGroup.position.set(0, 0, -1.5);
    this.officeGroup.add(deskGroup);

    // Table Top
    const deskTop = new THREE.Mesh(
      new THREE.BoxGeometry(4.4, 0.12, 1.8),
      new THREE.MeshLambertMaterial({ color: 0x1a222d })
    );
    deskTop.position.set(0, 0.95, 0);
    deskGroup.add(deskTop);

    // Desk Legs
    const legGeo = new THREE.BoxGeometry(0.1, 0.95, 0.1);
    const legMat = new THREE.MeshLambertMaterial({ color: 0x0f172a });
    [[-2.0, 0.47, -0.75], [2.0, 0.47, -0.75], [-2.0, 0.47, 0.75], [2.0, 0.47, 0.75]].forEach(([x, y, z]) => {
      const leg = new THREE.Mesh(legGeo, legMat);
      leg.position.set(x, y, z);
      deskGroup.add(leg);
    });

    // 1. CRT IDE Monitor (Center)
    const monitorCase = new THREE.Mesh(
      new THREE.BoxGeometry(1.25, 0.9, 0.65),
      new THREE.MeshLambertMaterial({ color: 0x1e293b })
    );
    monitorCase.position.set(0, 1.5, -0.15);
    deskGroup.add(monitorCase);

    const screenGeo = new THREE.PlaneGeometry(1.05, 0.72);
    const screenMat = new THREE.MeshBasicMaterial({ map: this.crtTexture });
    this.crtScreenMesh = new THREE.Mesh(screenGeo, screenMat);
    this.crtScreenMesh.position.set(0, 1.5, 0.18);
    this.crtScreenMesh.userData = { action: 'writePatch', hint: 'Пилить патч [ПРОБЕЛ/КЛИК]' };
    deskGroup.add(this.crtScreenMesh);
    this.interactables.push(this.crtScreenMesh);

    // Keyboard
    const kb = new THREE.Mesh(
      new THREE.BoxGeometry(0.85, 0.04, 0.32),
      new THREE.MeshLambertMaterial({ color: 0x090d16 })
    );
    kb.position.set(0, 1.03, 0.4);
    kb.userData = { action: 'writePatch', hint: 'Печатать код [ПРОБЕЛ]' };
    deskGroup.add(kb);
    this.interactables.push(kb);

    // 2. Desk Fan (Left)
    const fanGroup = new THREE.Group();
    fanGroup.position.set(-1.6, 1.01, -0.15);
    deskGroup.add(fanGroup);

    const fanBase = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.22, 0.06, 12), new THREE.MeshLambertMaterial({ color: 0x0f172a }));
    fanBase.position.y = 0.03;
    fanGroup.add(fanBase);

    this.fanBlades = new THREE.Group();
    this.fanBlades.position.set(0, 0.38, 0.07);
    for (let b = 0; b < 3; b++) {
      const blade = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.32, 0.015), new THREE.MeshLambertMaterial({ color: 0x64748b }));
      blade.rotation.z = (b * Math.PI * 2) / 3;
      this.fanBlades.add(blade);
    }
    fanGroup.add(this.fanBlades);

    // 3. TOXIC GAS VALVE WHEEL (Left side of desk, mouse-rotatable!)
    const valveGroup = new THREE.Group();
    valveGroup.position.set(-1.65, 1.05, 0.45);
    deskGroup.add(valveGroup);

    // Pipe
    const pipe = new THREE.Mesh(
      new THREE.CylinderGeometry(0.06, 0.06, 0.35, 8),
      new THREE.MeshLambertMaterial({ color: 0x475569 })
    );
    pipe.position.y = 0.17;
    valveGroup.add(pipe);

    // Red Valve Handwheel (Torus + Crossbars)
    this.gasValveWheel = new THREE.Group();
    this.gasValveWheel.position.y = 0.35;
    const rim = new THREE.Mesh(
      new THREE.TorusGeometry(0.18, 0.03, 8, 16),
      new THREE.MeshLambertMaterial({ color: 0xdc2626 }) // Red emergency wheel
    );
    rim.rotation.x = Math.PI / 2;
    this.gasValveWheel.add(rim);

    for (let s = 0; s < 4; s++) {
      const spoke = new THREE.Mesh(
        new THREE.BoxGeometry(0.03, 0.03, 0.36),
        new THREE.MeshLambertMaterial({ color: 0xf87171 })
      );
      spoke.rotation.y = (s * Math.PI) / 4;
      this.gasValveWheel.add(spoke);
    }

    this.gasValveWheel.userData = { action: 'spinGasValve', hint: 'Крутить вентиль газа по кругу!' };
    valveGroup.add(this.gasValveWheel);
    this.interactables.push(this.gasValveWheel);

    // 4. SYNTHETIC 3D BIOPRINTER (Carrot generator on right side!)
    const printGroup = new THREE.Group();
    printGroup.position.set(1.5, 1.01, -0.2);
    deskGroup.add(printGroup);

    this.printerMesh = new THREE.Mesh(
      new THREE.BoxGeometry(0.65, 0.45, 0.65),
      new THREE.MeshLambertMaterial({ color: 0x1e293b, map: this.textures.hazard })
    );
    this.printerMesh.position.y = 0.23;
    this.printerMesh.userData = { action: 'printCarrot', hint: 'Печать морковки для Трояна [КЛИК]' };
    printGroup.add(this.printerMesh);
    this.interactables.push(this.printerMesh);

    // Hologram / Printed Carrot inside printer chamber
    this.carrotHologram = new THREE.Group();
    this.carrotHologram.position.set(0, 0.28, 0);
    const carrotBody = new THREE.Mesh(
      new THREE.ConeGeometry(0.08, 0.26, 6),
      new THREE.MeshLambertMaterial({ color: 0xf97316 })
    );
    carrotBody.rotation.x = Math.PI;
    this.carrotHologram.add(carrotBody);

    const carrotGreens = new THREE.Mesh(
      new THREE.ConeGeometry(0.05, 0.12, 4),
      new THREE.MeshLambertMaterial({ color: 0x22c55e })
    );
    carrotGreens.position.y = 0.16;
    this.carrotHologram.add(carrotGreens);
    this.carrotHologram.userData = { action: 'printCarrot', hint: 'Печать морковки для Трояна' };
    printGroup.add(this.carrotHologram);
    this.interactables.push(this.carrotHologram);

    // 5. Pukanometer Dial Gauge
    const gaugeGroup = new THREE.Group();
    gaugeGroup.position.set(0.75, 1.01, 0.4);
    deskGroup.add(gaugeGroup);

    const gaugeBody = new THREE.Mesh(
      new THREE.CylinderGeometry(0.16, 0.18, 0.06, 12),
      new THREE.MeshLambertMaterial({ color: 0x0f172a })
    );
    gaugeBody.position.y = 0.03;
    gaugeGroup.add(gaugeBody);

    this.pukanDialNeedle = new THREE.Mesh(
      new THREE.BoxGeometry(0.015, 0.12, 0.01),
      new THREE.MeshBasicMaterial({ color: 0xf59e0b })
    );
    this.pukanDialNeedle.position.set(0, 0.07, 0);
    this.pukanDialNeedle.rotation.x = -Math.PI / 2;
    gaugeGroup.add(this.pukanDialNeedle);

    // 6. Yellow Rubber Duck (Desk Easter Egg / Pukan cooling)
    this.rubberDuck = new THREE.Group();
    this.rubberDuck.position.set(-0.65, 1.02, 0.35);
    deskGroup.add(this.rubberDuck);

    const duckMat = new THREE.MeshLambertMaterial({ color: 0xfacc15 }); // bright rubber yellow
    const duckBody = new THREE.Mesh(new THREE.SphereGeometry(0.09, 8, 8), duckMat);
    duckBody.scale.set(1, 0.85, 1.25);
    duckBody.position.y = 0.08;
    this.rubberDuck.add(duckBody);

    const duckHead = new THREE.Mesh(new THREE.SphereGeometry(0.065, 8, 8), duckMat);
    duckHead.position.set(0, 0.17, 0.05);
    this.rubberDuck.add(duckHead);

    const beakMat = new THREE.MeshLambertMaterial({ color: 0xf97316 }); // orange beak
    const beak = new THREE.Mesh(new THREE.ConeGeometry(0.03, 0.06, 6), beakMat);
    beak.rotation.x = Math.PI * 0.45;
    beak.position.set(0, 0.16, 0.12);
    this.rubberDuck.add(beak);

    const eyeMat = new THREE.MeshBasicMaterial({ color: 0x0f172a });
    const eyeL = new THREE.Mesh(new THREE.SphereGeometry(0.012, 6, 6), eyeMat);
    eyeL.position.set(-0.035, 0.18, 0.09);
    this.rubberDuck.add(eyeL);
    const eyeR = new THREE.Mesh(new THREE.SphereGeometry(0.012, 6, 6), eyeMat);
    eyeR.position.set(0.035, 0.18, 0.09);
    this.rubberDuck.add(eyeR);

    duckBody.userData = { action: 'clickDuck', hint: '🦆 Крякнуть резиновой уточкой [КЛИК]' };
    duckHead.userData = { action: 'clickDuck', hint: '🦆 Крякнуть резиновой уточкой [КЛИК]' };
    this.interactables.push(duckBody, duckHead);

    // 7. Coffee Mug (Desk Easter Egg / Power boost)
    this.coffeeMug = new THREE.Group();
    this.coffeeMug.position.set(0.65, 1.02, 0.35);
    deskGroup.add(this.coffeeMug);

    const mugMat = new THREE.MeshLambertMaterial({ color: 0x38bdf8 }); // dev cyan ceramic
    const mugCup = new THREE.Mesh(new THREE.CylinderGeometry(0.075, 0.065, 0.15, 12), mugMat);
    mugCup.position.y = 0.08;
    this.coffeeMug.add(mugCup);

    const coffeeMat = new THREE.MeshBasicMaterial({ color: 0x2b1509 }); // dark coffee
    const coffeeLiquid = new THREE.Mesh(new THREE.CylinderGeometry(0.065, 0.065, 0.01, 10), coffeeMat);
    coffeeLiquid.position.y = 0.14;
    this.coffeeMug.add(coffeeLiquid);

    const handleMat = new THREE.MeshLambertMaterial({ color: 0x38bdf8 });
    const handle = new THREE.Mesh(new THREE.TorusGeometry(0.045, 0.015, 6, 8, Math.PI), handleMat);
    handle.position.set(0.075, 0.08, 0);
    this.coffeeMug.add(handle);

    mugCup.userData = { action: 'drinkCoffee', hint: '☕ Выпить бодрящий кофе [КЛИК]' };
    this.interactables.push(mugCup);
  }

  // =========================================================================
  // THE 4 REAL MONSTERS: Distortion Giant, Bug-Tadpole, Trojan T-Pose, Burgundy
  // =========================================================================
  _buildMonsters() {
    // 1. DISTORTION GIANT («Исказитель / Архитектор Хуйло»)
    // Tall disproportionate dark shadowy mesh with glowing piercing eyes
    this.monsters3D.distortion = new THREE.Group();
    const distMat = new THREE.MeshBasicMaterial({ color: 0x05070a });
    const eyeGlow = new THREE.MeshBasicMaterial({ color: 0x38bdf8 }); // piercing cyan-white glare

    const dBody = new THREE.Mesh(new THREE.BoxGeometry(1.2, 3.2, 0.6), distMat);
    dBody.position.y = 1.9;
    this.monsters3D.distortion.add(dBody);

    const dHead = new THREE.Mesh(new THREE.BoxGeometry(0.85, 1.1, 0.8), distMat);
    dHead.position.y = 3.9;
    this.monsters3D.distortion.add(dHead);

    // Piercing Eyes
    const eye1 = new THREE.Mesh(new THREE.SphereGeometry(0.12, 8, 8), eyeGlow);
    eye1.position.set(-0.25, 4.0, 0.42);
    this.monsters3D.distortion.add(eye1);

    const eye2 = new THREE.Mesh(new THREE.SphereGeometry(0.12, 8, 8), eyeGlow);
    eye2.position.set(0.25, 4.0, 0.42);
    this.monsters3D.distortion.add(eye2);

    this.monsters3D.distortion.visible = false;
    this.scene.add(this.monsters3D.distortion);

    // 2. BUG-TADPOLE («Багогрыз-Головастик»)
    // Disgusting small hybrid of rat, tadpole and inkblot that scuttles on desk!
    this.monsters3D.tadpole = new THREE.Group();
    const tadMat = new THREE.MeshLambertMaterial({ color: 0x1e1b4b }); // dark purple-black slime
    const tEyeMat = new THREE.MeshBasicMaterial({ color: 0xf43f5e });

    const tBody = new THREE.Mesh(new THREE.SphereGeometry(0.16, 8, 8), tadMat);
    tBody.scale.set(1.4, 0.9, 1.0);
    this.monsters3D.tadpole.add(tBody);

    // Twitching tail
    const tTail = new THREE.Mesh(new THREE.ConeGeometry(0.08, 0.4, 5), tadMat);
    tTail.rotation.x = Math.PI / 2;
    tTail.position.set(0, 0, -0.25);
    this.monsters3D.tadpole.add(tTail);

    const tEyeL = new THREE.Mesh(new THREE.SphereGeometry(0.045, 6, 6), tEyeMat);
    tEyeL.position.set(-0.08, 0.08, 0.14);
    this.monsters3D.tadpole.add(tEyeL);

    const tEyeR = new THREE.Mesh(new THREE.SphereGeometry(0.045, 6, 6), tEyeMat);
    tEyeR.position.set(0.08, 0.08, 0.14);
    this.monsters3D.tadpole.add(tEyeR);

    this.monsters3D.tadpole.position.set(0, 1.08, -1.2);
    this.monsters3D.tadpole.userData = { action: 'hitTadpole', hint: 'ПРИБИТЬ БАГОГРЫЗА [КЛИК!]' };
    this.monsters3D.tadpole.visible = false;
    this.scene.add(this.monsters3D.tadpole);
    this.interactables.push(this.monsters3D.tadpole);

    // 3. TROJAN HORSE.EXE («Троянский Конь в T-Pose»)
    // Hilarious yet scary wooden horse in completely rigid motionless T-pose!
    this.monsters3D.trojan = new THREE.Group();
    const woodMat = new THREE.MeshLambertMaterial({ color: 0x78350f }); // rustic wood planks
    const wheelMat = new THREE.MeshLambertMaterial({ color: 0x1c1917 });

    // Horse Body
    const hBody = new THREE.Mesh(new THREE.BoxGeometry(1.4, 1.2, 2.4), woodMat);
    hBody.position.y = 1.6;
    this.monsters3D.trojan.add(hBody);

    // Long Neck & Wooden Head
    const hNeck = new THREE.Mesh(new THREE.BoxGeometry(0.55, 1.4, 0.7), woodMat);
    hNeck.position.set(0, 2.6, 0.95);
    hNeck.rotation.x = -Math.PI * 0.15;
    this.monsters3D.trojan.add(hNeck);

    const hHead = new THREE.Mesh(new THREE.BoxGeometry(0.65, 0.65, 1.1), woodMat);
    hHead.position.set(0, 3.2, 1.45);
    this.monsters3D.trojan.add(hHead);

    // Glowing creepy horse eye
    const hEye = new THREE.Mesh(new THREE.SphereGeometry(0.09, 6, 6), new THREE.MeshBasicMaterial({ color: 0xef4444 }));
    hEye.position.set(0, 3.3, 1.7);
    this.monsters3D.trojan.add(hEye);

    // Pure T-Pose Rigid Wooden Arms (sticking straight out!)
    const armL = new THREE.Mesh(new THREE.BoxGeometry(1.6, 0.25, 0.25), woodMat);
    armL.position.set(-1.4, 2.0, 0.4);
    this.monsters3D.trojan.add(armL);

    const armR = new THREE.Mesh(new THREE.BoxGeometry(1.6, 0.25, 0.25), woodMat);
    armR.position.set(1.4, 2.0, 0.4);
    this.monsters3D.trojan.add(armR);

    // 4 Wheels (non-rotating, just sliding!)
    [[-0.75, 0.4, 0.8], [0.75, 0.4, 0.8], [-0.75, 0.4, -0.8], [0.75, 0.4, -0.8]].forEach(([x, y, z]) => {
      const w = new THREE.Mesh(new THREE.CylinderGeometry(0.35, 0.35, 0.12, 10), wheelMat);
      w.rotation.z = Math.PI / 2;
      w.position.set(x, y, z);
      this.monsters3D.trojan.add(w);
    });

    this.monsters3D.trojan.visible = false;
    this.scene.add(this.monsters3D.trojan);

    // 4. BURGUNDY VENT STALKER («Бордовый Душегуб»)
    // Fast, sharp teeth, reptilian body that sneaks through vents
    this.monsters3D.burgundy = new THREE.Group();
    const burgMat = new THREE.MeshLambertMaterial({ color: 0x881337 }); // злобно-бордовый
    const bEye = new THREE.MeshBasicMaterial({ color: 0xfacc15 });

    const bTorso = new THREE.Mesh(new THREE.BoxGeometry(0.9, 1.2, 0.6), burgMat);
    bTorso.position.y = 1.4;
    this.monsters3D.burgundy.add(bTorso);

    const bHead = new THREE.Mesh(new THREE.ConeGeometry(0.48, 0.9, 5), burgMat);
    bHead.rotation.x = Math.PI / 2;
    bHead.position.set(0, 2.2, 0.2);
    this.monsters3D.burgundy.add(bHead);

    const bEye1 = new THREE.Mesh(new THREE.SphereGeometry(0.08, 6, 6), bEye);
    bEye1.position.set(-0.2, 2.3, 0.45);
    this.monsters3D.burgundy.add(bEye1);

    const bEye2 = new THREE.Mesh(new THREE.SphereGeometry(0.08, 6, 6), bEye);
    bEye2.position.set(0.2, 2.3, 0.45);
    this.monsters3D.burgundy.add(bEye2);

    this.monsters3D.burgundy.visible = false;
    this.scene.add(this.monsters3D.burgundy);
  }

  _setupLighting() {
    // Ambient light
    this.ambientLight = new THREE.AmbientLight(0x0a101d, 0.7);
    this.scene.add(this.ambientLight);

    // Overhead Office Fluorescent Light
    this.officeLight = new THREE.PointLight(0xe2e8f0, 1.5, 14, 1.8);
    this.officeLight.position.set(0, 3.6, 0);
    this.scene.add(this.officeLight);

    // Night sky cool blue rim light from back window
    this.nightSkyLight = new THREE.DirectionalLight(0x1e3a8a, 0.65);
    this.nightSkyLight.position.set(0, 3.0, 7.0);
    this.nightSkyLight.target.position.set(0, 1.5, 0);
    this.scene.add(this.nightSkyLight);
    this.scene.add(this.nightSkyLight.target);

    // Warm natural sunlight from window during daytime
    this.sunLight = new THREE.DirectionalLight(0xfef08a, 0.0);
    this.sunLight.position.set(0, 3.5, 7.5);
    this.sunLight.target.position.set(0, 1.2, 0);
    this.scene.add(this.sunLight);
    this.scene.add(this.sunLight.target);

    // Spotlights for doors
    this.leftSpotlight = new THREE.SpotLight(0xffffff, 0, 15, Math.PI / 4, 0.4);
    this.leftSpotlight.position.set(-5.2, 2.6, -0.5);
    this.leftSpotlight.target.position.set(-10, 1.2, -0.5);
    this.scene.add(this.leftSpotlight);
    this.scene.add(this.leftSpotlight.target);

    this.rightSpotlight = new THREE.SpotLight(0xffffff, 0, 15, Math.PI / 4, 0.4);
    this.rightSpotlight.position.set(5.2, 2.6, -0.5);
    this.rightSpotlight.target.position.set(10, 1.2, -0.5);
    this.scene.add(this.rightSpotlight);
    this.scene.add(this.rightSpotlight.target);

    // Emergency Red Strobe
    this.alarmStrobe = new THREE.PointLight(0xef4444, 0, 16, 1.5);
    this.alarmStrobe.position.set(0, 3.4, 0);
    this.scene.add(this.alarmStrobe);
  }

  setDaytime(isDay) {
    this.isDaytime = !!isDay;
    if (this.daySkyPlane && this.nightSkyPlane) {
      this.daySkyPlane.visible = this.isDaytime;
      this.nightSkyPlane.visible = !this.isDaytime;
    }

    if (this.ambientLight) {
      if (this.isDaytime) {
        this.ambientLight.color.setHex(0xffffff);
        this.ambientLight.intensity = 1.05;
      } else {
        this.ambientLight.color.setHex(0x0a101d);
        this.ambientLight.intensity = 0.7;
      }
    }

    if (this.sunLight) {
      this.sunLight.intensity = this.isDaytime ? 1.6 : 0.0;
    }

    if (this.nightSkyLight) {
      this.nightSkyLight.intensity = this.isDaytime ? 0.0 : 0.65;
    }

    if (this.officeLight) {
      this.officeLight.intensity = this.isDaytime ? 0.75 : 1.45;
    }

    if (this.alarmStrobe && this.isDaytime) {
      this.alarmStrobe.intensity = 0;
    }

    // Hide all monsters during daytime
    if (this.isDaytime) {
      if (this.monsters3D.distortion) this.monsters3D.distortion.visible = false;
      if (this.monsters3D.tadpole) this.monsters3D.tadpole.visible = false;
      if (this.monsters3D.trojan) this.monsters3D.trojan.visible = false;
      if (this.monsters3D.burgundy) this.monsters3D.burgundy.visible = false;
    }
  }

  // =========================================================================
  // 360° MOUSE LOOK & DRAGGABLE CONTROLS
  // =========================================================================
  _setupListeners() {
    // 360° Mouse Look
    window.addEventListener('mousedown', (e) => {
      this.isDragging = true;
      this.prevMouseX = e.clientX;
      this.prevMouseY = e.clientY;
    });

    window.addEventListener('mouseup', () => {
      this.isDragging = false;
      this.isDraggingValve = false;
    });

    window.addEventListener('mousemove', (e) => {
      const rect = this.container.getBoundingClientRect();
      this.mouseVec.x = ((e.clientX - rect.left) / rect.width) * 2 - 1;
      this.mouseVec.y = -((e.clientY - rect.top) / rect.height) * 2 + 1;

      // Mouse drag look (or hovering towards edges)
      if (this.isDragging && !window.prodGame?.cctvOpen) {
        const dx = e.clientX - this.prevMouseX;
        const dy = e.clientY - this.prevMouseY;
        this.prevMouseX = e.clientX;
        this.prevMouseY = e.clientY;

        // Smooth full 360° yaw rotation!
        this.targetYaw -= dx * 0.0055;
        this.targetPitch = Math.max(-0.65, Math.min(0.65, this.targetPitch - dy * 0.0045));
      } else if (!window.prodGame?.cctvOpen) {
        // Subtle edge glance
        const edgeX = (e.clientX / window.innerWidth) - 0.5;
        if (Math.abs(edgeX) > 0.35) {
          this.targetYaw -= edgeX * 0.015;
        }
      }

      // Check gas valve circular dragging
      if (this.isDraggingValve && window.prodGame) {
        const angle = Math.atan2(e.clientY - window.innerHeight / 2, e.clientX - window.innerWidth / 2);
        const delta = angle - this.valveLastAngle;
        this.valveLastAngle = angle;
        window.prodGame.turnGasValve(delta);
      }

      // Hover Tooltip check
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

    // Clicks on 3D objects
    this.container.addEventListener('click', () => {
      if (!window.prodGame || (!window.prodGame.running && !window.prodGame.inLobby) || window.prodGame.cctvOpen) return;
      this.raycaster.setFromCamera(this.mouseVec, this.camera);
      const hits = this.raycaster.intersectObjects(this.interactables, true);
      if (hits.length > 0) {
        let obj = hits[0].object;
        while (obj && !obj.userData?.action && obj.parent) obj = obj.parent;
        if (obj && obj.userData?.action) {
          this._handleAction(obj.userData.action);
        }
      }
    });
  }

  _handleAction(action) {
    if (!window.prodGame) return;
    if (action === 'toggleCabinet') window.prodGame.toggleCabinet();
    else if (action === 'clickDuck') window.prodGame.clickRubberDuck();
    else if (action === 'drinkCoffee') window.prodGame.drinkCoffee();
    else if (action === 'toggleGateLeft') window.prodGame.toggleSwitch('gateLeft');
    else if (action === 'toggleGateRight') window.prodGame.toggleSwitch('gateRight');
    else if (action === 'pingLeft') window.prodGame.pingPort('left');
    else if (action === 'pingRight') window.prodGame.pingPort('right');
    else if (action === 'writePatch') window.prodGame.writePatchChunk();
    else if (action === 'printCarrot') window.prodGame.startPrintingCarrot();
    else if (action === 'hitTadpole') window.prodGame.hitTadpole();
    else if (action === 'purgeSteam') window.prodGame.purgeVentsWithSteam();
    else if (action === 'flipBreaker') window.prodGame.resetBreaker();
    else if (action === 'spinGasValve') {
      this.isDraggingValve = true;
      this.valveLastAngle = 0;
      window.prodGame.turnGasValve(Math.PI * 0.7);
    }
  }

  // Check if player's camera yaw is pointing towards a specific monster direction
  isPlayerLookingAt(dir) {
    // Normalize yaw to 0..2*PI
    const normYaw = ((this.yaw % (Math.PI * 2)) + Math.PI * 2) % (Math.PI * 2);

    if (dir === 'DOOR_LEFT') {
      // Left is around PI*0.5
      return Math.abs(normYaw - Math.PI * 0.5) < 0.45;
    } else if (dir === 'DOOR_RIGHT') {
      // Right is around PI*1.5
      return Math.abs(normYaw - Math.PI * 1.5) < 0.45;
    } else if (dir === 'HALL_FRONT') {
      // Front is around 0 or 2*PI
      return normYaw < 0.45 || normYaw > Math.PI * 2 - 0.45;
    } else if (dir === 'WINDOW_BACK') {
      // Back window is around PI
      return Math.abs(normYaw - Math.PI) < 0.55;
    }
    return false;
  }

  startJumpscare(type) {
    this.jumpscareActive = true;
    this.jumpscareType = type;
    this.jumpscareTimer = 0;

    // Pick jumpscare 3D model
    if (type === 'distortion') {
      this.jumpscareEntity = this.monsters3D.distortion;
    } else if (type === 'trojan') {
      this.jumpscareEntity = this.monsters3D.trojan;
    } else if (type === 'burgundy') {
      this.jumpscareEntity = this.monsters3D.burgundy;
    } else if (type === 'tadpole') {
      this.jumpscareEntity = this.monsters3D.tadpole;
    } else {
      this.jumpscareEntity = this.monsters3D.distortion;
    }

    if (this.jumpscareEntity) {
      this.jumpscareEntity.visible = true;
      this.jumpscareEntity.position.set(0, 0.4, -2.4);
      this.jumpscareEntity.rotation.set(0, 0, 0);
    }
  }

  _updateCRTTexture() {
    if (!this.crtCanvas) return;
    const ctx = this.crtCanvas.getContext('2d');
    ctx.fillStyle = '#05090f';
    ctx.fillRect(0, 0, 512, 384);

    // CRT scanlines
    ctx.fillStyle = 'rgba(0,0,0,0.3)';
    for (let y = 0; y < 384; y += 4) {
      ctx.fillRect(0, y, 512, 2);
    }

    const pct = window.prodGame ? Math.floor(window.prodGame.patchProgress) : 0;
    ctx.fillStyle = '#10b981';
    ctx.font = 'bold 16px monospace';
    ctx.fillText(`HOTFIX_PROD.JS [ПАТЧ: ${pct}%]`, 20, 32);

    const lines = window.prodGame ? window.prodGame.codeLines : [];
    const displayLines = lines.slice(-6);
    displayLines.forEach((l, i) => {
      ctx.fillStyle = i === displayLines.length - 1 ? '#38bdf8' : '#22c55e';
      ctx.font = '13px monospace';
      ctx.fillText(l, 20, 75 + i * 44);
    });

    if (this.crtTexture) this.crtTexture.needsUpdate = true;
  }

  animate() {
    requestAnimationFrame(() => this.animate());
    const dt = this.clock.getDelta();
    const time = this.clock.getElapsedTime();

    if (!this.initialized) return;

    // 1. Fan blades
    if (this.fanBlades) this.fanBlades.rotation.z += dt * 28;

    // 2. Blast doors sliding
    if (window.prodGame) {
      const g = window.prodGame;
      const leftY = g.switches.gateLeft ? 1.45 : 4.2;
      this.leftDoorMesh.position.y += (leftY - this.leftDoorMesh.position.y) * 0.18;

      const rightY = g.switches.gateRight ? 1.45 : 4.2;
      this.rightDoorMesh.position.y += (rightY - this.rightDoorMesh.position.y) * 0.18;

      const centerY = g.switches.gateCenter ? 1.5 : 4.2;
      this.centerDoorMesh.position.y += (centerY - this.centerDoorMesh.position.y) * 0.18;

      // Lights & Spotlights
      const leftLightOn = g.pingLeftActive || (!g.switches.gateLeft && g.power > 0 && !g.hazards.blackout);
      this.leftSpotlight.intensity = leftLightOn ? 3.5 : 0;

      const rightLightOn = g.pingRightActive || (!g.switches.gateRight && g.power > 0 && !g.hazards.blackout);
      this.rightSpotlight.intensity = rightLightOn ? 3.5 : 0;

      // Blackout Lights off
      if (g.hazards.blackout) {
        this.officeLight.intensity = 0.05;
        this.alarmStrobe.intensity = Math.sin(time * 12) > 0 ? 1.8 : 0;
        this.alarmStrobe.color.setHex(0xff0000);
      } else {
        this.officeLight.intensity = g.pukanTemp > 75 ? (Math.random() < 0.1 ? 0.4 : 1.4) : 1.45;
        this.alarmStrobe.intensity = g.pukanTemp > 75 ? 2.2 : 0;
      }

      // Pukanometer Dial Needle
      if (this.pukanDialNeedle) {
        const targetRot = -Math.PI * 0.75 + (g.pukanTemp / 100) * (Math.PI * 1.5);
        this.pukanDialNeedle.rotation.z += (targetRot - this.pukanDialNeedle.rotation.z) * 0.1;
      }

      // Bio-printer carrot hologram spin
      if (this.carrotHologram) {
        this.carrotHologram.rotation.y += dt * 3.5;
        this.carrotHologram.visible = g.hazards.printerWorking || g.hazards.carrotsCount > 0;
      }

      // Gas Valve wheel rotation
      if (this.gasValveWheel) {
        this.gasValveWheel.rotation.y = g.hazards.valveAngle;
      }

      // Breaker lever state
      if (this.breakerLever) {
        this.breakerLever.rotation.x = g.hazards.blackout ? 0.45 : -0.45;
      }

      // Ceiling Vent Grate & Tail
      if (this.ventGrate && this.burgundyTail) {
        if (g.monsters.burgundy.stage === 2) {
          this.ventGrate.position.y = 3.9 + Math.sin(time * 24) * 0.04;
          this.burgundyTail.visible = true;
          this.burgundyTail.rotation.z = Math.sin(time * 14) * 0.35;
        } else {
          this.ventGrate.position.y = 3.9;
          this.burgundyTail.visible = false;
        }
      }

      // 3. Monsters 3D Live Placements
      this._updateMonsters3D(time);
    }

    // Cabinet door animation (smooth swing open/close)
    if (this.cabinetDoorGroup) {
      this.cabinetDoorGroup.rotation.y += (this.targetCabinetAngle - this.cabinetDoorGroup.rotation.y) * 0.15;
    }

    // 4. Jumpscare Animation vs CCTV vs 360 Office Camera
    if (this.jumpscareActive) {
      this.jumpscareTimer += dt;
      if (this.jumpscareEntity) {
        this.jumpscareEntity.position.z += (-1.05 - this.jumpscareEntity.position.z) * 0.22;
        this.jumpscareEntity.position.x = (Math.random() - 0.5) * 0.18;
        this.jumpscareEntity.position.y = 0.35 + (Math.random() - 0.5) * 0.18;
      }
      this.camera.position.x = (Math.random() - 0.5) * 0.14;
      this.camera.position.y = 1.62 + (Math.random() - 0.5) * 0.14;
      if (this.jumpscareTimer > 1.6) this.jumpscareActive = false;
    } else if (window.prodGame && window.prodGame.cctvOpen) {
      // CCTV Cam View
      const camKey = window.prodGame.currentCam || 'CAM01';
      const cfg = this.camPositions[camKey] || this.camPositions.CAM01;
      this.camera.position.copy(cfg.pos);
      const camLook = cfg.lookAt.clone();
      camLook.x += Math.sin(time * 0.6) * 0.06;
      this.camera.lookAt(camLook);
    } else {
      // 360° Office Camera Look
      this.camera.position.set(0, 1.62, 0.15);

      this.yaw += (this.targetYaw - this.yaw) * 0.09;
      this.pitch += (this.targetPitch - this.pitch) * 0.09;

      const breath = Math.sin(time * 1.6) * 0.003;
      this.camera.rotation.set(this.pitch, this.yaw + breath, 0, 'YXZ');
    }

    if (Math.random() < 0.2) this._updateCRTTexture();

    this.renderer.render(this.scene, this.camera);
  }

  _updateMonsters3D(time) {
    if (this.isDaytime) {
      if (this.monsters3D.distortion) this.monsters3D.distortion.visible = false;
      if (this.monsters3D.tadpole) this.monsters3D.tadpole.visible = false;
      if (this.monsters3D.trojan) this.monsters3D.trojan.visible = false;
      if (this.monsters3D.burgundy) this.monsters3D.burgundy.visible = false;
      return;
    }
    const g = window.prodGame;
    if (!g) return;

    // A. Distortion Giant
    const dist = g.monsters.distortion;
    if (this.monsters3D.distortion) {
      if (dist.active && dist.pos !== 'NONE') {
        this.monsters3D.distortion.visible = true;
        // Vertex jitter / glitch
        this.monsters3D.distortion.position.x += (Math.random() - 0.5) * 0.04;

        if (dist.pos === 'DOOR_LEFT') {
          this.monsters3D.distortion.position.set(-6.2, 0, -0.5);
          this.monsters3D.distortion.rotation.y = Math.PI / 2;
        } else if (dist.pos === 'DOOR_RIGHT') {
          this.monsters3D.distortion.position.set(6.2, 0, -0.5);
          this.monsters3D.distortion.rotation.y = -Math.PI / 2;
        } else if (dist.pos === 'HALL_FRONT') {
          this.monsters3D.distortion.position.set(0, 0, -5.5);
          this.monsters3D.distortion.rotation.y = 0;
        } else if (dist.pos === 'WINDOW_BACK') {
          this.monsters3D.distortion.position.set(0, 0, 5.2);
          this.monsters3D.distortion.rotation.y = Math.PI;
        }
      } else {
        this.monsters3D.distortion.visible = false;
      }
    }

    // B. Bug-Tadpole on Desk
    const tad = g.monsters.tadpole;
    if (this.monsters3D.tadpole) {
      if (tad.active) {
        this.monsters3D.tadpole.visible = true;
        // Twitching & scuttling
        tad.x += Math.sin(time * 8) * 0.006;
        this.monsters3D.tadpole.position.set(tad.x, 1.08, -1.2 + Math.cos(time * 8) * 0.06);
        this.monsters3D.tadpole.rotation.y = time * 6;
      } else {
        this.monsters3D.tadpole.visible = false;
      }
    }

    // C. Trojan Horse (gliding along tunnel in pure T-pose!)
    const trojan = g.monsters.trojan;
    if (this.monsters3D.trojan) {
      if (trojan.inRoom) {
        this.monsters3D.trojan.visible = true;
        this.monsters3D.trojan.position.set(0, 0, -2.6);
        this.monsters3D.trojan.rotation.y = 0;
      } else if (g.cctvOpen && g.currentCam === 'CAM03') {
        // Seen in tunnel on CCTV!
        this.monsters3D.trojan.visible = true;
        this.monsters3D.trojan.position.set(0, 0, -10 - (trojan.distance * 0.15));
        this.monsters3D.trojan.rotation.y = 0;
      } else {
        this.monsters3D.trojan.visible = false;
      }
    }
  }
}

window.view3D = new View3D();

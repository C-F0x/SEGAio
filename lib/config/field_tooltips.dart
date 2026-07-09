/// 上游 segatools.ini 中各字段的注解文本，用于 UI 浮标提示
/// key 格式: "section_name.field_name"
const Map<String, String> fieldTooltips = {
  // ═══════════════════════════════════════
  // [vfs]
  // ═══════════════════════════════════════
  'vfs.amfs': 'Insert the path to the game AMFS directory here (contains ICF1 and ICF2)',
  'vfs.option': 'Insert the path to the game Option directory here (contains MVxx or Axxx directories)',
  'vfs.appdata': 'Create an empty directory somewhere and insert the path here.\n'
      'This directory may be shared between multiple SEGA games.\n'
      'NOTE: This has nothing to do with Windows %APPDATA%.',

  // ═══════════════════════════════════════
  // [aime]
  // ═══════════════════════════════════════
  'aime.enable': 'Enable Aime card reader assembly emulation. Disable to use a real SEGA Aime reader.',
  'aime.aimePath': 'Path to the card ID file. Create a .txt file with the 20-digit card number.',
  'aime.highBaud': 'Enable high baud rate for the card reader.',
  'aime.scan': 'Virtual-key code. If this button is held then the emulated IC card reader '
      'emulates an IC card in its proximity. Default is the Return key (0x0D).',

  // ═══════════════════════════════════════
  // [vfd]
  // ═══════════════════════════════════════
  'vfd.enable': 'Enable VFD emulation. Disable to use a real VFD GP1232A02A FUTABA assembly.',

  // ═══════════════════════════════════════
  // [dns]
  // ═══════════════════════════════════════
  'dns.default': 'Insert the hostname or IP address of the server you wish to use here.\n'
      'Note that 127.0.0.1, localhost etc are specifically rejected.',
  'dns.router': 'Overrides the target of the tenporouter.loc and bbrouter.loc hostname lookups.',

  // ═══════════════════════════════════════
  // [netenv]
  // ═══════════════════════════════════════
  'netenv.enable': 'Simulate an ideal LAN environment. This may interfere with head-to-head play.\n'
      'SEGA games are somewhat picky about their LAN environment, so leaving this enabled is recommended.',
  'netenv.addrSuffix': 'The final octet of the local host\'s IP address on the virtualized subnet.\n'
      'e.g. if the keychip subnet is 192.168.32.0 and this is 11, then the virtualized LAN IP is 192.168.32.11.',

  // ═══════════════════════════════════════
  // [keychip]
  // ═══════════════════════════════════════
  'keychip.id': 'Keychip serial number. Pattern: A\\d{2}(E|X)-(01|20)[ABCDU]\\d{8}\n'
      'e.g. A69E-01A88888888',
  'keychip.subnet': 'The /24 LAN subnet that the emulated keychip will tell the game to expect.\n'
      'If you disable netenv, set this to your LAN\'s IP subnet (must start with 192.168).',
  'keychip.region': 'Override the keychip\'s region code.\n'
      '1: JPN (Japan), 4: EXP (Export for Asian markets)',

  // ═══════════════════════════════════════
  // [pcbid]
  // ═══════════════════════════════════════
  'pcbid.serialNo': 'Set the Windows host name. Should be an ALLS MAIN ID, without the hyphen.',

  // ═══════════════════════════════════════
  // [system]
  // ═══════════════════════════════════════
  'system.enable': 'Enable ALLS system settings.',
  'system.freeplay': 'Enable freeplay mode. This will disable the coin slot and set the game to freeplay.\n'
      'Some game modes (e.g. Freedom/Time Modes) will not allow you to start a game in freeplay mode.',
  'system.dipsw1': 'LAN Install: Set to 1 on exactly one machine and 0 on all others.',
  'system.dipsw2': 'Monitor type: 0 = 120FPS, 1 = 60FPS (Chusan).',
  'system.dipsw3': 'Cab type: 0 = SP (standard), 1 = CVT (Chusan).\nSP enables VFD and eMoney.',
  'system.dipsw4': 'Seat setting bit 1. 00 = Seat 1, 10 = Seat 2, 01 = Seat 3, 11 = Seat 4.',
  'system.dipsw5': 'Seat setting bit 2. 00 = Seat 1, 10 = Seat 2, 01 = Seat 3, 11 = Seat 4.',

  // ═══════════════════════════════════════
  // [gfx]
  // ═══════════════════════════════════════
  'gfx.enable': 'Enables the graphics hook.',
  'gfx.windowed': 'Force the game to run windowed.',
  'gfx.framed': 'Add a frame to the game window if running windowed.',
  'gfx.monitor': 'Select the monitor to run the game on. (Fullscreen only, 0 = primary screen)',
  'gfx.dpiAware': 'Enable DPI awareness, preventing Windows from stretching the game window if DPI scaling > 100%.',

  // ═══════════════════════════════════════
  // LED 各板
  // ═══════════════════════════════════════
  'led15093.enable': 'Enable emulation of the 15093-06 controlled lights, which handle the '
      'air tower RGBs and the rear LED panel (billboard) on the cabinet.',
  'led15070.enable': 'Enable emulation of the 837-15070 controlled lights, which handle the cabinet and seat LEDs.',
  'led15083.enable': 'Enable emulation of the 837-15083 controlled lights, which handle the cabinet and button LEDs.',
  'led15094.enable': 'Enable emulation of the 15094 controlled lights.',
  'led.cabLedOutputPipe': 'Output billboard LED strip data to a named pipe ("\\\\.\\pipe\\chuni_led" etc).',
  'led.cabLedOutputSerial': 'Output billboard LED strip data to serial port.',
  'led.controllerLedOutputPipe': 'Output controller/slider LED data to a named pipe.',
  'led.controllerLedOutputSerial': 'Output controller/slider LED data to the serial port.',
  'led.controllerLedOutputOpeNITHM': 'Use the OpeNITHM protocol for serial LED output.',
  'led.serialPort': 'Serial port to send data to if using serial output. Default is COM5.',
  'led.serialBaud': 'Baud rate for serial data (set to 115200 if using OpeNITHM).',

  // ═══════════════════════════════════════
  // IO DLL
  // ═══════════════════════════════════════
  'aimeio.path': 'To use a custom card reader IO DLL enter its path here.\nLeave empty to use built-in keyboard input.',
  'chuniio.path': 'Custom chuniio implementation comprised of a single 32bit DLL (uses chu2to3 engine internally).',
  'chuniio.path32': 'x86 chuniio DLL path. Must be paired with path64.',
  'chuniio.path64': 'x64 chuniio DLL path. Must be paired with path32.',
  'idacio.path': 'To use a custom IDAC IO DLL enter its path here.\nLeave empty to use built-in gamepad/wheel input.',
  'ektio.path': 'To use a custom EKT IO DLL enter its path here.\nLeave empty to use built-in keyboard/gamepad input.',
  'sekitoio.path': 'To use a custom Sekito IO DLL enter its path here.\nLeave empty to use built-in keyboard/gamepad input.',
  'mu3io.path': 'To use a custom O.N.G.E.K.I. IO DLL enter its path here.\nLeave empty to use built-in keyboard/gamepad input.',
  'mai2io.path': 'To use a custom maimai DX IO DLL enter its path here.\nLeave empty to use built-in keyboard input.',

  // ═══════════════════════════════════════
  // [io3] — Chusan
  // ═══════════════════════════════════════
  'io3.test': 'Test button virtual-key code. Default is the F1 key (0x70).',
  'io3.service': 'Service button virtual-key code. Default is the F2 key (0x71).',
  'io3.coin': 'Keyboard button to increment coin counter. Default is the F3 key (0x72).',
  'io3.ir': 'Set to 0 to enable separate IR control. Default is the Space key (0x20).',

  // ═══════════════════════════════════════
  // [io4] — Mu3/IDAC/EKT/Sekito
  // ═══════════════════════════════════════
  'io4.test': 'Test button virtual-key code. Default is the F1 key (0x70).',
  'io4.service': 'Service button virtual-key code. Default is the F2 key (0x71).',
  'io4.coin': 'Keyboard button to increment coin counter. Default is the F3 key (0x72).',
  'io4.mode': 'Input API selection: "keyboard" for keys, "xinput" for gamepad, "dinput" for steering wheel.',
  'io4.mouse': 'Set "1" to enable mouse lever emulation, "0" to use XInput (Mu3).',
  'io4.restrict': 'Scales steering wheel input so max positive/negative does not exceed this value (max 128).',
  'io4.sw1': 'SW1 virtual-key code. Default is the 4 key (0x34).',
  'io4.sw2': 'SW2 virtual-key code. Default is the 5 key (0x35).',

  // ═══════════════════════════════════════
  // [xinput] — IDAC
  // ═══════════════════════════════════════
  'xinput.autoNeutral': 'Automatically reset the simulated shifter to Neutral when Start is pressed.',
  'xinput.singleStickSteering': 'Use the left thumbstick for steering instead of both sticks.',
  'xinput.linearSteering': 'Use linear steering instead of the default non-linear cubing steering.',
  'xinput.leftStickDeadzone': 'Configure deadzone for the left thumbstick (default 7849, max 32767).',
  'xinput.rightStickDeadzone': 'Configure deadzone for the right thumbstick (default 8689, max 32767).',

  // ═══════════════════════════════════════
  // [dinput] — IDAC
  // ═══════════════════════════════════════
  'dinput.deviceName': 'Name of the DirectInput wheel to use (or any substring). Leave blank for first device.',
  'dinput.pedalsName': 'Name of the DirectInput pedals to use. Leave blank if pedals are part of the wheel.',
  'dinput.shifterName': 'Name of the positional shifter to use. Leave blank to simulate using buttons.',
  'dinput.brakeAxis': 'DirectInput axis for brake. Valid: X, Y, Z, RX, RY, RZ, U, V.',
  'dinput.accelAxis': 'DirectInput axis for accelerator. Valid: X, Y, Z, RX, RY, RZ, U, V.',
  'dinput.start': 'DirectInput button number for Start (numbered from 1).',
  'dinput.viewChg': 'DirectInput button number for View Change.',
  'dinput.shiftDn': 'DirectInput button number for Shift Down.',
  'dinput.shiftUp': 'DirectInput button number for Shift Up.',
  'dinput.constantForceStrength': 'Constant force strength for centering spring effect (0-100%).',
  'dinput.damperStrength': 'Damper strength for steering wheel damper effect (0-100%).',
  'dinput.rumbleStrength': 'Rumble strength for road surface effects (0-100%).',
  'dinput.rumbleDuration': 'Rumble duration factor from ms to us.',
  'dinput.baseDamperFraction': 'Minimum amount of weight/stiffness in the wheel (even when stationary).',
  'dinput.deadband': 'Deadband granularity (0.1% per unit, max 20.0%, default 20 = 2.0%).',

  // ═══════════════════════════════════════
  // [ffb] — IDAC
  // ═══════════════════════════════════════
  'ffb.enable': 'Enable force feedback (838-15069) board emulation. Required for both DirectInput and XInput wheel effects.',

  // ═══════════════════════════════════════
  // [indrun] — IDAC
  // ═══════════════════════════════════════
  'indrun.enable': 'Hooks to patch GameProject-Win64-Shipping.exe and IndRun.dll.\n'
      'Needed to boot version 1.60.00 and up. Not needed for version 1.50.00 and below.',

  // ═══════════════════════════════════════
  // [io2] — Mai2
  // ═══════════════════════════════════════
  'io2.test': 'Test button virtual-key code. Default is the F1 key (0x70).',
  'io2.service': 'Service button virtual-key code. Default is the F2 key (0x71).',
  'io2.coin': 'Keyboard button to increment coin counter. Default is the F3 key (0x72).',

  // ═══════════════════════════════════════
  // [unity] — Mai2/Mu3/EKT
  // ═══════════════════════════════════════
  'unity.enable': 'Enable Unity hook. Allows running custom .NET code before the game.',
  'unity.targetAssembly': 'Path to a .NET DLL that should run before the game.\nUseful for loading modding frameworks such as BepInEx.',

  // ═══════════════════════════════════════
  // [aime2] — EKT/Sekito
  // ═══════════════════════════════════════
  'aime2.enable': 'Enable second Aime card reader assembly emulation (satellite reader).',
  'aime2.aimePath': 'Path to the card ID file for the second reader.',
  'aime2.scan': 'Virtual-key code for the second card reader. Default is the Return key.',

  // ═══════════════════════════════════════
  // [keyboard] — EKT/Sekito
  // ═══════════════════════════════════════
  'keyboard.cancel': 'Cancel button virtual-key code.',
  'keyboard.decide': 'Decide/confirm button virtual-key code.',
  'keyboard.up': 'Up direction virtual-key code.',
  'keyboard.down': 'Down direction virtual-key code.',
  'keyboard.left': 'Left direction virtual-key code.',
  'keyboard.right': 'Right direction virtual-key code.',
  'keyboard.reserve': 'Reserve button virtual-key code.',

  // ═══════════════════════════════════════
  // [eeprom] / [sram] — Sekito
  // ═══════════════════════════════════════
  'eeprom.path': 'Path to the storage file for EEPROM emulation. Automatically created if not exists.',
  'sram.path': 'Path to the storage file for SRAM emulation.',

  // ═══════════════════════════════════════
  // [button] / [touch] — Mai2
  // ═══════════════════════════════════════
  'button.enable': 'Enable custom button keybindings for Mai2.',
  'touch.p1Enable': 'Enable touch sensor for Player 1.',
  'touch.p2Enable': 'Enable touch sensor for Player 2.',
};

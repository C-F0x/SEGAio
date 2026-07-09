import 'package:fluent_ui/fluent_ui.dart';

/// 一个 INI section 的定义
class SectionDef {
  final String name;      // INI section 名称
  final IconData icon;
  final String label;

  const SectionDef({required this.name, required this.icon, required this.label});
}

/// 一条启动命令
class LaunchCmd {
  final String exe;           // 可执行文件，如 "inject_x64.exe" / "inject.exe"
  final List<String> args;    // 参数列表
  final bool waitExit;        // 是否等待此进程退出（主游戏=true，后台 daemon=false）
  final bool background;      // 是否后台启动（对应 start /min）

  const LaunchCmd({
    required this.exe,
    required this.args,
    this.waitExit = false,
    this.background = false,
  });
}

/// 游戏类型定义
class GameType {
  final String id;
  final String label;
  final String detectFile;
  final List<LaunchCmd> launchCmds;
  final List<String> serverProcessNames; // 需要 kill 的后台进程
  final List<SectionDef> sections;

  const GameType({
    required this.id,
    required this.label,
    required this.detectFile,
    this.launchCmds = const [],
    this.serverProcessNames = const [],
    required this.sections,
  });
}

// ─── 通用 section ───
const _vfs     = SectionDef(name: 'vfs',     icon: FluentIcons.folder_open,   label: 'Path settings');
const _aime    = SectionDef(name: 'aime',    icon: FluentIcons.business_card, label: 'Device settings');
const _dns     = SectionDef(name: 'dns',     icon: FluentIcons.network_tower, label: 'Network settings');
const _keychip = SectionDef(name: 'keychip', icon: FluentIcons.settings,      label: 'Board settings');
const _gfx     = SectionDef(name: 'gfx',     icon: FluentIcons.video,         label: 'Misc. hooks');
const _aimeio  = SectionDef(name: 'aimeio',  icon: FluentIcons.game,          label: 'Custom IO');
const _led15093 = SectionDef(name: 'led15093', icon: FluentIcons.lightbulb,   label: 'LED settings');
const _vfd     = SectionDef(name: 'vfd',     icon: FluentIcons.video,         label: 'VFD display');
const _commonSections = [_vfs, _aime, _dns, _keychip, _gfx, _aimeio];

// ─── 启动命令辅助函数 ───
LaunchCmd _bg(String exe, List<String> args) => LaunchCmd(exe: exe, args: args, background: true);
LaunchCmd _game(String exe, List<String> args) => LaunchCmd(exe: exe, args: args, waitExit: true);
LaunchCmd _daemon(String exe, List<String> args) => LaunchCmd(exe: exe, args: args, background: true);

// ─── 所有游戏类型 ───
final List<GameType> gameTypes = [
  GameType(
    id: 'chusan', label: 'Chusan', detectFile: 'chusanApp.exe',
    launchCmds: [
      _daemon('inject_x64.exe', ['-d', '-k', 'chusanhook_x64.dll', 'amdaemon.exe', '-c',
        'config_common.json', 'config_server.json', 'config_client.json', 'config_cvt.json', 'config_sp.json', 'config_hook.json']),
      _game('inject_x86.exe', ['-d', '-k', 'chusanhook_x86.dll', 'chusanApp.exe']),
    ],
    serverProcessNames: ['amdaemon.exe'],
    sections: [..._commonSections, _led15093,
      SectionDef(name: 'led', icon: FluentIcons.lightbulb, label: 'LED output'), _vfd,
      SectionDef(name: 'chuniio', icon: FluentIcons.game, label: 'Chuni IO DLL'),
      SectionDef(name: 'io3', icon: FluentIcons.button_control, label: 'Input settings'),
      SectionDef(name: 'slider', icon: FluentIcons.touch, label: 'Slider emulation'),
      SectionDef(name: 'ir', icon: FluentIcons.hands_free, label: 'IR sensors'),
    ],
  ),
  GameType(
    id: 'mai2', label: 'Mai2', detectFile: 'mai2hook.dll',
    launchCmds: [
      _daemon('inject.exe', ['-d', '-k', 'mai2hook.dll', 'amdaemon.exe', '-f', '-c',
        'config_common.json', 'config_server.json', 'config_client.json', 'config_hook.json']),
      _game('inject.exe', ['-d', '-k', 'mai2hook.dll', 'sinmai',
        '-screen-fullscreen', '0', '-popupwindow', '-screen-width', '2160', '-screen-height', '1920', '-silent-crashes']),
    ],
    serverProcessNames: ['amdaemon.exe'],
    sections: [..._commonSections,
      SectionDef(name: 'led15083', icon: FluentIcons.lightbulb, label: 'LED settings'), _vfd,
      SectionDef(name: 'mai2io', icon: FluentIcons.game, label: 'Mai2 IO DLL'),
      SectionDef(name: 'unity', icon: FluentIcons.code, label: 'Unity hook'),
      SectionDef(name: 'io2', icon: FluentIcons.button_control, label: 'Input settings'),
    ],
  ),
  GameType(
    id: 'mu3', label: 'Mu3', detectFile: 'mu3hook.dll',
    launchCmds: [
      _daemon('inject.exe', ['-d', '-k', 'mu3hook.dll', 'amdaemon.exe', '-f', '-c',
        'config_common.json', 'config_server.json', 'config_client.json']),
      _game('inject.exe', ['-d', '-k', 'mu3hook.dll', 'mu3',
        '-screen-fullscreen', '0', '-popupwindow', '-screen-width', '1080', '-screen-height', '1920']),
    ],
    serverProcessNames: ['amdaemon.exe'],
    sections: [..._commonSections, _led15093,
      SectionDef(name: 'mu3io', icon: FluentIcons.game, label: 'Mu3 IO DLL'),
      SectionDef(name: 'unity', icon: FluentIcons.code, label: 'Unity hook'),
      SectionDef(name: 'io4', icon: FluentIcons.button_control, label: 'Input settings'),
    ],
  ),
  GameType(
    id: 'chuni', label: 'Chuni', detectFile: 'chunihook.dll',
    launchCmds: [
      _bg('inject.exe', ['-d', '-k', 'chunihook.dll', 'aimeReaderHost.exe', '-p', '12']),
      _game('inject.exe', ['-d', '-k', 'chunihook.dll', 'chuniApp.exe']),
    ],
    serverProcessNames: ['aimeReaderHost.exe'],
    sections: [..._commonSections, _led15093,
      SectionDef(name: 'chuniio', icon: FluentIcons.game, label: 'Chuni IO DLL'),
      SectionDef(name: 'io3', icon: FluentIcons.button_control, label: 'Input settings'),
      SectionDef(name: 'slider', icon: FluentIcons.touch, label: 'Slider emulation'),
    ],
  ),
  GameType(
    id: 'idac', label: 'IDAC', detectFile: 'idachook.dll',
    launchCmds: [
      _daemon('inject.exe', ['-d', '-k', 'idachook.dll', 'amdaemon.exe', '-c', '%AMDAEMON_CFG%']),
      _game('inject.exe', ['-d', '-k', 'idachook.dll',
        r'..\WindowsNoEditor\GameProject\Binaries\Win64\GameProject-Win64-Shipping.exe',
        '-culture=en', 'launch=Cabinet',
        'ABSLOG="..\\..\\..\\..\\..\\Userdata\\GameProject.log"',
        '-Master', '-UserDir="..\\..\\..\\Userdata"', '-NotInstalled', '-UNATTENDED']),
    ],
    serverProcessNames: ['amdaemon.exe'],
    sections: [..._commonSections,
      SectionDef(name: 'led15070', icon: FluentIcons.lightbulb, label: 'LED settings'),
      SectionDef(name: 'idacio', icon: FluentIcons.game, label: 'IDAC IO DLL'),
      SectionDef(name: 'ffb', icon: FluentIcons.radio_bullet, label: 'Force feedback'),
      SectionDef(name: 'indrun', icon: FluentIcons.code, label: 'IndRun hooks'),
      SectionDef(name: 'io4', icon: FluentIcons.button_control, label: 'Input settings'),
      SectionDef(name: 'xinput', icon: FluentIcons.game, label: 'XInput bindings'),
      SectionDef(name: 'dinput', icon: FluentIcons.game, label: 'DirectInput bindings'),
    ],
  ),
  GameType(
    id: 'idz', label: 'IDZ', detectFile: 'idzhook.dll',
    launchCmds: [
      _daemon('inject.exe', ['-d', '-k', 'idzhook.dll', 'amdaemon.exe', '-c',
        'configDHCP_Final_Common.json', 'configDHCP_Final_JP.json', 'configDHCP_Final_JP_ST1.json',
        'configDHCP_Final_JP_ST2.json', 'configDHCP_Final_EX.json', 'configDHCP_Final_EX_ST1.json',
        'configDHCP_Final_EX_ST2.json']),
      _game('inject.exe', ['-d', '-k', 'idzhook.dll', 'InitialD0_DX11_Nu.exe', '-m']),
    ],
    serverProcessNames: ['amdaemon.exe', 'ServerBoxD8_Nu_x64.exe'],
    sections: [..._commonSections,
      SectionDef(name: 'led15070', icon: FluentIcons.lightbulb, label: 'LED settings'),
      SectionDef(name: 'idacio', icon: FluentIcons.game, label: 'IDZ IO DLL'),
      SectionDef(name: 'io4', icon: FluentIcons.button_control, label: 'Input settings'),
      SectionDef(name: 'xinput', icon: FluentIcons.game, label: 'XInput bindings'),
    ],
  ),
  GameType(
    id: 'ekt', label: 'EKT', detectFile: 'ekthook.dll',
    launchCmds: [
      _daemon('inject_x64.exe', ['-d', '-k', 'ekthook_x64.dll', r'..\PackageBase\amdaemon.exe', '-c',
        r'..\PackageBase\config_terminal.json', 'config_hook.json']),
      _game('inject_x64.exe', ['-d', '-k', 'ekthook_x64.dll', 'ekt.exe',
        '-terminal', '-logfile', 'terminal.log',
        '-screen-fullscreen', '1', '-screen-width', '1920', '-screen-height', '1080',
        '-screen-quality', 'Ultra', '-silent-crashes']),
    ],
    serverProcessNames: ['amdaemon.exe'],
    sections: [..._commonSections, _led15093,
      SectionDef(name: 'ektio', icon: FluentIcons.game, label: 'EKT IO DLL'),
      SectionDef(name: 'unity', icon: FluentIcons.code, label: 'Unity hook'),
      SectionDef(name: 'aime2', icon: FluentIcons.business_card, label: '2nd card reader'),
      SectionDef(name: 'io4', icon: FluentIcons.button_control, label: 'Input settings'),
      SectionDef(name: 'keyboard', icon: FluentIcons.keyboard_classic, label: 'Keyboard bindings'),
    ],
  ),
  GameType(
    id: 'sekito', label: 'Sekito', detectFile: 'sekitohook.dll',
    launchCmds: [
      _daemon('inject_x64.exe', ['-d', '-k', 'sekitohook_x64.dll', r'bin\amdaemon.exe', '-c',
        r'bin\config_new.json', r'bin\config_video_single.json', r'bin\config_video_multi.json',
        r'bin\config_input_sate.json', r'bin\config_input_terminal.json',
        r'bin\config_input_terminal_exp.json', 'config_hook_terminal.json']),
      _game('inject_x86.exe', ['-d', '-k', 'sekitohook_x86.dll', r'bin\appTerminal.exe']),
    ],
    serverProcessNames: ['amdaemon.exe', 'appTerminal.exe'],
    sections: [..._commonSections, _led15093,
      SectionDef(name: 'sekitoio', icon: FluentIcons.game, label: 'Sekito IO DLL'),
      SectionDef(name: 'aime2', icon: FluentIcons.business_card, label: '2nd card reader'),
      SectionDef(name: 'eeprom', icon: FluentIcons.save, label: 'EEPROM emulation'),
      SectionDef(name: 'io4', icon: FluentIcons.button_control, label: 'Input settings'),
      SectionDef(name: 'keyboard', icon: FluentIcons.keyboard_classic, label: 'Keyboard bindings'),
    ],
  ),
  GameType(
    id: 'diva', label: 'Diva', detectFile: 'divahook.dll',
    launchCmds: [_game('inject.exe', ['-d', '-k', 'divahook.dll', 'diva.exe'])],
    sections: [..._commonSections],
  ),
  GameType(
    id: 'apm3', label: 'APM3', detectFile: 'apm3hook.dll',
    launchCmds: [_game('inject.exe', ['-d', '-k', 'apm3hook.dll', 'APM3.exe'])],
    sections: [..._commonSections],
  ),
  GameType(
    id: 'carol', label: 'Carol', detectFile: 'carolhook.dll',
    launchCmds: [
      _bg('inject.exe', ['-d', '-k', 'carolhook.dll', 'aimeReaderHost.exe', '-p', '10']),
      _game('inject.exe', ['-d', '-k', 'carolhook.dll', 'carol_nu.exe']),
    ],
    serverProcessNames: ['aimeReaderHost.exe'],
    sections: [..._commonSections],
  ),
  GameType(
    id: 'cm', label: 'CM', detectFile: 'cmhook.dll',
    launchCmds: [
      _daemon('inject.exe', ['-d', '-k', 'cmhook.dll', 'amdaemon.exe', '-c',
        'config_common.json', 'config_server.json', 'config_client.json', 'config_hook.json']),
      _game('inject.exe', ['-d', '-k', 'cmhook.dll', 'CardMaker.exe',
        '-screen-fullscreen', '0', '-popupwindow', '-screen-width', '1080', '-screen-height', '1920']),
    ],
    serverProcessNames: ['amdaemon.exe'],
    sections: [..._commonSections],
  ),
  GameType(
    id: 'cxb', label: 'CXB', detectFile: 'cxbhook.dll',
    launchCmds: [_game('inject.exe', ['-d', '-k', 'cxbhook.dll', 'Rev_v11.exe'])],
    sections: [..._commonSections],
  ),
  GameType(
    id: 'fgo', label: 'FGO', detectFile: 'fgohook.dll',
    launchCmds: [_game('inject.exe', ['-d', '-k', 'fgohook.dll', 'ago.exe'])],
    sections: [..._commonSections],
  ),
  GameType(
    id: 'kemono', label: 'Kemono', detectFile: 'kemonohook.dll',
    launchCmds: [
      _daemon('inject_x64.exe', ['-d', '-k', 'kemonohook_x64.dll', 'amdaemon.exe', '-c', 'config.json']),
      _game('inject_x86.exe', ['-d', '-k', 'kemonohook_x86.dll', r'UnityApp\Parade',
        '-screen-fullscreen', '0', '-popupwindow', '-screen-width', '720', '-screen-height', '1280', '-silent-crashes']),
    ],
    serverProcessNames: ['amdaemon.exe'],
    sections: [..._commonSections],
  ),
  GameType(
    id: 'mercury', label: 'Mercury', detectFile: 'mercuryhook.dll',
    launchCmds: [
      _daemon('inject.exe', ['-d', '-k', 'mercuryhook.dll', 'amdaemon.exe', '-c',
        'config.json', 'config_lan_install_client.json', 'config_lan_install_server.json',
        'config_video_clone.json', 'config_video_dual.json', 'config_video_clone_flip.json',
        'config_video_dual_flip.json', 'config_region_exp.json', 'config_region_chn.json', 'config_region_jpn.json']),
      _game('inject.exe', ['-d', '-k', 'mercuryhook.dll',
        r'..\WindowsNoEditor\Mercury\Binaries\Win64\Mercury-Win64-Shipping.exe']),
    ],
    serverProcessNames: ['amdaemon.exe'],
    sections: [..._commonSections],
  ),
  GameType(
    id: 'swdc', label: 'SWDC', detectFile: 'swdchook.dll',
    launchCmds: [
      _game('inject.exe', ['-d', '-k', 'swdchook.dll', 'SWDC.exe']),
    ],
    sections: [..._commonSections],
  ),
  GameType(
    id: 'tokyo', label: 'Tokyo', detectFile: 'tokyohook.dll',
    launchCmds: [
      _game('inject.exe', ['-d', '-k', 'tokyohook.dll', 'TokyoGame.exe']),
    ],
    sections: [..._commonSections],
  ),
];

GameType? findGameTypeByFile(String fileName) {
  for (final gt in gameTypes) {
    if (gt.detectFile == fileName) return gt;
  }
  return null;
}

GameType? findGameTypeById(String id) {
  for (final gt in gameTypes) {
    if (gt.id == id) return gt;
  }
  return null;
}

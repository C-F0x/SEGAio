/// 各游戏类型的硬编码 launch.bat 内容生成器
class LaunchScripts {
  /// 返回对应 variety 的 launch.bat 内容
  static String getBatContent(String variety, String projectPath) {
    final cd = '@echo off\r\ncd /d "$projectPath"\r\n';
    switch (variety) {
      case 'chusan': return cd + _bat(
        daemon: 'start /min inject_x64.exe -d -k chusanhook_x64.dll amdaemon.exe -c config_common.json config_server.json config_client.json config_cvt.json config_sp.json config_hook.json',
        game: 'inject_x86.exe -d -k chusanhook_x86.dll chusanApp.exe',
        cleanup: 'amdaemon.exe',
      );
      case 'mai2': return cd + _bat(
        daemon: 'start /min inject.exe -d -k mai2hook.dll amdaemon.exe -f -c config_common.json config_server.json config_client.json config_hook.json',
        game: 'inject.exe -d -k mai2hook.dll sinmai -screen-fullscreen 0 -popupwindow -screen-width 2160 -screen-height 1920 -silent-crashes',
        cleanup: 'amdaemon.exe',
      );
      case 'mu3': return cd + _bat(
        daemon: 'start /min inject.exe -d -k mu3hook.dll amdaemon.exe -f -c config_common.json config_server.json config_client.json',
        game: 'inject.exe -d -k mu3hook.dll mu3 -screen-fullscreen 0 -popupwindow -screen-width 1080 -screen-height 1920',
        cleanup: 'amdaemon.exe',
      );
      case 'chuni': return cd + _bat(
        bg: 'start /min inject.exe -d -k chunihook.dll aimeReaderHost.exe -p 12',
        game: 'inject.exe -d -k chunihook.dll chuniApp.exe',
        cleanup: 'aimeReaderHost.exe',
      );
      case 'idac': return cd + _bat(
        daemon: 'start /min inject.exe -d -k idachook.dll amdaemon.exe -c %AMDAEMON_CFG%',
        game: 'inject.exe -d -k idachook.dll ..\\WindowsNoEditor\\GameProject\\Binaries\\Win64\\GameProject-Win64-Shipping.exe -culture=en launch=Cabinet "ABSLOG=..\\..\\..\\..\\..\\Userdata\\GameProject.log" -Master -UserDir="..\\..\\..\\Userdata" -NotInstalled -UNATTENDED',
        cleanup: 'amdaemon.exe',
      );
      case 'idz': return cd + _bat(
        daemon: 'start /min inject.exe -d -k idzhook.dll amdaemon.exe -c configDHCP_Final_Common.json configDHCP_Final_JP.json configDHCP_Final_JP_ST1.json configDHCP_Final_JP_ST2.json configDHCP_Final_EX.json configDHCP_Final_EX_ST1.json configDHCP_Final_EX_ST2.json',
        game: 'inject.exe -d -k idzhook.dll InitialD0_DX11_Nu.exe -m',
        cleanup: 'amdaemon.exe ServerBoxD8_Nu_x64.exe',
      );
      case 'ekt': return cd + _bat(
        daemon: 'start /min inject_x64.exe -d -k ekthook_x64.dll ..\\PackageBase\\amdaemon.exe -c ..\\PackageBase\\config_terminal.json config_hook.json',
        game: 'inject_x64.exe -d -k ekthook_x64.dll ekt.exe -terminal -logfile terminal.log -screen-fullscreen 1 -screen-width 1920 -screen-height 1080 -screen-quality Ultra -silent-crashes',
        cleanup: 'amdaemon.exe',
      );
      case 'sekito': return cd + _bat(
        daemon: 'start /min inject_x64.exe -d -k sekitohook_x64.dll bin\\amdaemon.exe -c bin\\config_new.json bin\\config_video_single.json bin\\config_video_multi.json bin\\config_input_sate.json bin\\config_input_terminal.json bin\\config_input_terminal_exp.json config_hook_terminal.json',
        game: 'inject_x86.exe -d -k sekitohook_x86.dll bin\\appTerminal.exe',
        cleanup: 'amdaemon.exe appTerminal.exe',
      );
      case 'diva': return cd + _bat(game: 'inject.exe -d -k divahook.dll diva.exe');
      case 'apm3': return cd + _bat(game: 'inject.exe -d -k apm3hook.dll APM3.exe');
      case 'carol': return cd + _bat(
        bg: 'start /min inject.exe -d -k carolhook.dll aimeReaderHost.exe -p 10',
        game: 'inject.exe -d -k carolhook.dll carol_nu.exe',
        cleanup: 'aimeReaderHost.exe',
      );
      case 'cm': return cd + _bat(
        daemon: 'start /min inject.exe -d -k cmhook.dll amdaemon.exe -c config_common.json config_server.json config_client.json config_hook.json',
        game: 'inject.exe -d -k cmhook.dll CardMaker.exe -screen-fullscreen 0 -popupwindow -screen-width 1080 -screen-height 1920',
        cleanup: 'amdaemon.exe',
      );
      case 'cxb': return cd + _bat(game: 'inject.exe -d -k cxbhook.dll Rev_v11.exe');
      case 'fgo': return cd + _bat(game: 'inject.exe -d -k fgohook.dll ago.exe');
      case 'kemono': return cd + _bat(
        daemon: 'start /min inject_x64.exe -d -k kemonohook_x64.dll amdaemon.exe -c config.json',
        game: 'inject_x86.exe -d -k kemonohook_x86.dll UnityApp\\Parade -screen-fullscreen 0 -popupwindow -screen-width 720 -screen-height 1280 -silent-crashes',
        cleanup: 'amdaemon.exe',
      );
      case 'mercury': return cd + _bat(
        daemon: 'start /min inject.exe -d -k mercuryhook.dll amdaemon.exe -c config.json config_lan_install_client.json config_lan_install_server.json config_video_clone.json config_video_dual.json config_video_clone_flip.json config_video_dual_flip.json config_region_exp.json config_region_chn.json config_region_jpn.json',
        game: 'inject.exe -d -k mercuryhook.dll ..\\WindowsNoEditor\\Mercury\\Binaries\\Win64\\Mercury-Win64-Shipping.exe',
        cleanup: 'amdaemon.exe',
      );
      case 'swdc': return cd + _bat(game: 'inject.exe -d -k swdchook.dll SWDC.exe');
      case 'tokyo': return cd + _bat(game: 'inject.exe -d -k tokyohook.dll TokyoGame.exe');
      default: return cd + 'echo Unknown variety: $variety\r\npause\r\n';
    }
  }

  static String _bat({String? daemon, String? bg, required String? game, String? cleanup}) {
    final buf = StringBuffer();
    if (daemon != null) buf.writeln(daemon);
    if (bg != null) buf.writeln(bg);
    if (game != null) buf.writeln(game);
    if (cleanup != null) {
      for (final proc in cleanup.split(' ')) {
        buf.writeln('taskkill /f /im $proc >nul 2>&1');
      }
    }
    buf.writeln('exit');
    return buf.toString();
  }
}

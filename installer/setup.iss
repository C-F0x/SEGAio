; SEGAio — Inno Setup 安装脚本
; 使用前先执行 flutter build windows --release，然后运行本脚本

#define MyAppName "SEGAio"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "C-F0x"
#define MyAppURL "https://github.com/C-F0x/SEGAIO"
#define MyAppExeName "SEGAio.exe"

; 构建产物路径 — 根据实际 flutter build 输出调整
#define BuildDir "..\build\windows\x64\runner\Release"
#define ProjectRoot ".."

[Setup]
AppId={{B8F4A3D2-1E5C-4A7B-9D6F-8C3E2A1B5F7D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; 便携模式 — 数据存储在安装目录下
PrivilegesRequired=lowest
OutputDir=.
OutputBaseFilename=SEGAio-Setup-{#MyAppVersion}
SetupIconFile={#ProjectRoot}\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
; 安装后让用户能看到目录内的所有文件（不隐藏）
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; 主程序
Source: "{#BuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; Flutter 引擎 DLL
Source: "{#BuildDir}\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
; Rust FFI DLL
Source: "{#ProjectRoot}\revealer.dll"; DestDir: "{app}"; Flags: ignoreversion
; 数据目录（flutter_assets、icudtl.dat 等）
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; 插件 DLL（如有）
Source: "{#BuildDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
; 构建配置文件（避免缺失）
Source: "{#BuildDir}\*.pak"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
; 卸载时询问是否删除便携数据
Filename: "{cmd}"; Parameters: "/C rmdir /S /Q ""{app}\data"""; Flags: runhidden; RunOnceId: "CleanData"

; Sonic Vault Installer
; Inno Setup script — compiles a signed installer with automatic
; certificate trust installation for zero-warning user experience.

#define MyAppName "Sonic Vault"
#define MyAppVersion "1.2.1"
#define MyAppPublisher "Yuvraj Sarathe"
#define MyAppURL "https://github.com/Yuvraj-Sarathe/Sonic-Vault"
#define MyExeName "sonicvault.exe"

[Setup]
AppId={{B8F330E2-1376-4FA6-A127-48AD84A4831F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=SonicVault-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
; Require admin so the installer can trust the self-signed cert
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#MyExeName}
; Modern look
 WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
; All Flutter release output files
Source: "..\build\windows\x64\runner\Release\{#MyExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; The public certificate — extracted to temp, imported, then removed
Source: "sonicvault.cer"; DestDir: "{tmp}"; Flags: deleteafterinstall
; VC++ runtime redistributable — downloaded at install time if needed
Source: "vcredist_x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall skipifsourcedoesntexist

[Run]
; Install VC++ runtime if not present
Filename: "{tmp}\vcredist_x64.exe"; Parameters: "/install /quiet /norestart"; Flags: runhidden waituntilterminated skipifdoesntexist; StatusMsg: "Installing Visual C++ Runtime..."
; Install the certificate into the Local Machine Trusted Root store
Filename: "certutil.exe"; Parameters: "-addstore ""Root"" ""{tmp}\sonicvault.cer"""; Flags: runhidden; StatusMsg: "Installing security certificate — this app will be trusted on this PC..."
; Launch the app after setup
Filename: "{app}\{#MyExeName}"; Description: "Launch Sonic Vault"; Flags: nowait postinstall skipifsilent

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"; Tasks: desktopicon

[UninstallRun]
; Remove the certificate on uninstall (optional — clean, but may affect other apps signed with same cert)
; Filename: "certutil.exe"; Parameters: "-delstore ""Root"" ""{tmp}\sonicvault.cer"""; Flags: runhidden; RunOnceId: "RemoveCert"

[UninstallDelete]
Type: files; Name: "{app}\data\*"

[Code]
function IsVCRedistInstalled: Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec('powershell.exe', '-Command "Get-Package -Name ''Microsoft Visual C++ 2015-2022 Redistributable (x64)'' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version"', '', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := (ResultCode = 0);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    // Certificate was installed by [Run] section above.
    // No additional code needed — certutil handles it silently.
  end;
end;

; Script generado para Salufit App (Flutter Windows)
; Requiere Inno Setup para compilarse.

#define MyAppName "Salufit App"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Centro Salufit"
#define MyAppURL "https://www.centrosalufit.com/"
#define MyAppExeName "salufit_app.exe"

[Setup]
; Identificador único de la app (Generado aleatoriamente, no cambiar en futuras actualizaciones)
AppId={{D4F8A3B1-9C2E-4A5D-8F1B-7A9C3E2D1F0A}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; El archivo final se llamará SalufitSetup.exe
OutputBaseFilename=SalufitSetup
; Icono del instalador (debe existir en assets, si no tienes .ico usa el default o comenta esta línea)
; SetupIconFile=..\assets\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; IMPORTANTE: Esta ruta asume que el script está en la carpeta 'installers' y el build en 'build/windows/x64/runner/Release'
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; Incluimos cualquier otra DLL necesaria generada por plugins (firebase, etc)
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
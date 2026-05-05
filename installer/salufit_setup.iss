; ═══════════════════════════════════════════════════════════════
;  Salufit — Instalador Windows (Inno Setup 6)
;
;  AppId fijo entre versiones para que el instalador detecte la
;  instalación previa y haga upgrade automático (sin que el
;  usuario tenga que desinstalar manualmente).
;
;  Cómo compilar:
;    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" salufit_setup.iss
; ═══════════════════════════════════════════════════════════════

#define MyAppName       "Salufit"
#define MyAppVersion    "2.0.10"
#define MyAppPublisher  "Centro Salufit"
#define MyAppExeName    "salufit_app.exe"

[Setup]
; AppId — NO CAMBIAR entre versiones. Identifica la app en Windows.
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://centrosalufit.com
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\build\installer
OutputBaseFilename=SalufitSetup_{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
PrivilegesRequired=admin

; ── Upgrade automático ──────────────────────────────────────────
; Reutilizar directorio y grupo del menú inicio de instalaciones
; previas (mismo AppId) → sobrescribe sin preguntar.
UsePreviousAppDir=yes
UsePreviousGroup=yes
UsePreviousTasks=yes
; Cerrar Salufit si está abierto durante el upgrade y NO reiniciarlo
; al terminar (lo lanza el [Run] postinstall si el usuario quiere).
CloseApplications=force
RestartApplications=no
; Eliminar instalaciones antiguas que pudieran haber quedado en otros
; AppIds. Si conocemos AppIds previos, los listamos aquí.
; (vacío de momento — solo confiamos en mismo AppId)

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Accesos directos:"

; ── Limpieza pre-instalación ────────────────────────────────────
; Borra archivos de versiones anteriores antes de copiar los nuevos
; para evitar DLLs huérfanas si Flutter cambió dependencias.
[InstallDelete]
Type: filesandordirs; Name: "{app}\data"
Type: files; Name: "{app}\*.dll"
Type: files; Name: "{app}\{#MyAppExeName}"

[Files]
; Copia todo el contenido del Release de Flutter Windows.
; recursesubdirs cubre data/, plugins, etc.
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; VC++ Redistributable (instalado solo si falta).
Source: "VC_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{tmp}\VC_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Instalando Microsoft Visual C++ Redistributable..."; Check: VCRedistNeedsInstall
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
function VCRedistNeedsInstall: Boolean;
var
  Version: String;
begin
  // Solo instalar VC++ Redist si la versión actual es < v14.38
  if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version) then
    Result := (CompareStr(Version, 'v14.38') < 0)
  else
    Result := True;
end;

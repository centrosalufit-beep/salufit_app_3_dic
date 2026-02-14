; Script de Inno Setup para Salufit
; ---------------------------------
; INSTRUCCIONES:
; 1. Crea una carpeta llamada 'installer' en la raíz de tu proyecto.
; 2. Mete el archivo 'vc_redist.x64.exe' en esa carpeta 'installer'.
; 3. Guarda este código como 'setup.iss' dentro de 'installer'.

; --- CONFIGURACIÓN GENERAL ---
#define MyAppName "Salufit"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Salufit Team"
#define MyAppExeName "salufit_app.exe"

[Setup]
; NOTA: Este ID identifica la app en Windows. Úsalo siempre para actualizaciones futuras.
AppId={{A1B2C3D4-E5F6-7890-ABCD-1234567890EF}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
; Esta ruta crea la carpeta: C:\Archivos de Programa\Salufit
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Nombre del archivo final del instalador (ej: Salufit_Setup_v1.0.0.exe)
OutputBaseFilename=Salufit_Setup_v{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
; Si tienes un icono (.ico), descomenta la siguiente línea y pon el nombre del archivo:
; SetupIconFile=mi_icono.ico

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; 1. EL EJECUTABLE (Ruta relativa subiendo un nivel hacia build)
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; 2. DEPENDENCIAS DE FLUTTER (DLLs y carpeta data)
; Es vital incluir todo lo que hay en la carpeta Release, incluyendo subcarpetas
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; 3. CONTROLADOR VISUAL C++ (Debe estar junto a este script .iss)
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; 1. INSTALACIÓN SILENCIOSA DEL CONTROLADOR
; Se ejecuta antes de lanzar la app. /passive muestra barra de progreso sin pedir clicks.
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /passive /norestart"; StatusMsg: "Instalando componentes necesarios de Windows (Visual C++)..."; Flags: waituntilterminated

; 2. EJECUTAR APP AL FINALIZAR
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
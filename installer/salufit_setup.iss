[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName=Salufit
AppVersion=2.0.8
AppVerName=Salufit 2.0.8
AppPublisher=Centro Salufit
AppPublisherURL=https://centrosalufit.com
DefaultDirName={autopf}\Salufit
DefaultGroupName=Salufit
DisableProgramGroupPage=yes
OutputDir=..\build\installer
OutputBaseFilename=SalufitSetup_2.0.8
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\salufit_app.exe
PrivilegesRequired=admin

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Accesos directos:"

[Files]
Source: "..\build\windows\x64\runner\Release\salufit_app.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "VC_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\Salufit"; Filename: "{app}\salufit_app.exe"
Name: "{group}\Desinstalar Salufit"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Salufit"; Filename: "{app}\salufit_app.exe"; Tasks: desktopicon

[Run]
Filename: "{tmp}\VC_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Instalando Microsoft Visual C++ Redistributable..."; Check: VCRedistNeedsInstall
Filename: "{app}\salufit_app.exe"; Description: "Abrir Salufit"; Flags: nowait postinstall skipifsilent

[Code]
function VCRedistNeedsInstall: Boolean;
var
  Version: String;
begin
  if RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version) then
    Result := (CompareStr(Version, 'v14.38') < 0)
  else
    Result := True;
end;

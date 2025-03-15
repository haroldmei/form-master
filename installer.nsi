; Form-Master Installer Script
Unicode true

!define APPNAME "Form-Master"
!define DESCRIPTION "Form automation tool for Australian university applications"
!define VERSION "0.1.0"
!define PYTHON_VERSION "3.11.1"
!define PYTHON_URL "https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-amd64.exe"
!define PYTHON_INSTALLER "python-${PYTHON_VERSION}-amd64.exe"

Name "${APPNAME} ${VERSION}"
OutFile "Form-Master-Setup.exe"
InstallDir "$PROGRAMFILES64\Form-Master"
InstallDirRegKey HKLM "Software\Form-Master" "Install_Dir"
RequestExecutionLevel admin

; Include necessary NSIS libraries
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "nsDialogs.nsh"
!include "FileFunc.nsh"
!include "WinMessages.nsh"

; Modern UI settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\win.bmp"

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Launch Form-Master Now"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchApplication"

Function LaunchApplication
  ExecShell "" "$SMPROGRAMS\Form-Master\Form-Master.lnk"
FunctionEnd

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "README.md"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; Show details by default
ShowInstDetails show
ShowUninstDetails show

; Installer sections
Section "Python ${PYTHON_VERSION} (Required)" SectionPython
    SectionIn RO  ; Read-only, cannot be deselected
    SetOutPath "$TEMP"
    
    ; Check if Python is already installed
    ReadRegStr $0 HKLM "Software\Python\PythonCore\3.11\InstallPath" ""
    ReadRegStr $1 HKCU "Software\Python\PythonCore\3.11\InstallPath" ""
    
    ${If} $0 != ""
    ${OrIf} $1 != ""
        DetailPrint "Python 3.11 is already installed."
    ${Else}
        DetailPrint "Downloading Python ${PYTHON_VERSION}..."
        
        ; Use NSISdl as fallback if inetc isn't available
        !if ${NSIS_PACKEDVERSION} >= 0x03000000
            NSISdl::download "${PYTHON_URL}" "$TEMP\${PYTHON_INSTALLER}"
            Pop $0
            ${If} $0 != "success"
                DetailPrint "Python download failed: $0"
                MessageBox MB_ICONEXCLAMATION|MB_OK "Failed to download Python. Please check your internet connection and try again."
                Abort "Failed to download Python."
            ${EndIf}
        !else
            NSISdl::download "${PYTHON_URL}" "$TEMP\${PYTHON_INSTALLER}"
            Pop $0
            ${If} $0 != "success"
                DetailPrint "Python download failed: $0"
                MessageBox MB_ICONEXCLAMATION|MB_OK "Failed to download Python. Please check your internet connection and try again."
                Abort "Failed to download Python."
            ${EndIf}
        !endif
        
        DetailPrint "Installing Python ${PYTHON_VERSION}..."
        ExecWait '"$TEMP\${PYTHON_INSTALLER}" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0' $0
        ${If} $0 != 0
            DetailPrint "Python installation failed with code: $0"
            MessageBox MB_ICONEXCLAMATION|MB_OK "Python installation failed. You may need to install Python ${PYTHON_VERSION} manually."
        ${EndIf}
        
        Delete "$TEMP\${PYTHON_INSTALLER}"
    ${EndIf}
    
    ; Verify Python installation
    DetailPrint "Verifying Python installation..."
    ClearErrors
    ExecWait 'python --version' $0
    ${If} $0 != 0
        MessageBox MB_ICONEXCLAMATION|MB_OK "Python installation verification failed. You may need to install Python ${PYTHON_VERSION} manually from python.org."
    ${EndIf}
SectionEnd

Section "Form-Master (Required)" SectionFormMaster
    SectionIn RO  ; Read-only, cannot be deselected
    SetOutPath "$INSTDIR"
    
    ; Create directory structure
    CreateDirectory "$INSTDIR\src"
    CreateDirectory "$INSTDIR\src\formmaster"
    CreateDirectory "$INSTDIR\src\formmaster\forms"
    
    ; Copy project files
    File "README.md"
    File "setup.py"
    File /r "src\*.*"
    
    ; Install Form-Master and its dependencies
    DetailPrint "Installing Form-Master and dependencies..."
    DetailPrint "Upgrading pip..."
    ExecWait 'python -m pip install --upgrade pip'
    DetailPrint "Installing dependencies..."
    ExecWait 'python -m pip install -r "$INSTDIR\src\requirements.txt"'
    DetailPrint "Installing Form-Master..."
    ExecWait 'python -m pip install -e "$INSTDIR"'
    
    ; Create shortcuts
    CreateDirectory "$SMPROGRAMS\Form-Master"
    CreateShortcut "$SMPROGRAMS\Form-Master\Form-Master.lnk" "cmd.exe" '/k python -m formmaster.formfiller' ""
    CreateShortcut "$SMPROGRAMS\Form-Master\Uninstall.lnk" "$INSTDIR\uninstall.exe"
    CreateShortcut "$DESKTOP\Form-Master.lnk" "cmd.exe" '/k python -m formmaster.formfiller' ""
    
    ; Create uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    ; Write registry keys for uninstall
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "DisplayName" "Form-Master"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "Publisher" "Form-Master Team"
    WriteRegStr HKLM "Software\Form-Master" "Install_Dir" "$INSTDIR"
SectionEnd

Section "Browser Drivers (Recommended)" SectionDrivers
    SetOutPath "$INSTDIR\drivers"
    
    DetailPrint "Installing WebDriver Manager..."
    ExecWait 'python -m pip install webdriver-manager'
    
    DetailPrint "Installing WebDriver for Chrome..."
    ExecWait 'python -c "from webdriver_manager.chrome import ChromeDriverManager; ChromeDriverManager().install()"'
    
    DetailPrint "Installing WebDriver for Firefox..."
    ExecWait 'python -c "from webdriver_manager.firefox import GeckoDriverManager; GeckoDriverManager().install()"'
SectionEnd

Section "Create Desktop Shortcut" SectionDesktopShortcut
    CreateShortcut "$DESKTOP\Form-Master.lnk" "cmd.exe" '/k python -m formmaster.formfiller' ""
SectionEnd

; Descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionPython} "Installs Python ${PYTHON_VERSION}, required to run Form-Master."
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionFormMaster} "Installs the Form-Master application and its dependencies."
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionDrivers} "Installs browser drivers required for web automation (Chrome and Firefox)."
    !insertmacro MUI_DESCRIPTION_TEXT ${SectionDesktopShortcut} "Creates a shortcut on your desktop for easy access."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Uninstaller section
Section "Uninstall"
    ; Display a message
    DetailPrint "Uninstalling Form-Master..."
    
    ; Uninstall Form-Master package
    DetailPrint "Removing Python package..."
    ExecWait 'python -m pip uninstall -y form-master'
    
    ; Remove directories and files
    DetailPrint "Removing installed files..."
    RMDir /r "$INSTDIR\src"
    Delete "$INSTDIR\setup.py"
    Delete "$INSTDIR\README.md"
    Delete "$INSTDIR\uninstall.exe"
    RMDir /r "$INSTDIR"
    
    ; Remove shortcuts
    DetailPrint "Removing shortcuts..."
    Delete "$SMPROGRAMS\Form-Master\Form-Master.lnk"
    Delete "$SMPROGRAMS\Form-Master\Uninstall.lnk"
    RMDir "$SMPROGRAMS\Form-Master"
    Delete "$DESKTOP\Form-Master.lnk"
    
    ; Remove registry keys
    DetailPrint "Removing registry entries..."
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master"
    DeleteRegKey HKLM "Software\Form-Master"
    
    DetailPrint "Uninstallation complete."
SectionEnd

; Installer Functions
Function .onInit
    ; Check if already installed
    ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "UninstallString"
    StrCmp $R0 "" done
    
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
        "${APPNAME} is already installed. $\n$\nClick 'OK' to remove the previous version or 'Cancel' to cancel this installation." \
        IDOK uninst
    Abort
    
    uninst:
    ClearErrors
    ExecWait '"$R0" /S _?=$INSTDIR'
    
    done:
FunctionEnd

; EOF

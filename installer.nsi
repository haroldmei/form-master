; Form-Master Installer Script
Unicode true

!define APPNAME "Form-Master"
!define DESCRIPTION "Form automation tool for Australian university applications"
!define VERSION "0.1.0"
!define PYTHON_VERSION "3.11.1"
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

; Include string functions
!include "StrFunc.nsh"
; Initialize both installer and uninstaller string functions
${StrStr}
${UnStrStr}

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
        DetailPrint "Setting up Python ${PYTHON_VERSION}..."
        
        ; Copy Python installer from our build directory
        File /oname=$TEMP\${PYTHON_INSTALLER} "build\${PYTHON_INSTALLER}"
        
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
    CreateDirectory "$INSTDIR\packages"
    
    ; Copy project files
    File "README.md"
    File "setup.py"
    File /r "src\*.*"
    
    ; Copy packaged dependencies
    SetOutPath "$INSTDIR\packages"
    File /r "build\packages\*.*"
    
    ; Install Form-Master and its dependencies from local packages
    DetailPrint "Installing Form-Master and dependencies..."
    DetailPrint "Upgrading pip from local package..."
    ExecWait 'python -m pip install --no-index --find-links="$INSTDIR\packages" --upgrade pip' $0
    ${If} $0 != 0
        DetailPrint "Warning: pip upgrade failed with code $0 (continuing anyway)"
    ${EndIf}
    
    DetailPrint "Installing wheel from local package..."
    ExecWait 'python -m pip install --no-index --find-links="$INSTDIR\packages" wheel setuptools' $0
    ${If} $0 != 0
        DetailPrint "Warning: wheel/setuptools installation failed with code $0 (continuing anyway)"
    ${EndIf}
    
    DetailPrint "Installing dependencies from local packages..."
    ExecWait 'python -m pip install --no-index --find-links="$INSTDIR\packages" -r "$INSTDIR\src\requirements.txt"' $0
    ${If} $0 != 0
        MessageBox MB_ICONEXCLAMATION|MB_OK "Warning: Failed to install some dependencies. Form-Master may not function correctly."
    ${EndIf}
    
    DetailPrint "Installing Form-Master..."
    ExecWait 'python -m pip install -e "$INSTDIR"' $0
    ${If} $0 != 0
        MessageBox MB_ICONEXCLAMATION|MB_OK "Warning: Failed to install Form-Master. The application may not work properly."
    ${EndIf}
    
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
    CreateDirectory "$INSTDIR\drivers\chromedriver"
    CreateDirectory "$INSTDIR\drivers\geckodriver"
    
    ; Copy Chrome WebDriver from our build directory
    SetOutPath "$INSTDIR\drivers\chromedriver"
    File "build\drivers\chromedriver\chromedriver.exe"
    
    ; Copy Firefox WebDriver from our build directory
    SetOutPath "$INSTDIR\drivers\geckodriver"
    File "build\drivers\geckodriver\geckodriver.exe"
    
    ; Add drivers to PATH - using direct manipulation
    DetailPrint "Adding WebDriver directories to PATH..."
    
    ; Read current PATH
    ReadRegStr $0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
    
    ; Simply add the paths (we'll handle duplicates at uninstall time)
    StrCpy $0 "$0;$INSTDIR\drivers\chromedriver;$INSTDIR\drivers\geckodriver"
    
    ; Write updated PATH back to registry
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" $0
    
    ; Notify applications of the change
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
    
    ; Install WebDriver Manager for possible future updates
    DetailPrint "Installing WebDriver Manager from local package..."
    ExecWait 'python -m pip install --no-index --find-links="$INSTDIR\packages" webdriver-manager'
    
    ; Configure the system to use the bundled drivers
    DetailPrint "Configuring system to use bundled WebDrivers..."
    SetOutPath "$INSTDIR\config"
    FileOpen $0 "webdriver_config.py" w
    FileWrite $0 'import os$\r$\n'
    FileWrite $0 'os.environ["CHROME_DRIVER_PATH"] = r"$INSTDIR\drivers\chromedriver\chromedriver.exe"$\r$\n'
    FileWrite $0 'os.environ["GECKO_DRIVER_PATH"] = r"$INSTDIR\drivers\geckodriver\geckodriver.exe"$\r$\n'
    FileWrite $0 'os.environ["WDM_LOCAL"] = "1"$\r$\n'
    FileClose $0
    
    ; Create .pth file to auto-import our config
    ExecWait 'python -c "import site; open(site.getsitepackages()[0] + \"\\\formmaster_webdriver.pth\", \"w\").write(\"$INSTDIR\\config\")"'
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
    
    ; Remove browser drivers from PATH (simplified approach that doesn't use ${un.StrReplace})
    DetailPrint "Removing WebDriver directories from PATH..."
    ReadRegStr $0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
    
    ; Create a temporary variable to hold the new path
    StrCpy $1 ""
    
    ; Use direct string manipulation to remove our directories
    ; Split PATH into segments by semicolon and rebuild without our directories
    StrCpy $2 "$0;"  ; Add trailing semicolon to simplify parsing
    StrCpy $3 ""     ; Current segment
    StrLen $4 $2     ; Length of PATH
    StrCpy $5 0      ; Position in string
    
    ; Loop through each character in PATH
    loop:
        StrCpy $6 $2 1 $5    ; Get character at position $5
        
        ${If} $6 == ";"      ; If we found a segment delimiter
            ; Check if this segment is one of our driver paths
            ${If} $3 != "$INSTDIR\drivers\chromedriver"
            ${AndIf} $3 != "$INSTDIR\drivers\geckodriver"
                ; If not, add it to the new path
                ${If} $1 != ""
                    StrCpy $1 "$1;$3"
                ${Else}
                    StrCpy $1 "$3"
                ${EndIf}
            ${EndIf}
            
            StrCpy $3 ""     ; Reset current segment
        ${Else}
            StrCpy $3 "$3$6"  ; Add character to current segment
        ${EndIf}
        
        IntOp $5 $5 + 1      ; Move to next character
        ${If} $5 < $4
            Goto loop
        ${EndIf}
    
    ; Update PATH registry with cleaned value
    WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" $1
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
    
    ; Uninstall Form-Master package
    DetailPrint "Removing Python package..."
    ExecWait 'python -m pip uninstall -y form-master'
    
    ; Remove directories and files
    DetailPrint "Removing installed files..."
    RMDir /r "$INSTDIR\src"
    RMDir /r "$INSTDIR\packages"
    RMDir /r "$INSTDIR\drivers"
    RMDir /r "$INSTDIR\config"
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

; Initialize uninstaller string functions
!insertmacro StrReplace
${UnStrReplace}

; EOF

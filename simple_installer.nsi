; Basic Form-Master Installer (No String Function Complexity)
Unicode true

!define APPNAME "Form-Master"
!define VERSION "0.1.0"
!define PYTHON_VERSION "3.11.1"
!define PYTHON_INSTALLER "python-${PYTHON_VERSION}-amd64.exe"

Name "${APPNAME} ${VERSION}"
OutFile "Form-Master-Setup.exe"
InstallDir "$PROGRAMFILES64\Form-Master"
RequestExecutionLevel admin

!include "MUI2.nsh"
!include "LogicLib.nsh"

; Modern UI settings
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "README.md"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Install"
    SetOutPath "$TEMP"
    
    ; Check if Python is installed
    DetailPrint "Checking for Python installation..."
    ReadRegStr $0 HKLM "Software\Python\PythonCore\3.11\InstallPath" ""
    ReadRegStr $1 HKCU "Software\Python\PythonCore\3.11\InstallPath" ""
    
    ${If} $0 != ""
    ${OrIf} $1 != ""
        DetailPrint "Python 3.11 is already installed."
    ${Else}
        DetailPrint "Installing Python ${PYTHON_VERSION}..."
        File /oname=$TEMP\${PYTHON_INSTALLER} "build\${PYTHON_INSTALLER}"
        ExecWait '"$TEMP\${PYTHON_INSTALLER}" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0'
        Delete "$TEMP\${PYTHON_INSTALLER}"
    ${EndIf}
    
    ; Install Form-Master
    SetOutPath "$INSTDIR"
    File "README.md"
    File "setup.py"
    File /r "src\*.*"
    
    ; Copy dependencies
    CreateDirectory "$INSTDIR\packages"
    SetOutPath "$INSTDIR\packages"
    File /r "build\packages\*.*"
    
    ; Copy drivers
    CreateDirectory "$INSTDIR\drivers\chromedriver"
    CreateDirectory "$INSTDIR\drivers\geckodriver"
    SetOutPath "$INSTDIR\drivers\chromedriver"
    File "build\drivers\chromedriver\chromedriver.exe"
    SetOutPath "$INSTDIR\drivers\geckodriver"
    File "build\drivers\geckodriver\geckodriver.exe"
    
    ; Install everything
    DetailPrint "Installing Form-Master and dependencies..."
    ExecWait 'python -m pip install --upgrade pip'
    ExecWait 'python -m pip install --no-index --find-links="$INSTDIR\packages" wheel setuptools'
    ExecWait 'python -m pip install --no-index --find-links="$INSTDIR\packages" -r "$INSTDIR\src\requirements.txt"'
    ExecWait 'python -m pip install -e "$INSTDIR"'
    
    ; Create formmaster.ico for context menu
    SetOutPath "$INSTDIR"
    ${IfNot} ${FileExists} "$INSTDIR\formmaster.ico"
        File "build\formmaster.ico"
    ${EndIf}
    
    ; Create and update context menu registry entries
    DetailPrint "Setting up context menu integration..."
    
    ; Create context.reg with proper paths from template
    FileOpen $0 "$INSTDIR\context.reg" w
    FileWrite $0 "Windows Registry Editor Version 5.00$\r$\n$\r$\n"
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster]$\r$\n"
    FileWrite $0 '@="Open with Form-Master"$\r$\n'
    FileWrite $0 '"Icon"="$INSTDIR\formmaster.ico"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\command]$\r$\n"
    FileWrite $0 '@="cmd.exe /k cd \\"%V\\" && python -m formmaster.formfiller"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\FormMaster]$\r$\n"
    FileWrite $0 '@="Process with Form-Master"$\r$\n'
    FileWrite $0 '"Icon"="$INSTDIR\formmaster.ico"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\FormMaster\command]$\r$\n"
    FileWrite $0 '@="cmd.exe /k cd \\"%1\\" && python -m formmaster.formfiller \\"%1\\""$\r$\n'
    FileClose $0
    
    ; Import the registry file
    ExecWait 'regedit /s "$INSTDIR\context.reg"'
    
    ; Create shortcuts
    CreateDirectory "$SMPROGRAMS\Form-Master"
    CreateShortcut "$SMPROGRAMS\Form-Master\Form-Master.lnk" "cmd.exe" '/k python -m formmaster.formfiller'
    CreateShortcut "$SMPROGRAMS\Form-Master\Uninstall.lnk" "$INSTDIR\uninstall.exe"
    CreateShortcut "$DESKTOP\Form-Master.lnk" "cmd.exe" '/k python -m formmaster.formfiller'
    
    ; Create uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    ; Update registry
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "DisplayName" "Form-Master"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "DisplayVersion" "${VERSION}"
SectionEnd

Section "Uninstall"
    DetailPrint "Uninstalling Form-Master..."
    
    ; Remove context menu entries
    DetailPrint "Removing context menu integration..."
    DeleteRegKey HKCR "Directory\Background\shell\FormMaster"
    DeleteRegKey HKCR "Directory\shell\FormMaster"
    
    ; Uninstall package
    ExecWait 'python -m pip uninstall -y form-master'
    
    ; Remove directories
    RMDir /r "$INSTDIR\src"
    RMDir /r "$INSTDIR\packages"
    RMDir /r "$INSTDIR\drivers"
    Delete "$INSTDIR\*.*"
    RMDir /r "$INSTDIR"
    
    ; Remove shortcuts
    Delete "$SMPROGRAMS\Form-Master\*.*"
    RMDir "$SMPROGRAMS\Form-Master"
    Delete "$DESKTOP\Form-Master.lnk"
    
    ; Remove registry keys
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master"
SectionEnd

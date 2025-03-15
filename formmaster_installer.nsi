; Form-Master Compact Installer
Unicode true

!define APPNAME "Form-Master"
!define VERSION "0.1.1"
!define PYTHON_VERSION "3.11.4"
!define PYTHON_INSTALLER "python-${PYTHON_VERSION}-amd64.exe"

Name "${APPNAME} ${VERSION}"
OutFile "build\Form-Master-Setup.exe"
InstallDir "$PROGRAMFILES64\Form-Master"
RequestExecutionLevel admin

!include "MUI2.nsh"
!include "LogicLib.nsh"

; Modern UI settings
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
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
        
        ; Download Python if not included
        ${If} ${FileExists} "build\${PYTHON_INSTALLER}"
            DetailPrint "Using bundled Python installer."
            File /oname=$TEMP\${PYTHON_INSTALLER} "build\${PYTHON_INSTALLER}"
        ${Else}
            DetailPrint "Downloading Python ${PYTHON_VERSION}..."
            NSISdl::download "https://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_INSTALLER}" "$TEMP\${PYTHON_INSTALLER}"
            Pop $R0
            ${If} $R0 != "success"
                MessageBox MB_OK|MB_ICONEXCLAMATION "Failed to download Python. Please install Python 3.11 manually."
                Abort
            ${EndIf}
        ${EndIf}
        
        ; Install Python
        ExecWait '"$TEMP\${PYTHON_INSTALLER}" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0' $0
        Delete "$TEMP\${PYTHON_INSTALLER}"
        
        ${If} $0 != 0
            MessageBox MB_OK|MB_ICONEXCLAMATION "Python installation failed. Please install Python 3.11 manually."
            Abort
        ${EndIf}
    ${EndIf}
    
    ; Create installation directory
    SetOutPath "$INSTDIR"
    File "LICENSE"
    File "README.md"
    
    ; Create drivers directory and copy drivers
    CreateDirectory "$INSTDIR\drivers"
    SetOutPath "$INSTDIR\drivers"
    File /r "src\drivers\*.*"
    
    ; Install formmaster pip package
    DetailPrint "Installing Form-Master package..."
    
    ; First try with the pypi package
    nsExec::ExecToStack 'python -m pip install formmaster'
    Pop $0
    Pop $1
    
    ${If} $0 != 0
        DetailPrint "Failed to install from PyPI. Trying local install..."
        
        ; If PyPI install fails, try with a local wheel if available
        ${If} ${FileExists} "dist\formmaster-*.whl"
            FindFirst $2 $3 "dist\formmaster-*.whl"
            ${If} $2 != ""
                DetailPrint "Found local wheel: $3"
                nsExec::ExecToStack 'python -m pip install "$3"'
                FindClose $2
            ${Else}
                FindClose $2
                DetailPrint "No wheel found. Building from source..."
                nsExec::ExecToStack 'python -m pip install -e .'
            ${EndIf}
        ${Else}
            DetailPrint "No wheel found. Building from source..."
            nsExec::ExecToStack 'python -m pip install -e .'
        ${EndIf}
    ${EndIf}
    
    ; Configure environment for drivers
    DetailPrint "Configuring drivers path..."
    ${If} ${FileExists} "$INSTDIR\drivers\chromedriver\chromedriver.exe"
        System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("PATH", "$INSTDIR\drivers\chromedriver;$PATH").r0'
        ReadEnvStr $R0 "PATH"
        WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PATH" "$INSTDIR\drivers\chromedriver;$R0"
    ${EndIf}
    
    ; Create context menu entries
    DetailPrint "Creating context menu entries..."
    SetOutPath "$INSTDIR"
    
    ; Create context.reg
    FileOpen $0 "$INSTDIR\context.reg" w
    FileWrite $0 "Windows Registry Editor Version 5.00$\r$\n$\r$\n"
    
    ; USydney entries
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\USydney]$\r$\n"
    FileWrite $0 '@="Sydney University"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\USydney\command]$\r$\n"
    FileWrite $0 '@="python -m formmaster --uni=usyd \"%V\""$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\USydney]$\r$\n"
    FileWrite $0 '@="Sydney University"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\USydney\command]$\r$\n"
    FileWrite $0 '@="python -m formmaster --uni=usyd \"%1\""$\r$\n$\r$\n'
    
    ; UNSW entries
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\UNSW]$\r$\n"
    FileWrite $0 '@="New South Wales University"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\UNSW\command]$\r$\n"
    FileWrite $0 '@="python -m formmaster --uni=unsw \"%V\""$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\UNSW]$\r$\n"
    FileWrite $0 '@="New South Wales University"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\UNSW\command]$\r$\n"
    FileWrite $0 '@="python -m formmaster --uni=unsw \"%1\""$\r$\n'
    
    FileClose $0
    
    ; Import the registry file
    DetailPrint "Importing registry entries..."
    ExecWait 'regedit /s "$INSTDIR\context.reg"'
    
    ; Create shortcuts
    CreateDirectory "$SMPROGRAMS\Form-Master"
    CreateShortcut "$SMPROGRAMS\Form-Master\Form-Master.lnk" "cmd.exe" '/k python -m formmaster'
    CreateShortcut "$SMPROGRAMS\Form-Master\Uninstall.lnk" "$INSTDIR\uninstall.exe"
    CreateShortcut "$DESKTOP\Form-Master.lnk" "cmd.exe" '/k python -m formmaster'
    
    ; Create uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    ; Add uninstall information to Add/Remove Programs
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "DisplayName" "Form-Master"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "Publisher" "Form-Master Team"
SectionEnd

Section "Uninstall"
    ; Remove registry entries
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master"
    DeleteRegKey HKCR "Directory\Background\shell\USydney"
    DeleteRegKey HKCR "Directory\shell\USydney"
    DeleteRegKey HKCR "Directory\Background\shell\UNSW"
    DeleteRegKey HKCR "Directory\shell\UNSW"
    
    ; Uninstall the Python package
    DetailPrint "Uninstalling Form-Master package..."
    nsExec::ExecToStack 'python -m pip uninstall -y formmaster'
    
    ; Remove program files
    Delete "$INSTDIR\uninstall.exe"
    Delete "$INSTDIR\LICENSE"
    Delete "$INSTDIR\README.md"
    Delete "$INSTDIR\context.reg"
    RMDir /r "$INSTDIR\drivers"
    
    ; Remove start menu shortcuts
    Delete "$SMPROGRAMS\Form-Master\Form-Master.lnk"
    Delete "$SMPROGRAMS\Form-Master\Uninstall.lnk"
    RMDir "$SMPROGRAMS\Form-Master"
    Delete "$DESKTOP\Form-Master.lnk"
    
    ; Remove installation directory if empty
    RMDir "$INSTDIR"
SectionEnd

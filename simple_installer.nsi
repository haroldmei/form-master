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
    
    ; Find Python executable path
    DetailPrint "Locating Python executable..."
    StrCpy $9 "" ; Variable to store Python path
    
    ; Try to get Python path from registry
    ReadRegStr $9 HKLM "Software\Python\PythonCore\3.11\InstallPath" ""
    ${If} $9 != ""
        StrCpy $9 "$9python.exe"
    ${Else}
        ReadRegStr $9 HKCU "Software\Python\PythonCore\3.11\InstallPath" ""
        ${If} $9 != ""
            StrCpy $9 "$9python.exe"
        ${EndIf}
    ${EndIf}
    
    ; If not found in registry, try to locate using 'where' command
    ${If} $9 == ""
        DetailPrint "Python not found in registry, trying PATH..."
        nsExec::ExecToStack 'cmd /c where python.exe'
        Pop $0 ; Return value
        Pop $1 ; Output
        
        ${If} $0 == "0"
            ; Extract first line from output (if multiple Python installations)
            StrCpy $2 0  ; Index
            loop:
                StrCpy $3 $1 1 $2  ; Get character at position
                StrCmp $3 "$\r" found
                StrCmp $3 "$\n" found
                StrCmp $3 "" done
                IntOp $2 $2 + 1
                Goto loop
            found:
                StrCpy $9 $1 $2  ; Extract path up to newline
            done:
        ${EndIf}
    ${EndIf}
    
    ; If still not found, use "python" and hope it's in the PATH
    ${If} $9 == ""
        DetailPrint "Python executable not found, using 'python' from PATH"
        StrCpy $9 "python"
    ${EndIf}
    
    DetailPrint "Using Python: $9"
    
    ; Create formmaster.ico for context menu
    SetOutPath "$INSTDIR"
    ${IfNot} ${FileExists} "$INSTDIR\formmaster.ico"
        File "build\formmaster.ico"
    ${EndIf}
    
    ; Create and update context menu registry entries
    DetailPrint "Setting up context menu integration with university-specific options..."
    
    ; Create context.reg directly with proper Python path
    DetailPrint "Creating registry entries for context menu..."
    FileOpen $0 "$INSTDIR\context.reg" w
    FileWrite $0 "Windows Registry Editor Version 5.00$\r$\n$\r$\n"
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster]$\r$\n"
    FileWrite $0 '@="Form-Master"$\r$\n'
    FileWrite $0 '"Icon"="$9"$\r$\n'
    FileWrite $0 '"SubCommands"=""$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\general]$\r$\n"
    FileWrite $0 '@="General Form-Master"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\general\command]$\r$\n"
    FileWrite $0 '@="\"$9\" -m formfiller \"%V\""$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\usyd]$\r$\n"
    FileWrite $0 '@="Sydney University Application"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\usyd\command]$\r$\n"
    FileWrite $0 '@="\"$9\" -m formfiller --uni=usyd \"%V\""$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\unsw]$\r$\n"
    FileWrite $0 '@="New South Wales University Application"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\unsw\command]$\r$\n"
    FileWrite $0 '@="\"$9\" -m formfiller --uni=unsw \"%V\""$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\FormMaster]$\r$\n"
    FileWrite $0 '@="Process with Form-Master"$\r$\n'
    FileWrite $0 '"Icon"="$9"$\r$\n'
    FileWrite $0 '"SubCommands"=""$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\general]$\r$\n"
    FileWrite $0 '@="General Form-Master"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\general\command]$\r$\n"
    FileWrite $0 '@="\"$9\" -m formfiller \"%1\""$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\usyd]$\r$\n"
    FileWrite $0 '@="Sydney University Application"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\usyd\command]$\r$\n"
    FileWrite $0 '@="\"$9\" -m formfiller --uni=usyd \"%1\""$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\unsw]$\r$\n"
    FileWrite $0 '@="New South Wales University Application"$\r$\n$\r$\n'
    
    FileWrite $0 "[HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\unsw\command]$\r$\n"
    FileWrite $0 '@="\"$9\" -m formfiller --uni=unsw \"%1\""$\r$\n'
    
    FileClose $0
    
    ; Import the registry file
    ExecWait 'regedit /s "$INSTDIR\context.reg"'
    
    ; Create shortcuts (updated command)
    CreateDirectory "$SMPROGRAMS\Form-Master"
    CreateShortcut "$SMPROGRAMS\Form-Master\Form-Master.lnk" "cmd.exe" '/k python -m formfiller'
    CreateShortcut "$SMPROGRAMS\Form-Master\Uninstall.lnk" "$INSTDIR\uninstall.exe"
    CreateShortcut "$DESKTOP\Form-Master.lnk" "cmd.exe" '/k python -m formfiller'
    
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

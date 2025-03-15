/**
 *  EnvVarUpdate.nsh
 *    : Environmental Variables: append, prepend, and remove entries
 *
 *     WARNING: If you use StrFunc.nsh header then include it before this file
 *              with all required definitions. This is to avoid conflicts
 *
 *  Usage:
 *    ${EnvVarUpdate} "ResultVar" "EnvVarName" "Action" "RegLoc" "PathString"
 *
 *  Credits:
 *  Version 1.0 
 *  * Cal Turney (turnec2)
 *  * Amir Szekely (KiCHiK) and e-circ for developing the forerunners of this
 *    function: AddToPath, un.RemoveFromPath, AddToEnvVar, un.RemoveFromEnvVar,
 *    WriteEnvStr, and un.DeleteEnvStr
 *  * Diego Pedroso (deguix) for StrTok
 *  * Kevin English (kenglish_hi) for StrContains
 *  * Hendri Adriaens (Smile2Me) for StrReplace
 *
 *  Version 1.1 (compatibility with StrFunc.nsh)
 *  * techtonik
 *
 *  http://nsis.sourceforge.net/Environmental_Variables:_append%2C_prepend%2C_and_remove_entries
 *
 */


!ifndef ENVVARUPDATE_FUNCTION
!define ENVVARUPDATE_FUNCTION
!verbose push
!verbose 3
!include "LogicLib.nsh"
!include "WinMessages.nsh"
!include "StrFunc.nsh"

; ---- Fix for conflict if StrFunc.nsh is already includes in main file -----------------------
!macro _IncludeStrFunction StrFuncName
  !ifndef ${StrFuncName}_INCLUDED
    ${${StrFuncName}}
  !endif
  !ifndef Un${StrFuncName}_INCLUDED
    ${Un${StrFuncName}}
  !endif
  !define un.${StrFuncName} "${Un${StrFuncName}}"
!macroend

!insertmacro _IncludeStrFunction StrTok
!insertmacro _IncludeStrFunction StrStr
!insertmacro _IncludeStrFunction StrRep

; ---------------------------------- Macro Definitions ----------------------------------------
!macro _EnvVarUpdateConstructor ResultVar EnvVarName Action Regloc PathString
  Push "${EnvVarName}"
  Push "${Action}"
  Push "${RegLoc}"
  Push "${PathString}"
    Call EnvVarUpdate
  Pop "${ResultVar}"
!macroend
!define EnvVarUpdate '!insertmacro "_EnvVarUpdateConstructor"'
 
!macro _unEnvVarUpdateConstructor ResultVar EnvVarName Action Regloc PathString
  Push "${EnvVarName}"
  Push "${Action}"
  Push "${RegLoc}"
  Push "${PathString}"
    Call un.EnvVarUpdate
  Pop "${ResultVar}"
!macroend
!define un.EnvVarUpdate '!insertmacro "_unEnvVarUpdateConstructor"'
; ---------------------------------- Macro Definitions end-------------------------------------
 
;----------------------------------- EnvVarUpdate start ---------------------------------------
!define hklm_all_users     'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
!define hkcu_current_user  'HKCU "Environment"'
 
!macro EnvVarUpdateCall Result EnvVarName Action RegLoc PathString
  Push "${EnvVarName}"
  Push "${Action}"
  Push "${RegLoc}"
  Push "${PathString}"
  Call EnvVarUpdate
  Pop "${Result}"
!macroend
 
 
Function EnvVarUpdate
 
  Push $0
  Exch 4
  Exch $1
  Exch 3
  Exch $2
  Exch 2
  Exch $3
  Exch
  Exch $4
  Push $5
  Push $6
  Push $7
  Push $8
  Push $9
  Push $R0
 
  /* After this point:
  -------------------------
     $0 = ResultVar     (returned)
     $1 = EnvVarName    (input)
     $2 = Action        (input)
     $3 = RegLoc        (input)
     $4 = PathString    (input)
     $5 = Orig EnvVar   (read from registry)
     $6 = Len of $0     (temp)
     $7 = tempstr1      (temp)
     $8 = Entry counter (temp)
     $9 = tempstr2      (temp)
     $R0 = tempChar     (temp)  */
 
  ; Step 1:  Read contents of EnvVarName from RegLoc
  ;
  ; Check for empty EnvVarName
  ${If} $1 == ""
    SetErrors
    DetailPrint "ERROR: EnvVarName is blank"
    Goto EnvVarUpdate_Restore_Vars
  ${EndIf}
 
  ; Check for valid Action
  ${If}    $2 != "A"
  ${AndIf} $2 != "P"
  ${AndIf} $2 != "R"
    SetErrors
    DetailPrint "ERROR: Invalid Action - must be A, P, or R"
    Goto EnvVarUpdate_Restore_Vars
  ${EndIf}
 
  ${If} $3 == HKLM
    ReadRegStr $5 ${hklm_all_users} $1     ; Get EnvVarName from all users into $5
  ${ElseIf} $3 == HKCU
    ReadRegStr $5 ${hkcu_current_user} $1  ; Get EnvVarName from current user into $5
  ${Else}
    SetErrors
    DetailPrint 'ERROR: Action is [$3] but must be "HKLM" or HKCU"'
    Goto EnvVarUpdate_Restore_Vars
  ${EndIf}
 
  ; Check for empty PathString
  ${If} $4 == ""
    SetErrors
    DetailPrint "ERROR: PathString is blank"
    Goto EnvVarUpdate_Restore_Vars
  ${EndIf}
 
  ; Make sure we've got some work to do
  ${If} $5 == ""
  ${AndIf} $2 == "R"
    SetErrors
    DetailPrint "$1 is empty - Nothing to remove"
    Goto EnvVarUpdate_Restore_Vars
  ${EndIf}
 
  ; Step 2: Scrub EnvVar
  ;
  StrCpy $0 $5                             ; Copy the contents to $0
  ; Remove spaces around semicolons (NOTE: spaces before the 1st entry or
  ; after the last one are not removed here but instead in Step 3)
  ${If} $0 != ""                           ; If EnvVar is not empty ...
    ${Do}
      ${${UN}StrStr} $7 $0 " ;"
      ${If} $7 == ""
        ${ExitDo}
      ${EndIf}
      ${${UN}StrRep} $0  $0 " ;" ";"         ; Remove '<space>;'
    ${Loop}
    ${Do}
      ${${UN}StrStr} $7 $0 "; "
      ${If} $7 == ""
        ${ExitDo}
      ${EndIf}
      ${${UN}StrRep} $0  $0 "; " ";"         ; Remove ';<space>'
    ${Loop}
    ${Do}
      ${${UN}StrStr} $7 $0 ";;"
      ${If} $7 == ""
        ${ExitDo}
      ${EndIf}
      ${${UN}StrRep} $0  $0 ";;" ";"
    ${Loop}
 
    ; Remove a leading or trailing semicolon from EnvVar
    StrCpy  $7  $0 1 0
    ${If} $7 == ";"
      StrCpy $0  $0 "" 1                   ; Remove leading semicolon if present
    ${EndIf}
    StrLen $6 $0
    IntOp $6 $6 - 1
    StrCpy $7  $0 1 $6
    ${If} $7 == ";"
     StrCpy $0  $0 $6                      ; Remove trailing semicolon if present
    ${EndIf}
    ; Remove all trailing spaces
    ${Do}
      StrCpy $7  $0 1 $6
      ${If} $7 != " "
        ${ExitDo}
      ${EndIf}
      StrCpy $0  $0 $6                     ; Remove trailing space
      IntOp $6 $6 - 1
    ${Loop}
    ; Remove all leading spaces
    ${Do}
      StrCpy $7  $0 1 0
      ${If} $7 != " "
        ${ExitDo}
      ${EndIf}
      StrCpy $0  $0 "" 1                   ; Remove leading space
    ${Loop}
  ${EndIf}
 
  ; Step 3: Add/Append/Remove to path
  ;
  ${If} $2 == "A"                          ; Append
    ${If} $5 == ""                         ; EnvVar empty
      StrCpy $0 $4                         ; Use the first dir
    ${Else}
      StrCpy $0 $5
      ${If} $0 == $4                       ; if identical, skip
        Goto EnvVarUpdate_Restore_Vars
      ${EndIf}
      ; Append the configured path to the existing path, iff not found
      ; A ";" is inserted if needed
      Push "$0;"                           ; Prepare "$0;" for search
      Push "$4;"                           ; Search for "$4;"
      Call StrStr
      Pop $7                               ; $7 = search result
      ${If} $7 == ""
        Push "$0;"                         ; Prepare "$0;" for search
        Push "$4\;"                        ; Search for "$4\;"
        Call StrStr
        Pop $7                             ; $7 = search result
        ${If} $7 == ""
          StrCpy $0 $0;$4                  ; Append the path
        ${EndIf}
      ${EndIf}
    ${EndIf}
  ${ElseIf} $2 == "P"                      ; Prepend
    ${If} $5 == ""                         ; EnvVar empty
      StrCpy $0 $4                         ; Use the first dir
    ${Else}
      StrCpy $0 $5
      ${If} $0 == $4                       ; if identical, skip
        Goto EnvVarUpdate_Restore_Vars
      ${EndIf}
      ; Append the configured path to the existing path, iff not found
      ; A ";" is inserted if needed
      Push "$4;"                           ; Prepare "$4;" for search
      Push "$0;"                           ; Search for "$0;"
      Call StrStr
      Pop $7                               ; $7 = search result
      ${If} $7 == ""
        Push "$4;"                         ; Prepare "$4;" for search
        Push "$0\;"                        ; Search for "$0\;"
        Call StrStr
        Pop $7                             ; $7 = search result
        ${If} $7 == ""
          StrCpy $0 $4;$0                  ; Prepend the path
        ${EndIf}
      ${EndIf}
    ${EndIf}
  ${ElseIf} $2 == "R"                      ; Remove
    ${If} $5 == ""                         ; EnvVar empty
      Goto EnvVarUpdate_Restore_Vars
    ${EndIf}
    ; Ensure we have a clean starting point
    StrCpy $9 $0
    StrCpy $0 ""
    ; Start with the path to remove
    StrCpy $8 "$4;"
    ; Compare each entry in the path one at a time
    ${Do}
      ${${UN}StrTok} $7 $9 ";" $8 "0"      ; $7 = next entry, $8 = entry counter
      ${If} $7 == ""                        ; If we've run out of entries...
        ${ExitDo}                           ; ... exit the loop
      ${EndIf}                              ; Otherwise...
        ; Test if the path to remove exists in $7
        Push $7
        Push $4
        Call StrStr
        Pop $6
        ${If} $6 == ""                     ; If not found...
          ${If} $0 == ""                   ; Build new path from the first entry
            StrCpy $0 $7
          ${Else}                          ; ... or add it to the end
            StrCpy $0 "$0;$7"
          ${EndIf}                          
          StrCpy $8 "$8" + 1                ; Bump the counter
        ${ElseIf} $6 = $7
          StrCpy $8 "$8" + 1                ; Bump the counter
        ${Else}
          ${If} $0 == ""                   ; Build new path from first entry
            StrCpy $0 $7
          ${Else}                          ; ... or add it to the end
            StrCpy $0 "$0;$7"
          ${EndIf}
          StrCpy $8 "$8" + 1                ; Bump the counter
        ${EndIf}
    ${Loop}
  ${EndIf}
 
  ; Step 4:  Remove any cruft or duplicates crept in path during add/append/or remove
  ; Remove spaces around semicolons (NOTE: spaces before the 1st entry or
  ; after the last one are not removed here but instead in Step 3)
  ${If} $0 != ""                           ; If $0 is not empty ...
    ${Do}
      ${${UN}StrStr} $7 $0 " ;"
      ${If} $7 == ""
        ${ExitDo}
      ${EndIf}
      ${${UN}StrRep} $0  $0 " ;" ";"         ; Remove '<space>;'
    ${Loop}
    ${Do}
      ${${UN}StrStr} $7 $0 "; "
      ${If} $7 == ""
        ${ExitDo}
      ${EndIf}
      ${${UN}StrRep} $0  $0 "; " ";"         ; Remove ';<space>'
    ${Loop}
    ${Do}
      ${${UN}StrStr} $7 $0 ";;"
      ${If} $7 == ""
        ${ExitDo}
      ${EndIf}
      ${${UN}StrRep} $0  $0 ";;" ";"
    ${Loop}
 
    ; Remove a leading or trailing semicolon from EnvVar
    StrCpy  $7  $0 1 0
    ${If} $7 == ";"
      StrCpy $0  $0 "" 1                   ; Remove leading semicolon if present
    ${EndIf}
    StrLen $6 $0
    IntOp $6 $6 - 1
    StrCpy $7  $0 1 $6
    ${If} $7 == ";"
     StrCpy $0  $0 $6                      ; Remove trailing semicolon if present
    ${EndIf}
    ; Remove all trailing spaces
    ${Do}
      StrCpy $7  $0 1 $6
      ${If} $7 != " "
        ${ExitDo}
      ${EndIf}
      StrCpy $0  $0 $6                     ; Remove trailing space
      IntOp $6 $6 - 1
    ${Loop}
    ; Remove all leading spaces
    ${Do}
      StrCpy $7  $0 1 0
      ${If} $7 != " "
        ${ExitDo}
      ${EndIf}
      StrCpy $0  $0 "" 1                   ; Remove leading space
    ${Loop}
  ${EndIf}
 
  ; Step 5:  Save the new EnvVar and broadcast the change
  ;
  ${If} $3 == HKLM
    WriteRegExpandStr ${hklm_all_users} $1 $0     ; Write it in all users section
  ${ElseIf} $3 == HKCU
    WriteRegExpandStr ${hkcu_current_user} $1 $0  ; Write it to current user section
  ${EndIf}
 
  ; Always write to the "volatile" (HKCU) location to provide immediate
  ; feedback in the current environment.
  WriteRegExpandStr ${hkcu_current_user} $1 $0
 
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} \
            0 "STR:Environment" /TIMEOUT=5000
 
  EnvVarUpdate_Restore_Vars:
  ;
  ; Restore the variables used in this macro
  ;
  Pop $R0
  Pop $9
  Pop $8
  Pop $7
  Pop $6
  Pop $5
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
 
FunctionEnd
 
!macro _un.EnvVarUpdateConstructor ResultVar EnvVarName Action Regloc PathString
  Push "${EnvVarName}"
  Push "${Action}"
  Push "${RegLoc}"
  Push "${PathString}"
    Call un.EnvVarUpdate
  Pop "${ResultVar}"
!macroend
!define un.EnvVarUpdate '!insertmacro "_un.EnvVarUpdateConstructor"'
 
Function un.EnvVarUpdate
  Call EnvVarUpdate
FunctionEnd

!verbose pop
!endif


Option Explicit
const HKEY_CLASSES_ROOT = &H80000000
const HKEY_CURRENT_USER = &H80000001
const HKEY_LOCAL_MACHINE = &H80000002
const HKEY_USERS = &H80000003

Dim objWshShell, objFSO, objWMI, WshEnv
Dim ProgramFiles, strScriptFileDirectory

Set objWshShell = WScript.CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objWMI = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\.\root\cimv2")
Set WshEnv = objWshShell.Environment("PROCESS")
ProgramFiles = objWshShell.ExpandEnvironmentStrings("%ProgramFiles%")
strScriptFileDirectory = objFSO.GetParentFolderName(wscript.ScriptFullName)

On Error Resume Next
ExecuteApplicationItems

Wscript.Quit



' ~$~----------------------------------------~$~
'            FUNCTIONS & SUBROUTINES
' ~$~----------------------------------------~$~
Sub ExecuteApplicationItems
Dim strSubKey

' Attempts to remove old previous Mozilla Firefox installations.
If objFSO.FileExists (ProgramFiles & "\Mozilla Firefox\uninstall\uninst.exe") Then
    objWshShell.Run """" & ProgramFiles & "\Mozilla Firefox\uninstall\uninst.exe"" /S", 1, True
End If
If objFSO.FileExists (ProgramFiles & "\Mozilla Firefox\uninstall\helper.exe") Then
    objWshShell.Run """" & ProgramFiles & "\Mozilla Firefox\uninstall\helper.exe"" /S", 1, True
End If

strSubKey = DetermineSubKey(HKEY_LOCAL_MACHINE,"SOFTWARE\Classes\Installer\Products","ProductName","Mozilla Firefox")
If Not strSubKey = "" Then
    DeleteRegistryKey HKEY_LOCAL_MACHINE, strSubKey
End If
End Sub

' ~$~----------------------------------------~$~
Function DetermineSubKey(strRegRoot,strKeyPath,strValueName,strPattern)
' Attempts to check the subkeys in order to locate and delete the correct subkey that matches the submitted text pattern.
Dim objReg, RegExp, subkey, arrSubKeys, strValue, strCheckKey, strKey

On Error Resume Next

Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
Set RegExp = new RegExp
RegExp.IgnoreCase = true
RegExp.Pattern = strPattern
objReg.EnumKey strRegRoot, strKeyPath, arrSubKeys
strKey = ""

For Each subkey In arrSubKeys
    strValue = ""
    strCheckKey = strKeyPath & "\" & subkey
    ' Attempts to obtain the submitted subkey value.
    objReg.GetStringValue strRegRoot,strCheckKey,strValueName,strValue

    If Not IsNull(strValue) Then
        If (RegExp.test (strValue) = TRUE) Then
            strKey = subkey
        End If
    End If
Next

If strKey = "" Then
    DetermineSubKey = ""
Else
    DetermineSubKey = strKeyPath & "\" & strKey
End If
End Function

' ~$~----------------------------------------~$~
Sub DeleteRegistryKey(RegRoot, strPath)
' Attempts to delete all subkeys and values before deleting the parent registry key.
Dim strRegistryKeys, SubKeyCount, objRegistry, lRC, lRC2, strKey

On Error Resume Next

Set objRegistry = GetObject("winmgmts:root\default:StdRegProv")
lRC = objRegistry.EnumKey(RegRoot, strPath, strRegistryKeys)

If IsArray(strRegistryKeys) Then
    For each strKey in strRegistryKeys
        DeleteRegistryKey RegRoot, strPath & "\" & strKey
    Next
End If

lRC2 = objRegistry.DeleteKey(RegRoot, strPath)
End Sub 
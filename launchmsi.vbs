Set WshShell = WScript.CreateObject("WScript.Shell") 
Set objFSO = CreateObject("Scripting.FileSystemObject") 
strScriptFileDirectory = objFSO.GetParentFolderName(wscript.ScriptFullName) 

WshShell.Run "msiexec /i " & strScriptFileDirectory & "\1Synchronization-v2.0-x64-ENU.msi /q", 0, True 

WshShell.Run "msiexec /i " & strScriptFileDirectory & "\2ProviderServices-v2.0-x64-ENU.msi /q", 0, True 

WshShell.Run "msiexec /i " & strScriptFileDirectory & "\3SyncToySetup.msi /q", 0, True

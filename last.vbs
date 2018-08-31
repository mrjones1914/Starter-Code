  Dim Fso : Set Fso = CreateObject("Scripting.FileSystemObject")
  checkName = "ggilman"
  Set oContainer = GetObject("WinNT://Charlotte")
  oContainer.Filter = Array("computer")
  For Each oComputer1 in oContainer
      theComputer = oComputer.Name
      Set f = fso.GetFolder("\\" & theComputer & "c$\Users")
      Set sf = f.SubFolders
      For Each f1 in sf
              If lcase(checkName) = lcase(f1.Name) then
              MsgBox f1.Name
              End If
      Next
  'Next
  MsgBox "Done"
  
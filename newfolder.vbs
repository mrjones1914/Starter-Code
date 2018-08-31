Set WshNetwork = CreateObject("WScript.Network")
ParentFolder = ".\"
set objShell = CreateObject("Shell.Application")
set objFolder = objShell.NameSpace(ParentFolder)
Dim archive, subfolder, Name
Name = wshNetwork.UserName
archive = 1
Subfolder = 1
While archive < 5
 objFolder.NewFolder Name & " " & archive
 While Subfolder < 5
  ParentFolder = ".\" & Name
  objFolder.NewFolder Name & " " & Subfolder
  Subfolder = subfolder + 1
 Wend
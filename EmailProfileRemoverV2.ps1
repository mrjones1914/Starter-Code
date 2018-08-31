Start-Sleep -s 10

$User = [Environment]::UserName
$path = "C:\Outlook\" + "$User"
$ClearOutlook = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem"
If(-not(Test-Path -Path $path))
  {
   #  del $ClearOutlook -force -recurse
   
   del $ClearOutlook -force -recurse
   New-Item -Path $path -type directory
   }
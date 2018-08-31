
##Revised 03.14.2014
 
#Set path to Installers
$uninstaller = "C:\Install\CitrixReceiverEnterprise.exe"
$installer = "C:\Install\CitrixReceiver.exe"

if ((Get-WmiObject -Class Win32_OperatingSystem -ea 0).OSArchitecture -eq "64-bit") {
$architechture = "x64"
}
else {
$architechture = "x86"
}

if (((test-path "c:\program files (x86)\Citrix\Selfserviceplugin") -like "false") -AND ($architechture -like "x64")){
$installed = "False"
}

if (((test-path "c:\program files\Citrix\Selfserviceplugin") -like "false")  -AND ($architechture -like "x86")){
$installed = "False"
}

if ($installed -like "false") {

##UNINSTALL##

if ((test-path c:\temp\CitrixUninstalled.txt) -like "false") {

#Reg-paths to clean up
$RegPath = "HKLM:\SOFTWARE\Citrix"
$RegPath64 = "HKLM:\SOFTWARE\Wow6432Node\Citrix"
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue
$ClassesRootPath = "HKCR:\Installer\Products"


#Kill all Citrix-processes
get-process | where {$_.company -like "*citrix*"} | Stop-Process -Force -ErrorAction SilentlyContinue
            
#Execute uninstall-command
start-process $uninstaller -args "/uninstall /silent" -wait
 
#Clean up remaining registry settings
if ((test-path $RegPath) -like "true") {
    remove-item $_.pspath -force -recurse -ErrorAction SilentlyContinue
                }
if ((test-path $RegPath64) -like "true") {
                remove-item $_.pspath -force -recurse -ErrorAction SilentlyContinue
                }
#Clean out Citrix entries from Classes_Root
$CRResults = Get-ChildItem $ClassesRootPath -Recurse -ErrorAction SilentlyContinue | foreach {gp ($_.pspath)}
$CRResults | where {$_.ProductName -like "*Citrix*"} | foreach {
    remove-item $_.pspath -force -recurse -ErrorAction SilentlyContinue
}

#Remove local files 32- and 64-bit
remove-item -recurse -path $env:Programfiles\Citrix\ -force -ErrorAction SilentlyContinue
 
if ($architecture -like "x64") {
remove-item -recurse -path ${env:ProgramFiles(x86)}\Citrix -force -ErrorAction SilentlyContinue
}

New-Item c:\Temp\CitrixUninstalled.txt -type file

#Reboot
shutdown /r /t 00
}

##INSTALLATION##

if (((test-path c:\temp\CitrixInstalled.txt) -like "false") -and ((test-path c:\temp\CitrixUnInstalled.txt) -like "true")) {
 
#Install new version
Start-Process $installer -Arg "/includeSSON STORE0=Noah;https://web01.noah.corp/Citrix/Noah/discovery;on;Noah Apps /silent" -Wait -Verb 'Runas' 


New-Item c:\Temp\CitrixInstalled.txt -type file

#Reboot
shutdown /r /t 00
}

##POST-INSTALLATION

if (((test-path c:\temp\CitrixInstalled.txt) -like "true") -and ((test-path c:\temp\CitrixFinalized.txt) -like "False")) {

# Create shortcut in startup
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Citrix Receiver.lnk")
if ($architechture -like "x64") {
$Shortcut.TargetPath = "C:\Program Files (x86)\Citrix\SelfServicePlugin\SelfService.exe"}
else {
$Shortcut.TargetPath = "C:\Program Files\Citrix\SelfServicePlugin\SelfService.exe"}
$Shortcut.Save()

New-Item c:\Temp\CitrixFinalized.txt -type file
}
}
else {
write-host "Citrix Already Installed"
}
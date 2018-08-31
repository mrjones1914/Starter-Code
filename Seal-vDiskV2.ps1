###########################################################
#Step 2 - Clean-up event logs
###########################################################
Get-EventLog -List |%{$_.clear()}

###########################################################
#Step 5 - If MSDTS is installed
###########################################################
msdtc.exe -reset

###########################################################
#Step 6 - if Message Queuing is installed, clear its cache
###########################################################
#Stop-Service MQAC -Force -ErrorAction SilentlyContinue
#Stop-Service MSMQ -Force -ErrorAction SilentlyContinue

###########################################################
#Step 9 - Stop Profile Mgr Service
###########################################################
Stop-Service ctxProfile -Force

###########################################################
#Step 10 - Reset Profile Mgr INI
###########################################################
Rename-Item "C:\Program Files\Citrix\User Profile Manager\UPMPolicyDefaults_all.ini" UPMPolicyDefaults_all.old -ErrorAction SilentlyContinue

###########################################################
#Step 11 - Remove Profile Mgr Logs
###########################################################
Get-Item -Path C:\Windows\System32\LogFiles\UserProfileManager\* | Remove-Item -Force -Confirm:$False -ErrorAction SilentlyContinue

###########################################################
#Step 17 - Stop Client DHCP service
###########################################################
Stop-Service dhcp -Force

###########################################################
#Step 18 - Clean up DHCP settings in the Registry
###########################################################
#switch ($env:COMPUTERNAME) {
<# "ENTER HOST NAME" {
regedit /s $((Get-Item -Path ".\" -Verbose).FullName)\DHCP_clear_01.reg
$env:COMPUTERNAME
break
}
"ENTER HOST NAME" {
regedit /s $((Get-Item -Path ".\" -Verbose).FullName)\DHCP_clear_02.reg
$env:COMPUTERNAME
break
}
"ENTER HOST NAME" {
regedit /s $((Get-Item -Path ".\" -Verbose).FullName)\DHCP_clear_03.reg
$env:COMPUTERNAME
break
} #>
#"ENTER HOST NAME" {
regedit /s $((Get-Item -Path ".\" -Verbose).FullName)\DHCP_clear.reg
$env:COMPUTERNAME
break
#}
#}
###########################################################
#Step 21 - Shut 'er down
###########################################################
shutdown /s /t 0
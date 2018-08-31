cd e:\Veritas\NetBackup\bin\admincmd

$Input1 = Read-Host 'Enter Server FQDN'
$CompName = "$input1"

$Input2 = Read-Host 'Enter Change File Name'
$ChgFile = "$input2"

$Input3 = Read-Host 'Enter vCenter Server FQDN'
$VMServer = "$input3"

$IRComm = "nbrestorevm -vmw -ir_activate -C $CompName -temp_location NBU-Instant-Recovery -R /E/InstantRecovery/$ChgFile.txt -vmserver $VMServer"

Invoke-Expression -Command "cmd.exe /C $IRComm"
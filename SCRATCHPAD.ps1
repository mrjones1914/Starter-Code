$path = Read-host "Enter the UNC path including name of file>>>"  # my example: \\myserver\myshare\software\flash\install_flash_player_ax_11.4.402.265.exe
$parameters = Read-host "Enter parameters or switches example: "/qn" -Wait>>>" # my example: -install
$packageinstall=(split-path $location -leaf) + ' ' + $parameters # evaluates to: install_flash_player_ax_11.4.402.265.exe -install
$computers = get-content c:\temp\computers.txt

$computers | where{test-connection $_ -quiet -count 1} | ForEach-Object{

copy-item $path "\\$_\c$\temp" # copy install file to the remote machine

$newProc=([WMICLASS]"\\$_\root\cimv2:win32_Process").Create("C:\temp\$packageinstall")

If ($newProc.ReturnValue -eq 0) { Write-Host $_ $newProc.ProcessId } else { write-host $_ Process create failed with $newProc.ReturnValue }
}


$parameters = Read-host "Enter parameters or switches example: "/qn" -Wait>>>" # my example: -install
$packageinstall=(split-path $location -leaf) + ' ' + $parameters # evaluates to: install_flash_player_ax_11.4.402.265.exe -install
$address = get-content c:\temp\computers.txt


$address | where{test-connection $_ -quiet -count 1} | ForEach-Object{

copy-item $location "\\$_\c$\temp" # copy install file to the remote machine 

$newProc=([WMICLASS]"\\$_\root\cimv2:win32_Process").Create("C:\temp\$packageinstall")

If ($newProc.ReturnValue -eq 0) { Write-Host $_ $newProc.ProcessId } else { write-host $_ Process create failed with $newProc.ReturnValue }

}
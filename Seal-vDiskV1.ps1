###########################################################
#Step 1 - Defrag/Run chkdsk on C:
###########################################################

#Helper function to Decode Return Code
function Get-DfragReturn {
param ([uint16] $char)
#parse and return values
If ($char -ge 0 -and $char -le 5) {
switch ($char) {
0 {"00-Success"}
1 {"01-Success (volume locked and chkdsk scheduled for reboot)"}
2 {"02-unsupported file system"}
3 {"03-Unknown file system"}
4 {"04-No Media in drive"}
5 {"05-Unknown Error"}
}
}
Else {
"{0} - *Invalid Result Code*" -f $char}
Return
}

#Get all local disks
#then get first drive (C:\)
$disks=gwmi win32_Volume
$c=$disks | where {$_.name -eq "C:\"}

#print start
"Checking {0} on system: {1}" -f $c.name,$c.SystemName

#Now specify chkdsk paramaters and call chkdsk
$FixErrors = $true # If true, errors found on the disk are fixed
$VigorousIndexCheck = $true # If true, a vigorous check of index entries is performed
$SkipFolderCycle = $false # If true, the folder cycle checking should be skipped
$ForceDismount = $false # If true, the volume is dismounted before checking
$RecoverBadSecors = $false # If true, the bad sectors are located and the readable information is recovered
$OKToRunAtBootup = $true # If true, the Chkdsk operation is performed at the next boot up, in case the Chkdsk operation could not be performed because the volume was locked at the time the method was called
$start=get-date
"Commencing Defrag"
$res=$c.chkdsk($FixErrors, 
$VigorousIndexCheck, 
$SkipFolderCycle, 
$ForceDismount,
$RecoverBadSecors, 
$OKToRunAtBootup)
$finish=get-date

#Now Display returndvalue 
"Chkdsk call returned: {0}" -f (Get-DfragReturn($res.ReturnValue))

#Finally print time elapsed
"Starting Check Disk at: {0}" -f $start
"Finished at {0}" -f $finish
$duration = $finish-$start
"Elapsed time {0} minutes" -f ($duration.totalminutes.tostring("0.00"))

###########################################################
#Step 3 - Enable viewing hidden devices in Device Mgr
###########################################################
SET DEVMGR_SHOW_NONPRESENT_DEVICES=1

###########################################################
#Step 7 - Run Disk Cleanup on C: & Reboot
###########################################################
# regedit /s $((Get-Item -Path ".\" -Verbose).FullName)\Cleanmgr.reg

cleanmgr.exe /sagerun:0

for ($i=1; $i -le 2; $i++)
{
if ($(Get-Process cleanmgr -ErrorAction SilentlyContinue)) {
$i = 1
} else {
$i = 2
shutdown /r /t 0
}
}
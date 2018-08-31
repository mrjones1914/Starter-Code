#Script created by Greg Bays because LockOutStatus stopped working with Server 2012 and Windows 10
#This script will unlock a user from all of our DC's at one time

$user = Read-Host 'Enter username'
$lockedoutuser = "*$user*"

$lockedout = Get-ADUser $user -Properties * | Select-Object LockedOut

IF($lockedout.lockedout -eq "true")

 {Write-Host ""
 Write-Host ("User is locked out") -BackgroundColor red
 Write-Host ""
 Write-Host ("Unlocking User Now") -BackgroundColor red
 Write-Host ""
 $DCList = Get-ADComputer -Filter * -SearchBase ‘ou=Domain Controllers,dc=redgold,dc=com’
 Foreach ($targetDC in $DCList.Name)
 {
 Try
 {
 Get-ADuser $user | Unlock-ADAccount -Server $targetDC -ErrorAction SilentlyContinue
 Write-Host (“Completed on ” + $targetDC) -BackgroundColor DarkGreen
 }
 Catch
 {
 $errormsg = $targetDC + ” is down/not responding.”
 Write-Host $errormsg -ForegroundColor white -BackgroundColor red
 }
 }
 Write-Host ""
 Write-Host "The account has been unlocked. Have a great day" -BackgroundColor Black
 }

 ELSE 

 {Write-Host ""
 Write-Host ("User is not locked out") -BackgroundColor Magenta}
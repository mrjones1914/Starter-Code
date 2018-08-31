$DomainControllers = Get-ADDomainController -Filter *

Foreach($DC in $DomainControllers)

 {

Get-ADUser -Identity ntrueblood -Server $DC.Hostname -Properties AccountLockoutTime,LastBadPasswordAttempt,BadPwdCount,LockedOut

}
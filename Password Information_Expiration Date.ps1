$user = Read-Host 'Enter username'

Get-ADUser -identity $user -Properties PasswordExpired,PasswordLastSet,PasswordNeverExpires
;

Get-ADUser -identity $user -Properties msDS-UserPasswordExpiryTimeComputed | 
    select samaccountname,@{ Name = "Expiration Date"; Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
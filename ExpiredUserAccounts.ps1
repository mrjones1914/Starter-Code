
# find expired user accounts
# MRJ - Sep. 2015

Import-Module ActiveDirectory
Search-ADAccount -AccountExpired | ? {$_.ObjectClass -eq 'user'} | Select-Object SamAccountName,AccountExpirationDate,LastLogonDate | export-csv -path M:\Engineering\Scripts\Powershell\AccountExpired.csv

# E-mail the report:

$Server = "e-mail.redgold.com"
$Port = "587"
$To = "mjones@redgold.com"
$From = "ActiveDirectory@redgold.com"
$Subject = "Expired User Report"
$Body = (gc -Path M:\Engineering\Scripts\Powershell\AccountExpired.csv | Out-String)

Send-MailMessage -to $To -from $From -Subject $Subject -body $body -SmtpServer $Server -port $Port
# find disabled user accounts
# MRJ - Aug. 2015

Import-Module ActiveDirectory
$report = Search-ADAccount -AccountDisabled | where {$_.ObjectClass -eq 'user'} | Select-Object Name,ObjectClass,LastLogonDate | export-csv -path M:\Engineering\Scripts\Powershell\disabled.csv

# E-mail the report:

# $Server = "e-mail.redgold.com"
# $Port = "587"
# $To = "mjones@redgold.com"
# $From = "ActiveDirectory@redgold.com"
# $Subject = "Disabled User Report"
# $Body = (Get-Content -Path M:\Engineering\Scripts\Powershell\disabled.csv | Out-String)

# Send-MailMessage -to $To -from $From -Subject $Subject -body $body -SmtpServer $Server -port $Port
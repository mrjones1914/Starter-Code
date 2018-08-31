# find user accounts that have been inactive for 90 days
# MRJ - Aug. 2015

Import-Module ActiveDirectory

Search-ADAccount -AccountInactive -TimeSpan 90.00:00:00 | where {$_.ObjectClass -eq 'user'} | Select-Object SamAccountName,LastLogonDate,lockedout | Export-Csv -path M:\Engineering\Scripts\Powershell\inactive.csv

<# $Server = "e-mail.redgold.com"
$Port = "587"
$To = "mjones@redgold.com"
$From = "ActiveDirectory@redgold.com"
$Subject = "90-Day Inactive User Report"
$Body =  (Get-Content -Path M:\Engineering\Scripts\Powershell\inactive.csv | Out-String)


#Send-MailMessage -to $To -from $From -Subject $Subject -body $Body  -SmtpServer $Server -port $Port
#>
get-service | Out-File C:\Support\Services.txt

$Server = "e-mail.redgold.com"
$Port = "25"
$To = "mjones@redgold.com"
$From = "ActiveDirectory@redgold.com"
$Subject = "Services"
$Body = (get-content C:\Support\Services.txt |Out-String)

Send-MailMessage -to $To -from $From -Subject $Subject -body $Body -SmtpServer $Server -port $Port
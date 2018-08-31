# Attempt to get the user
$cred = Get-Credential

Get-Content "C:\scripts\computers.txt" | %{
  Get-WMIObject Win32_ComputerSystem -Impersonation 3 -Credential $cred -ComputerName $_ -ErrorVariable WMIError -ErrorAction SilentlyContinue

  # If WMIError has a value an error occurred. Create an object holding 
  # the Computer Name and an empty Username property for the output
  If ($WMIError) { $_ | Select-Object @{n='Name';e={ $_ }}, Username }
} | Select-Object Name, @{n='Username';e={ $_.Username -Replace ".*\\" }} | Export-CSV "C:\scripts\output.csv"

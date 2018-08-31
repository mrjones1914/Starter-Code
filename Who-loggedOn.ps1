#$computer = Read-Host "Enter the computer name"
#gwmi win32_computersystem -ComputerName $computer | select username,caption,manufacturer

function Get-MyLoggedOnUsers
{
 param([string]$Computer)
 Get-WmiObject Win32_LoggedOnUser -ComputerName $Computer | Select Antecedent -Unique | %{“{0}{1}” -f $_.Antecedent.ToString().Split(‘”‘)[1], $_.Antecedent.ToString().Split(‘”‘)[3]}
}
 $remotesessions=New-PSSession -Computer (Get-Content 'xaa.txt')
#$remotesessions = New-PSSession -Computer s005633
invoke-command -session $remotesessions -scriptblock {
    $result=if ([System.IntPtr]::Size -eq 4) { "32-bit" } else { "64-bit" }
    New-Object PSObject -Property @{'OSArchitecture'=$result;'Computer'=$ENV:ComputerName}
    } | Select Computer,OSArchitecture

$remotesessions | Remove-PSSession
function Start-GPUpdate
{
    param
    (
        [String[]]
        $ComputerName 
    )

    $code = {     
        $rv = 1 | Select-Object -Property ComputerName, ExitCode
        $null = "N" | gpupdate.exe /force
        $rv.Exitcode = $LASTEXITCODE
        $rv.ComputerName = $env:COMPUTERNAME
        $rv  
    }
    Invoke-Command -ScriptBlock $code -ComputerName $ComputerName |
      Select-Object -Property ComputerName, ExitCode

}
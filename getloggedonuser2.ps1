# This way it won't die when a machine is unavailable
# It's powered off, or the machine account was left behind, etc
$erroractionpreference = "SilentlyContinue"

function GetList 
{ param ([string]$base)
    # Give this function the LDAP search string and it will search there
    $blah = [ADSI]"$base"
    $objDomain = New-Object System.DirectoryServices.DirectoryEntry
    $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
    $objSearcher.Filter = "(objectClass=computer)"
    $objSearcher.SearchRoot = $blah

    $PropList = "cn","operatingSystem"
    foreach ($i in $PropList){$objSearcher.PropertiesToLoad.Add($i)}
    $Results = $objSearcher.FindAll()

    foreach ($objResult in $Results)
    {
        $OS = $objResult.Properties.operatingsystem
        If ($OS -match "Windows Server")
        {
            Echo $objResult.Properties.cn | Out-File -Append -FilePath $OutFile
        }
    }
}

# This is for output
$Outbook = New-Object -comobject Excel.Application
$Outbook.visible = $True

$Workbook = $Outbook.Workbooks.Add()
$Worksheet = $Workbook.Worksheets.Item(1)

$Worksheet.Cells.Item(1,1) = "Machine Name"
$Worksheet.Cells.Item(1,2) = "Remote User"

$Formatting = $Worksheet.UsedRange
$Formatting.Interior.ColorIndex = 19
$Formatting.Font.ColorIndex = 11
$Formatting.Font.Bold = $True

$intRow = 2

# Put the path to the OU with your computer accounts here, if you need more than one, put another GetList line
GetList "LDAP://redgold.com/""OU=Terminal Servers,DC=redgold,DC=com"""

foreach ($strComputer in Get-Content $OutFile)
{
    $Worksheet.Cells.Item($intRow,1)  = $strComputer.ToUpper()

    # Using .NET to ping the servers
    $Ping = New-Object System.Net.NetworkInformation.Ping
    $Reply = $Ping.send($strComputer)


    if($Reply.status -eq "success")
    {
        $RemoteSys = Get-WmiObject -Comp $strComputer -CL Win32_ComputerSystem
        If ($?)
        {
            $Worksheet.Cells.Item($intRow,2).Interior.ColorIndex = 4
            $Worksheet.Cells.Item($intRow,2) = $RemoteUser = $RemoteSys.UserName
        }
        Else
        {
            $Worksheet.Cells.Item($intRow,2).Interior.ColorIndex = 3
            $Worksheet.Cells.Item($intRow,2) = "Error"
        }
    }
    Else
    {
        $Worksheet.Cells.Item($intRow,2).Interior.ColorIndex = 3
        $Worksheet.Cells.Item($intRow,2) = "Not Pingable"
    }

    $Formatting.EntireColumn.AutoFit()

    $Reply = ""
    $pwage = ""
    $intRow = $intRow + 1
}

$Formatting.EntireColumn.AutoFit()
# cls
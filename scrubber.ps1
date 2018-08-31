#
$Global:Collection = @()

$Shell = New-Object -ComObject Shell.Application
$Global:Recycler = $Shell.NameSpace(0xa)

$csvfile = "\\S004425\users\mjones\RecycleBin.txt"
$LogFailed = "\\S004425\users\mjones\RecycleBinFailed.txt"


function Get-recyclebin
{ 
    [CmdletBinding()]
    Param
    (
        $RetentionTime = "7",
        [Switch]$DeleteItems
    )

    $User = $env:USERNAME
    $Computer = $env:COMPUTERNAME
    $DateRun = Get-Date

    foreach($item in $Recycler.Items())
        {
        $DeletedDate = $Recycler.GetDetailsOf($item,2) -replace "\u200f|\u200e","" #Invisible Unicode Characters
        $DeletedDate_datetime = get-date $DeletedDate   
        [Int]$DeletedDays = (New-TimeSpan -Start $DeletedDate_datetime -End $(Get-Date)).Days
      
        If($DeletedDays -ge $RetentionTime)
            {
            $Size = $Recycler.GetDetailsOf($item,3)
          
            $SizeArray = $Size -split " "
            $Decimal = $SizeArray[0] -replace ",","."
            If ($SizeArray[1] -contains "bytes") { $Size = [int]$Decimal /1024 }
            If ($SizeArray[1] -contains "KB") { $Size = [int]$Decimal }
            If ($SizeArray[1] -contains "MB") { $Size = [int]$Decimal * 1024 }
            If ($SizeArray[1] -contains "GB") { $Size = [int]$Decimal *1024 *1024 }
            
       $Object = New-Object Psobject -Property @{
                Computer = $computer
                User = $User
                DateRun = $DateRun
                Name = $item.Name
                Type = $item.Type
                SizeKb = $Size
                Path = $item.path
                "Deleted Date" = $DeletedDate_datetime
                "Deleted Days" = $DeletedDays }
            
            $Object

                If ($DeleteItems)
                {
                    Remove-Item -Path $item.Path -Confirm:$false -Force -Recurse
              
                    if ($?)
                    {
                        $Global:Collection += @($object)
                    }
                    else
                    {
                        Add-Content -Path $LogFailed -Value $error[0]
                    }
                }#EndIf $DeleteItems
            }#EndIf($DeletedDays -ge $RetentionTime)
}#EndForeach item
}#EndFunction

Get-recyclebin -RetentionTime 7 #-DeleteItems #Remove the comment if you wish to actually delete the content


if (@($collection).count -gt "7")
{
$Collection = $Collection | Select-Object "Computer","User","DateRun","Name","Type","Path","SizeKb","Deleted Days","Deleted Date"
$CsvData = $Collection | ConvertTo-Csv -NoTypeInformation
$Null, $Data = $CsvData

Add-Content -Path $csvfile -Value $Data
}

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell)

#ScriptEnd
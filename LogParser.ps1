param([string]$Computername = "localhost" ,[datetime]$startTimeStamp,[datetime]$EndTimeStamp)

$Logs = (Get-WinEvent -Listlog	* -Computername $Computername | where {$_.RecordCount }).LogName
$FilterTable = @{
	'StartTime' = $startTimeStamp
	'EndTime' = $endTimeStamp
	'LogName' = $Logs
	
}
Get-WinEvent -Computername $computername -filterHashTable $FilterTable -ErrorAction 'SilentlyContinue'



param([string]$Computername = 'localhost' ,[datetime]$startTimeStamp,[datetime]$EndTimeStamp)

$Logs = (Get-WinEvent -Listlog	* -Computername $Computername | where { $_.RecordCount }).LogName
$FilterTable = @{
	'StartTime' = $startTimeStamp
	'EndTime' = $EndTimeStamp
	'LogName' = $Logs
	
}

Get-WinEvent -Computername $Computername -filterHashTable $FilterTable -ErrorAction 'SilentlyContinue'



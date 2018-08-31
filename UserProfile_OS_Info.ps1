
<!-- saved from url=(0056)http://www.sivarajan.com/scripts/UserProfile_OS_Info.txt -->
<html><head><meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;">#
#	All User Profile &amp; OS Info - Santhosh Sivarajan
#
#	www.sivarajan.com
#
Cls
$UserInfoFile = New-Item -type file -force "C:\My Data\2010\Scripts\UserInfo.csv"
$FailedComputers_File = New-Item -type file -force "C:\My Data\2010\Scripts\FailedCompuers.csv"
"ComputerName,Profile,LastAccessTime,OSVersion,SPVersion" | Out-File $UserInfoFile -encoding ASCII
"ComputerName" | Out-File $FailedComputers_File -encoding ASCII 
write-host -fore Blue "`t--------------------------------------------------------------------------------------------------"
write-host -fore Blue "`tComputer Name`tProfile`t`tLast Access Date`t`tOS Verions`t`t`t`tSP Level"
write-host -fore Blue "`t--------------------------------------------------------------------------------------------------"
Import-CSV "C:\My Data\2010\Scripts\input.csv" | % { 
    $Computer = $_.ComputerName
	$ppath1 = "$compuer\c$\Documents and Settings"
	$ppath2 = "$computer\c$\Users"
	$profileaccess1 = Test-Path \\$ppath1
	$profileaccess2 = Test-Path \\$ppath2
			
        If ($profileacces1 -eq "TRUE")
		{
			$compOS = get-wmiobject Win32_OperatingSystem -comp $computer 
			$compOSF = $compOS.Caption
			$compSP = get-wmiobject Win32_OperatingSystem -comp $computer
			$compSPF = $compSP.ServicePackMajorVersion
			$profileNames = get-item "\\$ppath1\*" 
			foreach ($profilename in $profilenames) 
				{	
				$accountName = (get-item $profilename).PSChildName 
				$lastaccesstime = (get-item $profilename).LastAccessTime | 	get-date  –f "MM/dd/yyyy"
				"$Computer,$AccountName,$LastAccesstime,$compOSF,$compSPF" | Out-File $UserInfoFile -encoding ASCII -append
				write-host -fore Green "`t$Computer`t`t$AccountName`t`t$LastAccesstime`t`t$CompOSF`t`t$CompSPF"
				write-host -fore Blue "`t--------------------------------------------------------------------------------------------------"
				}
		}
		ElseIf ($profileaccess2 -eq "TRUE")
		{
			$compOS = get-wmiobject Win32_OperatingSystem -comp $computer 
			$compOSF = $compOS.Caption
			$compSP = get-wmiobject Win32_OperatingSystem -comp $computer
			$compSPF = $compSP.ServicePackMajorVersion
			$profileNames = get-item "\\$ppath2\*" 
			foreach ($profilename in $profilenames) 
				{	
				$accountName = (get-item $profilename).PSChildName 
				$lastaccesstime = (get-item $profilename).LastAccessTime | 	get-date  –f "MM/dd/yyyy"
				"$Computer,$AccountName,$LastAccesstime,$compOSF,$compSPF" | Out-File $UserInfoFile -encoding ASCII -append
				write-host -fore Green "`t$Computer`t`t$AccountName`t`t$LastAccesstime`t`t$CompOSF`t`t$CompSPF"
				write-host -fore Blue "`t--------------------------------------------------------------------------------------------------"
				}
		}
		Else 
		{
			Write-Host -fore Red "Can't access Computer -&gt; $computer"
			"$Computer" | Out-File FailedComputers_File -encoding ASCII -append
		}
	}


</pre></body></html>
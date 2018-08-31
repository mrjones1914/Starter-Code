<#
	.Synopsis
		Script to get CPU get architecture of local or remote computer
		
	.Description
		Script to get CPU get architecture of local or remote computer
		
	.Parameter ComputerName
		Name of the computer on which you want to query CPU architecture
		
	.Example
		Get-CPUArchitecture.ps1 -ComputerName TESTPC1
		This will query CPU architecture of TESTPC1
	
	.Example
		Get-CPUArchitecture.ps1 -ComputerName TESTPC1, SITARAM
		This will query CPU architecture of TESTPC1 and SITARAM
	
	.OUTPUTS
		PS C:\Scripts> .\Get-CPUArchitecture.ps1 -ComputerName SITARAM, TESTPC1

		ComputerName                            Architecture                            Status
		------------                            ------------                            ------
		SITARAM                                 x64                                     Success
		TESTPC1                                 Unknown                                 Failed


		PS C:\Scripts>

	.Notes
		Author : Sitaram Pamarthi
		WebSite: http://techibee.com
		twitter: https://www.twitter.com/pamarths
		Facebook: https://www.facebook.com/pages/TechIbee-For-Every-Windows-Administrator/134751273229196

#>
[cmdletbinding()]
Param(
	[string[]]$ComputerName =$env:ComputerName
)

$CPUHash = @{0="x86";1="MIPS";2="Alpha";3="PowerPC";5="ARM";6="Itanium-based systems";9="x64"}


foreach($Computer in $ComputerName) {
Write-Verbose "Working on $Computer"
 try {
	$OutputObj = New-Object -TypeName PSobject
	$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.toUpper()
	$OutputObj | Add-Member -MemberType NoteProperty -Name Architecture -Value "Unknown"
	$OutputObj | Add-Member -MemberType NoteProperty -Name Status -Value $null
	if(!(Test-Connection -ComputerName $Computer -Count 1 -quiet)) {
		throw "HostOffline"
	}
    $CPUObj = Get-WMIObject -Class Win32_Processor -ComputerName $Computer -EA Stop
	$CPUArchitecture = $CPUHash[[int]$CPUObj.Architecture]
	if($CPUArchitecture) {
		$OutputObj.Architecture = $CPUArchitecture
		$OutputObj.Status = "Success"
	} else {
		$OutputObj.Architecture = ("Unknown`({0}`)" -f $CPUObj.Architecture)
		$OutputObj.Status = "Success"
	}
 } catch {
	$OutputObj.Status = "Failed"
	Write-Verbose "More details on Failure: $_"
 }
$OutputObj
}

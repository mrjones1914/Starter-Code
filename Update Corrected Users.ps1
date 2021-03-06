
Import-Module ActiveDirectory
Add-PSSnapin Quest.ActiveRoles.ADManagement

$PathA = 'Z:\IT Project Documentation\2324 - F14 - Exchange Distribution List A3\Work Folder\TempADuserInformation3-20141029.csv'
$PathB = 'z:\IT Project Documentation\2324 - F14 - Exchange Distribution List A3\Work Folder\ADuserChangeLog.csv'

$ADrecords = Import-Csv $PathA

$totalObj = @()

foreach ($ADrecord in $ADrecords) {
	
		$LogRecord = Get-QADUser $ADrecord.SamAccountName
		Write-Host 'SAMaccount =' $LogRecord.SamAccountName
		Write-Host 'LastName = ' $LogRecord.LastName
		Write-Host 'FirstName = ' $LogRecord.FirstName
		
		# Create instance of object of type .NET
   		$obj = New-Object System.Object
    	# Add data from the $Group
		
				
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.FirstName -Name 'FirstName' 
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.Initials -Name 'Initials'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.LastName -Name 'LastName'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.UserPrincipalName -Name 'UserPrincipalName'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.SamAccountName -Name 'SamAccountName'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.Name -Name 'Name'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.Title -Name 'Title' 
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.Description -Name 'Description'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.Manager -Name 'Manager'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.Department  -Name 'Department'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.Office -Name 'Office'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.Company -Name 'Company'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.StreetAddress -Name 'StreetAddress'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.City -Name 'City'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.StateOrProvince -Name 'StateOrProvince'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.PostalCode -Name 'PostalCode'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.PostOfficeBox -Name 'PostOfficeBox'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.PhoneNumber -Name 'PhoneNumber'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.fax -Name 'fax'
		$obj | Add-Member -MemberType NoteProperty -Value $LogRecord.Email -Name 'Email' -Force
			 
		# Add the object to the array
   		$totalObj += $obj
	
		Set-QADUser $ADrecord.SAMAccountName -initials $ADrecord.Initials -FirstName $ADrecord.FirstName -LastName $ADrecord.LastName `
		-Title $ADrecord.Title -Description $ADrecord.Title -Department $ADrecord.Department `
		-Office $ADrecord.Office -Company $ADrecord.Company -StreetAddress $ADrecord.StreetAddress `
		-City $ADrecord.City -StateOrProvince $ADrecord.StateOrProvince -PostalCode $ADrecord.PostalCode `
		-PhoneNumber $ADrecord.PhoneNumber -Fax $ADrecord.Notes
	
		Set-ADUser $ADrecord.SAMAccountName -Replace @{PostOfficeBox = $ADrecord.PostOfficeBox}
	
}
	
	$totalObj | Export-Csv $PathB -NoTypeInformation
function Add-NTFSPermissions {
		Param (
			[Parameter(Mandatory=$true)] $ADObject, # This is a string representing the group/user
			[Parameter(Mandatory=$true)] $FSObject, # This is a string representing the path
  			$Permissions = "Read",
			$AccessControl = "Allow",
			$Inheritance = "None", # When multiple options are needed make it "ContainerInherit, ObjectInherit"
			$Propagation = "None"  # When multiple options are needed make it "InheritOnly, NoPropagationInherit"
		)

		Write-Progress -ID 2 -Activity "Handling folder: $FSObject" -Status "Group $ADObject will be granted permissions"
		$colRights = 		[System.Security.AccessControl.FileSystemRights]"$Permissions" 			#Options: AppendData, ChangePermissions, CreateDirectories, CreateFiles, Delete, DeleteSubdirectoriesAndFiles, ExecuteFile, FullControl, ListDirectory, Modify, Read, ReadAndExecute, ReadAttributes, ReadData, ReadExtendedAttributes, ReadPermissions, Synchronize, TakeOwnership, Traverse, Write, WriteAttributes, WriteData, WriteExtendedAttributes,
		$InheritanceFlag =	[System.Security.AccessControl.InheritanceFlags]"$Inheritance" 			#Options: ContainerInherit (the ACE is inherited by child containers, like subfolders), ObjectInherit (the ACE is inherited by child objects, like files),None
		$PropagationFlag = 	[System.Security.AccessControl.PropagationFlags]"$Propagation" 			#Options: InheritOnly (the ACE is Propagationd to all child objects), NoPropagationInherit (the ACE is not Propagationd to child objects),None
		$objType =			[System.Security.AccessControl.AccessControlType]"$AccessControl" 	#Options:Allow, Deny
		$objUser = (Get-QADObject $ADObject -ConnectionAccount $ConnectionUsr -ConnectionPassword $ConnectionPwd -service $ADTargetDomain).SID

		Write-Verbose "The SID of object $ADObject is $objUser"

		$objACE = New-Object System.Security.AccessControl.FileSystemAccessRule($objUser, $colRights, $InheritanceFlag, $PropagationFlag, $objType)
		$objACL = Get-ACL "$FSObject"
		$objACL.AddAccessRule($objACE)

		try {
			Set-ACL "$FSObject" $objACL
			Write-Progress -ID 2 -Activity "Handling folder: $FSObject" -Status "Group $ADObject is granted permissions"
			Write-Verbose "NTFS Permissions are altered"
		}
		catch {
			Write-Error "An error occured while changing NTFS Permissions"
			Write-Host $LogBuffer[$LogBuffer.count-1] -BackgroundColor "Black" -ForeGroundColor "Red"
			Write-Progress -ID 2 -Activity "Handling folder: $FSObject" -Status "Group $ADObject can not be granted permissions"
			$Error.clear()
		}
	}
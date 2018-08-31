#Update ACL security group members
#MRJ 12/3/2014
# TASKS:
# 1 - Create FS groups (M, RO) for folders on 'Z:\Employee Development and Performance'
#      based on the name of the manager's primary role; use the folders in 'C:\Dell' to practice with
# 2 - Add the FS groups to the folder ACL.
# 3 - Add the RS groups to the FS groups, then remove the RS groups from the folder ACL.
#
#[CmdletBinding()]
#Param(
#    [Parameter(Mandatory=$True)]
#    [string]$DirName
#)

# STEPS:
#1. get a directory listing and store folder names in an array
$folderlists = Get-ChildItem -Directory C:\Dell | Where-Object {$_.PSIsContainer} | ForEach-Object {$_.Name}
    #1a. find how to get just the part of the folder name needed for FSnewgroup



#2. read the ACL of each folder
$OutFile = "C:\temp\Permissions.csv"
$Header = "Folder Path,IdentityReference,AccessControlType,IsInherited,InheritanceFlags,PropagationFlags"
Del $OutFile
Add-Content -Value $Header -Path $OutFile 

$RootPath = "C:\Dell"

$Folders = dir $RootPath -recurse | where {$_.psiscontainer -eq $true}

foreach ($Folder in $Folders){
	$ACLs = get-acl $Folder.fullname | ForEach-Object { $_.Access  }
	Foreach ($ACL in $ACLs){
	$OutInfo = $Folder.Fullname + "," + $ACL.IdentityReference  + "," + $ACL.AccessControlType + "," + $ACL.IsInherited + "," + $ACL.InheritanceFlags + "," + $ACL.PropagationFlags
	Add-Content -Value $OutInfo -Path $OutFile
	}}
    

#3. create new "FS" groups based on part of the folder name (need a foreach here)
$newgroup = 
Get-Content C:\Dell\ACL.csv | New-ADGroup -name "FS" + $newgroup + "M" -Path "OU=Security Groups - Global,DC=redgold,DC=com" -GroupScope Universal
Get-Content C:\Dell\ACL.csv | New-ADGroup -name "FS" + $newgroup + "RO" -Path "OU=Security Groups - Global,DC=redgold,DC=com" -GroupScope Universal


#4. add role groups to new security group (find a way to grep Mgr's Title from folder name & use it for FSnewgroup)
# use foreach to read the array in step #2
Add-ADGroupMember -Identity "FSnewgroup M" -Members RSgroup0,RSgroup1
Add-ADGroupMember -Identity "FSnewgroup RO" -Members RSgroup2

#5. add "FSnewgroup M" and "FSnewgroup RO" to the folder ACL
Set-Acl C:\Dell 

#6. remove RSgroups from ACL
Foreach($acl in $acls)
{
#Do some stuff to change the ACL
} #end foreach acl

#7. Go to the next folder and do it all again (LOOP it)



# Now put some logic around your steps

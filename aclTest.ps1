# Test adding a user/group to a folder ACL
# Specify the directory to update
$directory = "C:\dell"
 
# Specify the group object 'sAMAccountName' to add to NTFS permission
$addGroup  = "redgold\RS Test BRich"
 
# Configure the access object values - READ-ONLY
$access    = [System.Security.AccessControl.AccessControlType]::Allow 
$rights    = [System.Security.AccessControl.FileSystemRights]"Read,ReadAndExecute,ListDirectory"
$inherit   = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
$propagate = [System.Security.AccessControl.PropagationFlags]::None 
$ace       = New-Object System.Security.AccessControl.FileSystemAccessRule($addGroup,$rights,$inherit,$propagate,$access) 
 
# Retrieve the directory ACL and add a new ACL rule
$acl = Get-Acl $directory
$acl.AddAccessRule($ace) 
$acl.SetAccessRuleProtection($false,$false) 
Set-Acl $directory $acl
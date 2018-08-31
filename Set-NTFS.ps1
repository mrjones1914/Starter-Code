function Set-NTFS
{
    param
    (
    # Directory to be modified
    $Path,
 
    # Identity of the object to add to the directory ACL
    $Identity = $(Read-Host "Enter user or group object name"),
 
    # Default options for permission sets
    [ValidateSet("Read","Write","Modify","FullControl")]
    $AccessLevel,
 
    # AccessControlType
    [ValidateSet("Allow","Deny")]
    $AccessControlType = "Allow"
    )
 
    switch ( $AccessControlType )
    {
        "Allow"
        {
        $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
        }
        "Deny"
        {
        $AccessControlType = [System.Security.AccessControl.AccessControlType]::Deny
        }
    }
 
    switch ( $AccessLevel )
    {
        "Read"
        {
        $FileSystemRights = [System.Security.AccessControl.FileSystemRights]"Read,ReadAndExecute,ListDirectory"
        $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
        $PropagationFlags = [System.Security.AccessControl.PropagationFlags]::None 
        }
        "Write"
        {
        # Configure WRITE access
        }
        "Modify"
        {
        # Configure MODIFY access
        $FileSystemRights = [System.Security.AccessControl.FileSystemRights]"Modify"
        $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
        $PropagationFlags = [System.Security.AccessControl.PropagationFlags]::None 
        }
        "FullControl"
        {
        # Configure FULL access
        }
        default
        {
        # Default catch - not to be used - send warning to screen
        }
    }
 
    # Configure the Access Control object
    $ace = New-Object System.Security.AccessControl.FileSystemAccessRule($Identity,$FileSystemRights,$InheritanceFlags,$PropagationFlags,$AccessControlType) 
 
    # Retrieve the directory ACL and add a new ACL
    $acl = Get-Acl $Path
    $acl.AddAccessRule($ace) 
    $acl.SetAccessRuleProtection($false,$false) 
 
    # Add the ACL to the directory object
    Set-Acl $Path $acl
 
}
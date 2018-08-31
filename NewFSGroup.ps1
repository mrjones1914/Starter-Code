#3. create new "FS" groups based on part of the folder name (need a foreach here)
Import-Module ActiveDirectory
$folderlists = Get-ChildItem -Directory C:\Dell | Where-Object {$_.PSIsContainer} | ForEach-Object {$_.Name}

Foreach ($folderlist in $folderlists) {
# $newgroup = 
# Get-Content C:\Dell\ACL.csv | New-ADGroup -name "FS" + $newgroup + "M" -Path "OU=Security Groups - Global,DC=redgold,DC=com" -GroupScope Universal
# Get-Content C:\Dell\ACL.csv | New-ADGroup -name "FS" + $newgroup + "RO" -Path "OU=Security Groups - Global,DC=redgold,DC=com" -GroupScope Universal
New-ADGroup -name "FS" + $folderlist + "M" -Path "OU=Security Groups - Global,DC=redgold,DC=com" -GroupScope Global #Universal
New-ADGroup -name "FS" + $folderlist + "RO" -Path "OU=Security Groups - Global,DC=redgold,DC=com" -GroupScope Global #Universal

}

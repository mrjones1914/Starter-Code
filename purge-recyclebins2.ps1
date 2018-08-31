$sharedfolder='\\s004425\users'
New-PSDrive -name "hdrive" -PSProvider FileSystem -Root $sharedfolder
 
Get-ChildItem -Path "hdrive:" -Force -Recurse -ErrorAction SilentlyContinue | `
       ? {($_.fullname -match 'recycle.bin') -and ((Get-Date).AddDays(-60) -gt $_.LastWriteTime) -and ($_.PSIsContainer)} | `
       % {gci -Recurse -Force $_.fullname } | ? { ! $_.PSIsContainer } | `
       % {
    $a = $_.fullname
    $a = $a.replace($sharedfolder , 'hdrive:')
    write-host $_.LastAccessTime"--"$_.LastWriteTime"--"$a
    $a | remove-item -force -recurse
    }
Remove-PSDrive -Name "hdrive"
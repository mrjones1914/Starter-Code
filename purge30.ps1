# Purge files 30 days and older
# MRJ
# set folder path
$dump_path = "C:\$RECYCLE.BIN"
 
# set min age of files
$max_days = "-30"
  
# get the current date
$curr_date = Get-Date
 
# determine how far back we go based on current date
$del_date = $curr_date.AddDays($max_days)
 
# delete the files
Get-ChildItem $dump_path -Recurse | Where-Object { $_.LastWriteTime -lt $del_date } | Remove-Item

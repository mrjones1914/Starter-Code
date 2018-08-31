<# 
Take a handful of small csv files
and combine them into 1 big csv file
#>

Set-Location "\\dakotanas-4037\CompanyShare\Integrations\Sodexo\Originals from Sodexo"
$files = (dir *.csv)
$outfile = "\\dakotanas-4037\CompanyShare\Integrations\Sodexo\combined.csv"
$files | %{Get-Content $_.FullName | select -Skip 2 | Add-Content $outfile} 

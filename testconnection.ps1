$computers = C:\temp\Relays.txt
Test-Connection $computers -count 1 | out-file C:\temp\pingresult.csv

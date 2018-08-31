$servers = Get-Content -Path "C:\Scripts\target.txt"
foreach ($server in $servers) {

dsquery computer -name "$server" | dsget computer -desc

}
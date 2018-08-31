Import-Module activedirectory
$input = "y"
New-Item -ItemType Directory -Force -Path C:\ADOutput\

While ($input = "y") 
{
$input = Read-Host AD Username
$user = Get-ADUser $input -Properties mail
$user.mail -replace "'n", "'r'n" | Add-Content 'C:\ADOutput\ShowcaseUsersEmail.txt'
}
until ($input = "N")
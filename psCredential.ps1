# Creating AES key with random data and export to file
$KeyFile = "c:\Scripts\AES.key"
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

# Creating SecureString object
$PasswordFile = "c:\Scripts\Password.txt"
$KeyFile = "c:\Scripts\AES.key"
$Key = Get-Content $KeyFile
$Password = "P@ssword1" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile

# Creating PSCredential object
$User = "MyUserName"
$PasswordFile = "c:\Scripts\Password.txt"
$KeyFile = "c:\Scripts\AES.key"
$key = Get-Content $KeyFile
$MyCredential = New-Object -TypeName System.Management.Automation.PSCredential `
 -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
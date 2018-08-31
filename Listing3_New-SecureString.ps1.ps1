# New-SecureString.ps1

# Returns a SecureString as a String.
function ConvertTo-String {
  param(
    [System.Security.SecureString] $secureString
  )
  $marshal = [System.Runtime.InteropServices.Marshal]
  try {
    $intPtr = $marshal::SecureStringToBSTR($secureString)
    $string = $marshal::PtrToStringAuto($intPtr)
  }
  finally {
    if ( $intPtr ) {
      $marshal::ZeroFreeBSTR($intPtr)
    }
  }
  $string
}

do {
  $ss1 = read-host "Enter string          " -assecurestring
  $ss2 = read-host "Enter again to confirm" -assecurestring
  $ok = (ConvertTo-String $ss1) -ceq (ConvertTo-String $ss2)
  if (-not $ok ) {
    write-host "Strings do not match`r`n"
  }
}
until ( $ok )

$ss1

' Constants (taken from WinReg.h)
'
On Error Resume Next

Const HKEY_CLASSES_ROOT   = &H80000000
Const HKEY_CURRENT_USER   = &H80000001
Const HKEY_LOCAL_MACHINE  = &H80000002
Const HKEY_USERS          = &H80000003

Const REG_SZ        = 1
Const REG_EXPAND_SZ = 2
Const REG_BINARY    = 3
Const REG_DWORD     = 4
Const REG_MULTI_SZ  = 7

' Chose computer name, registry tree and key path
'
strComputer = "." ' Use "." for current machine
hDefKey = HKEY_LOCAL_MACHINE
strKeyPath = "SOFTWARE\Microsoft\Cryptography\Defaults\Provider"

' Connect to registry provider on target machine with current user
'
Set oReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")

' Enum the subkeys of the key path we've chosen
'
oReg.EnumKey hDefKey, strKeyPath, arrSubKeys

For Each strSubkey In arrSubKeys

  ' Show the subkey
  '
  wscript.echo strSubkey

  ' Show its value names and types
  '
  strSubKeyPath = strKeyPath & "\" & strSubkey
  oReg.EnumValues hDefKey, strSubKeyPath, arrValueNames, arrTypes

  For i = LBound(arrValueNames) To UBound(arrValueNames)
    strValueName = arrValueNames(i)
    Select Case arrTypes(i)

      ' Show a REG_SZ value
      '
      Case REG_SZ          
        oReg.GetStringValue hDefKey, strSubKeyPath, strValueName, strValue
        wscript.echo "  " & strValueName & " (REG_SZ) = " & strValue

      ' Show a REG_EXPAND_SZ value
      '
      Case REG_EXPAND_SZ
        oReg.GetExpandedStringValue hDefKey, strSubKeyPath, strValueName, strValue
        wscript.echo "  " & strValueName & " (REG_EXPAND_SZ) = " & strValue

      ' Show a REG_BINARY value
      '          
      Case REG_BINARY
        oReg.GetBinaryValue hDefKey, strSubKeyPath, strValueName, arrBytes
        strBytes = ""
        For Each uByte in arrBytes
          strBytes = strBytes & Hex(uByte) & " "
        Next
        wscript.echo "  " & strValueName & " (REG_BINARY) = " & strBytes

      ' Show a REG_DWORD value
      '
      Case REG_DWORD
        oReg.GetDWORDValue hDefKey, strSubKeyPath, strValueName, uValue
        wscript.echo "  " & strValueName & " (REG_DWORD) = " & CStr(uValue)				  

      ' Show a REG_MULTI_SZ value
      '
      Case REG_MULTI_SZ
        oReg.GetMultiStringValue hDefKey, strSubKeyPath, strValueName, arrValues				  				
        wscript.echo "  " & strValueName & " (REG_MULTI_SZ) ="
        For Each strValue in arrValues
          wscript.echo "    " & strValue 
        Next

    End Select
  Next

Next
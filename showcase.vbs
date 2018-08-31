'==========================================================================
'
' System DSN for Showcase 9
'
' NAME: 
'
' AUTHOR: Red Gold, Inc , IS Department
' DATE  : 9/28/2011
' Modified: 11/29/2011
'
' COMMENT: does some stuff then exits
'
'=======================================================================

Const HKEY_LOCAL_MACHINE = &H80000002

strComputer = "."
 
Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & _ 
    strComputer & "\root\default:StdRegProv")
 
strKeyPath = "SOFTWARE\ODBC\ODBC.INI\ODBC Data Sources"
strValueName = "Showcase ODBC Driver45"
strValue = "ShowCase ODBC"
objReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
 
strKeyPath = "SOFTWARE\ODBC\ODBC.INI\Showcase ODBC Driver45"

objReg.CreateKey HKEY_LOCAL_MACHINE,strKeyPath

strKeyPath = "SOFTWARE\ODBC\ODBC.INI\Showcase ODBC Driver45"

strValueName = "Database"
strValue = "Showcase ODBC Driver45"
objReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
 
strValueName = "Driver"
strValue = "C:\Program Files (x86)\IBM\ShowCase\9\bin\SCOJDBC.dll"
objReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue

strValueName = "Description"
strValue = "Showcase ODBC Driver45"
objReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue

strValueName = "System"
strValue = "SALSA"
objReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue

strValueName = "TcpPort"
strValue = "43422"
objReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue

strValueName = "Trusted_Connection"
strValue = "Yes"
objReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
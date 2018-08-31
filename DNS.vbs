on error resume next 
 
Const STR_NEWDNS1 = "10.1.2.5"  'Enter first Server IP here 
Const STR_NEWDNS2 = "10.1.2.2" 'Enter second Server IP here 
Set oFS = CreateObject("Scripting.FileSystemObject") 
Set oTS = oFS.OpenTextFile("computers.txt") 
 
arrServers = Split( strParamServers, " " ) 
Do Until oTS.AtEndOfStream 
    sComputer = oTS.ReadLine 
    Showdns sComputer 
    Do 
        choice = MakeChoice( "Want to Change to " & STR_NEWDNS1 & ", " & STR_NEWDNS2 & " (Y/N)?"  ) 
    Loop until choice ="Y" or choice = "N" 
    if choice = "Y" then 
        Setdns sComputer 
    end if 
    WScript.echo( vbCrlf ) 
Loop 
oTS.Close 
 
Sub Showdns( strServer ) 
    strWinMgmt = "winmgmts:{impersonationLevel=impersonate}!//"& strServer &"" 
    Set objNICs = GetObject( strWinMgmt ).InstancesOf( "Win32_NetworkAdapterConfiguration" ) 
    WScript.echo strServer & ": " & vbCrlf 
    For Each objNIC In objNICs 
        If objNIC.IPEnabled Then 
            WScript.echo "  " & objNIC.Description & ": " & vbCrlf & "    " 
                n = 1 
            For Each strDns In objNIC.DNSServerSearchOrder  
                WScript.echo vbTab & "DNS" & n & ":" & strDns & " " 
                n = n + 1 
            Next 
            WScript.echo vbCrlf 
        End If 
    Next 
End Sub 
 
Sub Setdns( strServer ) 
    strWinMgmt = "winmgmts:{impersonationLevel=impersonate}!//"& strServer &"" 
    Set objNICs = GetObject( strWinMgmt ).InstancesOf( "Win32_NetworkAdapterConfiguration" ) 
    WScript.echo "Set DNS for NIC: " 
    For Each objNIC In objNICs 
        If objNIC.IPEnabled Then 
            objNIC.SetDNSServerSearchOrder Array(STR_NEWDNS1,STR_NEWDNS2) 
            WScript.echo objNIC.Description & "  "      
        End If 
    Next 
    WScript.echo  vbCrlf 
End Sub 
 
Function MakeChoice(strMsg) 
    WScript.StdOut.Write(strMsg) 
    WScript.StdIn.Read(0) 
    strChoice = WScript.StdIn.ReadLine() 
    MakeChoice = UCase( Left( strChoice, 1 ) ) 
End Function 
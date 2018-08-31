'==========================================================================================================================
'
' NAME: SCCM_Client_Health_Check
'
' AUTHOR: Chris Stauffer, Commonwealth Of Pennsylvania
' DATE  : 2/9/2009
'
' COMMENT: Version 1.3
'
' 1.0 - all features enabled
' 1.1 - additional Credit Given
'	  - Minor error in one of the email functions was fixed.
' 1.2 - Script was modified to run as a Startup script
'	  - Email Function was disabled
'	  - If SCCM Reg key is missing it will now trigger a client install
'	  - Client install source points to the SCCM Site Share  SMS_(Sitecode)\Client\CCMSetup.exe
' 1.3 - Removed Advertisement check that was used in original helthcheck advertisement script.
'
' Features To be added:
'		- Do we actually need aguments For client install since they should be In AD If site Is constructed proporly
'		- WMI Solution
'
'**************************************************************************************************************************
'**************************************************************************************************************************
'  Special Thanks to:
' 1E And Richard Threlkeld  For the original Health Check tool 
' David Turner For cache expander Function
' DudeWorks For script functions from their original Health Check scripts
' Sherry Kissinger For Error checking And Function editing
' Authors of SMS 2003 Recipes (a must have book For any SMS admin)
' My beta testers. I've been asked by some to not mention there names so I will not.
' The rest know who they are and I will gladly give them recognition if they want it.
' The guys And gals On the MyITForum MSSMS list For chiming in when needed
' And anybody Else that added their 2 cents :-)

'
'==========================================================================================================================
'==========================================================================================================================

On Error Resume Next

'Adjustable Variables
SCCMServer = "S006670.redgold.com" 'change To your site server name
SCCMSiteCode = "RG2" ' Change to your site code
SCCMCacheSize = "5100" 'Change to the cache size you want
StrDays = 3 'Change To number of days between Advertisement Check 
' InstallArgs = "" ' only needed if you have not extended AD
StrLocalAdminGroup = "Administrators"		'Specify Local Admin group to add SMS Admin Account to(DEFAULT=Administrators)
STRadmACCT = "redgold\SCCMWKSAdmin"	'Specify Desktop SMS Admin account domain/account
STRAdmSRACCT = "redgold\sccm_admin" 'Specify Server SMS Admin account domain/account
' DFSRootForClientInstall = "\\mycompany.com\sysvol\mycompany.com\scripts\ConfigMgr"

'Client Install Source Paths
'Choose either DSF or SCCM 1= True 0 = False
DSFinstall= 0 '1= True 0 = False
SCCMInstall= 1 '1= True 0 = False

'Email Variables
CompanyEmailRecipient = "mjones@redgold.com" 'who should get these emails, can be multiple accounts separated by a , 
CompanySMTPServer = "Smtp.redgold.com"
'intranet server that has smtp--most companies have one for alerting.
CompanyEmailSender = "SmsServer@redgold.com" 'Can be a made up sender name

Set WshShell = WScript.CreateObject("WScript.Shell")
Set WshShell1 = CreateObject ("WScript.Shell")

'===========File System Constants==================================
Const ForReading = 1, TemporaryFolder = 2, ForAppending = 8 
Const OverwriteExisting = True
Const HARD_DISK = 3
'===========Registry Constants=====================================

Const HKEY_LOCAL_MACHINE = &H80000002
	
'===========Event Log Constants====================================

Const EVENT_SUCCESS = 0
Const EVENT_ERROR = 1
Const EVENT_WARNING = 2
Const EVENT_INFORMATION = 4
Const AUDIT_SUCCESS = 8
Const AUDIT_FAILURE = 16
				
'=========== Set Enviornment variables ============================	    
WinDir = WshShell.ExpandEnvironmentStrings("%windir%")
Compname = WshShell.ExpandEnvironmentStrings("%COMPUTERNAME%")
ComSpec = WshShell.ExpandEnvironmentStrings("%COMSPEC%")
tempdir = WshShell.ExpandEnvironmentStrings("%temp%")

'******************
'*  Get timezone  *
'******************

Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
Set colTimeZone = objWMIService.ExecQuery ("Select * from Win32_TimeZone")
For Each objTimeZone in colTimeZone
    intBias = cint(objTimeZone.Bias )
Next

'******************************************************
'*              Setup Reg key connections
'*
'*****************************************************
' Get Local CCM Path

Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
	strKeyPath = "SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties"
	strValueName = "Local SMS Path"
	oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
	StrSCCMPath= strValue
	

' Get registry Path for Health Check tracking
'Check for keys existance if it is not present Create it
Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"
strValueName = "InstallDate"
oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
										
	If Strvalue = "" Or IsNull (Strvalue) Then
		strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"
		oReg.CreateKey HKEY_LOCAL_MACHINE,strKeyPath	
		
		
			
	End If



'============Set up the logging ====================================
Set fso = CreateObject("Scripting.FileSystemObject")
STRLOG = StrSCCMPath & "\logs\Client_Health_Check.Log"
If fso.FolderExists(strSCCMPath& "\Logs")Then
 	Set logfile = fso.OpenTextFile( STRLOG ,2,True) 
Else 
	Set logfile = fso.OpenTextFile( "c:\ConfigMgr.Log",2,True)
	Strlog =  "c:\ConfigMgr.Log"
End If

' Start Logging
logfile.writeline "*******************************************************"
logfile.writeline "Beginning SCCM 2012 Client Health Script"
logfile.writeline "*******************************************************"
wShShell1.LogEvent 0,"SCCM Client Health Check Starting, Please see Log for full results." & StrLog

'Log Site Server Name
logfile.WriteLine "SCCM Server= " & SCCMServer
logfile.writeline "CCM Install Path: " & StrSCCMPath
'************************************************
'************************************************
'************************************************
'*  Do System Health Checks                     *
'************************************************
'*  Increment Script History by 1               *
'*  Checking for Admin $                        *
'*  Then Check for SCCM Access account          *
'*	Then Check for SCCM Client Server       *
'************************************************
CheckWMI 'Check WMI if failure, email admin and exit script
Script_increment  'Increment Registry Key For script by 1 And move present value To history 		
Check_Admin1 ' Check Admin$ Share
Check_SMSLOCALADMIN 'Check Local Admin account

If StrSCCMPath = "" Or IsNull (StrSCCMPath) Then
		logfile.WriteLine "CCM install Path is missing"
		logfile.WriteLine "Triggering Client Install"
		Call AdvCliInst(ComSpec)
	        WScript.Sleep 10000
	        Call Cleanup
	        WScript.Quit
End If


Results = ServiceState("ccmexec")'Check CCM Status

'**********************************
'* Service Is Running so Do this  *
'**********************************		
		
If LCase(Results) = LCase("Running")Then
				
			'Set Reg key for Client restart To 0 since it is running 
	    	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
			strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"	
			strValueName = "CCM_Service_Check"
			STrCCMValue = 0
			oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strCCMValue
				
				'********************************************
				'Run Health Checks
				'********************************************				
				Check_Client_info 'Check Client Variable	    			
	    			Check_Inventory   'Check Invetory
	    			Check_cache_info  'Check Client Cache info
	    			'******************************************** 
	    		   
	    		logfile.writeline  ""
	    		logfile.writeline "Exiting script processing because ccmsetup service Is running And it passed other health Checks"
	    		wShShell1.LogEvent 0, "Exiting script processing because ccmsetup service Is running and it passed other health Checks"
	    		WScript.Quit

'****************************************
'* Service is Stopped, restart service  *
'****************************************
	    		
	   Elseif LCase(Results) = LCase("Stopped")Then
	    		logfile.WriteLine "ccmsetup service Is In a stopped state, attempting To start"
	    		wShShell1.LogEvent 1, "ccmsetup service Is In a stopped state, attempting To start"
	    		KickService("ccmsetup")
	    			'Set Reg key For Client restart to 1 
			    	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
					strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"	
					strValueName = "CCM_Service_Check"
					STrCCMValue = 1
					oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strCCMValue
					    		
	    		'********************************************
			'Run Health Checks
			'********************************************				
			Check_Client_info 'Check Client Variable	    			
	    		Check_Inventory   'Check Invetory
	    		Check_cache_info  'Check Client Cache info 
	    		'******************************************** 
	    		
	    		logfile.writeline  ""
	    		logfile.writeline "Exiting script processing because ccmsetup service Is running And it passed other health Checks"
	    		wShShell1.LogEvent 0, "Exiting script processing because ccmsetup service Is running and it passed other health Checks"
	    		WScript.Quit		
	    		
	    	End If

'*******************************************************************************
'*  Service Does NOT Exist, Install Client and do health checks on next Cycle  *
'*******************************************************************************

	      
	  If Err then
	        'Advanced client not installed
	        logfile.writeline "SCCM Client Not installed, calling AdvCliInst To install the client"
	        wShShell1.LogEvent 1, "SCCM Client Not installed, calling AdvCliInst To install the client" 
	        'Set Reg key For Client restart to 1 since client is not running 
			    	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
					strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"	
					strValueName = "CCM_Service_Check"
					STrCCMValue = 1
					oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strCCMValue
	        
	        Call AdvCliInst(ComSpec)
	        WScript.Sleep 10000
	        Call Cleanup
	        WScript.Quit
	   Else
	      'Log Client Variables

Set SmsClient = GetObject("winmgmts:ROOT/CCM:SMS_Client=@")
	      			      	
	      Select Case SmsClient.ClientVersion
'IMPORTANT! >>>>>>>>> Adjust CASE as necessary, but do *not* remove it! <<<<<<<<IMPORTANT!
	      'Alter this by adding an additional CASE statement followed by the version in quotes for each SMS client
	      'version which is allowed in the hierarchy. This can also be used as an additional cleanup method after
	      'upgrading clients for those that might have missed this via software distribution  
		  
'******************************************
Case "5.00.8634.1010" ' SCCM client version
' 4.00.6221.1000
' RTM 4.00.5931.0001
' SP1 4.00.6221.1000
'******************************************
		  
		  logfile.writeline "SCCM Client Version Passed"
		    WScript.Sleep 1
	          Case Else
	          	logfile.writeline "Calling AdvCliInst routine To install SCCM client"
	            wShShell1.LogEvent 1, "Calling AdvCliInst routine To install SCCM client"
	            'logfile.writeline "test"
	            Call AdvCliInst(ComSpec)
	            WScript.Sleep 10000
	            Call Cleanup
	            WScript.Quit
	        End Select
	   End If
	
	    ' SMS Logs recently updated
	 	  logfile.writeline "Begining to evaluate " & windir & "\CCM\Logs\PolicyEvaluator.log"
	      strSMSPolEval = windir & "\CCM\Logs\PolicyEvaluator.log"
	      startdate = ShowFileAccessInfo(strSMSPolEval, Compname)
	      logfile.writeline "startdate = " & startdate
	      enddate = date()
	      logfile.writeline "enddate = "  & enddate
	
	      If isDate(startdate) Then
	        diffdate = DateDiff("d", startdate, enddate)
	        logfile.writeline "diffdate = " & diffdate
	      End If
	
	      If diffdate > 14 Then
	      		logfile.writeline "diffdate Is greater than 14 days, attempting To repair SMS Client"
	      		wShShell1.LogEvent 1, "diffdate Is greater than 14 days, attempting To repair SMS Client"
	      		smsClient.RepairClient
	      		wscript.quit
	      End If
	    
	    
'********************************

		
	    ' SMS Agent Host Service started
	    logfile.writeline "Calling KickService"
	    WshShell1.LogEvent 0, "Calling KickService"
	    Call KickService("CcmExec")
	
		' Remote Registry Service started
		logfile.writeline "Calling RemoteRegistry"
		wShShell1.LogEvent 0, "Calling RemoteRegistry"
		Call KickService("RemoteRegistry")		
		
		
		'Ensure that the client is assigned to a site if its not assigned to any
		logfile.writeline "Checking to make sure SMS Client has site assignment"
		Set ISmsClient = CreateObject ("Microsoft.SMS.Client")
		AssignedSite = ISmsClient.GetAssignedSite
		If NOT Len(AssignedSite & "")>0 Then
	  		logfile.writeline "Client Is Not assigned, attempting To AutoDiscover And Set"
	  		wShShell1.LogEvent 1, "Client Is Not assigned, attempting To AutoDiscover And Set"
	  		ISmsClient.EnableAutoAssignment 1
			DiscoveredSite = ISmsClient.AutoDiscoverSite
			ISmsClient.SetAssignedSite DiscoveredSite,0
			logfile.writeline "Client Is Now assigned To " & ISmsClient.GetAssignedSite
			wShShell1.LogEvent 0, "Client Is Now assigned To " & ISmsClient.GetAssignedSite
		End If
		
		logfile.writeline "Cleaning Up"
		wShShell1.LogEvent 0, "Cleaning Up"
	    Call Cleanup
	    logfile.writeline "Ending Processing"
	    wShShell1.LogEvent 0, "Ending Processing"
	
	WScript.Quit
	
'******************************************************
'******************************************************
'******************************************************	
	
	
 ' *****************************************************
 ' *           KickService function                    *
 ' *****************************************************
 Function KickService(servicename)
  On Error Resume Next
  logfile.writeline "Running KickService"
  Dim Results, wmi, Service, returncode, Service2, Started
  		Results = ServiceState(servicename)
  		logfile.writeline "servicename = " & servicename
  		 'wShShell1.LogEvent 0, "servicename = " & servicename
  		logfile.writeline "Results = " & Results
  		 'wShShell1.LogEvent 0, "Results = " & Results
  		set wmi = getobject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
  		
    	If NOT LCase(Results) = LCase("Running")Then
    		set Results = wmi.execquery("select state from win32_service where name='" & servicename & "'")
    		For Each Service In Results
		        ' Start service
		          returncode = Service.StartService
		          logfile.writeline "returncode = " & returncode
		           'wShShell1.LogEvent 0, "returncode = " & returncode
		          if returncode <> 0 Then
		          	    logfile.writeline "Error starting Service your Windows Management Service (" & servicename & ") "
		    			WshShell1.LogEvent 1, "Error starting Service your Windows Management Service (" & servicename & ")"
		    			'Call EmailMessage("Error starting Service your Windows Management Service (" & servicename & ") " & CompName &")") 
		    			Call Cleanup
		    			logfile.writeline "Quiting Script"
		    			wShShell1.LogEvent 0, "Quiting Script"
		    			WScript.Quit
		    		
		 end If
		   Do Until Started = True
		'IMPORTANT! >>>>>>>>> Adjust sleep as necessary, but do *not* remove it! <<<<<<<<IMPORTANT!
					logfile.writeline "Sleeping for 2 seconds..."
					logfile.writeline "Use the below text to see how many times the script looped to start the Service"
		             WScript.Sleep 2000 'Sleep for 2 Seconds                    
		             set Results = wmi.execquery("select state from win32_service where name='" & servicename & "'")
		              for each Service2 in Results
		               if lcase(Service2.State) = lcase("Running") Then
		               logfile.writeline "Started = " & Started
		               	Started = True
		               end if
		              next
		          Loop
			Next
		 End If 
	Err.clear
End Function  

'**********************************
'*   Check For admin$ share       *
'**********************************

Function Check_Admin1
	'Check for Admin$ - If not present then Log
err.clear

	Set wmi = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
	Set colShares = wmi.ExecQuery("Select * from Win32_Share Where Name = 'ADMIN$'")
	
	If colShares.Count > 0 Then
			logfile.WriteLine "Admin$ Is Present."
	   	  	wShShell1.LogEvent 0, "Admin$ Is Present."
	   	  	
	   Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
		strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"	  
		strValueName = "Admin$_Check"
		STrADValue = 0
		oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strADValue
			
	   	  	
		Else
			logfile.WriteLine "Admin$ Is missing."
	   	    wShShell1.LogEvent 1, "Admin$ Is missing."
	   	    
	   	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
		strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"    
		strValueName = "Admin$_Check"
		STrADValue = 1
		oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strADValue
			
	   	   
	   	   Check_Admin_Share' Attempt to fix problem
	   	   
		End If
		If Err.Number <> 0 Then
		logfile.writeline "Admin$ Is missing."
		wShShell1.LogEvent 1, "Admin$ Is missing or broken."
		Err.Clear
		End If

End Function

'**************************************
'*  Attempt To Fix admin$ share       *
'*************************************************************************************************
'                                                                                                *
' Windows 2000 is the only OS that should have this key by Default                               *
' All newer OS's don't have this key by default so if it exists, change the the value to 1       *
' Then on the next reboot the system should recreate the Admin$ share on its own.                *
'*************************************************************************************************

Function Check_Admin_Share
	StrDomainRole= GetDomainRole
	logfile.writeline StrDomainRole
	
	If StrDomainRole < 2 Then
	logfile.writeline "Device Is a Workstation"
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
		strKeyPath = "System\CurrentControlSet\Services\LanmanServer\Parameters"
		strValueName = "AutoShareWks"
		oReg.GetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,dwValue
		StrShareStat= dwValue
		logfile.writeline "AutoShareWks value: " & 	StrShareStat
	
			If StrShareStat = 0 Then
				strKeyPath = "System\CurrentControlSet\Services\LanmanServer\Paramaters"
				strValueName = "AutoShareWks"
				dwValue = 1
				oReg.SetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,dwValue
				logfile.writeline "AutoShareWks value changed To: " & dwValue
			End If 	
	Else
	logfile.writeline "Device Is a Server"
	
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
		strKeyPath = "System\CurrentControlSet\Services\LanmanServer\Parameters"
		strValueName = "AutoShareServer"
		oReg.GetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,dwValue
		StrShareStat= dwValue
		logfile.writeline "AutoShareServer value: " & StrShareStat	
	
		If StrShareStat = 0 Then
			strKeyPath = "System\CurrentControlSet\Services\LanmanServer\Paramaters"
			strValueName = "AutoShareServer"
			dwValue = 1
			oReg.SetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,dwValue
			logfile.writeline "AutoShareServer value changed To: " & dwValue
		End If 
	
	End If

End Function


' *****************************************************
' *            ServiceState subprocedure              *
' *****************************************************
Function ServiceState(servicename)
 	On Error Resume Next
 	logfile.writeline "Running ServiceState"
 	'wShShell1.LogEvent 0, "Running ServiceState"
 	logfile.WriteLine "Checking " & servicename & " Service"
 	'wShShell1.LogEvent 0, "Checking " & servicename & " Service"
 	Dim wmi, Results, Service, StateResults, StartMode
 	set wmi = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
   set Results = wmi.execquery("select state from win32_service where name='" & servicename & "'")
   For Each Service In Results
   	StateResults = Service.State
   	logfile.writeline "StateResults = " & StateResults
   	'wShShell1.LogEvent 0, "Checking " & servicename & " Service"
   Next
     ServiceState = StateResults
End Function

' *****************************************************
' *              AdvCliInst subprocedure              *
' *****************************************************
Sub AdvCliInst(ComSpec)
     On Error Resume Next
     logfile.writeline "Running AdvCliInst"
     Dim smsinstall, WshShell, InstallArgs

     Set WshShell = WScript.CreateObject("WScript.Shell")
     ComSpec = WshShell.ExpandEnvironmentStrings("%COMSPEC%")
     If ComSpec = "" Then
		logfile.writeline "Displaying Message To user - Windows Management Service Installation Failed.  Please contact The Help Desk"
	    wShShell1.LogEvent 1, "Displaying Message To user - Windows Management Service Installation Failed.  Please contact The Help Desk"
	   'Call EmailMessage("Windows Management Service Installation Failed.  Please contact The Help Desk " & CompName) 
	    Call Cleanup
	    logfile.writeline "Exiting Script Processing"
		wShShell1.LogEvent 0, "Exiting Script Processing"
		WScript.Quit
  	     	
     Else
     
     	  If Wscript.Arguments.Named.Exists("params") Then
     		If Wscript.Arguments.Named("params") <> "" Then
      			InstallArgs = Wscript.Arguments.Named("params")
      			logfile.writeline = "InstallArgs = " & InstallArgs
     		End If
   	  End If
      
      ' Make sure that you create a share on your SCCm server on this driectory as Client$
      ' drive:\smsinstall diretory\Client
      
      If SCCMinstall = 1 Then
      
      smsinstall = ComSpec & " /c \\"& SCCMServer &"\SMS_"& SCCMSiteCode &"\Client\CCMSetup.exe" & InstallArgs
      
      End If
      
      If DSFinstall = 1 Then
      
      smsinstall =ComSpec & " /c "& DFSRootForClientInstall &"\CCMSetup.exe" & InstallArgs
	  End If    
      
       logfile.writeline "Calling SCCM Client installation With below command line:"
       wShShell1.LogEvent 0, "Calling SCCM Client installation With below command line:"& smsinstall
       logfile.writeline "smsinstall = " & smsinstall
     	' Run SMS Client Installation
       WshShell.Run smsinstall,0,False
     End If
End Sub
   
   
' *****************************************************
' *               GetDomainRole function              *
' *****************************************************
Function GetDomainRole
     On Error Resume Next
     logfile.writeline "Running GetDomainRole"
     'wShShell1.LogEvent 0, "Running GetDomainRole"
     Dim domainroles, wmi, domainrole
     Set wmi = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
     Set domainroles = wmi.ExecQuery("Select domainrole FROM Win32_ComputerSystem")
     For Each domainrole in domainroles
       GetDomainRole = domainrole.domainrole
       logfile.writeline "GetDomainRole = " & GetDomainRole
     	'wShShell1.LogEvent 0, "GetDomainRole = " & GetDomainRole
     Next
     Set domainroles = Nothing
     Set wmi = Nothing
End Function
  

 
'******************************************************************************************** 
'* Check For Your SMS Admin Account and add it to the Local Admininstrators Group if needed *
'******************************************************************************************** 
Sub Check_SMSLOCALADMIN()

Strdomainrole = GetDomainRole()

logfile.WriteLine "DomainRole= " & Strdomainrole


If Strdomainrole <= "1" Then


	logfile.writeline "Checking Membership of Admin"
	logfile.writeline STRLocalAdminGroup & "\" & STRadmACCT
	On Error Resume next
    Set objGroup = GetObject("WinNT://" & Compname & "/" & STRLocalAdminGroup & ",group")
    If Not objGroup.IsMember("WinNT://" & STRadmACCT) Then
	       objGroup.Add ("WinNT://"& STRadmACCT)
	       logfile.writeline "Admin Missing"
	       logfile.writeline "Adding Admin"
	       
	      	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
			strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"
	       	strValueName = "Account_Check"
			STrACCValue = 1
			oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strACCValue
				
	     Else 
	       logfile.writeline "Admin Present"
	       
	      	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
			strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"
			strValueName = "Account_Check"
			STrACCValue = 0
			oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strACCValue
				
	       
        End If

Else

' Server Check

logfile.writeline "Checking Membership of Admin"
	logfile.writeline STRLocalAdminGroup & "\" & STRAdmSRACCT
	On Error Resume next
    Set objGroup = GetObject("WinNT://" & Compname & "/" & STRLocalAdminGroup & ",group")
    If Not objGroup.IsMember("WinNT://" & STRAdmSRACCT) Then
	       objGroup.Add ("WinNT://"& STRAdmSRACCT)
	       logfile.writeline "Admin Missing"
	       logfile.writeline "Adding Admin"
	       
	      	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
			strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"
	       	strValueName = "Account_Check"
			STrACCValue = 1
			oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strACCValue
				
	     Else 
	       logfile.writeline "Admin Present"
	       
	      	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
			strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"
			strValueName = "Account_Check"
			STrACCValue = 0
			oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strACCValue

	End If
End If

End Sub
 
'************************************
'*      Check WMI                   *
'*  no solution for fixing WMI Yet  *
'************************************
  
'CHECK If WMI IS ACCESSIBLE and CONNECT, If not Alert user to contact Domain Admin
Function CheckWMI    
    Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
	
	If err<>0 Then
		'//CANNOT CONNECT TO WMI
		 logfile.writeline "ERRORS","WMI_CONNECT","FAILED",Err.description,Null
		 'Call EmailMessage ("WMI Connection is failing on computer: " & Compname& ".", "Please check this machine out. WMI Error message: "& Err.description & "")
		 WScript.Quit
	Else
		logfile.writeline "WMI Check Passed"
	End If
	
End Function			



'**********************************
'*   Check Client Info            *
'**********************************
' no solution needed just gathering info for other tasks

Function Check_Client_info

	Set SmsClient = GetObject("winmgmts:ROOT/CCM:SMS_Client=@")
	Set oUIResManager = CreateObject("UIResource.UIResourceMgr")
	Set oSMSClient = CreateObject ("Microsoft.SMS.Client")
		
	
		logfile.writeline  ""
		logfile.writeline  "Client Info"
		logfile.writeline  "SCCM Client Version: " & SmsClient.ClientVersion
		logfile.writeline  "Assigned To: " & oSMSClient.GetAssignedSite
		logfile.writeline  "MP: " & oSMSClient.gETCurrentManagementPoint
		logfile.writeline  ""
		wShShell1.LogEvent 0, "SCCM Client Version: "& SmsClient.ClientVersion
		wShShell1.LogEvent 0, "Assigned To: " & oSMSClient.GetAssignedSite
		logfile.writeline ""
End Function



' *****************************************************
' *           ShowFileAccessInfo function             *
' *****************************************************
' for future use
Function ShowFileAccessInfo(filespec, Compname)
    On Error Resume Next
    logfile.writeline "Running ShowFileAccessInfo"
    Dim fso, f, filespec_date, FSpace
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(filespec) Then
	     Set f = fso.GetFile(filespec)
	     logfile.writeline "f = " & f
	     filespec_date = f.DateLastModified
	     logfile.writeline "filespec_date = " & filespec_date
	     FSpace = InStr(filespec_date," ") - 1
	     logfile.writeline "FSpace = " & FSpace
	     ShowFileAccessInfo = Left(filespec_date,FSpace)
	     logfile.writeline "ShowFileAccessInfo = " & ShowFileAccessInfo
	 Else
 		logfile.writeline "File Missing - " & filespec & " is missing On " & Compname
 		logfile.writeline "Exiting Script Processing"
 		WScript.Quit
  	End If
End Function


'************************************************************************************
'*      Run Inventory check and run if needed                                       *
'*    Checks And solutions are added In already                                    *
'************************************************************************************
'**********************************
'*   Check_Inventory              *
'**********************************


Function Check_Inventory
	logfile.writeline  ""
	logfile.writeline "Checking Hardware and Software Inventory Scan Dates"
	'**********************************
	' Inventory Checks
	'**********************************
	logfile.writeline  ""
	StrHWDays= 3 'Change To number of days since last Hardware Scan
	StrSWDays= 5 'Change To number of days since last Software Scan
	StrToday = Date()
	'****************************
	' Hardware Inventory Scan
	'****************************
	
	Set objSMS = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\ccm\invagt")
	Set colInvInfo = objSMS.ExecQuery ("Select * from InventoryActionStatus where InventoryActionID like '%00000000-0000-0000-0000-000000000001%'")
	logfile.writeline  "Start Hardware Check Check"
	
	For Each objInvInfo In colInvInfo
	
		Select Case objInvInfo.InventoryActionID
			Case "{00000000-0000-0000-0000-000000000001}"
				strHWInv = "Hardware Inventory"
		End Select
		strHWresults = convDate(objInvInfo.LastCycleStartedDate, intBias)
		'logfile.writeline strHWInv & vbTab & strHWresults
		logfile.writeline "Last Hardware scan Date: " & strHWresults
	
		
		'logfile.writeline "Todays Date: " & StrToday
		
		StrDiff1 = (DateDiff ("d",strHWresults, strToday))
		
		If  StrHWDays > StrDiff Then
			logfile.writeline "Hardware Inventory check is good."
			
			
				Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
				strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"
				strValueName = "HW_Check"
				STrHWValue = 0
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strHWValue
						
			Else
			logfile.writeline "Inventory check hasn't run In atleast 3 days, Harware scan last run " & StrDiff1 & "Days ago."
			logfile.writeline "Run Hardware scan Now"
			
				Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
				strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"
				strValueName = "HW_Check"
				STrHWValue = 1
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strHWValue
						
			Sync_HW_Inventory
		End If 		
	
	Next
	'****************************
	' Software Inventory Scan
	'****************************
	Set colInvInfo = objSMS.ExecQuery ("Select * from InventoryActionStatus where InventoryActionID like '%00000000-0000-0000-0000-000000000002%'")
	logfile.writeline  "Start Software Check Check"
	For Each objInvInfo In colInvInfo
	
		Select Case objInvInfo.InventoryActionID
			Case "{00000000-0000-0000-0000-000000000002}"
				strSWInv = "Software Inventory"
		End Select
		strSWResults= convDate(objInvInfo.LastCycleStartedDate, intBias)
		'logfile.writeline strSWInv & vbTab & strSWResults
		logfile.writeline "Last Software scan date: " & strSWResults
		
		StrDiff = (DateDiff ("d",strSWResults, strToday))
		
		If  StrSWDays > StrDiff Then
			logfile.writeline "Software Inventory check Is good."
			
				Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
				strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"
				strValueName = "SW_Check"
				STrSWValue = 0
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strSWValue
					
			Else
			logfile.writeline "Inventory check hasn't run In at least 5 days, Hardware scan last run " & StrDiff & "Days ago."
			logfile.writeline "Run Software scan Now"
			
				Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\Default:StdRegProv")
				strKeyPath = "SOFTWARE\Red Gold IT\Health_Check"
				strValueName = "SW_Check"
				STrSWValue = 1
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strSWValue
				
			
			Sync_SW_Inventory
		End If 		
	
	
	
	Next
	
End Function

'********************************
'*    Convert date to readable  *
'********************************

Function convDate(dtmInstallDate, intBias)
    convDate = CDate(Mid(dtmInstallDate, 5, 2) & "/" & _
    Mid(dtmInstallDate, 7, 2) & "/" & Left(dtmInstallDate, 4) _
    & " " & Mid (dtmInstallDate, 9, 2) & ":" & _
    Mid(dtmInstallDate, 11, 2) & ":" & Mid(dtmInstallDate, 13, 2))
	convDate = DateAdd("N",intBias,convDate)           
End Function


'*****************************************
'*      Hardware Inventory Sync          *
'*****************************************

Function Sync_HW_Inventory
	
	'Declare Variables
	
	On Error Resume Next
	
	Set sho = CreateObject("WScript.Shell")
	
	strSystemRoot = sho.expandenvironmentstrings("%SystemRoot%")
	strCurrentDir = Left(WScript.ScriptFullName, (InstrRev(Wscript.ScriptFullName, "\") -1))
	' Get a connection to the "root\ccm\invagt" namespace (where the Inventory agent lives)
	Dim oLocator
	Set oLocator = CreateObject("WbemScripting.SWbemLocator")
	Dim oServices
	Set oServices = oLocator.ConnectServer( , "root\ccm\invagt")
	'Reset SMS Hardware Inventory Action to force a full HW Inventory Action
	sInventoryActionID = "{00000000-0000-0000-0000-000000000001}"
	' Delete the specified InventoryActionStatus instance
	oServices.Delete "InventoryActionStatus.InventoryActionID=""" & sInventoryActionID & """"
	'Pause 3 seconds To allow the action to complete.
	wscript.sleep 3000
	'Run a SMS Hardware Inventory
	Set cpApplet = CreateObject("CPAPPLET.CPAppletMgr")
	Set actions = cpApplet.GetClientActions
	For Each action In actions
	    If Instr(action.Name,"Hardware Inventory") > 0 Then
	        action.PerformAction   
	End If
	Next
End Function

'*****************************************
'*      Software Inventory Sync          *
'*****************************************

Function Sync_SW_Inventory
	On Error Resume Next
	
	Set sho = CreateObject("WScript.Shell")
	
	strSystemRoot = sho.expandenvironmentstrings("%SystemRoot%")
	strCurrentDir = Left(WScript.ScriptFullName, (InstrRev(Wscript.ScriptFullName, "\") -1))
	' Get a connection to the "root\ccm\invagt" namespace (where the Inventory agent lives)
	Dim oLocator
	Set oLocator = CreateObject("WbemScripting.SWbemLocator")
	Dim oServices
	Set oServices = oLocator.ConnectServer( , "root\ccm\invagt")
	'Reset SMS Hardware Inventory Action to force a full SW Inventory Action
	sInventoryActionID = "{00000000-0000-0000-0000-000000000002}"
	' Delete the specified InventoryActionStatus instance
	oServices.Delete "InventoryActionStatus.InventoryActionID=""" & sInventoryActionID & """"
	'Pause 3 seconds To allow the action to complete.
	WScript.sleep 3000
	'Run a SMS Software Inventory
	Set cpApplet = CreateObject("CPAPPLET.CPAppletMgr")
	Set actions = cpApplet.GetClientActions
	For Each action In actions
	    If Instr(action.Name,"Software Inventory Collection Cycle") > 0 Then
	        action.PerformAction   
	End If
	Next
	WScript.sleep 3000
End Function


'*********************************** End of Inventory Checks ********************************




'**********************************
'*   Client Cache Info            *
'*   included a solution          *
'**********************************

Function Check_cache_info
	
	Set oUIResManager = CreateObject("UIResource.UIResourceMgr")
	Set cacheinfo=oUIResManager.GetCacheInfo
	Set oSMSClient = CreateObject ("Microsoft.SMS.Client")
		
	strDrive = Left(cacheinfo.location,2)
	strCacheFree = cacheinfo.FreeSize
    strPrevious  = cacheinfo.TotalSize
    strLocation  = cacheinfo.location
    	
		logfile.writeline  ""
		logfile.writeline  "Cache Info"
		logfile.writeline  "Cache Drive Letter: " & strDrive 
		logfile.writeline  "Location: " & strLocation
		logfile.writeline  "Total Size: " & strPrevious
		logfile.writeline  "Free Size: " & strCacheFree
		logfile.writeline ""
			
	' Get free disk Space
	Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
	Set colDisks = objWMIService.ExecQuery ("Select * from Win32_LogicalDisk Where DriveType = " & HARD_DISK & "")
	For Each objDisk In colDisks
	            ' loop through all of the drives until we find one that matches the cache location
	            if UCase(objDisk.DeviceID) = UCase(strDrive) Then 
	                        ' get the available disk space and convert to MB 
	               strDiskFree =  round(objDisk.FreeSpace/1048576,0)  
	                        Exit For
	   end If 
	Next
	optCache = strPrevious + ( SCCMCacheSize - strCacheFree) 
	StrOptCache = optCache
	available = round(strDiskFree * .5, 0 )
	' If there's not enough free disk Then we'll create and error message
	if optCache < available Then 
	            cacheinfo.TotalSize = optCache
	            logfile.writeline "Cache size Set to: " & StrOptCache
	  Else
	            logfile.writeline =  "Not ENOUGH SPACE"
	end If
	
	Set oUIResManager=Nothing
	set oCache=Nothing
		
End Function

' *****************************************************
' Destroy any objects
' *****************************************************
Sub Cleanup
     On Error Resume Next
     logfile.writeline "Running Cleanup"
     Set WshShell = Nothing
  Set ComSpec = Nothing
  Set windir = Nothing
  Set strCompName = Nothing
  Set SmsClient = Nothing
End Sub
 ' *****************************************************
 
' ******************************************************
' *     EmailMessage Function                          *               
' ******************************************************
Function EmailMessage(Subject, Body)
      On Error Resume Next
      Dim objEmail
    ' email using a generic user account as system is being booted up and user may not have logged on yet
      Set objEmail = CreateObject("CDO.Message")
      objEmail.From = CompanyEmailSender
      objEmail.To = CompanyEmailRecipient
      objEmail.Subject = Subject
      objEmail.Textbody = Body
      objEmail.Configuration.Fields.Item _
      ("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2
      objEmail.Configuration.Fields.Item _
      ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = _
      CompanySMTPServer
      objEmail.Configuration.Fields.Item _
      ("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25
      objEmail.Configuration.Fields.Update
      objEmail.Send
      Set objEmail = Nothing
End Function

' ******************************************************
' *     Repair Client Function                         *               
' ******************************************************
Function Repair_Client
	Set sho = CreateObject("WScript.Shell")
	Err.clear
	Set smsclient = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\ccm:SMS_Client")
	if err.number <> 0 then
	 sho.logevent 4, "Unable to access " & CompName & vbcr & "Error: " & err.description
	 wscript.quit
	end If
	smsClient.RepairClient
	 sho.logevent 4, "Executed Remote SMS Client Repair Request."
End Function

' ******************************************************
' *     Script_increment Function                      *               
' ******************************************************

Function Script_increment
	strValue = ""
	logfile.writeline "Health Check Scan run"
			strValueName = "Scan_Run"
			oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
			
			'logfile.writeline "Value= "& strValue

	If Strvalue = "" Or IsNull (Strvalue) Then
				'logfile.writeline "Health Check Scan run1"
				strValueName = "Scan_Run"
				STRACCValue = 0
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strACCValue
				'logfile.writeline "Account_Check value changed To: " & STRACCValue	
			Else
				'logfile.writeline "Health Check Scan run2"
				strValueName = "Scan_Run"
				oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
				'logfile.writeline "Value= " & Strvalue 
				STrHCValue = strValue + 1 ' increment value plus 1
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strHCValue
				'logfile.writeline "Scan_Run value changed To: " & STRHCValue
	End If

	If STRHCValue = 1 Then
			logfile.writeline ""
			logfile.writeline "Run History Shift Function"
			History_Shift
	End If
	
	If STRHCValue = 2 Then
			logfile.writeline ""
			logfile.writeline "Run History Shift Function"
			History_Shift
			logfile.writeline ""
			logfile.writeline "Run History Check Function"
			History_Check
	End If

End Function


' ******************************************************
' *     History_Shift Function                         *               
' ******************************************************
Function History_Shift
	'Advertisement History move
	logfile.writeline "Advertisement Check History Shifted"
				strValueName = "Adertisement_Check"
				strValueName1 = "HS_Adertisement_Check"
				oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
				'logfile.writeline "Adertisement_Check value Is: " & STRValue
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName1,strValue
				'logfile.writeline "HS_Adertisement_Check value changed To: " & STRValue
				STRHSACValue =STRValue
	
	'Hardware History move
	logfile.writeline "Hardware Scan History Shifted"
				strValueName = "HW_Check"
				strValueName1 = "HS_HW_Check"
				oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
				'logfile.writeline "HW_Check value Is: " & STRValue
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName1,strValue
				'logfile.writeline "HS_HW_Check value changed To: " & STRValue		
				STRHSHWValue = STRValue
	
	'Software History move			
	logfile.writeline "Software Scan History Shifted"
				strValueName = "SW_Check"
				strValueName1 = "HS_SW_Check"
				oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
				'logfile.writeline "SW_Check value Is: " & STRValue
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName1,strValue
				'logfile.writeline "HS_SW_Check value changed To: " & STRValue
				STRHSSWValue = STRValue
	
	' CCM service History move
	logfile.writeline "CCMClient Service check History Shifted"
				strValueName = "CCM_Service_Check"
				strValueName1 = "HS_CCM_Service_Check"
				oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
				'logfile.writeline "CCM_Service_Check value Is: " & STRValue
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName1,strValue
				'logfile.writeline "HS_CCM_Service_Check value changed To: " & STRValue
				STRHSCCMValue = STRValue	
	
	' Admin$ Check History move			
	logfile.writeline "Admin$ History Shifted"
				strValueName = "Admin$_Check"
				strValueName1 = "HS_Admin$_Check"
				oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
				'logfile.writeline "Admin$_Check value Is: " & STRValue
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName1,strValue
				'logfile.writeline "HS_Admin$_Check value changed To: " & STRValue
				STRHSADValue = STRValue
	
	'Account Check History move			
	logfile.writeline "Admin account History Shifted"
				strValueName = "Account_Check"
				strValueName1 = "HS_Account_Check"
				oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
				'logfile.writeline "Account_Check value Is: " & STRValue
				oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName1,strValue
				'logfile.writeline "HS_Account_Check value changed To: " & STRValue
				STRHSACCValue = STRValue

End Function

' ******************************************************
' *     History_Check Function                         *               
' ******************************************************
Function History_Check

		' Account Check
		strValueName = "Account_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRACCValue = STRValue
		
		strValueName = "HS_Account_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRHSACCValue = STRValue
		
		' Admin$ Check
		strValueName = "HS_Admin$_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRHSADValue = STRValue
		
		strValueName = "Admin$_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRADValue = STRValue
		
		'CCM Service Check
		strValueName = "CCM_Service_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRCCMValue = STRValue
		
		strValueName = "HS_CCM_Service_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRHSCCMValue = STRValue
		
		'Software Check
		strValueName = "HS_SW_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRHSSWValue = STRValue
		
		strValueName = "SW_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRSWValue = STRValue
		
		' Hardware Check			
		strValueName = "HS_HW_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRHSHWValue = STRValue
		
		strValueName = "HW_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRHWValue = STRValue
		
		' Advertisement Check
		strValueName = "HS_Adertisement_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRHSACValue =STRValue
		
		strValueName = "Adertisement_Check"
		oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
		STRACValue = STRValue
		
		'**************************************
		' Account Check			
		If 	STRHSACCValue =	STRACCValue And STRACCValue = 1 Then
		
		logfile.writeline "Email Admin that someone keeps Deleting account"
		'Call EmailMessage ("Admin account repeatedly deleted from " & Compname& ".", "Please ckeck this machine out") 
		End If 	
		
		' Admin$ Check			
		If 	STRHSADValue = STRADValue And STRADValue = 1 Then
		
		logfile.writeline "Email Admin that someone keeps Diabling Admin$ Share"
		'Call EmailMessage ("Admin account repeatedly deleted from " & Compname &".", "Please ckeck this machine out") 
		End If 	
		
		' CCM Service account Check			
		If STRHSCCMValue = STRCCMValue and STRCCMValue =1 Then
		
		logfile.writeline "Email Admin that someone keeps disabling service"
		'Call EmailMessage ("Service account repeatedly deleted from " & Compname &".", "Please ckeck this machine out") 
		
		End If 	
		
		' Software Check			
		If 	STRHSSWValue = STRSWValue and STRSWValue = 1 Then
		
			logfile.writeline "Failed Software Check, Repair Client"
			logfile.writeline "Clear all Reg keys"
			oReg.DeleteKey HKEY_LOCAL_MACHINE, strKeyPath
			Repair_Client
		End If 	
		
		' Hardware Check			
		If 	STRHSHWValue = STRHWValue And STRHWValue = 1 Then
		
			logfile.writeline "Failed Hardware Check, Repair Client "
			logfile.writeline "Clear all Reg keys"
			oReg.DeleteKey HKEY_LOCAL_MACHINE, strKeyPath
			 Repair_Client
		End If 	
		
		' Advertisement Check			
		If 	STRHSACValue = STRACValue and STRACValue =1 Then
		
			logfile.writeline "Failed Advertisement Check, Repair Client"
			logfile.writeline "Clear all Reg keys"
			oReg.DeleteKey HKEY_LOCAL_MACHINE, strKeyPath
			Repair_Client
		End If 

End Function
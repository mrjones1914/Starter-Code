'****************************************************************************************
' Originally by Mark Nunn - CollAdd.vbs to add Machines to a collection
' Modified by nhalme (19.6.2008) - CollAddUsers.vbs to add Users to a collection
'
'This adds a list of user names from a file to a collection.
'It can also list all collections on a server.

' Usage:
'        Colladd.vbs ServerName FileName CollectionID   - to add from file to collection
'        Colladd.vbs ServerName                         - to list collectionID's
' To make a log file use Command prompt (cmd.exe) and the following command line:
'        cscript Colladd.vbs ServerName FileName CollectionID >[LOG PATH\FileName.log]

'****************************************************************************************

Set fso = CreateObject("Scripting.FileSystemObject")					 

Set arrArgs = WScript.Arguments
if (arrArgs.Count = 0) Then								'Display Blurb
	wscript.echo ("CollAddUsers.vbs v1.0")					
	wscript.echo ("Colladd.vbs ServerName FileName CollectionID - to add from file to collection")
	wscript.echo ("Colladd.vbs ServerName - to list collectionID's")
else

	on error resume next								'Some error handling

	strServer=arrArgs(0)								'set variables from command line

	if (arrArgs.Count = 3) Then
		strFile=arrArgs(1)
		strCollID=arrArgs(2)
	end if
	Set objLocator = CreateObject("WbemScripting.SWbemLocator") 			
	Set objSMS = objLocator.ConnectServer(strServer, "Root/SMS")			'connect to sms
	objSMS.Security_.ImpersonationLevel = 3
	wscript.Echo("Connecting to Root/SMS on " & strServer)			
	
	set colSiteDetails=objSMS.ExecQuery("select Machine, SiteCode from SMS_ProviderLocation where ProviderForLocalSite=True")
	For Each insSiteDetails In colSiteDetails
		strSiteCode=insSiteDetails.SiteCode
	next										
	wscript.Echo("Connecting to Root/SMS/site_" & strSiteCode &" on " & strServer)
	set objSMS=objLocator.ConnectServer(strServer, "root/SMS/site_" + strSiteCode)
	wscript.Echo("Connected") 

	if (arrArgs.Count < 3) Then							'if not all arguments supplied list colelctions
		set colCollections=objSMS.ExecQuery("select CollectionID, Name from SMS_Collection ORDER BY CollectionID")
		wscript.echo("CollectionID" & vbTab & "Name")
		For Each insCollection In colCollections
			wscript.echo(insCollection.CollectionID & VbTab & insCollection.Name)
		Next
	else										'otherwise add from file
		set instColl = objSMS.Get("SMS_Collection.CollectionID="&"""" & strCollID & """")
		if Instcoll.Name="" then						'check valid collection
			wscript.echo (strCollId &" Not Found")
		else
			Set filNames = fso.OpenTextFile(strFile)				'open file of machines
			if  (filNames) then
				While not filNames.AtEndOfStream
					strUser=filNames.ReadLine				'read each line and find resource ID
					set colNewResources=objSMS.ExecQuery("SELECT ResourceId FROM SMS_R_User WHERE Name LIKE ""%" + strUser + "%""")	
					strNewResourceID = 0  				
					For each insNewResource in colNewResources
						strNewResourceID = insNewResource.ResourceID
					Next
					if strNewResourceID <> 0 then				'if one exists crate a collection rule
						Set instDirectRule = objSMS.Get("SMS_CollectionRuleDirect").SpawnInstance_ ()
						instDirectRule.ResourceClassName = "SMS_R_User"	
						instDirectRule.ResourceID = strNewResourceID
						instDirectRule.RuleName = insNewResource.Name
						instColl.AddMembershipRule instDirectRule , SMSContext
						instColl.RequestRefresh False
						wscript.echo(strUser & " Added to " & Instcoll.Name)
					else
						wscript.echo(strUser & " Not Found")		'otherwise display error
					end if
				WEnd								'next line
			else
				 wscript.echo ("Can't Open " & strfile)				'if file not found
			end if
		end if
	end if
end if


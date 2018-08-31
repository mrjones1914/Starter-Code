' Create an SMS Package and Program



On Error Resume Next

Dim objSWbemLocator
Dim objSWbemServices
Dim ProviderLoc
Dim Location

Dim PackageName
Dim ProgramName
Dim newPackage
Dim newProgram
Dim Package
Dim PackageID
Dim Path

PackageName="Package Name"
ProgramName="Program Name"

'connect to provider namespace for local computer
Set objSWbemLocator = CreateObject("WbemScripting.SWbemLocator")

Set objSWbemServices= objSWbemLocator.ConnectServer(".", "root\sms")

Set ProviderLoc = objSWbemServices.InstancesOf("SMS_ProviderLocation")

For Each Location In ProviderLoc
        If Location.ProviderForLocalSite = True Then
            Set objSWbemServices = objSWbemLocator.ConnectServer _
                 (Location.Machine, "root\sms\site_" + Location.SiteCode)
        End If
Next

'create package

Set newPackage = objSWbemServices.Get("SMS_Package").SpawnInstance_()
newPackage.Name = PackageName
newPackage.Description = "created by script"
newPackage.PkgSourceFlag = 2 
newPackage.PkgSourcePath = "\\S006670.redgold.com\Source$"
Path=newPackage.Put_
Wscript.Echo "Created packge " +PackageName

'and get the automatically assigned package ID

Set Package=objSWbemServices.Get(Path)
PackageID= Package.PackageID

Set newProgram = objSWbemServices.Get("SMS_Program").SpawnInstance_()
newProgram.ProgramName = ProgramName
newProgram.PackageID = PackageID
newProgram.Comment = "phone the helpdesk for support with this program"
newProgram.CommandLine = "setup.exe"
newProgram.Put_
Wscript.Echo "Created program " + ProgramName
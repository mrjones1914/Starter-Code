#
# Copyright Citrix Systems 2011-2012
#
# Script to check UPM configuration
# $Revision: #140 $
#

<#
.SYNOPSIS
This script analyses a machine running UPM and inspects the environment to generate configuration recommendations.
The environment data can be exported to a CSV file.
.PARAMETER ProfileDriveThresholdPercent
 ProfileDriveThresholdPercent sets a disk threshold for the Profile Volume.  The script warns if the free disk on the Profile Volume is below the stated percentage.
.PARAMETER WriteCsvFiles
 WriteCsvFiles causes the script to write fixed-named data files in CSV format, to assist with offline analysis.
.PARAMETER iniFilePath
 iniFilePath configures an alternate file path for the INI file.  There are two use-cases - debugging the script is one, but the parameter could also be used for testing an INI file, prior to deploying it in a live environment
.DESCRIPTION
The script inspects the UPM Service status and configuration, the machine environment and information on other installed Citrix products, such as PVD, VDI-in-a-Box, XenApp, XenDesktop, XenServer, as well as third-party products, including hypervisors.  The script predominatly obtains its information through WMI queries, and by examining the registry.

The script recommends changes to the UPM configuration, where the environment corresponds to one that has been studied by the UPM team.  

However, this is at best "good faith" advice, and your next step should always to review the advice alongside other Citrix and trusted third-party documentation.  Bear in mind that usage patterns, as well as other factors that the script cannot detect, may invalidate the recommendations of the script.

When WriteCsvFiles is specified, two CSV files will be generated:
-  UPMPolicySummary.csv contains information on which UPM policies have been tested, whether the policies were detected in an INI file, Group Policy (FullArmor) or defaulted.
-  UPMEnvironmentSummary.csv contains summary information an the environment, including UPM itself, Windows, Hypervisors, XenApp, XenDesktop, PVD.

The script is designed to be run from a powershell command line logged-on as a domain user.  Some operations may not be available without elevated privilege, and the script will advise in such cases.

Supported Platforms: Windows XP, Windows Server 2003, Windows Vista, Windows 7, Windows Server 2008 R2, Windows 8, Windows Server 2012.  Support for this script on a platform does not imply that Citrix supports any specific features, products or combination of products on that platform, including but not limited to UPM (Citrix Profile Management), XenApp, XenDesktop, Xen Server, Personal vDisk and/or VDI-in-a-Box.

Errors detected: None.
.LINK
The latest version of the script can be downloaded from citrix.com:
Download: http://support.citrix.com/article/CTX132805
Blog:     http://blogs.citrix.com/2012/09/18/did-i-get-it-right-the-profile-management-configuration-check-tool-upmconfigcheck/
#>


param (
  [int]$ProfileDriveThresholdPercent = 15,
  [Parameter(Mandatory=$false)]
  [switch]
  $WriteCsvFiles,
  [Parameter(Mandatory=$false)]
  [string]
  $iniFilePath=""
)

$copyright = "Citrix Systems 2011-2013"
$upmCheckVersion = 'UPM Configuration checking tool version $Revision: #140 $'
$scriptRunDate = date
"Run at " + $scriptRunDate.DateTime

############################################################################
#
# ... start of the function definitions + associated data structures
#
############################################################################

$mandatorySyncExclusionListDir = @()  # initially empty, but added-to through environment checks
                                      # if folders are put here, it's because we've detected
                                      # something in the environment that NEEDS the exclusion
                                      # else stuff will break

$appVDefaultExcludedFolder      = '!ctx_localappdata!\Microsoft\AppV'
$groupPolicyExclusionFolder = '!ctx_localappdata!\GroupPolicy'
$shareFileDefaultExcludedFolder = 'sharefile'
$win8DefaultExcludedFolderList = @('!ctx_localappdata!\Packages','!ctx_localappdata!\Microsoft\Windows\Application Shortcuts')

$recommendedSyncExclusionListDir = @(
'$Recycle.Bin',
'AppData\LocalLow',
$groupPolicyExclusionFolder,
'!ctx_internetcache!',
$appVDefaultExcludedFolder,
'!ctx_localappdata!\Microsoft\Windows\Burn',
'!ctx_localappdata!\Microsoft\Windows\CD Burning',
'!ctx_localappdata!\Microsoft\Windows Live',
'!ctx_localappdata!\Microsoft\Windows Live Contacts',
'!ctx_localappdata!\Microsoft\Terminal Server Client',
'!ctx_localappdata!\Microsoft\Messenger',
'!ctx_localappdata!\Microsoft\OneNote',
'!ctx_localappdata!\Microsoft\Outlook',
'!ctx_localappdata!\Windows Live',
'!ctx_localappdata!\Sun',
'!ctx_localsettings!\Temp',
'!ctx_roamingappdata!\Sun\Java\Deployment\cache',
'!ctx_roamingappdata!\Sun\Java\Deployment\log',
'!ctx_roamingappdata!\Sun\Java\Deployment\tmp',
'!ctx_localappdata!\Google\Chrome\User Data\Default\Cache',
'!ctx_localappdata!\Google\Chrome\User Data\Default\Cached Theme Images',
'!ctx_startmenu!'
)

function addMandatoryFolderExclusions ($Folder) {
  $FolderList = @($Folder)
  for ($ix = 0; $ix -lt $FolderList.Length; $ix++) {
    $f = $FolderList[$ix]
    $script:mandatorySyncExclusionListDir = $script:mandatorySyncExclusionListDir + $f
    $script:mandatorySyncExclusionListDir = @($script:mandatorySyncExclusionListDir)  #force it to be an array
  }
}

function addRecommendedFolderExclusions ($Folder) {
  $FolderList = @($Folder)
  for ($ix = 0; $ix -lt $FolderList.Length; $ix++) {
    $f = $FolderList[$ix]
    $script:recommendedSyncExclusionListDir = $script:recommendedSyncExclusionListDir + $f
    $script:recommendedSyncExclusionListDir = @($script:recommendedSyncExclusionListDir)  #force it to be an array
  }
}

filter v1SubstituteNames {
  begin {
    }
  process {
      $_ `
           -replace "!ctx_internetcache!",  "Local Settings\Temporary Internet Files" `
           -replace "!ctx_localappdata!",   "Local Settings\Application Data" `
           -replace "!ctx_localsettings!",  "Local Settings" `
           -replace "!ctx_roamingappdata!", "Application Data" `
           -replace "!ctx_startmenu!",      "Start Menu" 
    }
  end {
    }
}

filter v1RemoveNames {
  begin {
    }
  process {
      $line = $_
      switch -regex ($line) {
        "^Local Settings" {}
        "^Application Data" {}
        "^Start Menu" {}
        default { $line }
      }
    }
  end {
    }
}

function v1CompatibleNames ($stringArray) {
  $hasNames = $false
  switch -regex ($stringArray) {
    "^Local Settings" { $hasNames = $true }
    "^Application Data" { $hasNames = $true }
    "^Start Menu" { $hasNames = $true }
    default {}
  }
  $hasNames
}

function neutralNames ($stringArray) {
  $hasNames = $false
  switch -regex ($stringArray) {
    "^\!CTX_[A-Z]+\!" { $hasNames = $true }
    default {}
  }
  $hasNames
}

filter v2SubstituteNames {
  begin {
    }
  process {
      $_ `
           -replace "!ctx_internetcache!",  "AppData\Local\Microsoft\Windows\Temporary Internet Files" `
           -replace "!ctx_localappdata!",   "AppData\Local" `
           -replace "!ctx_localsettings!",  "AppData\Local" `
           -replace "!ctx_roamingappdata!", "AppData\Roaming" `
           -replace "!ctx_startmenu!",      "Appdata\Roaming\Microsoft\Windows\Start Menu" 
    }
  end {
    }
}

filter v2RemoveNames {
  begin {
    }
  process {
      $line = $_
      switch -regex ($line) {
        "^AppData" {}
        default { $line }
      }
    }
  end {
    }
}

function v2CompatibleNames ($stringArray) {
  $hasNames = $false
  switch -regex ($stringArray) {
    "^AppData" { $hasNames = $true }
    default {}
  }
  $hasNames
}

filter ReportDifferences ($type) {
  begin {
    }
  process {
      $item = $_.InputObject
      $indicator = $_.SideIndicator
      $t = $null
      switch ($indicator) {
        "=>" { $t = "Added" }
        "<=" { $t = "Missing" }
        "==" { $t = "Same" }
      }
      if ($t -ne $null) {
        New-Object Object |
          Add-Member NoteProperty ComparisonType $type -PassThru |
          Add-Member NoteProperty Difference     $t    -PassThru |
          Add-Member NoteProperty LineItem       $item -PassThru 
      }
    }
  end {
    }
}

function CompareLists ($preferredList, $specimenList) {
  #
  # force both lists to be arrays - this helps cookie / mirrored folder processing
  $preferredList = @($preferredList)
  $specimenList = @($specimenList)
  #
  # the specimenList just needs to be sorted once, into alphabetical order
  # note that duplicates are removed here, because duplicate testing is
  # performed elsewhere
  #
  $processedSpecimen = $specimenList | sort-object -Unique
  if (neutralNames($processedSpecimen)) {
    #
    # if the speciment array contains neutral names, then we sort both 
    # the preferred and specimen arrays alphabetically, removing duplicates
    # and compare them without processing to either v1 or v2 names
    #
    $processedPreferred = $preferredList | sort-object -Unique
    write-host "Compare as Neutral List"
    Compare-Object -ReferenceObject $processedPreferred -DifferenceObject $processedSpecimen -IncludeEqual | ReportDifferences -type "Neutral"
  } else {
    #
    # the specimen contains no neutral names, so we process the list once 
    # for v1 names and once for v2 names
    # It is possible for both v1 and v2 names to be present in
    # an exclusion list - some customers share the list for both
    # XP and Win7 machines in a single OU
    #
    # Remove any V2 profile names from the list and if not empty,
    # test against the V1 version of the list
    #
    $processedV1List = $processedSpecimen | v2RemoveNames
    if (v1CompatibleNames($processedV1List)) {
      $processedPreferred = $preferredList | v1SubstituteNames | sort-object
      write-host "Compare as V1 List"
      Compare-Object -ReferenceObject $processedPreferred -DifferenceObject $processedV1List -IncludeEqual | ReportDifferences -type "V1"
    }
    #
    # Remove any V1 profile names from the list and if not empty,
    # test against the V2 version of the list
    #
    $processedV2List = $processedSpecimen | v1RemoveNames
    if (v2CompatibleNames($processedV2List)) {
      $processedPreferred = $preferredList | v2SubstituteNames | sort-object
      write-host "Compare as V2 List"
      Compare-Object -ReferenceObject $processedPreferred -DifferenceObject $processedV2List -IncludeEqual | ReportDifferences -type "V2"
    }
  }
}

function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

$sdir = Get-ScriptDirectory

#
# standard files are created relative to the folder where we place the script
#
$csvSinglePolicySummaryFile    = $sdir + "\UPMPolicySummary.csv"
$csvListPolicySummaryFile      = $sdir + "\UPMListPolicySummary.csv"
$csvEnvironmentSummaryFile     = $sdir + "\UPMEnvironmentSummary.csv"

#
# customise colours used by Write-Host
#
$errorColours = @{foreground="red";background="black"}
$warnColours = @{foreground="magenta";background="blue"}
$infoColours = @{foreground="cyan";background="blue"}
$hilight1 = @{foreground="red";background="blue"}
$hilight2 = @{foreground="yellow";background="blue"}

$physical = "Physical"   # constant denoting physical (non-hypervisor) and non-provisioned environments

#
# used to build up list of recommendations
#
$errStrings = @()
#
# Functions for maintaining a "database" of policies
#

$policyList = @(
  #  PolicyName                               Default Value
  @("CPEnabled",                              0),
  @("CPMigrationFromBaseProfileToCPStore",    0),
  @("CPPath",                                 "Windows\PM_CP"),
  @("CPSchemaPath",                           ""),
  @("CPUserGroupList",                        ""),
  @("DeleteCachedProfilesOnLogoff",           0),
  @("DisableDynamicConfig",                   ""),
  @("ExcludedGroups",                         ""),
  @("ExclusionListRegistry",                  ""),
  @("InclusionListRegistry",                  ""),
  @("LoadRetries",                            5),
  @("LocalProfileConflictHandling",           1),
  @("LogLevelActiveDirectoryActions",         0),
  @("LogLevelFileSystemActions",              0),
  @("LogLevelFileSystemNotification",         0),
  @("LogLevelInformation",                    1),
  @("LogLevelLogoff",                         1),
  @("LogLevelLogon",                          1),
  @("LogLevelPolicyUserLogon",                0),
  @("LogLevelRegistryActions",                0),
  @("LogLevelRegistryDifference",             0),
  @("LogLevelUserName",                       1),
  @("LogLevelWarnings",                       1),
  @("LoggingEnabled",                         0),
  @("LogoffRatherThanTempProfile",            ""),
  @("MaxLogSize",                             1048576),
  @("MigrateWindowsProfilesToUserStore",      1),
  @("MirrorFoldersList",                      ""),
  @("OfflineSupport",                         0),
  @("PSAlwaysCache",                          0),
  @("PSAlwaysCacheSize",                      0),
  @("PSEnabled",                              0),
  @("PSMidSessionWriteBack",                  0),
  @("PSPendingLockTimeout",                   1),
  @("PSUserGroupsList",                       ""),
  @("PathToLogFile",                          ""),
  @("PathToUserStore",                        "Windows"),
  @("ProcessAdmins",                          0),
  @("ProcessCookieFiles",                     0),
  @("ProcessedGroups",                        ""),
  @("ProfileDeleteDelay",                     ""),
  @("ServiceActive",                          0),
  @("SyncDirList",                            ""),
  @("SyncExclusionListDir",                   ""),
  @("SyncExclusionListFiles",                 ""),
  @("SyncFileList",                           ""),
  @("TemplateProfileIsMandatory",             ""),
  @("TemplateProfileOverridesLocalProfile",   ""),
  @("TemplateProfileOverridesRoamingProfile", ""),
  @("TemplateProfilePath",                    ""),
  @("USNDBPath",                              "")    # installation directory
)

#############################################################
# functions and datastructures for reporting on policy
# lists, such as inclusion and exclusion
#
$policyListDb = @()

function Add-PolicyListRecord($PolicyName,$ProfileType,$DifferenceType,$Value,$Advice="",$Notes="",$Origin="") {
  $offset = $script:policyListDb.Length
  $policyObj = New-Object Object |
      Add-Member NoteProperty Name                  $PolicyName              -PassThru |
      Add-Member NoteProperty ProfileType           $ProfileType             -PassThru |
      Add-Member NoteProperty MatchesBestPractice   $DifferenceType          -PassThru |
      Add-Member NoteProperty Value                 $Value                   -PassThru |
      Add-Member NoteProperty Advice                $Advice                  -PassThru |
      Add-Member NoteProperty Notes                 $Notes                   -PassThru |
      Add-Member NoteProperty Origin                $Origin                  -PassThru 
  $script:policyListDb = $script:policyListDb + $policyObj
}


#############################################################
# functions and datastructures for reporting on policy
#
$policyDbIndex = @{}
$policyDb = @()

function Add-PolicyRecord($PolicyName,$Default) {
  $offset = $script:policyDb.Length
  $policyObj = New-Object Object |
      Add-Member NoteProperty Name             $PolicyName              -PassThru |
      Add-Member NoteProperty DefaultValue     $Default                 -PassThru |
      Add-Member NoteProperty PreferredValue   ""                       -PassThru |
      Add-Member NoteProperty EffectiveValue   ""                       -PassThru |
      Add-Member NoteProperty Advice           ""                       -PassThru |
      Add-Member NoteProperty Notes            ""                       -PassThru |
      Add-Member NoteProperty Origin           "Not Checked"            -PassThru 
  $script:policyDb = $script:policyDb + $policyObj
  $policyDbIndex[$PolicyName] = $offset
}

for ($ix = 0; $ix -lt $policyList.Length; $ix++) {
  $pn = $policyList[$ix][0]
  $dv = $policyList[$ix][1]
  Add-PolicyRecord -PolicyName $pn -Default $dv
}

function Replace-PolicyRecordProperty ([string]$PolicyName, [string]$PropertyName, $NewValue) {
  $offset = $policyDbIndex[$PolicyName]
  if ($offset -ne $null) {
    $obj = $script:policyDb[$offset]
    if (($null -ne $NewValue) -and ($NewValue.GetType().BaseType.Name -eq "Array")) {
      $sub = $NewValue -Join "`n"
    } else {
      $sub = $NewValue
    }
    $newobj = $obj | Add-Member NoteProperty $PropertyName -Value $sub -Force -PassThru
    # use Select-Object to force the same order for fields
    $newobj2 = $newobj | Select-Object -Property Name,DefaultValue,PreferredValue,EffectiveValue,Advice,Notes,Origin 
    $script:policyDb[$offset] = $newobj2
  }
}

function Get-PolicyRecordProperty ([string]$PolicyName, [string]$PropertyName) {
  $offset = $policyDbIndex[$PolicyName]
  if ($offset -ne $null) {
    $obj = $script:policyDb[$offset]
    $obj.$PropertyName
  }
}

#
# filter which captures recommendations in the "errStrings" array, but also passes them on
#
filter CaptureRecommendations ([string]$PolicyName, $Reason=$null) {
  #
  # print the recommendation, but also capture it to the $errStrings array
  #
  begin{
  }
  process {
    $errInfo = $_
    write-host @warnColours $errInfo
    Replace-PolicyRecordProperty -PolicyName $PolicyName -PropertyName Advice -NewValue $errInfo
    $script:errStrings += $errInfo
    $script:errStrings = @($script:errStrings)  # force it to be an array
    if ($Reason -ne $null) {
      $script:errStrings += "    notes: $Reason"
      Replace-PolicyRecordProperty -PolicyName $PolicyName -PropertyName Notes -NewValue $Reason
      # $script:errStrings = @($script:errStrings)  # force it to be an array
    }
  }
  end{
  }
}

#
# Start point is the OS version
#
$osinfo = Get-WmiObject Win32_OperatingSystem          # this is useful info - hang on to it
$versionMajor = $script:osinfo.Version -replace "\..*",""
$lastBoot     = $script:osinfo.ConvertToDateTime($script:osinfo.LastBootUpTime)
$installTime  = $script:osinfo.ConvertToDateTime($script:osinfo.InstallDate)
$IsWorkstation = $script:osinfo.ProductType -eq 1
$osMajorVer    = ([string]$script:osinfo.Version)[0]
$osMinorVer    = ([string]$script:osinfo.Version)[2]

#
# discover where UPM is installed
#
$UPMBase = "c:\Program Files\Citrix\User Profile Manager"     # default location
$UPMPath = "HKLM:\\SYSTEM\CurrentControlSet\services\ctxProfile"
$c = Get-ItemProperty $UPMPath -name "ImagePath" -ea SilentlyContinue
$UPMExe = [string]$c.ImagePath
if ($UPMExe.Length -eq 0) {
  "*** ERROR - UPM is not installed. " | CaptureRecommendations -PolicyName "" -Reason "Other recommendations should be treated with extreme caution"
} else {
  $u = $UPMExe.Substring(1,$UPMExe.Length - 2)   # get rid of quotes
  $fo = dir $u
  $UPMBase = [string]($fo.DirectoryName)
  "UPM Installed in folder '" + $UPMBase + "'"
}

#
# Step 1: detect the UPM version
#
$upmname = "unset"
$upmpublisher = "unset"
$upmversion = "unset"
$upmmajor = 0
$upmminor = 0
Get-ChildItem -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -recurse | foreach {
  if ($_.ValueCount -gt 0 ) {
    if ( $_.GetValue("DisplayName") -match "Citrix" ) {
      if ( $_.GetValue("DisplayName") -match "Profile" ) {
        $upmname = $_.GetValue("DisplayName")
        $upmpublisher = $_.GetValue("Publisher")
        $upmversion = $_.GetValue("DisplayVersion")
        $upmmajor = $_.GetValue("VersionMajor")
        $upmminor = $_.GetValue("VersionMinor")
      }
    }
  }
}

#
# look for INI files
#   For UPM version 5, there is only one INI file
#   For UPM versions 2-4:
#   On XP and 2k3, the path is language-dependent, so we look for the local language first, then fall back to English
#   On all other OS we are language-independent
#
if ($iniFilePath -eq "") {
  if ($upmmajor -lt 5) {
    if ($versionMajor -lt 6) {
      # look for language-specific version first
      $c = Get-Culture
      $lang = $c.TwoLetterISOLanguageName
      $iniFile = $UPMBase + "\UPMPolicyDefaults_V1Profile_" + "$lang" + ".ini"
      $targetExists = Test-Path -LiteralPath $iniFile -ea SilentlyContinue
      if ($targetExists -eq $false) {
        $iniFile = $UPMBase + "\UPMPolicyDefaults_V1Profile_en.ini"
      }
    } else {
      $iniFile = $UPMBase + "\UPMPolicyDefaults_V2Profile_all.ini"
    }
  } else {
    $iniFile = $UPMBase + "\UPMPolicyDefaults_all.ini"
  }
} else {
  $iniFile = $iniFilePath
}

#
# If we have an INI file we read it into a variable, else
# we set up an empty variable
#
if (Test-Path -LiteralPath $iniFile) {
  $iniContent = Get-Content $iniFile | Select-String -Pattern "^;" -NotMatch
  "Found INI file at '" + $iniFile + "' - contents after stripping comments:"
  $iniContent
} else {
  $iniContent = @("")
}

############################################################################
#
# Next block is the function definitions used throughout the script
#
############################################################################

#
# get the user object for an AD user
# see http://stackoverflow.com/questions/2184692/updating-active-directory-user-properties-in-active-directory-using-powershell
#
function Get-ADUser( [string]$samid=$env:username){
     $searcher=New-Object DirectoryServices.DirectorySearcher
     $searcher.Filter="(&(objectcategory=person)(objectclass=user)(sAMAccountname=$samid))"
     $user=$searcher.FindOne()
      if ($user -ne $null ){
          $user.getdirectoryentry()
     }
}

function Get-ADUserVariable ([string]$variableName, [string]$defaultString) {
  $user = Get-ADUser
  $answer = $user.psbase.properties[$variableName]
  if ($null -ne $answer) {
    if ($answer -ne "") { return $answer }
  }
  $defaultString
}

function Get-EnvVariable    ([string]$variableName, [string]$defaultString) {
  #
  # only supports
  dir env: | foreach { if ($_.Name -eq $variableName) { $answer = $_.Value } }
  if ($null -ne $answer) {
    return $answer
  }
  $defaultString
}

function Get-OsShortName () {
  if ($osMajorVer -eq "5") {
    if ($IsWorkstation) {
      return "WinXP"
    } else {
      return "Win2003"
    }
  } else {
    if ($IsWorkstation) {
      switch ($osMinorVer) {
      0 { return "WinVista" }
      1 { return "Win7" }
      default { return "Win8" }
      }
    } else {
      switch ($osMinorVer) {
      0 { return "Win2008" }
      1 { return "Win2008" }    # R2 - but the short string is the same
      default { return "Win2012" }
      }
    }
  }
}

function Get-IECookieFolder () {
  if ($osMajorVer -eq "5") {
    return 'Cookies'
  } else {
    return 'AppData\Roaming\Microsoft\Windows\Cookies'
  }
}

function Get-CitrixVariable ([string]$variableName, [string]$defaultString) {
  switch ($variableName) {
  "CTX_PROFILEVER" { $osMajorVer = ([string]$script:osinfo.Version)[0] ; if ($osMajorVer -eq "5") { return "v1" } ; return "v2" }
  "CTX_OSBITNESS" { if ($script:osinfo.OSArchitecture -eq "64-bit") { return "x64" } ; return "x86" }
  "CTX_OSNAME" { return Get-OsShortName }
  }
  $defaultString
}

function Get-SubstituteString ([string]$delimitedString) {
  $delimiter = $delimitedString[0]
  $strippedString = $delimitedString.Substring(1, $delimitedString.Length - 2)
  $answer = $delimitedString       # default is to not change the string, if we can't find a match
  switch ($delimiter) {
  '#' { $answer = Get-ADUserVariable -variableName $strippedString -defaultString $delimitedString }
  '%' { $answer = Get-EnvVariable    -variableName $strippedString -defaultString $delimitedString }
  '!' { $answer = Get-CitrixVariable -variableName $strippedString -defaultString $delimitedString }
  }
  $answer
}

function Get-ProcessedPath ([string]$path) {
  $specials = '#!%'
  $startOfSearch = 0
  while ($true) {
    $firstDelimiterOffset = $path.IndexOfAny($specials, $startOfSearch)
    $delimiterChar = $path[$firstDelimiterOffset]
    # write-host "delimiter " $delimiterChar " found at offset " $firstDelimiterOffset
    if ($firstDelimiterOffset -lt 0) { break }
    $secondDelimiterOffset = $path.IndexOf($delimiterChar, $firstDelimiterOffset + 1)
    # write-host "matching delimiter " $path[$secondDelimiterOffset] " found at offset " $secondDelimiterOffset
    if ($secondDelimiterOffset -lt 0) { break }
    $parameterStringLength = $secondDelimiterOffset - $firstDelimiterOffset
    $parameterStringLength += 1
    $seg1 = $path.substring(0, $firstDelimiterOffset)
    $seg2 = $path.substring($firstDelimiterOffset, $parameterStringLength)
    $seg3 = $path.substring($firstDelimiterOffset + $parameterStringLength, $path.Length - ($firstDelimiterOffset + $parameterStringLength))
    # write-host "Keep start " $seg1
    # write-host "Substitute " $seg2
    # write-host "Keep end   " $seg3
    $seg2 = Get-SubstituteString -delimitedString $seg2
    $path = $seg1 + $seg2
    $startOfSearch = $path.Length
    $path = $path + $seg3
  }
  $path
}

#
# returns an array of lines from the section identified
#
function Get-IniList ( $textCollection, $sectionName ) {
  $copying = $false
  for ($ix = 0; $ix -lt $textCollection.Length; $ix++ ) {
    $line = $textCollection[$ix]
    # write-host @hilight1 "inistring   " $line
    if ($line -match "\[") {
      $copying = $false
      $matchString = "[" + $sectionName + "]"
      if ( [string]$line -eq [string]$matchString ) {
        $copying = $true
        # write-host $hilight2 "start copy   " $line
      }
    } else {
      if ($copying) {
        if ( ([string]$line).Length -gt 0 ) {
          # write-host $hilight2 "inistring   " $line
          ([string]$line) -replace "=\s*$",""
        }
      }
    }
  }
}

#
# Harmonise reporting of policies
#

$strPoliciesDetected = @{}
$strHDXPoliciesDetected = @{}
$strIniLinesDetected = @{}
$strDefaultsDetected = @{}

function ReportPolicyDetected($policyName, $policyValue, $policySource="Policy") {
  $reportLine = "$policySource '$policyName' detected in registry - INI file was not checked"
  switch ($policySource) {
  "Policy" { $strPoliciesDetected[$policyName] = $policyValue }
  "HDXPolicy" { $strHDXPoliciesDetected[$policyName] = $policyValue }
  }
}

function ReportIniLineDetected($policyName, $policyValue) {
  $reportLine = "Policy '" + $policyName + "' detected in INI file after failing to find in registry"
  $strIniLinesDetected[$policyName] = $policyValue
}

function ReportDefaultDetected($policyName, $policyValue) {
  $reportLine = "Policy '" + $policyName + "' using default as no registry or INI file values detected"
  $strDefaultsDetected[$policyName] = $policyValue
}

#
# Functions for reading settings from the registry and from the INI file
#
function Get-IniSetting ( $textCollection, $sectionName, $settingName ) {
  $list = Get-IniList -textCollection $textCollection -sectionName $sectionName
  $list = @($list)
  for ($ix = 0; $ix -lt $list.Length; $ix++ ) {
    $keyPlusVal = $list[$ix] -split '=',2
    $key = $keyPlusVal[0]
    if ($keyPlusVal.Length -eq 2) {
      $val = $keyPlusVal[1]
    } else {
      $val = ""
    }
    if ($key -like $settingName ) {
      if ($val -match '^".*"$' ) {
        $val = ([string]$val).Substring(1,([string]$val).Length - 2)
      }
      return $val
    }
  }
}

$policyOriginTable = @(
  @( "Policy",    "HKLM:\\SOFTWARE\Policies\Citrix\UserProfileManager\" ),
  @( "HDXPolicy", "HKLM:\\SOFTWARE\Policies\Citrix\UserProfileManagerHDX\" )
)

function GetPolicyGeneralSetting($regName="" , $policyName ) {
  $retVal = "unset"
  #
  # look in registry first
  #
  for ($policySourceIndex = 0; $policySourceIndex -lt $policyOriginTable.Length; $policySourceIndex++) {
    $policyOrigin = ($policyOriginTable[$policySourceIndex])[0]
    $registryBase = ($policyOriginTable[$policySourceIndex])[1]
    $regPath = $registryBase + $regName
    Write-Host @infoColours "GetPolicyGeneralSetting: Check " $regPath ":" $policyName
    Get-ItemProperty $regPath -name $policyName -ErrorAction SilentlyContinue | foreach {
      $retVal = $_.$policyName
    }
    if ($retval -ne "unset" ) {
      ReportPolicyDetected -policyName $policyName -policyValue @($retval) -policySource $policyOrigin
      Replace-PolicyRecordProperty -PolicyName $policyName -PropertyName EffectiveValue -NewValue $retval
      Replace-PolicyRecordProperty -PolicyName $policyName -PropertyName Origin         -NewValue $policyOrigin
      return $retVal
    }
  }

  Write-Host @infoColours "GetPolicyGeneralSetting: Check INI file section General Settings, setting name:" $policyName
  $retval = Get-IniSetting -textCollection $iniContent -sectionName "General Settings" -settingName $policyName
  if ($retval -ne $null) {
    ReportIniLineDetected -policyName $policyName -policyValue @($retval)
    Replace-PolicyRecordProperty -PolicyName $policyName -PropertyName EffectiveValue -NewValue $retval
    Replace-PolicyRecordProperty -PolicyName $policyName -PropertyName Origin         -NewValue "IniFile"
  } else {
    ReportDefaultDetected -policyName $policyName -policyValue @($retval)
    Replace-PolicyRecordProperty -PolicyName $policyName -PropertyName EffectiveValue -NewValue $retval
    Replace-PolicyRecordProperty -PolicyName $policyName -PropertyName Origin         -NewValue "Default"
  }
  $retval
}

function GetPolicySingleSetting($regName , $valName, $defaultSetting, $autoSetting ) {
  $retVal = "unset"
  #
  # look in registry first
  #
  for ($policySourceIndex = 0; $policySourceIndex -lt $policyOriginTable.Length; $policySourceIndex++) {
    $policyOrigin = ($policyOriginTable[$policySourceIndex])[0]
    $registryBase = ($policyOriginTable[$policySourceIndex])[1]
    $regPath = $registryBase + $regName
    Write-Host @infoColours "GetPolicySingleSetting: Check " $regPath ":" $valName
    Get-ItemProperty $regPath -name $valName -ErrorAction SilentlyContinue | foreach {
      $retVal = $_.$valName
    }
    if ($retval -ne "unset" ) {
      ReportPolicyDetected -policyName $valName -policyValue @($retval) -policySource $policyOrigin
      $policyObj = New-Object Object |
        Add-Member NoteProperty Value            $retVal                  -PassThru |
        Add-Member NoteProperty Origin           $policyOrigin            -PassThru 
      Replace-PolicyRecordProperty -PolicyName $valName -PropertyName EffectiveValue -NewValue $policyObj.Value
      Replace-PolicyRecordProperty -PolicyName $valName -PropertyName Origin         -NewValue $policyObj.Origin
      return $policyObj
    }
  }
  #
  # failed to find in either registry location
  #
  Write-Host @infoColours "GetPolicySingleSetting: Check INI file section General Settings, setting name:" $valName
  $retVal = Get-IniSetting -textCollection $iniContent -sectionName "General Settings" -settingName $valName
  if ($retVal -ne $null) {
    ReportIniLineDetected -policyName $valName -policyValue @($retval)
    $policyObj = New-Object Object |
      Add-Member NoteProperty Value            $retVal                  -PassThru |
      Add-Member NoteProperty Origin           "IniFile"                -PassThru 
    Replace-PolicyRecordProperty -PolicyName $valName -PropertyName EffectiveValue -NewValue $policyObj.Value
    Replace-PolicyRecordProperty -PolicyName $valName -PropertyName Origin         -NewValue $policyObj.Origin
    return $policyObj
  } else {
    ReportDefaultDetected -policyName $valName -policyValue @($retval)
    if ($autoSetting -eq $null) {
      $policyObj = New-Object Object |
        Add-Member NoteProperty Value            $defaultSetting          -PassThru |
        Add-Member NoteProperty Origin           "Default"                -PassThru 
    } else {
      # optionally report this as an autosetting, rather than a default
      $policyObj = New-Object Object |
        Add-Member NoteProperty Value            $autoSetting             -PassThru |
        Add-Member NoteProperty Origin           "Default"                -PassThru 
    }
    Replace-PolicyRecordProperty -PolicyName $valName -PropertyName EffectiveValue -NewValue $policyObj.Value
    Replace-PolicyRecordProperty -PolicyName $valName -PropertyName Origin         -NewValue $policyObj.Origin
    return $policyObj
  }
}

function Get-ListItemCountRaw ($list) {
  if ($list -is [array]) {
    [string]($list.Length)
  } elseif ($list -is [string]) {
    1
  } else {
    0
  }
}

function Get-ListItemCount ($list) {
  $count = Get-ListItemCountRaw -list $list
  "List contains " + $count + " item(s)"
}

function GetPolicyListSettingRaw($regName ) {
  $retVal = "unset"
  #
  # look in registry first
  #
  for ($policySourceIndex = 0; $policySourceIndex -lt $policyOriginTable.Length; $policySourceIndex++) {
    $policyOrigin = ($policyOriginTable[$policySourceIndex])[0]
    $registryBase = ($policyOriginTable[$policySourceIndex])[1]
    $regPath = $registryBase + $regName
    Write-Host @infoColours "GetPolicyListSettingRaw: Check" $regPath
    switch ($policyOrigin) {
      "Policy" {
        $keyObj = Get-ChildItem $regPath -ErrorAction SilentlyContinue 
        if ($keyObj.ValueCount -gt 0) {
          $retVal = for ($ix = 0; $ix -lt $keyObj.ValueCount; $ix++ ) {
            $keyObj.Property[$ix]
          }
          ReportPolicyDetected -policyName $regName  -policyValue @($retVal)
          Replace-PolicyRecordProperty -PolicyName $regName -PropertyName EffectiveValue -NewValue $retval
          Replace-PolicyRecordProperty -PolicyName $regName -PropertyName Origin         -NewValue $policyOrigin
          return $retVal
        }
      }
      "HDXPolicy" {
        #
        # This will be a registry multi-string, with no "List" subkey
        #
        $keyArr = Get-ChildItem $registryBase -ErrorAction SilentlyContinue
        $keyArr = @($keyArr)
        $keyObj = for ($kix = 0 ; $kix -lt $keyArr.Length; $kix++ ) {
          $kname = $keyArr[$kix].Name -replace ".*\\",""
          if ($kname -eq $regName) {
            $keyArr[$kix]
          }
        }
        if ($keyObj -ne $null) {
          $retVal = for ($ix = 0; $ix -lt $keyObj.ValueCount; $ix++ ) {
            $keyObj.GetValue($regName)
          }
          ReportPolicyDetected -policyName $regName  -policyValue @($retVal) -policySource $policyOrigin
          Replace-PolicyRecordProperty -PolicyName $regName -PropertyName EffectiveValue -NewValue $retval
          Replace-PolicyRecordProperty -PolicyName $regName -PropertyName Origin         -NewValue $policyOrigin
          return $retVal
        }
      }
    }
  }

  #
  # look in INI file
  # return $retVal
  Write-Host @infoColours "GetPolicyListSettingRaw: Check INI file section" $regName
  $retval = Get-IniList -textCollection $iniContent -sectionName $regName
  if ($retval -ne $null) {
    ReportIniLineDetected -policyName $regName  -policyValue @($retVal)
    Replace-PolicyRecordProperty -PolicyName $regName -PropertyName EffectiveValue -NewValue $retval
    Replace-PolicyRecordProperty -PolicyName $regName -PropertyName Origin         -NewValue "IniFile"
  } else {
    ReportDefaultDetected -policyName $regName  -policyValue @($retVal)
    Replace-PolicyRecordProperty -PolicyName $regName -PropertyName EffectiveValue -NewValue $retval
    Replace-PolicyRecordProperty -PolicyName $regName -PropertyName Origin         -NewValue "Default"
  }
  $retval
}

function GetPolicyListSetting($regName ) {
  $resp = GetPolicyListSettingRaw -regName $regName
  $rv = @($resp)  # force the response to be an array
  $rv
}

function ValidateList($list, $policyName) {
  Get-ListItemCount -list $list

  $sortPol = $list | sort
  $uniqPol = $list | sort -Unique
  if ($sortPol.Length -ne $uniqPol.Length) {
    "*** Warning: Some lines are duplicated in Policy:" + $policyName | CaptureRecommendations -PolicyName $policyName
    Compare-Object -ReferenceObject $uniqPol -DifferenceObject $sortPol | foreach { $_.InputObject }
  } else {
    "No duplicates found in Policy:" + $policyName
  }
  $list | foreach {
    $item = $_
    switch -wildcard ($item) {
    "%USERPROFILE%*" { "*** Warning: do not specify %USERPROFILE% in policy " + $policyName + " line '" + $item + "'" | CaptureRecommendations -PolicyName $policyName -Reason "UPM automatically assumes paths relative to %USERPROFILE%" }
    }
    switch -regex ($item) {
    ".*[\s=]$" { "*** Warning: trailing whitespace or = in policy " + $policyName + " line '" + $item + "'" | CaptureRecommendations -PolicyName $policyName -Reason "trailing whitespace can lead to unpredictable and hard-to-diagnose behaviour in UPM" }
    }
  }
}

#
# This routine returns an object indicating the effective value
# and whether the value was explicitly set or defaulted
#
function GetEffectivePolicyFlag ($policyName, $defaultSetting, $autoSetting, [switch]$AsNumber) {
  #
  # Let's check a policy - $policyName - and calculate the effective value if defaulted
  #
  $polName = $policyName
  $pol = GetPolicySingleSetting -valName $polName -defaultSetting $defaultSetting -autoSetting $autoSetting
  if ($AsNumber) {
    $val = $pol.Value
  } else {
    if ($pol.Value -eq 0) {
      $val = "Disabled"
    } else {
      $val = "Enabled"
    }
  }
  $origin = $pol.Origin
  write-host "$polName is $val from $origin"
  $pol
}

function AssertFlagNotSet ($policyName, $Reason=$null) {
  $temp = GetEffectivePolicyFlag -policyName $policyName -defaultSetting 0
  $origin = $temp.Origin
  if ($origin -ne "Default") {
    $val = $temp.Value
    "*** policy $policyName is set to $val in $origin" | CaptureRecommendations -PolicyName $policyName -Reason $Reason
  }
}

function PreferPolicyFlag ($policyName, $defaultSetting, $preferredSetting, $autoSetting, $Reason=$null, [switch]$ShowAsNumber) {
  #
  # Let's check a policy - $policyName - and calculate the effective value if defaulted
  #
  if (($upmmajor -eq 5) -and ($autoSetting -ne $null)) {
    Replace-PolicyRecordProperty -PolicyName $policyName -PropertyName DefaultValue -NewValue $autoSetting
    if ($autosetting -ne $defaultSetting) {
      write-host @infoColours "*** overwriting default for policy $policyName : default $defaultSetting changed to autoSetting $autoSetting"
      $defaultSetting = $autoSetting
    }
  } else {
    Replace-PolicyRecordProperty -PolicyName $policyName -PropertyName DefaultValue -NewValue $defaultSetting
  }
  Replace-PolicyRecordProperty -PolicyName $policyName -PropertyName PreferredValue -NewValue $preferredSetting
  $defaultString = "Enabled"
  if ($defaultSetting -eq 0) {
    $defaultString = "Disabled"
  }
  $polName = $policyName
  $pol = GetPolicyGeneralSetting -policyName $polName
  $polName + " = " + $pol
  if ($null -eq $pol) {
    if ($ShowAsNumber) {
      $polName + " is unset and will default to " + $defaultSetting ; $actualSetting = $defaultSetting
    } else {
      $polName + " is unset and will default to " + $defaultString ; $actualSetting = $defaultSetting
    }
  } else {
    switch ( $pol ) {
      0 { $polName + " is Disabled" ; $actualSetting = 0 }
      1 { $polName + " is Enabled" ; $actualSetting = 1 }
    }
  }
  Replace-PolicyRecordProperty -PolicyName $policyName -PropertyName EffectiveValue -NewValue $actualSetting
  #
  # now report on the difference between what we've got and what we recommend
  #
  if ($ShowAsNumber) {
    $preferredString = [string]$preferredSetting
    $actualString = [string]$actualSetting
  } else {
    $preferredString = "Enabled"
    if ($preferredSetting -eq 0) {
      $preferredString = "Disabled"
    }
    $actualString = "Enabled"
    if ($actualSetting -eq 0) {
      $actualString = "Disabled"
    }
  }
  if ($actualSetting -ne $preferredSetting) {
    "*** Warning: " + $polName + " actual/effective setting (" + $actualString + ") does not match preferred setting (" + $preferredString + ")" | CaptureRecommendations -PolicyName $policyName -Reason $Reason
  } else {
    $polName + ": actual/effective setting (" + $actualString + ") matches preferred setting (" + $preferredString + ")" 
  }
}

#
# Get-VolumeMountPoints : returns the path names of all mounted volumes that 
#                         are mounted on a drive letter or a sub-folder
#
function Get-VolumeMountPoints() {
  $comp = Get-WmiObject Win32_Volume
  $comp | foreach {
    $mp = $_.Name
    switch -regex ($mp) {
    "^[a-z]:" { [string]$mp }
    }
  } | sort
}

#
# Get-MountPointCount : returns the number of matches of the given path 
#                       against the list of mount points.  We use this to detect
#                       detect when (say) c:\Users is a separate volume
#                       (This breaks the use of Change Journalling)
#
function Get-MountPointCount ($path) {
  $mountpoints = Get-VolumeMountPoints
  $mpc = 0
  for ($ix = 0; $ix -lt $mountpoints.Length; $ix++) {
    $p = [string]($mountpoints[$ix])
    [string]$path |select-string -simplematch $p | foreach {
      $mpc++
    }
  }
  $mpc
}

function ConvenientBytesString($bytes) {
  if ($bytes -gt 1GB) {
    $gb = [math]::Round($bytes / 1GB,1)
    return [string]($gb) + " GB"
  }
  if ($bytes -gt 1MB) {
    $mb = [math]::Round($bytes / 1MB,1)
    return [string]($mb) + " MB"
  }
  if ($bytes -gt 1KB) {
    $kb = [math]::Round($bytes / 1KB,1)
    return [string]($kb) + " KB"
  }
  return [string]($bytes) + " bytes"
}

$envLogArray = @()

function AddEnvironmentLine ([string]$section, [string]$item, $value) {
  $policyObj = New-Object Object |
      Add-Member NoteProperty Section          $section          -PassThru |
      Add-Member NoteProperty Item             $item             -PassThru |
      Add-Member NoteProperty Value            $value            -PassThru 
  $script:envLogArray = $script:envLogArray + $policyObj
}

function ReportEnvironment ([string]$section, [string]$item, $value) {
  AddEnvironmentLine $section $item $value
  $padSection = $section.PadRight(10)
  $padItem = $item.PadRight(45)
  "$padSection : $padItem : $value"
}

#
# This is all set up at the top of the script
#
ReportEnvironment "UpmCheck" "Version"   $upmCheckVersion
ReportEnvironment "UpmCheck" "Copyright" $copyright
ReportEnvironment "UpmCheck" "RunDate"   $scriptRunDate.DateTime

############################################################################
#
# ... end of the function definitions
#
############################################################################

"========================================="
"= Gathering Environment Information     ="
"========================================="

#
# Take an inventory of Citrix products
#
New-PSDrive -Name Uninstall -PSProvider Registry -Root HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -ea SilentlyContinue >$null
New-PSDrive -Name Uninstall32 -PSProvider Registry -Root HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -ea SilentlyContinue >$null
$citrixProds = Get-ChildItem -Path @("Uninstall:","Uninstall32:") -ea SilentlyContinue | ForEach-Object -Process {
  $q = $_
  $dn = $q.GetValue("DisplayName") 
  # write-host $dn
  $dp = $q.GetValue("Publisher") 
  $dv = $q.GetValue("DisplayVersion") 
  $cs = New-Object Object |
    Add-Member NoteProperty Product      $dn           -PassThru |
    Add-Member NoteProperty Publisher    $dp           -PassThru |
    Add-Member NoteProperty Version      $dv           -PassThru
  $cs
} | where-object { (($_.Product -match "Citrix") -or ($_.Publisher -match "Citrix") -or ($_.Product -match "ShareFile") -or ($_.Publisher -match "ShareFile")) }

$xenDesktopPresent = $false
$xenAppPresent = $false
$shareFilePresent = $false ; $wrongShareFilePresent = $false
foreach ($prod in $citrixProds) {
  ReportEnvironment "CtxProduct" $prod.Product $prod.Version
  switch -wildcard ($prod.Product) {
  "*MetaFrame*" { $xenAppPresent = $true; $xenAppVersion = $prod.Version }
  "*Presentation Server*" { $xenAppPresent = $true; $xenAppVersion = $prod.Version }
  "*XenApp*" { $xenAppPresent = $true; $xenAppVersion = $prod.Version }
  "*Virtual Desktop Agent*" { $xenDesktopPresent = $true; $xenDesktopVersion = $prod.Version }
  "Citrix ShareFile Sync" { $shareFilePresent = $true; $shareFileVersion = $prod.Version }
  "ShareFile Desktop Sync" { $wrongShareFilePresent = $true; $wrongShareFileProduct = $prod.Product; $wrongShareFileVersion = $prod.Version }
  }
}

ReportEnvironment "UPM" "Display Name"    $upmname
ReportEnvironment "UPM" "Publisher"       $upmpublisher
ReportEnvironment "UPM" "DisplayVersion"  $upmversion
ReportEnvironment "UPM" "VersionMajor"    $upmmajor
ReportEnvironment "UPM" "VersionMinor"    $upmminor

#
# Step 2: detect the environment
#
$currentUser = "unset"
$currentDomain = "unset"
$currentLocalProfile = "unset"
dir env: | foreach {
  $x = $_
  if ($x.Key -eq "USERNAME") { $currentUser = $x.Value }
  if ($x.Key -eq "USERDOMAIN") { $currentDomain = $x.Value }
  if ($x.Key -eq "USERPROFILE") { $currentLocalProfile = $x.Value }
}

"Checking Windows Event log for Citrix Profile Management, EventCode 10 to verify User and determine Path to User Store"
"This may fail if current user does not have permission to access Windows Event Log, or the Event log has wrapped"

$fullpathtouserstore = "unset"
$Logs = Get-WmiObject -query "SELECT * FROM Win32_NTLogEvent WHERE (logfile='Application') AND (SourceName='Citrix Profile Management') AND (EventCode='10')"
$Logs | sort-object -Property TimeGenerated | foreach {
  $logonEventTime = $_.ConvertToDateTime($_.TimeGenerated )
  $logonEventUser = $_.InsertionStrings[0]
  $logonEventPtus = $_.InsertionStrings[1]
  if ($logonEventUser -eq $currentUser) {
    # but remember current user
    $fullpathtouserstore = $logonEventPtus
    $isLoggedOnUser = $true
  } else {
    $isLoggedOnUser = $false
  }
  #
  # might want to save this info here - for now just output it
  "$logonEventTime : UPM User $logonEventUser logged-on : Current user $isLoggedOnUser : Path to user store $logonEventPtus "
}

#
# see http://blogs.technet.com/b/heyscriptingguy/archive/2010/10/11/use-wmi-and-powershell-to-get-a-user-s-sid.aspx
#
$userSID = ([wmi]"win32_userAccount.Domain='$env:userdomain',Name='$env:username'").SID
ReportEnvironment "ADuser" "User"               $currentUser
ReportEnvironment "ADuser" "Domain"             $currentDomain
ReportEnvironment "ADuser" "SID"                $userSID
ReportEnvironment "ADuser" "Path to User Store" $fullpathtouserstore
ReportEnvironment "ADuser" "Local Profile"      $currentLocalProfile

#
# work out if this is the user's first UPM logon - there won't be a UPMSettings.ini file at the path to user store
#
$userProfileRoot = "unset"
$firstLogon = $true
if ($fullpathtouserstore -ne "unset") {
  if (Test-Path $fullpathtouserstore) {
    # Get-ChildItem $fullpathtouserstore
    $userProfileRoot = $fullpathtouserstore -replace "\\UPM_Profile",""
    $upmSettingsPath = $userProfileRoot + "\UPMSettings.ini"
    if (Test-Path $upmSettingsPath) {
      "UPMSettings.ini file found in path to user store - profile has been created by a previous logon"
      $firstLogon = $false
    }
  }
}

#
# See http://www.powershellmagazine.com/2012/10/31/pstip-new-powershell-drive-psdrive/
#
# Set up a PSDrive for HKEY_USERS (which doesn't have a drive by default)
#

$hasHku = $false
Get-PSDrive -PSProvider Registry | foreach {
  if ($_.Root -eq "HKEY_USERS") {
    $hasHku = $true
  }
}

#
# create the drive
#
if (-not $hasHku) {
  New-PSDrive -Name HKU  -PSProvider Registry –Root HKEY_USERS
}

"-----------------------------------------"
"- Check for Redirected Folders          -"
"-----------------------------------------"

function AdviseAgainstRedirecting ($isLocalFolder, $shortName, $longName, $location) {
  if (-not $isLocalFolder) { "*** consider not redirecting local folder $shortName ($location) to a network share"  | CaptureRecommendations -PolicyName "" -Reason "Citrix recommends that $longName should be kept inside the profile" }
}

function ConsiderRedirecting ($isLocalFolder, $shortName, $longName, $location, $explanation) {
  if ($null -eq $explanation) { $explanation = "Citrix recommends that $longName should be redirected" }
  if ($isLocalFolder) { "*** consider redirecting local folder $shortName ($location) to a network share"  | CaptureRecommendations -PolicyName "" -Reason $explanation }
}

$profileFolderHash = @{}   # this gives us a list of where all the profile folders are

Get-ChildItem "HKU:\$userSID\Software\Microsoft\Windows\CurrentVersion\Explorer" | foreach {
  $k = $_
  if ($k.PSChildName -eq "User Shell Folders") {
    foreach ($folderName in $k.Property) {
      $folderTarget = $k.GetValue($folderName)
      if ($folderName -eq "{374DE290-123F-4565-9164-39C4925E467B}") { $folderName = "Downloads" }
      ReportEnvironment "Folders" $folderName $folderTarget
      $profileFolderHash[$folderName] = $folderTarget
      $isLocalFolder = $false
      if ($folderTarget.StartsWith($currentLocalProfile)) {
        $isLocalFolder = $true
      }
      switch ($folderName) {
        "AppData"              {  }
        "Cache"                {  }
        "Cookies"              { AdviseAgainstRedirecting $isLocalFolder $folderName "Cookies" $folderTarget }
        "Desktop"              {  }
        "Favorites"            {  }
        "History"              {  }
        "Local AppData"        {  }
        "My Music"             { ConsiderRedirecting $isLocalFolder $folderName "My Music" $folderTarget }
        "My Pictures"          { ConsiderRedirecting $isLocalFolder $folderName "My Pictures" $folderTarget }
        "My Video"             { ConsiderRedirecting $isLocalFolder $folderName "My Video" $folderTarget }
        "NetHood"              {  }
        "Personal"             { ConsiderRedirecting $isLocalFolder $folderName "My Documents" $folderTarget }
        "Programs"             {  }
        "Recent"               {  }
        "SendTo"               {  }
        "Startup"              {  }
        "Start Menu"           {  }
        "Templates"            {  }
        "Downloads"            { if ($xenDesktopPresent -or $xenAppPresent) { ConsiderRedirecting $isLocalFolder $folderName "Downloads" $folderTarget "Citrix recommends that Downloads should be redirected when XenDesktop or XenApp Published Desktops are used" } }
        "PrintHood"            {  }
      }
    }
  }
}

"-----------------------------------------"
"- Check for locally-cached UPM Profiles -"
"-----------------------------------------"

$locallyCachedUpmProfiles = 0

$ptusFromRegistry = "unset"

$profileListKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

write-host "checking $profileListKey"

Get-ChildItem $profileListKey | foreach {
  $key = $_
  # $key.Name
  $pip = $key.GetValue("ProfileImagePath")
  # $pip
  $upmv = $key.GetValue("UPMProfileVersion")
  if ($key.PSChildName -eq $userSID) {
    # mark current user
    $markCurrentUser = '* '
  } else {
    $markCurrentUser = ''
  }
  if ($null -ne $upmv) {
    $upmusl = $key.GetValue("UPMUserStoreLocation")
    "$markCurrentUser$pip is a locally-cached UPM profile stored at $upmusl"
    $locallyCachedUpmProfiles++
    # and save the path if not already done
    if ($key.PSChildName -eq $userSID) {
      if ($userProfileRoot -eq "unset") {
        $userProfileRoot = $upmusl
      }
      $ptusFromRegistry = $upmusl
    }
  } else {
    #
    # current profile is not a UPM Profile - so see what it is
    # and whether it belongs to the current user
    # see what flags are set
    # 
    # Get the "State" flags
    $profileStateFlags = $key.GetValue("State")
    $profileStateFlagsHex = "0x" + $profileStateFlags.ToString("x4")
    switch ($profileStateFlags) {
    0 { "$markCurrentUser$pip is a Local Profile" }
    0x100 { "$markCurrentUser$pip is an Administrator Profile" }
    0x21c { $netPath = $key.GetValue("CentralProfile"); "$markCurrentUser$pip is a Roaming Profile stored at $netPath" }
    default {
        #
        # don't recognise this, so just decode the flags
        $flagString = ""
        $bitMask = 1
        for ($bitCount = 0; $bitCount -lt 32; $bitCount++) {
          if ($profileStateFlags -band $bitMask) {
            $bitMaskString = "0x" + $bitMask.ToString("x4")
            switch ($bitMask) {
            0x0001 { $flagString = $flagString + "Mandatory ($bitMaskString), " }
            0x0002 { $flagString = $flagString + "UseCache ($bitMaskString), " }
            0x0004 { $flagString = $flagString + "NewLocal ($bitMaskString), " }
            0x0008 { $flagString = $flagString + "NewCentral ($bitMaskString), " }
            0x0010 { $flagString = $flagString + "UpdateCentral ($bitMaskString), " }
            0x0020 { $flagString = $flagString + "DeleteCache ($bitMaskString), " }
            0x0040 { $flagString = $flagString + "(notused) ($bitMaskString), " }
            0x0080 { $flagString = $flagString + "GuestUser ($bitMaskString), " }
            0x0100 { $flagString = $flagString + "AdminUser ($bitMaskString), " }
            0x0200 { $flagString = $flagString + "NetReady ($bitMaskString), " }
            0x0400 { $flagString = $flagString + "SlowLink ($bitMaskString), " }
            0x0800 { $flagString = $flagString + "TempAssigned ($bitMaskString), " }
            0x1000 { $flagString = $flagString + "(notused) ($bitMaskString), " }
            0x2000 { $flagString = $flagString + "PartlyLoaded ($bitMaskString), " }
            0x4000 { $flagString = $flagString + "BackupExists ($bitMaskString), " }
            0x8000 { $flagString = $flagString + "ThisIsBak ($bitMaskString), " }
            }
          }
          $bitMask = 2 * $bitMask
        }
        $flagString = $flagString -replace ", $",""  # remove trailing comma
        "$markCurrentUser$pip is an unknown Profile type, with State ($profileStateFlagsHex), flags ($flagString)"
      }
    }
  }
}

#
# Examine UserProfileOrigin.ini
#
$sourceProfileType = "unknown"
if ($userProfileRoot -ne "unset") {
   $upoFilePath = $userProfileRoot + "\UserProfileOrigin.ini"
   Get-ChildItem $upoFilePath -ea SilentlyContinue | foreach {
     $upoFileObj = $_
     $creationTime = $upoFileObj.CreationTime
     cat $upoFilePath | foreach {
       $line = $_
       switch -regex ($line) {
       "OP([a-zA-Z]+)=(.*$)" {
           $sourceProfileType = $matches[1]
           $sourceProfile = $matches[2]
           if ($sourceProfile -eq "C:\Users\Default") {
             $sourceProfileType = "Default"
           }
           "Profile created from $sourceProfileType Profile using $sourceProfile at $creationTime"
         }
       }
     }
   }
}

"-----------------------------------------"
"- XenDesktop Checks (WMI API)           -"
"-----------------------------------------"
$prov = $physical         # assume physically provisioned
$IsRunningXD = $false     # this is specifically used to mimic logic in autoConfig, and doesn't care about older versions of XD
try
{
	$vdiInfo = Get-WmiObject -Namespace ROOT\citrix\DesktopInformation -class Citrix_VirtualDesktopInfo
}
catch
{
	"No XenDesktop WMI interface available"
}
if ($null -ne $vdiInfo) {
  $IsRunningXD = $true
  ReportEnvironment "VdiInfo" "Assignment Type"               $vdiInfo.AssignmentType
  ReportEnvironment "VdiInfo" "Broker Site Name"              $vdiInfo.BrokerSiteName
  ReportEnvironment "VdiInfo" "Desktop Catalog Name"          $vdiInfo.DesktopCatalogName
  ReportEnvironment "VdiInfo" "Desktop Group Name"            $vdiInfo.DesktopGroupName
  ReportEnvironment "VdiInfo" "Host Identifier"               $vdiInfo.HostIdentifier
  ReportEnvironment "VdiInfo" "Is Assigned"                   $vdiInfo.IsAssigned
  ReportEnvironment "VdiInfo" "Is Master Image"               $vdiInfo.IsMasterImage
  ReportEnvironment "VdiInfo" "Is Provisioned"                $vdiInfo.IsProvisioned
  ReportEnvironment "VdiInfo" "Is Virtual Machine"            $vdiInfo.IsVirtualMachine
  ReportEnvironment "VdiInfo" "OS Changes Persist"            $vdiInfo.OSChangesPersist
  ReportEnvironment "VdiInfo" "Persistent Data Location"      $vdiInfo.PersistentDataLocation
  ReportEnvironment "VdiInfo" "Personal vDisk Drive Letter"   $vdiInfo.PersonalvDiskDriveLetter
  ReportEnvironment "VdiInfo" "Provisioning Type"             $vdiInfo.ProvisioningType
#  "PS Computer Name :            " + $vdiInfo.PSComputerName           # remove this - it is added (unintentionally) by PowerShell 3.0
  $isAssigned = $vdiInfo.IsAssigned
  $isVirtualMachine = $vdiInfo.IsVirtualMachine
  $osChangesPersist = $vdiInfo.OSChangesPersist
  if ($vdiInfo.OSChangesPersist -eq $false) {
    $prov = "PVS/MCS"
  }
  if ($vdiInfo.IsProvisioned) {
    $prov = $vdiInfo.ProvisioningType
  }
} else {
  "checking C:\personality.ini"
  #check for provisioned

  if ( test-path -path "C:\personality.ini" ) {
    #
    $personalityObj = Get-ChildItem "C:\Personality.ini"
    $personalitytime = $personalityObj.LastWriteTime

    if ( $personalitytime -ge $lastBoot ) {
      # only if personality was created on this boot...
      if ( test-path -path "C:\Program Files\Citrix\PvsVM\Service\Persisted Data" ) {
        $prov = "MCS"
      } else {
        $pvsmode = "Private"
        Get-Content "C:\personality.ini" | select-string -pattern "DiskMode=Shared" | foreach {
          $pvsmode = "Shared"
        }
        $prov = "PVS_" + $pvsmode
      }
    }
  }
}

ReportEnvironment "Machine" "Provisioning" $prov

"-----------------------------------------"
"- Virtualisation Checks                 -"
"-----------------------------------------"

$hypervisor = $physical
$shutdownService = "No Shutdown Service"

$comp = Get-WmiObject Win32_ComputerSystem
switch ( $comp ) {
  { $_.Manufacturer -match "Xen" }                { $hypervisor = "XenServer" ; $shutdownService = "xensvc" }
  { $_.Manufacturer -match "Microsoft" }          { $hypervisor = "Hyper-V" ;   $shutdownService = "vmicshutdown" }
  { $_.Manufacturer -match "vmware" }             { $hypervisor = "VMWare" ;    $shutdownService = "VMTools" }
  { $_.Model -match "vmware" }                    { $hypervisor = "VMWare" ;    $shutdownService = "VMTools" }
}

$bios = Get-WmiObject Win32_Bios
switch ( $bios ) {
  { $_.Manufacturer -match "Xen" }                { $hypervisor = "XenServer" ; $shutdownService = "xensvc" }
  { $_.Version -match "Xen" }                     { $hypervisor = "XenServer" ; $shutdownService = "xensvc" }
  { $_.Version -match "VRTUAL" }                  { $hypervisor = "Hyper-V" ;   $shutdownService = "vmicshutdown" }
  { $_.SerialNumber -match "vmware" }             { $hypervisor = "VMWare" ;    $shutdownService = "VMTools" }
}

ReportEnvironment "Machine" "Hypervisor" $hypervisor

"-----------------------------------------"
"- Tests for Laptop                      -"
"-----------------------------------------"
$isLaptop = $false

$sysEnc = Get-WmiObject Win32_SystemEnclosure
switch ($sysEnc.ChassisTypes) {
8 { "SystemEnclosure: Portable" ; $isLaptop = $true }
9 { "SystemEnclosure: Laptop" ; $isLaptop = $true }
10 { "SystemEnclosure: Notebook" ; $isLaptop = $true }
11 { "SystemEnclosure: Handheld" ; $isLaptop = $true }
14 { "SystemEnclosure: Sub-Notebook" ; $isLaptop = $true }
default { "SystemEnclosure: Not Portable/Laptop/Notebook/Handheld/Sub-Notebook" }
}

$Battery = Get-WmiObject Win32_Battery
if ($Battery -eq $null) {
  "No Battery"
} else {
  "Has Battery"
  $isLaptop = $true
}

$PortableBattery = Get-WmiObject Win32_PortableBattery
if ($PortableBattery -eq $null) {
  "No PortableBattery"
} else {
  "Has PortableBattery"
  $isLaptop = $true
}

$PcmCiaController = Get-WmiObject Win32_PCMCIAController
if ($PcmCiaController -eq $null) {
  "No PCMCIA Controller"
} else {
  "Has PCMCIA Controller"
  $isLaptop = $true
}

ReportEnvironment "Machine" "Laptop" $isLaptop

#
# for now, just get the policies
#
# Get-ChildItem -path HKLM:\SOFTWARE\Policies\Citrix\UserProfileManager -recurse

"-----------------------------------------"
"- Tests for WinLogon Hooking            -"
"-----------------------------------------"
if ($versionMajor -ge 6) {
  $regPath = "HKLM:\\System\CurrentControlSet\Control\Winlogon\Notifications\Configurations\Default"
  "Checking registry: $regPath"
  $Logon = Get-ItemProperty $regPath -name "Logon"
  ReportEnvironment "WinLogon" "LogonHook" $Logon.Logon
  $Logoff = Get-ItemProperty $regPath -name "Logoff"
  ReportEnvironment "WinLogon" "LogoffHook" $Logoff.Logoff
  $logonSeq = $Logon.Logon -split ","
  $upmLogonFound = $false
  $logonCheck = $false
  for ($ix = 0; $ix -lt $logonSeq.Length; $ix++) {
    switch ($logonSeq[$ix]) {
      "UserProfileMan" { $upmLogonFound = $true }
      "Profiles" { if ($upmLogonFound) { $logonCheck = $true } }
    }
  }
  if ($logonCheck) {
    "UPM correctly hooked for logon processing"
  } else {
    "*** ERROR UPM not correctly hooked for logon processing - check that UPM was installed by full domain admin account" | CaptureRecommendations -PolicyName "" -Reason "UPM requires full administrator privilege during install to write to certain protected areas of the registry"
  }
  $logoffSeq = $Logoff.Logoff -split ","
  $profileLogoffFound = $false
  $logoffCheck = $false
  for ($ix = 0; $ix -lt $logoffSeq.Length; $ix++) {
    switch ($logoffSeq[$ix]) {
      "Profiles" { $profileLogoffFound = $true }
      "UserProfileMan" { if ($profileLogoffFound) { $logoffCheck = $true } }
    }
  }
  if ($logoffCheck) {
    "UPM correctly hooked for logoff processing"
  } else {
    "*** ERROR UPM not correctly hooked for logoff processing - check that UPM was installed by full domain admin account" | CaptureRecommendations -PolicyName "" -Reason "UPM requires full administrator privilege during install to write to certain protected areas of the registry"
  }
}

"-----------------------------------------"
"- OS Checks                             -"
"-----------------------------------------"
#
# check OS version, boot time, install date
#

ReportEnvironment "OS" "Version"          $script:osinfo.Version
ReportEnvironment "OS" "BuildNumber"      $script:osinfo.BuildNumber
ReportEnvironment "OS" "Caption"          $script:osinfo.Caption
ReportEnvironment "OS" "LastBootUpTime"   $lastBoot
ReportEnvironment "OS" "InstallDate"      $installTime
ReportEnvironment "OS" "OSArchitecture"   $script:osinfo.OSArchitecture
# Product type 1=workstation, 2=domain controller, 3=server
$ostype = "unset"
switch ( $script:osinfo.ProductType ) {
1 { $ostype = "Workstation" }
2 { $ostype = "Domain Controller" }
3 { $ostype = "Server" }
}
ReportEnvironment "OS" "ProductType"  $ostype
ReportEnvironment "OS" "Machine Name" $script:osinfo.__SERVER

#
# Save OS identifier for specific tests elsewhere
#
$winVer = Get-OsShortName

"-----------------------------------------"
"- Tests for Terminal Svcs / Profiles    -"
"-----------------------------------------"
#
# check for Roaming profiles
#
#
# Query in the following order:
#
#  1. Group policy TS profile directory (if in TS session)
#  2. User account TS profile directory (if in TS session)
#  3. Group policy "normal" profile directory (if on Vista/2008)
#  4. User account "normal" profile directory
#
$roaming = $false
#
$regPath = "HKLM:SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
$valname = "WFProfilePath"
Get-ItemProperty $regPath -name $valName -ErrorAction SilentlyContinue | foreach {
  ReportEnvironment "TsProf" "Group policy TS profile directory"   $_.$valName
  $roaming = $true
}

#
# Adsi query goes here (User account TS profile directory, look at #TerminalServicesProfilePath# in user object)
#
$aduser = Get-ADUser
$aduser.psbase.properties.propertynames | foreach {
  if ($_ -eq "TerminalServicesProfilePath") {
    ReportEnvironment "TsProf" "#TerminalServicesProfilePath#"   $aduser.psbase.properties["TerminalServicesProfilePath"]
    $roaming = $true
  }
}

$regPath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\System"
$valname = "MachineProfilePath"
Get-ItemProperty $regPath -name $valName -ErrorAction SilentlyContinue | foreach {
  ReportEnvironment "TsProf" "Group policy normal profile directory" $_.$valName
  $roaming = $true
}

#
# Adsi query goes here (User account TS profile directory, look at #ProfilePath# in user object)
#
$aduser.psbase.properties.propertynames | foreach {
  if ($_ -eq "ProfilePath") {
    ReportEnvironment "TsProf" "#ProfilePath#" $aduser.psbase.properties["ProfilePath"]
    $roaming = $true
  }
}



if ($roaming) {
  "Roaming Profile path detected"
} else {
  "Roaming Profile path not detected"
}

"-----------------------------------------"
"- Check for Services                    -"
"-----------------------------------------"

#
# checks here to pick up:
# xensvc       - the Xen Tools service
# VMTools      - the VMWare Tools Service
# vmicshutdown - the Hyper-V guest shutdown service (one of 5 Hyper-V services in Win 8)
# ProfSvc      - the User Profile service (Vista & newer)
# UPHClean     - UPHClean (XP / Win2003)
# vdiAgent     - VDI-in-a-Box (5.1 and newer)
# KavizaAgent  - VDI-in-a-Box (pre-5.1)
# AppVClient   - Microsoft App-V Client
#
$uphCleanStatus = "*** No UPHClean/User Profile service Installed"
$uphCleanActive = $false
$hypervisorHasGracefulShutdown = $false
$hypervisorToolsActive = $false
$VdiInABoxPresent = $false
$appVPresent = $false

get-service | foreach {
  $serviceInfo = $_
  $s = $serviceInfo.Status
  $n = $serviceInfo.Name
  switch -regex ($n) {
    { $_ -eq $shutdownService } {
        # Hypervisor tools service
        ReportEnvironment "Service" $n $s
        if ($s -ne "Running") {
          "*** Hypervisor tools service $n is $s" | CaptureRecommendations -PolicyName "" -Reason "if the Hypervisor tools service is not running, VMs cannot be gracefully terminated.  This can lead to data loss"
        } else {
          "Hypervisor tools service $n is $s"
          $hypervisorToolsActive = $true
          $hypervisorHasGracefulShutdown = $true
        }
      }
    "AppVClient" {
        # Microsoft App-V Client
        ReportEnvironment "Service" $n $s
        if ($s -ne "Running") {
          "*** Microsoft App-V Client service $n is $s" | CaptureRecommendations -PolicyName "" -Reason "if the Microsoft App-V Client service is not running, local App-V apps may not behave correctly"
        } else {
          "Microsoft App-V Client service $n is $s"
          $appVPresent = $true
          addMandatoryFolderExclusions -Folder $appVDefaultExcludedFolder
        }
      }
    "vdiAgent|KavizaAgent" {
        # VDI in a Box
        ReportEnvironment "Service" $n $s
        if ($s -ne "Running") {
          "*** VDI-in-a-Box service $n is $s" | CaptureRecommendations -PolicyName "" -Reason "if the VDI-in-a-box service is not running, VMs may not behave correctly"
        } else {
          "VDI-in-a-Box service $n is $s"
          $VdiInABoxPresent = $true
        }
      }
    "ProfSvc" {
        # User Profile Service - must be Win 7, 2k8 or newer
        ReportEnvironment "Service" $n $s
        if ($versionMajor -lt 6) {
          $uphCleanStatus = "*** User Profile Service Installed on wrong OS version" | CaptureRecommendations -PolicyName "" -Reason "the user profile service is designed for Windows 7, Windows Server 2008 and newer.  On older operating systems, use UPHClean"
        } else {
          if ($s -ne "Running") {
            $uphCleanStatus = "*** User Profile Service is $s" | CaptureRecommendations -PolicyName "" -Reason "check the Service Manager for correct configuration.  check the event log for reasons why the service might not be running"
          } else {
            $uphCleanStatus = "User Profile Service is $s"
            $uphCleanActive = $true
          }
        }
      }
    "UPHClean" {
        # UPHClean - must be Win XP or Win 2k3
        ReportEnvironment "Service" $n $s
        if ($versionMajor -ne 5) {
          $uphCleanStatus = "*** UPHClean Service Installed on wrong OS version" | CaptureRecommendations -PolicyName "" -Reason "UPHClean is designed for Windows XP and Windows Server 2003.  On newer operating systems, the User Profile Service performs similar functions, and is built-in to the OS"
        } else {
          if ($s -ne "Running") {
            $uphCleanStatus = "*** UPHClean Service is $s" | CaptureRecommendations -PolicyName "" -Reason "check the Service Manager for correct configuration.  check the event log for reasons why the service might not be running"
          } else {
            $uphCleanStatus = "UPHClean Service is $s"
            $uphCleanActive = $true
          }
        }
      }
  }
}

$uphCleanStatus

if ($hypervisor -ne $physical) {
  if ($hypervisorHasGracefulShutdown -eq $false) {
    "*** Hypervisor $hypervisor does not have graceful shutdown capability - check tools are installed and active" | CaptureRecommendations -PolicyName ""
  }
}

"-----------------------------------------"
"- ShareFile analysis                    -"
"-----------------------------------------"
#
# Check to see if the supported version of the Enterprise Sync is installed.
#
if ($wrongShareFilePresent) {
  ReportEnvironment "ShareFile" "WrongSyncProgram" $wrongShareFileProduct
  ReportEnvironment "ShareFile" "WrongSyncVersion" $wrongShareFileVersion
  "*** ERROR - UPM version is not compatible with '$wrongShareFileProduct' version $wrongShareFileVersion detected . ShareFile data may be lost"  | CaptureRecommendations -PolicyName "" -Reason "For UPM and ShareFile interoperability use UPM v4.1.2 or newer with ShareFile Enterprise Sync Tool 2.1 or newer"
}

if ($shareFilePresent) {
  #
  # check versions of UPM and of ShareFile
  #
  $shareFileVersionInfo = $shareFileVersion -split "\."
  $upmVersionInfo = $upmversion -split "\."
  $shareFileTooLow = $true
  $upmTooLow = $true
  switch ($upmmajor) {
    # if version 4, then must be 4.1.2 or newer
    4 { if (($upmVersionInfo[1] -eq 1) -and ($upmVersionInfo[2] -ge 2)) { $upmTooLow = $false } 
        if ($upmVersionInfo[1] -gt 1) { $upmTooLow = $false } 
      }
    # if version 5 or greater, then it's good
    { $_ -gt 4 } { $upmTooLow = $false }
  }
  ReportEnvironment "ShareFile" "SyncProgramVersion" $ShareFileVersion
  if ($upmTooLow) {
    "*** ERROR - UPM version is not compatible with ShareFile Enterprise Sync Tool detected. ShareFile data may be lost"  | CaptureRecommendations -PolicyName "" -Reason "For UPM and ShareFile interoperability use UPM v4.1.2 or newer (detected UPM $upmversion)"
  }
  switch ($shareFileVersionInfo[0]) {
    { $_ -eq 2 } { if ($shareFileVersionInfo[1] -ge 1) { $shareFileTooLow = $false } }
    { $_ -gt 2 } { $shareFileTooLow = $false }
  }
  if ($shareFileTooLow) {
    "*** ERROR - ShareFile Enterprise Sync Tool version is not compatible with UPM detected. ShareFile data may be lost"  | CaptureRecommendations -PolicyName "" -Reason "For UPM and ShareFile interoperability use ShareFile Enterprise Sync Tool 2.1 or newer (detected Sharefile $ShareFileVersion)"
  }
  #
  # check ShareFile policies
  #
  # - HKLM
  #
  $shareFileBase = "HKLM:\\Software\Policies\Citrix\ShareFile\EnterpriseSync"
  $valueName = "On-demandSyncDiskVolume"
  $c = Get-ItemProperty $shareFileBase -name $valueName -ea SilentlyContinue
  if ($c -ne $null) {
    $diskVol = [string]$c.$valueName
    ReportEnvironment "ShareFile" $valueName $diskVol
    if ($diskVol.Substring(0,1) -ne $currentLocalProfile.Substring(0,1)) {
      "*** ERROR - ShareFile Enterprise Sync Tool $valueName $diskVol does not match local profile volume for $currentLocalProfile"  | CaptureRecommendations -PolicyName "" -Reason "ShareFile Enterprise Sync must be configured to map sharefile data into the UPM Profile"
    }
  } else {
    "*** ERROR - ShareFile Enterprise Sync Tool $valueName is not configured."  | CaptureRecommendations -PolicyName "" -Reason "ShareFile Enterprise Sync must be configured to map sharefile data into the UPM Profile"
  }
  #
  # - HKCU
  #
  $shareFileBase = "HKCU:\\Software\Policies\Citrix\ShareFile\EnterpriseSync"
  "Account","AuthenticationType","LocalSyncFolder","On-demandPersonalFolder" | foreach {
    $valueName = $_
    $c = Get-ItemProperty $shareFileBase -name $valueName -ea SilentlyContinue
    if ($c -ne $null) {
      $configuredValue = [string]$c.$valueName
      ReportEnvironment "ShareFile" $valueName $configuredValue
      switch ($valueName) {
        "Account" {
            if (-not ($configuredValue -like "*.sharefile.com")) {
              "*** warning - personal account configured: $configuredValue - Enterprise Account required"  | CaptureRecommendations -PolicyName "" -Reason "ShareFile Enterprise Account can be configured by policy to map into the UPM Profile"
            }
          }
        "AuthenticationType" {
            if (-not ($configuredValue -eq 1)) {
              "*** warning - $valueName must be configured to 1 (manual authentication).  Actual value configured: $configuredValue"  | CaptureRecommendations -PolicyName "" -Reason "Single sign-on not supported"
            }
          }
        "LocalSyncFolder" {
            $clp = $currentLocalProfile + "\" -replace "\\$","\"
            $excludedShareFileFolder = $shareFileDefaultExcludedFolder
            $preferredValue = $clp + $excludedShareFileFolder
            if (-not ($configuredValue -eq $preferredValue)) {
              "*** warning - LocalSyncFolder: $configuredValue - not set to recommended value $preferredValue"  | CaptureRecommendations -PolicyName "" -Reason "LocalSyncFolder is recommended to be $preferredValue"
              #
              # see if there are any more serious conditions
              if (($configuredValue.Length -lt $clp.Length) -or ($configuredValue.Substring(0,$clp.Length) -ne $clp)) {
                "*** ERROR - LocalSyncFolder: $configuredValue - is set outside profile root $clp"  | CaptureRecommendations -PolicyName "" -Reason "LocalSyncFolder $configuredValue may not be writeable outside the profile root $clp"
                $excludedShareFileFolder = $configuredValue   # note that this will be an absolute path!
              } else {
                # LocalSyncFolder is in the profile but not at the recommended location
                # does it match any of the known folders?
                # the test below catches clashes with folders that have not been redirected
                foreach ($item in $profileFolderHash.GetEnumerator()) {
                  $folderName = $item.Name
                  $folderLocation = $item.Value
                  # write-host "Compare $folderLocation and $configuredValue"
                  if ($folderLocation.StartsWith($configuredValue,[stringcomparison]::CurrentCultureIgnoreCase)) {
                    "*** ERROR - LocalSyncFolder: $configuredValue matches known folder $folderName at $folderLocation"  | CaptureRecommendations -PolicyName "" -Reason "LocalSyncFolder $configuredValue must not be set to any standard profile folders"
                  }
                }
                # - extract the "excess" string and look for misconfigurations
                $chopLength = $clp.Length
                $excess = $configuredValue.Substring($chopLength, $configuredValue.Length - $chopLength)
                $excludedShareFileFolder = $excess
                switch -regex ($excess) {
                "(Documents)|(My Documents)" {
                      "*** ERROR - LocalSyncFolder: $configuredValue - is set to $excess"  | CaptureRecommendations -PolicyName "" -Reason "LocalSyncFolder $configuredValue must not be set to any standard profile folders"
                  }
                }
              }
            }
          }
        "On-demandPersonalFolder" {
            if (-not ($configuredValue -eq 1)) {
              "*** warning - $valueName must be configured to 1 (On-demand sync).  Actual value configured: $configuredValue"  | CaptureRecommendations -PolicyName "" -Reason "Use of On-demand sync optimises bandwidth"
            }
          }
      }
    } else {
      "*** ERROR - ShareFile Enterprise Sync Tool $valueName is not configured."  | CaptureRecommendations -PolicyName "" -Reason "ShareFile Enterprise Sync must be configured to map sharefile data into the UPM Profile"
    }
  }

  #
  # check folder exclusion
  #
  if ([string]$excludedShareFileFolder -ne "") {
    #
    # add it to the list of excluded folders, which will be picked up later
    addRecommendedFolderExclusions -Folder $excludedShareFileFolder
    addMandatoryFolderExclusions -Folder $excludedShareFileFolder
  }
}

else
{
	"ShareFile is not detected "
}

"-----------------------------------------"
"- Personalization (PvD) analysis        -"
"-----------------------------------------"
#
# Check to see if there's a Citrix_PvDInfo class
#

$pvdActive = $false
$pvdPresent = $false
$pvdPresent = $false

Get-WmiObject -Namespace root\Citrix -Recurse -List | select-string "Citrix_PvDInfo" | foreach {
  $pvdPresent = $true
}

if ($pvdPresent) {
$pvdinfo = Get-WmiObject -Namespace root\Citrix Citrix_PvDPool
  $pvdinfo | foreach {
    if ($_.key -eq 0) {
      if ($_.IsActive) {
        $pvdActive = $true
      }
    }
  }
}

ReportEnvironment "PvD" "Present"    $pvdPresent
ReportEnvironment "PvD" "PvD Active" $pvdActive

if ($pvdPresent) {
  if ($pvdActive) {
    #
    # Check some PvD settings
    #
    $regPath = "HKLM:\\SOFTWARE\Citrix\personal vDisk\Config"
    $vhdMountPoint = Get-ItemProperty $regPath -name "VHDMountPoint"
    ReportEnvironment "PvD" "vhdMountPoint" $vhdMountPoint.VHDMountPoint

    $regPath = "HKLM:\\SOFTWARE\Citrix\personal vDisk\Config\Virtual"
    $VdeskNativeMode = Get-ItemProperty $regPath -name "VdeskNativeMode"
    ReportEnvironment "PvD" "VdeskNativeMode" $VdeskNativeMode.VdeskNativeMode

    $regPath = "HKLM:\\SOFTWARE\Citrix\personal vDisk\Config"
    $PercentOfPvDForApps = Get-ItemProperty $regPath -name "PercentOfPvDForApps"
    ReportEnvironment "PvD" "PercentOfPvDForApps" $PercentOfPvDForApps.PercentOfPvDForApps

    $pvdpool = Get-WmiObject -Namespace root\Citrix Citrix_PvDPool
    $pvdpool | foreach {
      $ppi = $_
      if ($ppi.key -eq 0) {
        if ($ppi.IsActive) {
          $tb = ConvenientBytesString -bytes $ppi.TotalBytes
          $tasb = ConvenientBytesString -bytes $ppi.TotalAppSizeBytes
          $tpsb = ConvenientBytesString -bytes $ppi.TotalProfSizeBytes
          $casb = ConvenientBytesString -bytes $ppi.CurrentAppSizeBytes
          $cpsb = ConvenientBytesString -bytes $ppi.CurrentProfSizeBytes
          $fb = ConvenientBytesString -bytes $ppi.FreeBytes
          ReportEnvironment "PvD" "PvD volume" $ppi.MountPoint
          ReportEnvironment "PvD" "PvD volume size" $tb
          ReportEnvironment "PvD" "App Size total" $tasb
          ReportEnvironment "PvD" "App Size used" $casb
          ReportEnvironment "PvD" "Prof Size total" $tpsb
          ReportEnvironment "PvD" "Prof Size used" $cpsb
          ReportEnvironment "PvD" "Free Bytes" $fb
        }
      }
    }

  } else {
    ReportEnvironment "PvD" "Mode" "base mode"
  }
}

########################################################################################
#
# The following logic duplicates the environment checking in UpmConfig\UpmConfig.cpp
# We use global variables already determined
# This is used to determine autoconfig properties for UPM v5 and defaults on older versions             
#
########################################################################################
function Get-AutoconfigSettingsFromEnv ($enabled) {
  #
  # Set the basics for "original" hardwired defaults
  $settingDeleteProfiles         = 0
  $settingProfileDeleteDelay     = 0
  $settingStreaming              = 0
  $settingAlwaysCache            = 0
  $settingAlwaysCacheSize        = 0
  $settingActiveWriteBack        = 0
  $settingProcessAdmins			 = 0
  #
  # let's put the globals into local variables
  
  switch ($upmmajor) {
    5 {
        #
        # set up for XenApp, then adjust
        $settingDeleteProfiles         = 1
        $settingProfileDeleteDelay     = 0
        $settingStreaming              = 1
        $settingAlwaysCache            = 0
        $settingActiveWriteBack        = 1
        if ($IsWorkstation) {
		   $settingProcessAdmins       = 1 # on workstations admins are processed
          if ($pvdActive) {
            $settingDeleteProfiles         = 0
            $settingStreaming              = 0
            $settingAlwaysCache            = 0
            $settingActiveWriteBack        = 0
          } elseif ($IsRunningXD) {
            if ($vdiInfo.IsAssigned) {
              $settingDeleteProfiles         = 0  # we want profiles to persist
            } else {
              $settingDeleteProfiles         = 1  # we delete profiles on pooled desktops
            }
            if (-not $vdiInfo.OSChangesPersist) {
              $settingProfileDeleteDelay     = 60    # allow a minute before we start deleting, as the disk may be discarded before we waste IOPS
            }
            $settingStreaming              = 1
            $settingAlwaysCache            = 0
            $settingActiveWriteBack        = 1
          } else {
            $settingDeleteProfiles         = 0
            $settingStreaming              = 1
            $settingAlwaysCache            = 1
            $settingActiveWriteBack        = 1
          }
        }
      }
    3 {
        $settingActiveWriteBack        = 1    # this is the default on UPM v3 (which is effectively the same as autoconfig)
      }
    default {
        $settingActiveWriteBack        = 0    # this is the default on UPM v4 (which is effectively the same as autoconfig)
      }
  }
  New-Object Object |
    Add-Member NoteProperty DeleteCachedProfilesOnLogoff   $settingDeleteProfiles     -PassThru |
    Add-Member NoteProperty ProfileDeleteDelay             $settingProfileDeleteDelay -PassThru |
    Add-Member NoteProperty PSEnabled                      $settingStreaming          -PassThru |
    Add-Member NoteProperty PSAlwaysCache                  $settingAlwaysCache        -PassThru |
    Add-Member NoteProperty PSAlwaysCacheSize              $settingAlwaysCacheSize    -PassThru |
    Add-Member NoteProperty PSMidSessionWriteBack          $settingActiveWriteBack    -PassThru |
	Add-Member NoteProperty ProcessAdmins				   $settingProcessAdmins      -PassThru
}

#
# test DisableDynamicConfig
#
$dynamic = GetEffectivePolicyFlag -policyName "DisableDynamicConfig" -defaultSetting 0
if ($upmmajor -lt 5) {
  $dynamicConfigEnabled = $false
} else {
  if ($dynamic.Value -eq 0) {
    $dynamicConfigEnabled = $true
  } else {
    $dynamicConfigEnabled = $false
  }
}

if ($dynamicConfigEnabled) {
  $autoConfigSettings = Get-AutoconfigSettingsFromEnv -enabled $dynamicConfigEnabled
} else {
  $autoConfigSettings = $null
}

"========================================="
"= Checking Policies against environment ="
"========================================="

#
# Let's check a policy - ServiceActive
#
$polName = "ServiceActive"
PreferPolicyFlag -policyName $polName -defaultSetting 0 -preferredSetting 1 -Reason "UPM is configured as disabled by default, and must be explicitly enabled" 
$serviceActive = Get-PolicyRecordProperty -PolicyName $polName -PropertyName EffectiveValue

########################################################################################
#
# Having checked basic policies, we now work through everything in systematic fashion
# We echo the sequence of the documentation (the Sixfold Way).
#
########################################################################################

########################################################################################
#
# Question 1: Pilot or production?
#

# It's difficult to be sure whether we've got a pilot system or a production system.
# However, if we don't have _any_ UPM policies in the registry, then a pilot is
# likely.
# Similarly, if we don't have a complex Path to user store, that also indicates a pilot
# If we don't have _any_ path to user store, or only a relative path (i.e. to 
# somewhere in the homedrive), that's certainly a pilot
#
########################################################################################

"-----------------------------------------"
"- Checking Pilot or production?         -"
"-----------------------------------------"

$pilot = $true

function Test-UserStore ($Path, $ExpandedPath) {
  "Testing $Path"
  #
  # Test that the path is well-formed
  # It must contain a user name: one of #CN# , #sAMAccountName# or %USERNAME%
  # Any AD attributes should precede the user name - these are usually used for load-balancing across multiple servers / DFS namespaces
  # Any CTX-variables should follow the user name - these are usually used for keeping the user's different profiles together
  #
  # $components = $Path -split "\\"
  $adAttributes = $false
  $userNames = $false
  $ctxVars = $false
  $username = ""
  $usernameIndex = 0
  $backslashCount = 0
  $pathToTest = ""
  $parentPathToTest = ""
  $errors = @()
  $varMatches = $Path | Select-String -Pattern "(#[^#]+#|%[^%]+%|![^!]+!)" -AllMatches
  $varMatches.Matches | foreach {
    $matchItem = $_
    $comp = $matchItem.Value
    write-host "Testing path component $comp"
    switch -regex ($comp) {
      "(#cn#|%username%|#sAMAccountName#)" {
          $username = $matches[1]
          $userNames = $true
          #
          # work out how many backslashes up to this point
          $usernameIndex = $matchItem.Index
          $prePath = $Path.Substring(0,$usernameIndex)
          $splitPath = $prePath.split("\\")
          $backslashCount = $splitPath.Length
          $iy = 0
          $ep = $ExpandedPath + "\"   # add a trailing slash to ensure we catch an unterminated path
          for ($ix = 0; $ix -lt $backslashCount; $ix++) {
            $iy = $ep.IndexOf("\",$iy)
            $iy++
            $parentPathToTest = $pathToTest
            $pathToTest = $ep.Substring(0,$iy)
          }
          if ($username -eq "#cn#") {
            "*** Path to user store $Path : warning #cn# may not be unique - prefer %USERNAME% or #sAMAccountName#" | CaptureRecommendations -PolicyName "PathToUserStore" -Reason "additionally, #cn# more commonly contains whitespace, punctuation or national language characters that may cause errors when used as folder or file names."
          }
        }
      "(%[^%]+%)" {
          $m = $matches[1]
          switch -regex ($m) {
            '%username%|%userdomain%' {
                # these are fine
              }
            default {
                "*** Path to user store $Path : warning $m may not be defined.  Only system environment variables are supported" | CaptureRecommendations -PolicyName "PathToUserStore" -Reason "UPM supports %USERNAME% and %USERDOMAIN% as environment variables.  Other system environment variables may be supported, but these usually require additional scripting to configure."
              }
          }
        }
      "(#[^#]+#)" {
          $m = $matches[1]
          if ($m -ne $username) {
            if ($ctxVars -or $userNames) {
              "*** Path to user store $Path : warning AD attribute $m follows CTX variable or user name" | CaptureRecommendations -PolicyName "PathToUserStore" -Reason "putting AD attributes first allows grouping of users by common attributes, such as department or location.  This helps to load-balance profiles across file servers, and make use of DFS namespaces, which improves scalability."
            }
            $adAttributes = $true
          }
        }
      "(!ctx.*!)" {
          $m = $matches[1]
          if (-not $userNames) {
            "*** Path to user store $Path : CTX variable $m precedes user name" | CaptureRecommendations -PolicyName "PathToUserStore" -Reason "putting CTX variables after the user name makes it easier to back-up all a users settings together.  It may also simplify setting up ACLs."
          }
          $ctxVars = $true
        }
    }
  }
  if (-not $userNames) {
    "*** Path to user store $Path does not contain a user name" | CaptureRecommendations -PolicyName "PathToUserStore" -Reason "You must specify one of %USERNAME% #sAMAccountName# or #cn#.  #cn# is least preferred."
  }
  if (-not $adAttributes) {
    "*** Path to user store $Path conforms to all rules but may not scale without the use of AD user object attributes" | CaptureRecommendations -PolicyName "PathToUserStore" -Reason "To scale, use geographic or organisational attributes from the AD user object to partition UPM users across multiple DFS targets.  See http://support.citrix.com/proddocs/topic/user-profile-manager-sou/upm-plan-high-availability-disaster-recovery-intro.html for a full discussion of this topic."
  }
}

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking PathToUserStore              /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

$polName = "PathToUserStore"
$pol = GetPolicyGeneralSetting -policyName $polName
$polName + " = " + $pol
$expandedPathToUserStore = Get-ProcessedPath -path $pol
"Expanding using current environment, policy expands to '" + $expandedPathToUserStore + "' for current user"
"(from event log, expands to '" + $fullpathtouserstore + "' for current user)"
switch -wildcard ($pol) {
# '*#CN#*' { '*** Path to user store contains #CN# - #sAMAccountName# or %USERNAME%.%USERDOMAIN% is recommended to avoid spaces in name' | CaptureRecommendations -PolicyName $polName -Reason "Also, #CN# is not unique in AD.  %USERNAME%.%USERDOMAIN% is the best choice, as it allows UPM to work in multi-domain (forest) environments" }
'\\*' { 'Path to user store appears to be a fileshare or DFS namespace, assuming Production' ; $pilot = $false }
'* ' { '*** Path to user store has a trailing space - this may cause errors' | CaptureRecommendations -PolicyName $polName -Reason "trailing whitespace can lead to unpredictable and hard-to-diagnose behaviour in UPM" }
}

if (($null -eq $expandedPathToUserStore) -and ($expandedPathToUserStore -ne "")) {
  $targetExists = Test-Path -LiteralPath $expandedPathToUserStore -ea SilentlyContinue
  if ($targetExists) {
    "Testing for path succeeded - path exists: " + $expandedPathToUserStore  
  } else {
    "*** Testing for path failed - path does not exist: " + $expandedPathToUserStore | CaptureRecommendations -PolicyName $polName -Reason "If UPM is running and processing this login, the user store path should have been created by now."
  }
}

if (-not $pilot) {
  # only test path to user store for production
  Test-UserStore -Path $pol -ExpandedPath $expandedPathToUserStore
}

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking ProcessedGroups              /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

$polName = "ProcessedGroups"
$pol = GetPolicyListSetting -regName $polName
$polName + ":"
$pol

ValidateList -list $pol -policyName $polName

$polcount = Get-ListItemCountRaw -list $pol
if (($polcount -eq 0) -and ($pilot -eq $false)) { "*** Processed Groups not set in production environment.  Setting this policy may help manage your licence compliance (EULA)." | CaptureRecommendations -PolicyName $polName -Reason "However, UPM will still operate correctly." }

if ($upmmajor -ge 5) {
  "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
  "/ Checking ExcludedGroups               /"
  "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

  $polName = "ExcludedGroups"
  $pol = GetPolicyListSetting -regName $polName
  $polName + ":"
  $pol

  ValidateList -list $pol -policyName $polName

  # $polcount = Get-ListItemCountRaw -list $pol
  # if (($polcount -eq 0) -and ($pilot -eq $false)) { "*** Excluded Groups not set in production environment.  Setting this policy may help manage your licence compliance (EULA)." | CaptureRecommendations -PolicyName $polName -Reason "However, UPM will still operate correctly." }
}

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking LogoffRatherThanTempProfile  /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

$preferLogoffToTempProfile = GetEffectivePolicyFlag -policyName "LogoffRatherThanTempProfile" -defaultSetting 0
if (($preferLogoffToTempProfile.Value -eq 1) -and ($upmmajor -gt 4)) {
  #
  "In failure cases, where UPM would normally give a temporary profile, a logoff will be forced."
} else {
  #
  "In failure cases, UPM will give a temporary profile."
}

########################################################################################
#
# Question 2: Migrated or Clean Start?
#
# Our best indicator here is whether we've got policies to migrate Roaming Profiles.
# If UPM is disabled, we can try checking for a "rich" local profile (significantly 
# bigger than the Windows default profile), on the assumption that the script is 
# being run on the unmigrated system.
#
########################################################################################

"-----------------------------------------"
"- Checking Migrated or Clean Start?     -"
"-----------------------------------------"

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking MigrateWindowsProfilesToUserStore  /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

#
# Let's check a policy - MigrateWindowsProfilesToUserStore
#
$polName = "MigrateWindowsProfilesToUserStore"
$pol = GetPolicyGeneralSetting -policyName $polName
$polName + " = " + $pol
$migrateProfiles = $pol

if( $pol){
	switch ( $pol ) {
		1 { "MigrateWindowsProfilesToUserStore is set to All" }
		2 { "MigrateWindowsProfilesToUserStore is set to Local" }
		3 { "MigrateWindowsProfilesToUserStore is set to Roaming" }
		4 { "MigrateWindowsProfilesToUserStore is set to None" }
		default { "*** MigrateWindowsProfilesToUserStore is unset and will default to All" | CaptureRecommendations -PolicyName $polName -Reason "the default action is to migrate whichever is found: either a local or a roaming profile.  Where users have both, this might not give the intended outcome" ; $migrateProfiles = 1 }
	}
}
else{
	"*** MigrateWindowsProfilesToUserStore is unset and will default to All" | CaptureRecommendations -PolicyName $polName -Reason "the default action is to migrate whichever is found: either a local or a roaming profile.  Where users have both, this might not give the intended outcome" ; $migrateProfiles = 1
}

if ($roaming) {
  if ($pol -eq 4) {
    "*** Warning: Roaming Profile policy detected, but MigrateWindowsProfilesToUserStore is set to None" | CaptureRecommendations -PolicyName $polName -Reason "Even though Roaming Profiles are configured, they will not be migrated."
  }
} else {
  switch ($pol) {
  1 { "*** Warning: Roaming Profile policy not detected, but MigrateWindowsProfilesToUserStore is set to All" | CaptureRecommendations -PolicyName $polName -Reason "As there is no Roaming Profile policy detected, there is no reason to select a policy of 'All'.  Choose 'Local' or 'None'." }
  3 { "*** Warning: Roaming Profile policy not detected, but MigrateWindowsProfilesToUserStore is set to Roaming" | CaptureRecommendations -PolicyName $polName -Reason "As there is no Roaming Profile policy detected, there is no reason to select a policy of 'Roaming'.  Check that your Roaming Profile policy is being correctly applied, else choose 'Local' or 'None'." }
  }
}

if ($sourceProfileType -eq "Local") {
  if ($firstLogon) {
    "Profile origin = $sourceProfileType; First Logon = $firstLogon : Profile was created from a Local profile on this machine"
  } else {
    "Profile origin = $sourceProfileType; First Logon = $firstLogon : Profile was created from a Local profile on an unknown machine."
  }
} else {
  "Profile origin = $sourceProfileType; First Logon = $firstLogon : Profile was not created from a Local profile."
}

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking LocalProfileConflictHandling /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
#
# if the current profile is a temporary profile and the user store contains a UPM profile
# then we have a profile locking problem,
# if the current profile is a local profile  and the user store contains a UPM profile
# then we have triggered a local profile conflict, resolved by keeping the local profile
# if we have a UPM profile and there is also a profile in c:\Users\<user>.upm.backup
# then we have triggered a local profile conflict, resolved by backing up the local profile
# we cannot tell if a local profile has been silently obliterated
#
$localProfileConflicts = GetEffectivePolicyFlag -policyName "LocalProfileConflictHandling" -defaultSetting 1 -AsNumber
switch ($localProfileConflicts.Value) {
  1 { "LocalProfileConflictHandling is set to Use the Local Profile" }
  2 { "LocalProfileConflictHandling is set to Delete the Local Profile" }
  3 { "LocalProfileConflictHandling is set to Rename the Local Profile" }
}
"*** FIXME - checks for LocalProfileConflictHandling not implemented."

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking TemplateProfilePath          /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

$polName = "TemplateProfilePath"
$pol = GetPolicyGeneralSetting -policyName $polName
$polName + " = " + $pol
if (($upmmajor -ge 5) -or (($upmmajor -eq 4) -and ($upmminor -gt 0))) {
  $expandedTemplatePath = Get-ProcessedPath -path $pol
  "After expansion -> $expandedTemplatePath"
} else {
  $expandedTemplatePath = $pol
}

switch -wildcard ($expandedTemplatePath) {
'*ntuser.dat' { '*** Do not specify the path of an NTUSER.DAT file.  Specify the Path of the containing folder' | CaptureRecommendations -PolicyName $polName -Reason "this is an occasional mis-configuration encountered on the support forum.  The documentation has been clarified to make this unlikely!" }
'\\*' { 'Template Profile path appears to be a fileshare or DFS namespace' }
'* ' { '*** Template Profile path has a trailing space - this may cause errors' | CaptureRecommendations -PolicyName $polName -Reason "trailing whitespace can lead to unpredictable and hard-to-diagnose behaviour in UPM" }
}

#
# validate the path
$templateIsValid = $false
if (($null -eq $expandedTemplatePath) -or ($expandedTemplatePath -eq "")) {
  "*** no Template Profile Path" | CaptureRecommendations -PolicyName $polName -Reason "If the Template Profile Path is not configured and migration of existing profiles is not configured, new users will receive an initial profile copied from the Windows default profile.  This will work, but using a template profile gives more control over the initial profile contents"
} else {
  $exists = Test-Path $expandedTemplatePath
  if ($exists -eq $false) {
    "*** Template Profile Path is specified but does not exist: " + $expandedTemplatePath | CaptureRecommendations -PolicyName $polName -Reason "This implies a network configuration problem, such as DNS or an ACL problem.  Or a simple typo.  Check everything."
  } else {
    $hasNtuser = $false
    Get-ChildItem -Path $expandedTemplatePath -Force  -ErrorAction SilentlyContinue | foreach {
      if ($_.Name -eq "NTUSER.DAT") { $hasNtuser = $true }
    }
    if ($hasNtuser) {
      "Template Profile Path contains an NTUSER.DAT"
      $templateIsValid = $true
    } else {
      "*** Template Profile path is not readable or does not contain an NTUSER.DAT" | CaptureRecommendations -PolicyName $polName -Reason "Check that the path is correctly configured and has suitable access rights"
    }
  }
}

#
# if we have a template path, it can either be used as a template
# or as a mandatory profile
if ($templateIsValid) {
  $polName = "TemplateProfileIsMandatory"
  $templateProfileIsMandatory = GetEffectivePolicyFlag -policyName $polName -defaultSetting 0
  $tpim = $templateProfileIsMandatory.Value
  if ($tpim -eq 1) {
    #
    # mandatory, therefore neither TemplateProfileOverridesLocalProfile nor 
    # TemplateProfileOverridesRoamingProfile should be set
    AssertFlagNotSet -policyName "TemplateProfileOverridesLocalProfile" -Reason "Template profile is being used as a mandatory profile"
    AssertFlagNotSet -policyName "TemplateProfileOverridesRoamingProfile" -Reason "Template profile is being used as a mandatory profile"
  } else {
    #
    # template profile is being used as a template profile
    # either TemplateProfileOverridesLocalProfile or
    # TemplateProfileOverridesRoamingProfile (or both) can be set
    # all combinations are meaningful
    # (if we were picky, we could object to roaming profile option if there's no roaming profile)
    "TemplateProfileOverridesLocalProfile","TemplateProfileOverridesRoamingProfile" | foreach {
      $polName = $_
      $pol = GetPolicyGeneralSetting -policyName $polName
      $polName + " = " + $pol
    }
  }
} else {
  AssertFlagNotSet -policyName "TemplateProfileIsMandatory" -Reason "Template Profile has not been set up"
  AssertFlagNotSet -policyName "TemplateProfileOverridesLocalProfile" -Reason "Template Profile has not been set up"
  AssertFlagNotSet -policyName "TemplateProfileOverridesRoamingProfile" -Reason "Template Profile has not been set up"
}

########################################################################################
#
# Question 3: XenApp or XenDesktop?
#
# While we could check for actual products, it's better just to look for a Workstation
# OS or a Server OS.
#
########################################################################################

"-----------------------------------------"
"- Checking XenApp or XenDesktop?        -"
"-----------------------------------------"

#
# This section looks at 4 related policies, and is now fairly complex
#
# Set up constants and preferred settings for all policies, then adjust as we go
#
$deleteOnLogoff = 1                                           # DeleteCachedProfilesOnLogoff
$keepOnLogoff = 0                                             # DeleteCachedProfilesOnLogoff
$preferredProfileDisposition = $keepOnLogoff                  # DeleteCachedProfilesOnLogoff
$profileDeleteImmediate = 0                                   # ProfileDeleteDelay
$profileDeleteDeferred = 60                                   # ProfileDeleteDelay
$preferredDeleteDelay = $profileDeleteImmediate               # ProfileDeleteDelay
$profilesStreamedOnDemand = 1                                 # PSEnabled
$profilesCopiedInFull = 0                                     # PSEnabled
$activeWriteBackDisabled = 0                                  # PSMidSessionWriteBack
$activeWriteBackEnabled = 1                                   # PSMidSessionWriteBack
$activeWriteBackPreferred = $activeWriteBackEnabled           # PSMidSessionWriteBack
$activeWriteBackDefault = $activeWriteBackEnabled             # PSMidSessionWriteBack
$backgroundCacheFill = 1                                      # PSAlwaysCache
$onDemandCacheFill = 0                                        # PSAlwaysCache
$alwaysCacheDefault = $onDemandCacheFill                      # PSAlwaysCache
$preferredCacheFill = $onDemandCacheFill                      # PSAlwaysCache
$cacheFillReason = "no reason set"                            # PSAlwaysCache

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking DeleteCachedProfilesOnLogoff /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
#
# The policy was originally designed for tidying up XenApp servers at session end.  But things aren’t so simple…
#
# You should not delete locally cached profiles on logoff if…
# * The (virtual) machine is volatile and will be destroyed on logoff, or
# * Specifically, VDI-in-a-Box is in use, or
# * The machine is “assigned” to one user (XenDesktop), or
# * The profile is stored in a Personal vDisk, or
# * The machine is dedicated for the use of a small number of users, and has a suitably-large persistent disk.
#
# You should delete locally cached profiles on logoff if…
# * XenApp persistent.  Delete, to avoid the proliferation of stale profiles, or
# * XenDesktop pooled.  Delete if the desktops can be recycled between users, rather than being created/destroyed on demand
#

#
# $vmIsVolatile - set this if we are running on a hypervisor and are provisioned
# But clear it if there is evidence that this machine was created well before logon
# or has been re-used
# Clues: big difference between session start and boot time
#        other profiles present in file system
#        registry entries for other profiles in HKLM
# 
$vmIsVolatile = $false

if ($null -eq $vdiInfo) {
  #
  # need to make best guess at whether we have a volatile environment
  #
  "No XenDesktop WMI - assume volatile if provisioning in use"
  if ($prov -ne $physical) {
    $vmIsVolatile = $true
    #
    # get the start time for the session
    #
    $sess    = Get-WmiObject -Class Win32_Session
  #  $logonTime = $sess.ConvertToDateTime($sess.StartTime)
    foreach ($s in $sess) {
      $logonTime = $s.ConvertToDateTime($s.StartTime)
    }
    $elapsed = $logonTime - $lastBoot
  }
} else {
  #
  # we know from Santa Cruz WMI if we have a volatile environment
  #
  if ($vdiInfo.OSChangesPersist) {
    $vmIsVolatile = $false
  } else {
    $vmIsVolatile = $true
  }
}

$preferredProfileDisposition = $keepOnLogoff   # this is the default
$profileDispositionReason = "No special environment detected - keep cached profiles on logoff"
$deleteDelayReason = "Profile should be deleted immediately to free disk space"

# * The (virtual) machine is volatile and will be destroyed on logoff - don't delete
if ($vmIsVolatile) {
  $profileDispositionReason = "Volatile environment - no need to delete cached profiles"
  $profileDispositionReason
  $preferredProfileDisposition = $keepOnLogoff   # why waste time deleting - it'll be destroyed
  $preferredCacheFill = $onDemandCacheFill       # but no need to background cache fill
  $cacheFillReason = "profile will be deleted when machine shuts down - no need to fully-cache-fill"
  $preferredDeleteDelay = $profileDeleteDeferred                # ProfileDeleteDelay
  $deleteDelayReason = "in volatile environments, profile delete should be deferred in case the machine is deleted.  Starting profile delete promptly risks wasting IOPS"
}

# * Specifically, VDI-in-a-Box is in use, or
if ($VdiInABoxPresent) {
  $profileDispositionReason = "VDI-in-a-Box - no need to delete cached profiles"
  $profileDispositionReason
  $preferredProfileDisposition = $keepOnLogoff   # why waste time deleting - it'll be destroyed
  $preferredCacheFill = $onDemandCacheFill       # but no need to background cache fill
  $cacheFillReason = "profile will be deleted when machine shuts down - no need to fully-cache-fill"
  $preferredDeleteDelay = $profileDeleteDeferred                # ProfileDeleteDelay
  $deleteDelayReason = "when using VDI in a Box, profile delete should be deferred in case the machine is deleted.  Starting profile delete promptly risks wasting IOPS"
}

# * The machine is “assigned” to one user (XenDesktop), or
if ($null -ne $vdiInfo) {
  if ($vdiInfo.IsAssigned) {
    $profileDispositionReason = "Assigned Desktop - no need to delete cached profiles"
    $profileDispositionReason
    $preferredProfileDisposition = $keepOnLogoff
    $preferredCacheFill = $backgroundCacheFill       # trying to create a fully-cache-filled local profile
    $cacheFillReason = "profile will be retained when machine shuts down - need to fully-cache-fill"
    $deleteDelayReason = "for assigned desktops, profiles are best retained at the end of session"
  }
} else {
  # CAN'T DETECT THIS IF WMI NOT AVAILABLE
}

# * The profile is stored in a Personal vDisk - don't delete
if ($pvdActive) {
  #
  # the v4 PVD UPM code actually disables streaming and deletion of cached profiles - there's no choice about it!
  #
  $profileDispositionReason = "Personal vDisk - no need to delete cached profiles"
  $profileDispositionReason
  $preferredProfileDisposition = $keepOnLogoff
  $preferredCacheFill = $backgroundCacheFill       # trying to create a fully-cache-filled local profile
  $cacheFillReason = "profile will be retained when machine shuts down - need to fully-cache-fill"
  $deleteDelayReason = "when PVD is in use, profiles will be retained at the end of session"
}

# * The machine is dedicated for the use of a small number of users, and has a suitably-large persistent disk.
  # CAN'T DETECT THIS

# * XenApp persistent.  Delete, to avoid the proliferation of stale profiles, or
if ($ostype -eq "Server") {
  if ($vmIsVolatile) {
    $profileDispositionReason = "provisioned Server - safest to delete cached profiles, unless frequent reboots keep cached profiles within resource limits"
    $profileDispositionReason
    $preferredProfileDisposition = $deleteOnLogoff
    $preferredCacheFill = $onDemandCacheFill       # but no need to background cache fill
    $cacheFillReason = "profile will be deleted on logoff - no need to fully-cache-fill"
  } else {
    $profileDispositionReason = "non-provisioned Server - recommend to delete cached profiles"
    $profileDispositionReason
    $preferredProfileDisposition = $deleteOnLogoff
    $preferredCacheFill = $onDemandCacheFill       # but no need to background cache fill
    $cacheFillReason = "profile will be deleted on logoff - no need to fully-cache-fill"
  }
}

# * XenDesktop pooled.  Delete if the desktops can be recycled between users, rather than being created/destroyed on demand
if (($ostype -eq "Workstation") -and ($locallyCachedUpmProfiles -gt 1)) {
  $profileDispositionReason = "Shared desktop - recommend to delete cached profiles"
  $profileDispositionReason
  $preferredProfileDisposition = $deleteOnLogoff
  $preferredCacheFill = $onDemandCacheFill       # but no need to background cache fill
  $cacheFillReason = "profile will be deleted on logoff - no need to fully-cache-fill"
  if (-not $vmIsVolatile) {
    $deleteDelayReason = "for XenDesktop pooled, profiles should be deleted immediately on logoff to prevent running out of disk space"
  }
}

# we've reached the end
# do the test

"Final recommendation: $profileDispositionReason"
PreferPolicyFlag -policyName "DeleteCachedProfilesOnLogoff" -defaultSetting $keepOnLogoff -preferredSetting $preferredProfileDisposition -autoSetting $autoConfigSettings.DeleteCachedProfilesOnLogoff -Reason $profileDispositionReason
if ($upmmajor -gt 4) {
  PreferPolicyFlag -policyName "ProfileDeleteDelay" -ShowAsNumber -defaultSetting $profileDeleteImmediate -preferredSetting $preferredDeleteDelay -autoSetting $autoConfigSettings.ProfileDeleteDelay -Reason $deleteDelayReason
}

#
# worry about special case where locally-cached profiles are deleted on Win8
if ($winver -eq "Win8") {
  $deleteCached = GetEffectivePolicyFlag -policyName "DeleteCachedProfilesOnLogoff" -defaultSetting $keepOnLogoff
  if ($deleteCached.Value -eq $deleteOnLogoff) {
    #
    # the effective value is to delete, so we must enforce the presence of the 2 extra folders
    addMandatoryFolderExclusions -Folder $win8DefaultExcludedFolderList
  }
  if ($preferredProfileDisposition -eq $deleteOnLogoff) {
    #
    # we need to add the folders to the recommended exclusions 
    addRecommendedFolderExclusions -Folder $win8DefaultExcludedFolderList
  }
}

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking PSEnabled                    /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

$alwaysCacheChecked = $false
$streaming = GetEffectivePolicyFlag -policyName "PSEnabled" -defaultSetting $profilesCopiedInFull -autoSetting $autoConfigSettings.PSEnabled
if ($preferredProfileDisposition -eq $keepOnLogoff) {
  #
  # We're recommending to keep the profile, so there are two valid choices
  # - Choice 1 - disable streaming
  # - Choice 2 - enable streaming and also set always cache with size = 0
  if ($streaming.Value -eq $profilesCopiedInFull) {
    #
    # this is good - just get the message out
    "Following recommendation that Local Profile should be cached, Profile Streaming is disabled"
    PreferPolicyFlag -policyName "PSEnabled"         -defaultSetting $profilesCopiedInFull -preferredSetting $profilesCopiedInFull     -autoSetting $autoConfigSettings.PSEnabled    -Reason "this may indicate incomplete installation of UPM"
  } else {
    "Following recommendation that Local Profile should be cached, Profile Streaming is enabled"
    PreferPolicyFlag -policyName "PSEnabled"         -defaultSetting $profilesCopiedInFull -preferredSetting $profilesStreamedOnDemand -autoSetting $autoConfigSettings.PSEnabled    -Reason " *** Local Profile should be cached, so Profile Streaming should be enabled"
    PreferPolicyFlag -policyName "PSAlwaysCache"     -defaultSetting $alwaysCacheDefault   -preferredSetting $preferredCacheFill       -autoSetting $autoConfigSettings.PSAlwaysCache  -Reason $cacheFillReason
    PreferPolicyFlag -policyName "PSAlwaysCacheSize" -defaultSetting 0                     -preferredSetting 0                         -autoSetting $autoConfigSettings.PSAlwaysCacheSize  -ShowAsNumber -Reason " *** Local Profile should be cached, so AlwaysCacheSize should be 0"
    $alwaysCacheChecked = $true
  }
} else {
  #
  # We're recommending to delete the profile, so we enable profile streaming
  PreferPolicyFlag -policyName "PSEnabled"         -defaultSetting $profilesCopiedInFull -preferredSetting $profilesStreamedOnDemand -autoSetting $autoConfigSettings.PSEnabled    -Reason " *** Local Profile should be discarded, so Profile Streaming should be enabled"
  "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
  "/ Checking PSAlwaysCache                /"
  "/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
  PreferPolicyFlag -policyName "PSAlwaysCache"     -defaultSetting $alwaysCacheDefault   -preferredSetting $preferredCacheFill       -autoSetting $autoConfigSettings.PSAlwaysCache  -Reason $cacheFillReason
  PreferPolicyFlag -policyName "PSAlwaysCacheSize" -defaultSetting 0                     -preferredSetting 0                         -autoSetting $autoConfigSettings.PSAlwaysCacheSize  -ShowAsNumber -Reason " *** AlwaysCacheSize should be 0"
  $alwaysCacheChecked = $true
}

if (-not $alwaysCacheChecked) {
  #
  # if we haven't explicitly checked PSAlwaysCache by now, it's because we're recommending not
  # to use streaming, so we don't use PSAlwaysCache.  We should check, for completeness sake
  PreferPolicyFlag -policyName "PSAlwaysCache"     -defaultSetting $alwaysCacheDefault   -preferredSetting $alwaysCacheDefault       -autoSetting $autoConfigSettings.PSAlwaysCache  -Reason $cacheFillReason
  PreferPolicyFlag -policyName "PSAlwaysCacheSize" -defaultSetting 0                     -preferredSetting 0                         -autoSetting $autoConfigSettings.PSAlwaysCacheSize  -ShowAsNumber -Reason " *** AlwaysCacheSize should be 0"
  $alwaysCacheChecked = $true
}

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking PSMidSessionWriteBack        /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
if ($upmmajor -ge 4) {
  $activeWriteBackDefault = $activeWriteBackDisabled
}

if ($pvdActive) {
  $activeWriteBackReason = "PVD is active - Active Write Back should be disabled, as profile changes will be protected by the Personal vDisk"
  $activeWriteBackReason
  $activeWriteBackPreferred = $activeWriteBackDisabled
}

if ($vmIsVolatile -eq $false) {
  $activeWriteBackReason = "Machine os not volatile - Active Write Back should be disabled, as profile changes will be saved on the local disk"
  $activeWriteBackReason
  $activeWriteBackPreferred = $activeWriteBackDisabled
} else {
  if ($pvdActive -eq $false) {
    if (($ostype -eq "Workstation")) {
      # recommend PVD in workstation environments
      "*** Machine is volatile workstation - recommend PVD" | CaptureRecommendations -PolicyName $polName -Reason "PVD gives: fast access to the profile, and is robust against loss of settings due to power outages.  Use PVD with UPM to also allow profile sharing, and to back up settings to a network location."
    } else {
      $activeWriteBackReason = "Machine is volatile server - Active Write Back should be enabled, to preserve profile changes against power outages.  Check applications do not require corresponding file and registry changes"
      $activeWriteBackReason
      $activeWriteBackPreferred = $activeWriteBackEnabled
    }
  }
}
PreferPolicyFlag -policyName "PSMidSessionWriteBack" -defaultSetting $activeWriteBackDefault -preferredSetting $activeWriteBackPreferred -autoSetting $autoConfigSettings.PSMidSessionWriteBack -Reason $activeWriteBackReason

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking ProcessAdmins                /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
$processAdminReason = "ProcessAdmins should be set in workstation environments, where the end user also needs to administer the machine.  ProcessAdmins is not recommended for server environments"

$polName = "ProcessAdmins"
if ($ostype -eq "Workstation") {
  PreferPolicyFlag -policyName $polName -defaultSetting 0 -preferredSetting 1 -Reason $processAdminReason -autoSetting $autoConfigSettings.ProcessAdmins
} else {
  PreferPolicyFlag -policyName $polName -defaultSetting 0 -preferredSetting 0 -Reason $processAdminReason -autoSetting $autoConfigSettings.ProcessAdmins
}
$processAdmins = Get-PolicyRecordProperty -PolicyName $polName -PropertyName EffectiveValue

[System.Security.Principal.WindowsIdentity]::GetCurrent().Groups | foreach {
  $currentGroup = $_
  switch ($currentGroup.Value) {
  "S-1-5-32-544" { if ($processAdmins -eq 0) {
        "*** Warning - current user is a member of BUILTIN\Administrators (S-1-5-32-544) and will not be processed by UPM" | CaptureRecommendations -PolicyName "ProcessAdmins" -Reason $processAdminReason 
      }
    }
  }
}

########################################################################################
#
# Question 4: Provisioned or Persistent?
#
# We can easily check for the presence of PVS or MCS
#
########################################################################################

"-----------------------------------------"
"- Checking Provisioned or Persistent?   -"
"-----------------------------------------"


"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking USNDBPath                    /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

$polName = "USNDBPath"
$pol = GetPolicyGeneralSetting -policyName $polName
$polName + " = " + $pol
switch -wildcard ($pol) {
'\\*' { 'MFT cache file path appears to be a fileshare or DFS namespace' }
'* ' { '*** MFT cache file path has a trailing space - this may cause errors' | CaptureRecommendations -PolicyName $polName -Reason "trailing whitespace can lead to unpredictable and hard-to-diagnose behaviour in UPM" }
}

#
# validate the path
if (($null -eq $pol) -or ($pol -eq "")) {
  "MFT cache file Path is not configured - this is the recommended configuration in all cases"
} else {
  "*** MFT cache file Path has been configured" | CaptureRecommendations -PolicyName $polName -Reason "this is not recommended, unless the default drive is not writeable or is a slow (e.g. networked) device"
  $exists = Test-Path $pol
  if ($exists -eq $false) {
    "*** MFT cache file Path is specified but does not exist or is not accessible: " + $pol | CaptureRecommendations -PolicyName $polName -Reason "This is not necessarily an error, as the path may be hidden by ACLs.  Check the path from a system account."
  } else {
    "*** MFT cache file Path is specified and exists: " + $pol | CaptureRecommendations -PolicyName $polName -Reason "This is may be an error, as the path may be insufficiently protected by ACLs.  Check the ACLs on the path from a system account."
  }
}

########################################################################################
#
# Question 5: Mobile or Static?
#
# Best bet here is to look for Power Management Options.  Or a Lid event.  Or a battery
# Also check out: http://blogs.technet.com/b/heyscriptingguy/archive/2004/09/21/how-can-i-determine-if-a-computer-is-a-laptop-or-a-desktop-machine.aspx
# Or: http://www.robvanderwoude.com/vbstech_inventory_laptop.php
# Or: http://stackoverflow.com/questions/1013354/how-to-check-the-machine-type-laptop-or-desktop
#
########################################################################################

"-----------------------------------------"
"- Checking Mobile or Static?            -"
"-----------------------------------------"
#
# note that this is now largely covered elsewhere, but the laptop case is new
$reported = $false
if ($pvdActive -eq $false) {
  if ($upmmajor -ge 4) {
    if ($isLaptop) {
      PreferPolicyFlag -policyName "OfflineSupport" -defaultSetting 0 -preferredSetting 1 -Reason "laptops need to be able to synchronise the profile after being used while disconnected from the domain"
      PreferPolicyFlag -policyName "PSEnabled" -defaultSetting $profilesCopiedInFull -preferredSetting $profilesCopiedInFull -autoSetting $autoConfigSettings.PSEnabled  -Reason "a laptop can be removed from the domain once the first logon is complete, so the profile must be copied in full before the logon completes"
      PreferPolicyFlag -policyName "DeleteCachedProfilesOnLogoff" -defaultSetting $keepOnLogoff -preferredSetting $keepOnLogoff -autoSetting $autoConfigSettings.DeleteCachedProfilesOnLogoff  -Reason "a laptop must have persistent store and may be absent from the domain at logon - it MUST retain the profile on logoff"
      $reported = $true
    }
  }
}
if (-not $reported) {
  PreferPolicyFlag -policyName "OfflineSupport" -defaultSetting 0 -preferredSetting 0 -Reason "OfflineSupport not required or supported for this device.  Profile streaming will be disabled.  Delete cached profiles on logoff will be disabled."
}

########################################################################################
#
# Question 6: Which Applications?
#
# This will be driven by support issues:
# - Start Menu
# - presence of VMWare Tools
#
########################################################################################

"-----------------------------------------"
"- Checking Which Applications?          -"
"-----------------------------------------"
#
# Let's check a policy - SyncDirList
#
$polName = "SyncDirList"
$pol = GetPolicyListSetting -regName $polName
$polName + ":"
$pol

ValidateList -list $pol -policyName $polName

$startMenuFound = $false
$pol | foreach { 
  $item = $_
  switch ($item) {
  "AppData\Roaming\Microsoft\Windows\Start Menu" {$startMenuFound = $true}
  }
}
if ($startMenuFound -eq $false) { "recommend adding 'AppData\Roaming\Microsoft\Windows\Start Menu' to " + $polName }

#
# Let's check a policy - SyncFileList
#
$polName = "SyncFileList"
$pol = GetPolicyListSetting -regName $polName
$polName + ":"
$pol

ValidateList -list $pol -policyName $polName

#
# Let's check a policy - InclusionListRegistry
#
$polName = "InclusionListRegistry"
$pol = GetPolicyListSetting -regName $polName
$polName + ":"
$pol

ValidateList -list $pol -policyName $polName

#
# Let's check a policy - ExclusionListRegistry
#
$polName = "ExclusionListRegistry"
$pol = GetPolicyListSetting -regName $polName
$polName + ":"
$pol

ValidateList -list $pol -policyName $polName

#
# Let's check a policy - SyncExclusionListDir
#
$polName = "SyncExclusionListDir"
$pol = GetPolicyListSetting -regName $polName
$polName + ":"
$pol

ValidateList -list $pol -policyName $polName

#
# Now compare the actual list with the recommended list
#
"--------------------------------------------------------"
"Compare Folder exclusion list with Citrix recommendation"
"--------------------------------------------------------"
$exclusionAnalysis = CompareLists -preferredList $recommendedSyncExclusionListDir -specimenList $pol

$exclusionAnalysis | foreach {
  $item = $_
  $diff = ($item.Difference).PadRight(10)
  $lineItem = $item.LineItem
  "$diff : $lineItem"
  Add-PolicyListRecord -PolicyName $polName -ProfileType $item.ComparisonType -DifferenceType $item.Difference -Value $item.LineItem
}

#
# while the above comparison is useful, we can also alert if we find specific apps or services
# in the environment, and these need to be flagged with more emphasis
#
"--------------------------------------------------------"
"Compare Folder exclusion list with env detections       "
"--------------------------------------------------------"
if ($mandatorySyncExclusionListDir.Length -ne 0) {
  $exclusionAnalysis = CompareLists -preferredList $mandatorySyncExclusionListDir -specimenList $pol

  $exclusionAnalysis | foreach {
    $item = $_
    $lineItem = $item.LineItem
    switch ($item.Difference) {
      "Missing" {
          # we only care about missing items (but we care very much!)
          "*** Warning: Policy $polName is missing '$lineItem'" | CaptureRecommendations -PolicyName $polName -Reason "An application, service or OS level has been detected that requires an entry in the $polName policy.  Incorrect application or service behaviour may occur."
        }
    }
  }
}

#Excluded files: 2010-06-02;23:39:48.871;ERROR;CSCSOLUTIONS;jmacioci;0;3088;DeleteAnyFile: Deleting the file <C:\documents and settings\jmacioci\Local Settings\Application Data\VMware\hgfs.dat> failed with: The process cannot access the file because it is being used by another process.
# See also: http://support.citrix.com/proddocs/topic/user-profile-manager-sou/upm-using-with-vmware.html
#
# Let's check a policy - SyncExclusionListFiles
#

$profileRoot = dir env: | foreach { if ($_.Name -eq "USERPROFILE") { $_.Value } }
$charsToRemove = [string]$profileRoot.Length
$charsToRemove = 1 + $charsToRemove
$local = dir env: | foreach { if ($_.Name -eq "LOCALAPPDATA") { $_.Value } }
$vmfile = Get-ChildItem $local -recurse -ea SilentlyContinue | foreach {
  if ($_.Name -eq "hgfs.dat") {
    $_.FullName
  }
}

if ($null -ne $vmfile) {
  $vmexclude = [string]$vmfile.Remove(0,$charsToRemove)
}

$polName = "SyncExclusionListFiles"
$pol = GetPolicyListSetting -regName $polName
$polName + ":"
$pol

ValidateList -list $pol -policyName $polName

$vmwareToolsExclusionFound = $false
if ($null -ne $vmexclude) {
  $pol | foreach { 
    $item = $_
    switch ($item) {
    $vmexclude {$vmwareToolsExclusionFound = $true}
    }
  }
}

if (($vmwareToolsExclusionFound -eq $false) -and ($hypervisor -eq "VMWare")) {
  if ($vmexclude -ne $null) {
    "*** recommend adding '" + $vmexclude + "' to " + $polName | CaptureRecommendations -PolicyName $polName -Reason "Failure to exclude this path can result in the profile being locked during logoff, leading to data loss.  See http://support.citrix.com/proddocs/topic/user-profile-manager-sou/upm-using-with-vmware.html ."
  } else {
    "*** recommend adding hgfs.dat to " + $polName | CaptureRecommendations -PolicyName $polName -Reason "Failure to exclude this path can result in the profile being locked during logoff, leading to data loss.  See http://support.citrix.com/proddocs/topic/user-profile-manager-sou/upm-using-with-vmware.html .  Note that this system does not appear to contain an hgfs.dat file.  Locate the file manually and add it to the $polName policy."
  }
}


########################################################################################
#
# Question 7: The "don't touch" settings
#
# "dead" options
#
########################################################################################

"-----------------------------------------"
"- Checking The 'don't touch' settings   -"
"-----------------------------------------"

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking PSUserGroupsList             /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
#
# for this release, simply report what is configured, though for future releases
# we should expand the group(s) and report on the number of users in the group(s)
#

$polName = "PSUserGroupsList"
$pol = GetPolicyListSetting -regName $polName
$polName + ":"
$pol

ValidateList -list $pol -policyName $polName

$polcount = Get-ListItemCountRaw -list $pol
if ($polcount -ne 0) { "*** PSUserGroupsList has been set.  This policy may be deprecated in future releases." | CaptureRecommendations -PolicyName $polName -Reason "However, UPM will still operate correctly." }
#BUG0433025: the policy is not deprecated in Bruin

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking PSPendingLockTimeout         /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

#
# Let's check a policy - PSPendingLockTimeout
#
$polName = "PSPendingLockTimeout"
$pol = GetPolicyGeneralSetting -policyName $polName
$polName + " = " + $pol
if ( $null -ne $pol ) {
  "*** Warning: PSPendingLockTimeout should not be set" | CaptureRecommendations -PolicyName $polName -Reason "this setting should not be set, unless explicitly requested by authorized Citrix support personnel"
}

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking LoadRetries                  /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

#
# Let's check a policy - LoadRetries
#
$polName = "LoadRetries"
$pol = GetPolicyGeneralSetting -policyName $polName
$polName + " = " + $pol
if ( $null -ne $pol ) {
  "*** Warning: LoadRetries should not be set" | CaptureRecommendations -PolicyName $polName -Reason "this setting should not be set, unless explicitly requested by authorized Citrix support personnel"
}


########################################################################################
#
# Question 8: UPM Logging
#
# File size and folder location.  ACLs?
#
# If persistent, then we can use the default location
# If provisioned, then use the special persistent location provided by PVS (MCS?)
#   or send the logging "off-box" to a network location
#
# If workstation then default size should be OK
# If server, then suggest increasing above default
#
# Just report the individual settings, except that if we're actually logging
# and any settings are disabled, then warn that we may not be collecting all logging
#
########################################################################################

"-----------------------------------------"
"- Checking UPM Logging                  -"
"-----------------------------------------"
                    # FlagName                          Default
$logLevelFlags = @( @("LogLevelActiveDirectoryActions", 0),
                    @("LogLevelFileSystemActions",      0),
                    @("LogLevelFileSystemNotification", 0),
                    @("LogLevelInformation",            1),
                    @("LogLevelLogoff",                 1),
                    @("LogLevelLogon",                  1),
                    @("LogLevelPolicyUserLogon",        0),
                    @("LogLevelRegistryActions",        0),
                    @("LogLevelRegistryDifference",     0),
                    @("LogLevelUserName",               1),
                    @("LogLevelWarnings",               1)
)

$allFlagsSet = $true
for ($ix = 0; $ix -lt $logLevelFlags.Length; $ix++) {
  $logFlag = $logLevelFlags[$ix]
  $logFlagName = $logFlag[0]
  $logFlagDefault = $logFlag[1]
  $logSetting = GetEffectivePolicyFlag -policyName $logFlagName -defaultSetting $logFlagDefault
  if ($logSetting.Value -eq 0) {
    $allFlagsSet = $false
  }
}

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking LoggingEnabled (and flags)   /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

$polName = "LoggingEnabled"
$loggingEnabled = GetEffectivePolicyFlag -policyName $polName -defaultSetting 0

if (($loggingEnabled.Value -eq 1) -and ($allFlagsSet -eq $false)) {
  #
  # warn that we're running logging with some flags not set
  "*** Some UPM log flags are not set, but logging is enabled" | CaptureRecommendations -PolicyName $polName -Reason "When troubleshooting UPM, Citrix recommends collecting all logging events, unless specifically advised by Citrix Support staff."
}

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking MaxLogSize                   /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

$polName = "MaxLogSize"
$maxLogSizeDefault = 1048576
if ($IsWorkstation) {
  $maxLogSizePreferred = 1048576
  $maxLogText = "workstation"
} else {
  $maxLogSizePreferred = 10485760
  $maxLogText = "server"
}
$logFileSize = GetEffectivePolicyFlag -policyName $polName -defaultSetting $maxLogSizeDefault -AsNumber
$lfs = $logFileSize.Value
if ($lfs -lt $maxLogSizePreferred) {
  #
  # warn that the logfile size might be on the small side
  "*** UPM log size set too low ($lfs)" | CaptureRecommendations -PolicyName $polName -Reason "For $maxLogText environments, a minimum value of $maxLogSizePreferred is recommended."
}

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking PathToLogFile                /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

$sysRoot = $env:SystemRoot
$polName = "PathToLogFile"
$logPathDefault = "$sysRoot\System32\Logfiles\UserProfileManager"
$logPathPreferred = $logPathDefault
$reason = "When running UPM in a physical environment, it is recommended to save log files in the Windows log file folder ($logPathDefault) or on a network share.  This will enable logs to be easily collected."
if ($prov -ne $physical) {
  $logPathPreferred = "c:\Program Files\Citrix\PvsVm\Service\PersistedData\"
  $reason = "When running UPM in a provisioned environment, it is recommended to save log files in a persistent location, provided by Citrix PVS or MCS, or to a network location.  This will prevent logs being lost in the event of a serious failure."
}
if ($null -ne $vdiInfo) {
  if ([string]$vdiInfo.PersistentDataLocation -ne "") {
    $logPathPreferred = $vdiInfo.PersistentDataLocation
  }
}

$logPathPreferred = $logPathPreferred -replace "\\$",""

$logFilePath = GetEffectivePolicyFlag -policyName $polName -defaultSetting $logPathDefault
$lfp = $logFilePath.Value -replace "\\$",""

switch -regex ($lfp) {
"\\\\\w+\\.*" {
    #
    # off-box location
    write-host "Off-box location specified: $lfp"
  }
{ $_ -eq $logPathPreferred } {
    #
    # matches preferred path
    write-host "Preferred path matched: $lfp"
  }
default {
    #
    # doesn't match default
    "*** Warning: PathToLogFile ($lfp) does not match preferred path ($logPathPreferred)" | CaptureRecommendations -PolicyName "" -Reason $reason
  }
}

########################################################################################
#
# Question 9: Miscellaneous checks
#
# Anything not covered - support list topics?
#
########################################################################################

"-----------------------------------------"
"- Checking Cookies                      -"
"-----------------------------------------"

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking ProcessCookieFiles           /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

#
# Let's check a policy - ProcessCookieFiles
#
$polName = "ProcessCookieFiles"
PreferPolicyFlag -policyName $polName -defaultSetting 0 -preferredSetting 1 -Reason "Citrix recommends this setting to help manage cookie bloat"

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking MirrorFoldersList            /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

$polName = "MirrorFoldersList"
$pol = GetPolicyListSetting -regName $polName
$polName + ":"
$pol

ValidateList -list $pol -policyName $polName

# Calculate the preferred cookie folder and note it
$cookieFolder = Get-IECookieFolder
"Recommended Internet Explorer Cookie Folder = " + $cookieFolder
Replace-PolicyRecordProperty -PolicyName $polName -PropertyName PreferredValue -NewValue $cookieFolder

$polcount = Get-ListItemCountRaw -list $pol
if (($polcount -eq 0) -and ($pilot -eq $false)) { "*** MirrorFoldersList not set in production environment." | CaptureRecommendations -PolicyName $polName -Reason "You should set this policy to include the IE cookies folder: $cookieFolder" }

if ($polcount -gt 0) {
  $polmatch = 0
  for ($ix = 0; $ix -lt $polcount; $ix++) {
    $folder = ([array]$pol)[$ix]
    # "Folder:" + $folder + ":"
    if ($folder -eq $cookieFolder) {
      $polmatch += 1
    } else {
      # also check if folder is subfolder of cookie folder
      if ($folder.Length -gt $cookieFolder.Length) {
        $folderstart = $folder.Substring(0,$cookieFolder.Length)
        if ($folderstart -eq $cookieFolder) {
          "*** ERROR in folder name: " + $folder + " : do not specify subfolders of the Cookie folder in MirrorFoldersList" | CaptureRecommendations -PolicyName $polName -Reason "UPM will perform any management of subfolders required.  Configuration of a cookie folder and a subfolder caused issues in older versions of UPM"
        }
      }
    }
  }
  if ($polmatch -ne 1) {
    "*** Cookie folder ( $cookieFolder ) should be specified exactly once.  It has been specified $polmatch times." | CaptureRecommendations -PolicyName $polName -Reason "This causes errors in older UPM versions."
  } else {
    "Cookie folder ( $cookieFolder )is included once in MirrorFoldersList"
  }
}
"-----------------------------------------"
"- Miscellaneous checks                  -"
"-----------------------------------------"

"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"
"/ Checking environment inconsistencies  /"
"/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/"

filter sumProfile ($RootFolder) {
  begin {
    $totalFiles = 0
    $totalFolders = 0
    $totalSize = 0
  }
  process {
    if ($_.PSIsContainer) {
      $totalFolders++
    } else {
      $totalFiles++
      $totalSize += $_.Length
    }
  }
  end {
    $ts = ConvenientBytesString $totalSize
    ReportEnvironment "UpmProf" "Profile Location" $RootFolder
    ReportEnvironment "UpmProf" "Total Folders"    $totalFolders
    ReportEnvironment "UpmProf" "Total Files"      $totalFiles
    ReportEnvironment "UpmProf" "Total Size"       $ts
  }
}

if ($versionMajor -gt 5) {
  $userprofile = dir env: | foreach { if ($_.Name -eq "USERPROFILE") { $_.Value } }
  $mpc = Get-MountPointCount -path $userprofile
  Get-ChildItem $userprofile -Recurse -Force -ea SilentlyContinue | sumProfile -RootFolder $userprofile
  if ($mpc -ne 1) {
    "*** ERROR: " + $userprofile + " is not on the root volume of its drive.  UPM will not function." | CaptureRecommendations -PolicyName "" -Reason "UPM is designed to work with the profile volume being the root volume of a drive, and will not work if the profile volume is mounted as a subfolder of another drive."
  } else {
    #
    # report on disk usage
    $drive = $userprofile.Substring(0,2)
    Get-WmiObject Win32_LogicalDisk | where-object {$_.DeviceID -eq $drive} | foreach {
      $driveName = $_.DeviceID
      $volName = $_.VolumeName
      $freespace = ConvenientBytesString -bytes $_.FreeSpace
      $size = ConvenientBytesString -bytes $_.Size
      $freePercent = [math]::Floor(($_.FreeSpace * 100) / $_.Size)
      $driveStatus = "Profile Drive status - $driveName (Volume Name '$volName') Size = $size, Free Space = $freespace ($freePercent%)"
      ReportEnvironment "UpmProf" "Profile Drive"       $driveName
      ReportEnvironment "UpmProf" "Volume Name"         $volName
      ReportEnvironment "UpmProf" "Size"                $size
      ReportEnvironment "UpmProf" "Free Space"          $freespace
      ReportEnvironment "UpmProf" "Free Space %"        $freePercent
      # 15% was a bit arbitrary - making tpc a command-line parameter and rename to ProfileDriveThresholdPercent
      if ($freePercent -lt $ProfileDriveThresholdPercent) {
        if ($ostype -eq "Server") {
          "*** " + $driveStatus | CaptureRecommendations -PolicyName "" -Reason "Profile Drive has less than $ProfileDriveThresholdPercent% free - consider increasing the size of the Profile Drive, removing old and unused profiles using a tool such as delprof2.exe or setting DeleteCachedProfilesOnLogoff"
        } else {
          if ($pvdActive) {
            "*** " + $driveStatus | CaptureRecommendations -PolicyName "" -Reason "Profile Drive has less than $ProfileDriveThresholdPercent% free - consider increasing the size of the Personal vDisk or reducing the user's profile size"
          } else {
            "*** " + $driveStatus | CaptureRecommendations -PolicyName "" -Reason "Profile Drive has less than $ProfileDriveThresholdPercent% free - consider increasing the size of the Profile Drive or reducing the user's profile size"
          }
        }
      }
    }
  }
} else {
  "*** Unable to check for volume mount issues on Windows XP/2003" | CaptureRecommendations -PolicyName "" -Reason "Windows XP and Windows Server 2003 do not support the necessary WMI classes"
}

#
# TODO
#
# Add functionality to take a path and check whether (net) it is included or excluded
# This makes it easy to add one-liners for specific support issues
#
# Check for RingCube and suggest disabling Profile Streaming and Deleted Locally Cached Profiles on Logoff - DONE
#
# Check for whitespace and = at the end of include/exclude folders - DONE
#
# Check for use of extended synchronization on XA - not supported, see
#   http://forums.citrix.com/thread.jspa?threadID=294190&tstart=0
#
# Check for use of %appdata% in paths - not supported, see
#   http://forums.citrix.com/thread.jspa?threadID=294190&tstart=0
#
# Check for 8.3 filename support disabled - DONE
#
$longPathCheck = $false        # only care if XP / 2k3 AND 'long' install path chosen AND 8.3 file support disabled
$x8dot3disabled = 0
$regPath = "HKLM:System\CurrentControlSet\Control\FileSystem"
$valname = "NtfsDisable8Dot3NameCreation"
Get-ItemProperty $regPath -name $valName -ErrorAction SilentlyContinue | foreach {
  $x8dot3disabled = $_.NtfsDisable8Dot3NameCreation
}
"NtfsDisable8Dot3NameCreation = " + $x8dot3disabled
if ($versionMajor -eq 5) {
  switch ($x8dot3disabled) {
  0 { "8.3 filename support enabled - supported case for UPM" }
  1 { "*** WARNING  8.3 filename support disabled - you must not install UPM to a 'long' path" | CaptureRecommendations -PolicyName "" -Reason "On Windows XP and Windows Server 2003, UPM requires that each component in its installation path conforms to 8.3 filename limitations, else UPM is unable to detect logons."
      $longPathCheck = $true
    }
  default { "*** WARNING 8.3 filename support not enabled on all volumes - not supported case for UPM" | CaptureRecommendations -PolicyName "" -Reason "On Windows XP and Windows Server 2003, UPM requires that each component in its installation path conforms to 8.3 filename limitations, else UPM is unable to detect logons.  UpmConfigCheck is unable to verify this condition for all drives in your system." }
  }
} else {
  "UPM on this Windows version does not require any specific setting of NtfsDisable8Dot3NameCreation"
}

#
# Check for valid install path (normally c:\Program Files\Citrix\User Profile Manager )
#
$pathOk = $true
if ($longPathCheck) {
  $UpmFolderList = $UPMBase.Split('`\',[stringsplitoptions]::RemoveEmptyEntries)
  for ($ix = 0; $ix -lt $UpmFolderList.Length; $ix++) {
    if (($UpmFolderList[$ix]).Length -gt 8) {
      $pathOk = $false
    }
  }
  if ($pathOk -eq $false) {
    "*** ERROR - one or more components of the UPM install folder exceed 8 chars: '$UPMBase'" | CaptureRecommendations -PolicyName "" -Reason "Reinstall to a path where all folder names are 8 chars or less"
  }
}
#
# Check for inclusion of icon cache, see
#   http://forums.citrix.com/thread.jspa?threadID=262886&start=0&tstart=0 and
#   http://support.citrix.com/article/CTX123271
#

$regCount = 0
$gpoCount = 0
$hdxCount = 0
""
"The following policies were found in the Policy registry"
"========================================================"
foreach ($pair in $strPoliciesDetected.GetEnumerator()) {
  $pair.Key # + " : " + $pair.Value
  $regCount++
  $gpoCount++
}

$iniCount = 0
""
"The following policies were found in the HDX Policy registry"
"============================================================"
foreach ($pair in $strHDXPoliciesDetected.GetEnumerator()) {
  $pair.Key # + " : " + $pair.Value
  $regCount++
  $hdxCount++
}

$iniCount = 0
""
"The following policies were found in the INI file"
"================================================="
foreach ($pair in $strIniLinesDetected.GetEnumerator()) {
  $pair.Key # + " : " + $pair.Value
  $iniCount++
}

if (($gpoCount -gt 0) -and ($hdxCount -gt 0)) {
  "*** Warning: Configuration mixes GPO policies and HDX policies" | CaptureRecommendations -PolicyName "" -Reason "Citrix recommends using either GPO policies or HDX policies, but not both together in production environemnts.  Pay particular attention to registry key, file and folder lists - if you are configuring empty lists in GPO policy, non-empty lists in HDX policy may override them, leading to unexpected effects."
}

if (($regCount -gt 0) -and ($iniCount -gt 0)) {
  "*** Warning: Configuration mixes GPO/HDX policies and INI-file settings" | CaptureRecommendations -PolicyName "" -Reason "Citrix recommends using either GPO/HDX policies or INI files, but not both together in production environemnts.  Pay particular attention to registry key, file and folder lists - if you are configuring empty lists in policy, non-empty lists in INI files may override them, leading to unexpected effects."
}
""
"The following policies were checked and defaulted"
"================================================="
foreach ($pair in $strDefaultsDetected.GetEnumerator()) {
  $pair.Key # + " : " + $pair.Value
}

""
"The following policies were not checked"
"======================================="
for ($pix = 0; $pix -lt $policyDb.Length; $pix++) {
  if ($policyDb[$pix].Origin -eq "Not Checked") {
    $policyDb[$pix].Name
  }
}

function Write-Wrapped ($str) {
  switch -regex ($str) {
  "^\*\*\* " { $str }
  "^(    notes: )(.*)$" {
      $prefix = $matches[1]
      $rest = $matches[2]
      $prefixlen = $prefix.Length
      $leadingSpace = ""
      for ($ix = 0; $ix -lt $prefixlen; $ix++) {
        $leadingSpace += " "
      }
      while ($rest.Length -gt 0) {
        $outStr = $prefix
        $prefix = $leadingSpace
        # now work out how many characters we can copy without blowing 80 chars
        $max = 80 - $prefixlen         # stop when we've got 80 chars
        if ($max -gt $rest.Length) {
          $outStr + $rest
          $rest = ""
        } else {
          $splitAt = $max
          $offset = $rest.LastIndexOf(" ",$max)
          if ($offset -eq -1) {
            # not found - truncate after $max characters
            $s1 = $rest.Substring(0,$max)
            $rest = $rest.Substring($max,$rest.Length - $max)
            $outStr + $s1
          } else {
            # found - truncate after $offset+1 characters
            $offset++
            $s1 = $rest.Substring(0,$offset)
            $rest = $rest.Substring($offset,$rest.Length - $offset)
            $outStr + $s1
          }
        }
      }
    }
  }
}

if ($WriteCsvFiles) {
  #
  # Export the Policy Summary array
  #
  $policyDb     | Export-Csv $csvSinglePolicySummaryFile -NoType
  $policyListDb | Export-Csv $csvListPolicySummaryFile   -NoType
  $envLogArray  | Export-Csv $csvEnvironmentSummaryFile  -NoType
}

""
"The following items should be reviewed, as they may be sub-optimal in the detected configuration"
"================================================================================================"
foreach ($s in $errStrings) { Write-Wrapped $s }

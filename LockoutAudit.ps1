Function Extract-UserName
{
param (
   $StringData
)
   <#
    Extract the username from the log file.
     The following line of code performs several tasks.  It receives
     a multi line string that is the message data from the event.  This data
     is saved in the variable $StringData.  Since this is a [STRING] object
     we have access to the methods Split, Replace, and Trim.

    - The first operation splits the string into an array of single lines.
      This is accomplished with the "Split" method.  The `n tells the
      method to split on each new line.

    - The next operation take the contents in array index [10]

    - The "Replace" method is used to replace the part of the string that we
      do not want.  In this case, we are replacing "Account Name:" with $NULL.

    - The "Trim" method removes all leading and trailing spaces and leaves
      us with just the username.
   #>
   ((($StringData.Split("`n"))[10]).Replace("Account Name:",$Null)).Trim()
}

Function Extract-ComputerName
{
param (
   $StringData
)
   # Extract the computer name from the log file.
   Write-Output ((($StringData.Split("`n"))[13]).Replace("Caller Computer Name:",$Null)).Trim()
}

<#
.SYNOPSIS
Discovers the client that a user account was locked out on.

.DESCRIPTION
Returns the client machine which has locked out a user account.
See the NOTEs section for setup information.

.PARAMETER $User
The Name of the User Account that you want to discover the client
that locked this account out.

.PARAMETER $DaysToSearch
This is the number of days to look back in the security logs.
The default setting is 14 days.

.EXAMPLE
Find-LockingClients -user jyoder

UserName                      LockingClient                TimeLocked
--------                      -------------                ----------
jyoder                        LON-CL1                      8/27/2012
7:02:06 PM
jyoder                        LON-CL1                      8/28/2012
8:53:42 PM

Returns the clients where the user account -jyoder was locked out.

.EXAMPLE
Find-LockingClients -User jyoder -DaysToSearch 7

Returns the clients where the user account -jyoder was locked out.
This will search the security logs for the past 7 days. 
The default is 14 days.


.NOTES
For the cmdlet to work, advanced auditing needs to be configured
on the domain controllers. This can be configured locally or in
Group Policy.  It must be done for all Domain Controllers.

Category: Account Management
Subcategory: User Account Management
Audit for: Success

#>
Function Find-LockingClients
{
Param(
    [cmdletbinding()]
    [Parameter(Mandatory=$True)][String]$User = $(Read-Host "Provide a user name"),
    [int]$DaysToSearch = 14


)
   # Get a list of all of the Domain Controllers
   $DCs = Get-ADComputer -Filter * `
    -SearchBase "OU=Domain Controllers,$((Get-ADDomain).distinguishedName)"



   # Set up the number of days to search in the past.
   $StartTime = (Get-Date).AddDays(-($DaysToSearch))

   # Create the hash for the event logs.
   $LogHash = @{LogName = 'Security';StartTime = $StartTime; ID=4740}


   # Store each relevant event in the variable $Events.
    ForEach($Item in $DCs)
     {

      # Error handling just in case Domain Controllers
      # are offline.
      Try
       {
          Write-Host "Gathering events from"$Item.Name-ForegroundColor Green `
           -BackgroundColor DarkMagenta
          $Events = Get-WinEvent -FilterHashtable $LogHash `
          -ComputerName $Item.Name -ErrorAction Stop |
          Sort-Object -Property TimeCreated
       }
      Catch
      {
       
           Write-host "Domain Controller"$Item.Name" is unreachable" `
           -ForegroundColor Red `
           -BackgroundColor DarkRed
       }
      Finally
       {
            Write-Host $Item.Name"completed" -ForegroundColor Green `
            -BackgroundColor DarkMagenta
       }
     }



   # Set up the array to hold multiple sets of data from the event logs.
   $EventArray = @()

   ForEach ($Event in $Events)
    {
       # Send the event message data to the functions to extract
       # Username and Computer Name.
       $UserName = Extract-UserName $Event.Message
       $ComputerName = Extract-ComputerName $Event.Message

     
       # Write the data to the object.
       $Obj = New-Object -TypeName PSObject
       $Obj |Add-Member -MemberType NoteProperty -Name "UserName" -Value $UserName
       $Obj |Add-Member -MemberType NoteProperty -Name "LockingClient" -Value $ComputerName
       $Obj |Add-Member -MemberType NoteProperty -Name "TimeLocked" -Value $Event.TimeCreated
     
       # Add the individual object to the array of objects.
       $Obj | Where-Object {$_.Username -eq $User}

    }

   # Filter for the user specified in the parameter $User and
   # Send the output into the Pipeline.
  #$EventArray |Where-Object {$_.UserName -eq $User}


}

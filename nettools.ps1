<#
NET TOOLS - a collection of system managment tools using Powershell remoting
 
Credits:                                                       
Felipe Binotto   - Thx Felipe    
"LocalAdminPwd" section added (Requires LAPS CSE to be installed) - MRJ Aug2015 
"Computer Description" section added (Requires RSAT) - MRJ Apr2017
Removed "Computer Description" and added "Disk Space" and "Server Info" options - MRJ Aug2018
    - "Server Info" lists AD description, OU, OS version, OS build number, OS architecture and processor architecture
Added "IP Address" and "Who's Logged On" options - MRJ Aug2018
    - Lists computer name, IPv4 address, whether DHCP is endabled, SM, GW, DNS servers & MAC address

#>
Import-Module ActiveDirectory

# This function retrieves IP address configuration from a computer
Function Get-IPv4Info {
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName = $env:computername
    )            

    begin {}
    process {
        foreach ($Computer in $ComputerName) {
            if (Test-Connection -ComputerName $Computer -Count 1 -ea 0) {
                $Networks = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer | Where-Object {$_.IPEnabled}
                foreach ($Network in $Networks) {
                    $IPAddress = $Network.IpAddress[0]
                    $SubnetMask = $Network.IPSubnet[0]
                    $DefaultGateway = $Network.DefaultIPGateway
                    $DNSServers = $Network.DNSServerSearchOrder
                    $IsDHCPEnabled = $false
                    If ($network.DHCPEnabled) {
                        $IsDHCPEnabled = $true
                    }
                    $MACAddress = $Network.MACAddress
                    $OutputObj = New-Object -Type PSObject
                    $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()
                    $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
                    $OutputObj | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $SubnetMask
                    $OutputObj | Add-Member -MemberType NoteProperty -Name Gateway -Value $DefaultGateway
                    $OutputObj | Add-Member -MemberType NoteProperty -Name IsDHCPEnabled -Value $IsDHCPEnabled
                    $OutputObj | Add-Member -MemberType NoteProperty -Name DNSServers -Value $DNSServers
                    $OutputObj | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MACAddress
                    $OutputObj
                }
            }
        }
    }            
}
# This function provides disk space statistics
function Get-DiskStats {
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string]$ComputerName
)
Write-Host $ComputerName -ForegroundColor Black  -BackgroundColor Cyan
get-wmiobject -computer $ComputerName win32_logicaldisk -filter "drivetype=3" | ForEach-Object `
{ 
	Write-Host Device name : $_.deviceid "(" $_.VolumeName ")" -BackgroundColor Black ; write-host Total Space : ($_.size/1GB).tostring("0.00")GB; write-host Free Space : ($_.freespace/1GB).tostring("0.00")GB
}
}

# This function Uses WMI to retrieve details from target
function Get-ServerInfo {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [Alias('name')]
        [string[]]$computername,
        [string]$logfile = 'failed.txt'
    )
    BEGIN {
        Remove-Item $logfile -ea SilentlyContinue
    }
    PROCESS {
        foreach ($computer in $computername) {
            $continue = $true
            try {
                $os = Get-WmiObject -class Win32_OperatingSystem `
                 -computer $computer -ea Stop
            } catch {
                $computer | out-file $logfile -append
                $continue = $false
            }
            if ($continue) {
                $bios = Get-WmiObject -class Win32_BIOS `
                 -computername $computer
                $proc = Get-WmiObject -class Win32_Processor `
                 -computername $computer | Select-Object -first 1
                $hash = @{
                    'ComputerName' = $computer;
                    'BIOSSerial'=$bios.serialnumber;
                    'Description'  = get-adcomputer $computer -prop description|Select-Object -ExpandProperty description;
                    'OU' = get-adcomputer $computer -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName;  
                    'OSVersion'=$os.caption;
                    'OSBuild'=$os.buildnumber;
                    'SPVersion'=$os.servicepackmajorversion;
                    'OSArch'=$os.osarchitecture;
                    'ProcArch'=$proc.addresswidth
                }
                $obj = New-Object -TypeName PSObject -Property $hash
                Write-Output $obj
            }
        }
    }
}


# Edit This item to change the DropDown Values
[array]$DropDownArray = "Ping", "Traceroute", "NSLookup", "BIOS", "Services","Disk Space","Server Info","IP Address", "Installed Programs","Who's Logged On", "RemoteUninstall", "RemoteInstall", "LocalAdminPwd"

# This Function Returns the Selected Value and their actions then Closes the Form
function Return-DropDown {
	$Choice = $DropDown.SelectedItem.ToString()
	$Address = $Address.Text
	#$Form.Close()
        if ($choice -eq "ping") 
        {
            write-host "PING $address"
            Test-Connection $address | Out-gridview
			write-host
        }
        elseif ($choice -eq "traceroute") 
        {
            write-host "TRACEROUTE $address"
            tracert $address | Out-gridview
            write-host
        }
        elseif ($choice -eq "nslookup") 
        {
            write-host "NSLOOKUP $address"
            nslookup $address | Out-gridview
            write-host
        }    	
		elseif ($choice -eq "BIOS") 
        {
            write-host "BIOS of $address"
            Get-WmiObject win32_bios -ComputerName $address | Out-gridview
            write-host
        }   
		elseif ($choice -eq "Services") 
        {
            write-host "Services of $address"
            Get-WmiObject win32_service -ComputerName $address | Out-gridview
            write-host
        }   
        elseif ($choice -eq "Disk Space") 
        {
            Get-DiskStats -ComputerName $Address
            Write-host
            
        }   
        elseif ($choice -eq "Server Info") 
        {
            Write-host "Server Info for $address"
            Get-ServerInfo -computername $Address | Out-GridView
            
        } 
		elseif ($choice -eq "Installed Programs") 
        {
            write-host "Programs installed on $address"
            Get-WmiObject win32_product -ComputerName $address | Out-gridview
            write-host
        }    	
		elseif ($choice -eq "RemoteUninstall") 
        {
            write-host "Uninstall program on $address"
            .\remoteuninstallv2.ps1
        }   
		elseif ($choice -eq "RemoteInstall") 
        {
            write-host "Install program on $address"
            .\remoteinstall.ps1
        }

        elseif ($Choice -eq "LocalAdminPwd") # requires LAPS CSE
        {
            Import-Module AdmPwd.ps
            Get-AdmPwdPassword -ComputerName $Address | Out-GridView
            write-host
        }
        elseif ($Choice -eq "IP Address")
        {
            Write-host "Getting IP info for $address"
            Get-IPv4Info -ComputerName $address | Out-GridView
        }
        elseif ($Choice -eq "Who's Logged On")
        {
            invoke-command -ComputerName $address -ScriptBlock {quser.exe} | Out-GridView
        }
			}
#}

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$Form = New-Object System.Windows.Forms.Form

$Form.width = 300
$Form.height = 250
$Form.Text = "Network Tools"
$Form.maximumsize = New-Object System.Drawing.Size(300,250)
$Form.startposition = "centerscreen"
$Form.KeyPreview = $True
$Form.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {return-dropdown}})
$Form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})



$DropDown = new-object System.Windows.Forms.ComboBox
$DropDown.Location = new-object System.Drawing.Size(100,10)
$DropDown.Size = new-object System.Drawing.Size(130,30)

ForEach ($Item in $DropDownArray) {
	$DropDown.Items.Add($Item)
}

$Form.Controls.Add($DropDown)


$DropDownLabel = new-object System.Windows.Forms.Label
$DropDownLabel.Location = new-object System.Drawing.Size(10,10)
$DropDownLabel.size = new-object System.Drawing.Size(100,20)
$DropDownLabel.Text = "Command"
$Form.Controls.Add($DropDownLabel)

$Button = new-object System.Windows.Forms.Button
$Button.Location = new-object System.Drawing.Size(100,150)
$Button.Size = new-object System.Drawing.Size(100,20)
$Button.Text = "OK"
$Button.Add_Click({Return-DropDown})
$form.Controls.Add($Button)

$address = new-object System.Windows.Forms.TextBox
$address.Location = new-object System.Drawing.Size(100,100)
$address.Size = new-object System.Drawing.Size(100,20)

$Form.Controls.Add($address)

$addresslabel = new-object System.Windows.Forms.Label
$addresslabel.Location = new-object System.Drawing.Size(10,100)
$addresslabel.size = new-object System.Drawing.Size(100,20)
$addresslabel.Text = "Computer"
$Form.Controls.Add($addresslabel)

$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()
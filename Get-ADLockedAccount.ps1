<#
.SYNOPSIS
	List all user accounts locked out of the current domain
	
.NOTES
	Author		: Alexandre Augagneur (www.alexwinner.com)
	File Name	: Get-ADAccountLockedOut.ps1
	
.EXAMPLE
	.\Get-ADLockedAccount.ps1
	
.PARAMETER DomainName
	Name of the specific domain

.PARAMETER UnlockAll
	Unlock all locked accounts found
#>

param (	
	[Parameter()]
	[String] $DomainName,
	
	[Parameter()]
	[switch] $UnlockAll
)

#Region Variables
####################################################
# Variables
####################################################
$ADSearcher = New-Object System.DirectoryServices.DirectorySearcher
$ADSearcher.PageSize = 1000
$isPSOExist = $false
$ComputeLockoutTime = $false
$ADS_UF_LOCKOUT = 16

#EndRegion

#Region Main
####################################################
# Main
####################################################

try
{
	if ($DomainName)
	{
		# Connect to the specific domain
		$DomainContext = new-object System.directoryServices.ActiveDirectory.DirectoryContext("Domain",$DomainName)
		$objDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
	}
	else
	{
		# Connect to the current domain
		$objDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
	}

	# Try to connect to the PDC Emulator
	if ( [ADSI]::Exists("LDAP://$($objDomain.PDCRoleOwner)") )
	{
		# Connect to the PDC Emulator
		$objDeDomain = [ADSI] "LDAP://$($objDomain.PDCRoleOwner)"
		
		# Get Domain Functional Level of the current domain (http://msdn.microsoft.com/en-us/library/cc223742.aspx)
		$BehaviorVersion = [int] $objDeDomain.Properties['msds-behavior-version'].item(0)
		
		# Check if PSOs are existing in the current domain
		if ( $BehaviorVersion -ge 3 )
		{
			Write-Verbose "Current domain is compatible with Fine-Grained Password Policy."
			
			$ADSearcher.SearchRoot = $objDeDomain
			$ADSearcher.Filter = "(objectclass=msDS-PasswordSettings)"
			$PSOs = $ADSearcher.FindAll()
			
			if ( $PSOs.Count -gt 0 )
			{	
				$isPSOExist = $true
				Write-Verbose "Number of Fine-Grained Password Policies found: $($PSOs.Count)"
			}
			else
			{
				Write-Verbose "No Fine-Grained Password Policies found."
			}
		}
		# Check if users account can be locked out in the domain
		elseif ($objDeDomain.lockoutThreshold -gt 0 )
		{
			$DomainLockoutDuration = $objDeDomain.ConvertLargeIntegerToInt64($objDeDomain.Properties.lockoutduration.Value)
			
			# No need to compute the lockoutTime attribute
			if ( -$DomainLockoutDuration -gt [datetime]::MaxValue.Ticks )
			{
				Write-Verbose "Accounts are not unlocked automatically."
			}
			# Enabling the compute of the lockout time
			else
			{
				$ComputeLockoutTime = $true
			}
		}
	
		# No need to treat user accounts (no account lockout policy)
		if ( !($ComputeLockoutTime) -and !($isPSOExist) )
		{
			Write-Host "No account lockout policy found in the domain."
			Exit
		}
		
		# Collect user accounts with a lockouttime attribute greater than 0
		$ADSearcher.SearchRoot = $objDeDomain
		$ADSearcher.Filter = "(&(objectCategory=person)(objectClass=user)(lockoutTime>=1))"
		$Users = $ADSearcher.FindAll()
		
		# Determine the time limit for the lockouttime attribute of each user
		$CurrentDateTFT = (Get-Date).ToFileTimeUtc()
		$LockoutTimeLimit = $CurrentDateTFT + $DomainLockoutDuration
		
		if ( $Users.Count -eq 0 )
		{
			Write-Host "No locked account found in the domain."
		}
		else
		{
			$i = 0
			
			# Treatment of each user
			foreach ( $User in $Users )
			{
				if ( @('Guest','Administrator') -notcontains $User.Properties['samaccountname'] )
				{
					if ( $isPSOExist )
					{
						# PSOs applied to user = call the msds-user-account-control-computed attribute
						if ( $User.Properties['msds-psoapplied'].Count -ge 1 )
						{
							$DeUser = $User.GetDirectoryEntry()
							$DeUser.RefreshCache("msds-user-account-control-computed")

							# Return the value of msds-user-account-control-computed
							$UserAccountFlag = $DeUser.Properties["msds-user-account-control-computed"].Value
							
							if ( $UserAccountFlag -band $ADS_UF_LOCKOUT )
							{
								$isLocked = $true
								$i++
							}
						}
						else
						{
							# No PSOs applied to user = use the lockoutTime
							if ($User.Properties['lockouttime'] -gt $LockoutTimeLimit )
							{ 
								$isLocked = $true
								$i++
							}
						}
					}
					else
					{
						# No PSOs applied to user = use the lockoutTime
						if ($User.Properties['lockouttime'] -gt $LockoutTimeLimit )
						{
							$isLocked = $true
							$i++
						}
					}
					
					if ( $isLocked ) 
					{ 
						Write-host "$($User.Properties['samaccountname']): " -NoNewline
						Write-host "locked" -ForegroundColor Yellow
					}
					
					# Unlock account
					if ( $isLocked -and $UnlockAll )
					{
						Write-host "$($User.Properties['samaccountname']): " -NoNewline
						
						try
						{
							if ( -not($DeUser) )
							{
								$DeUser = $User.GetDirectoryEntry()
							}
							else
							{
								$DeUser.Put('lockouttime',0)
								$DeUser.SetInfo()
							}
							
							Write-host "unlocked" -ForegroundColor Green
						}
						catch
						{
							Write-host "unable to unlock" -ForegroundColor Red
						}
						
						$DeUser = $null
					}
				
					$isLocked = $false
				}
			}
			
			Write-Host "Locked accounts: " -NoNewline
			Write-Host $i -ForegroundColor Magenta
		}
	}
	else
	{
		Write-Host "Unable to connect to the PDC Emulator $($objDomain.PDCRoleOwner)" -ForegroundColor Red
	}
}
Catch
{
	Write-Host "$($_.Exception.Message)" -ForegroundColor Red
}
#EndRegion
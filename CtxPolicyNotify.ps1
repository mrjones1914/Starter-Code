<#
Set-MonitorNotificationEmailServerConfiguration -ProtocolType SMTP -ServerName e-mail.redgold.com -PortNumber 25 -SenderEmailAddress mjones@redgold.com -RequiresAuthentication 0

Set-MonitorNotificationEmailServerConfiguration -ProtocolType SMTP -ServerName NameOfTheSMTPServerOrIPAddress -PortNumber PortNumber -SenderEmailAddress EmailAddressFromWhichDirectorShouldSendAnEmailWhenThereIsAnAlert -RequiresAuthentication 1 -Credential “SenderEmailAddressUserNameAsPerYourExchangeServerOrAD”

Set-MonitorNotificationEmailServerConfiguration -ProtocolType SMTP -ServerName NameOfTheSMTPServerOrIPAddress -PortNumber PortNumber -SenderEmailAddress EmailAddressFromWhichDirectorShouldSendAnEmailWhenThereIsAnAlert -RequiresAuthentication 0
#>

asnp Citrix*

# Add Parameters

$timeSpan = New-TimeSpan -Seconds 30

$alertThreshold = 1

$alarmThreshold = 2

# Add Target UID’s:
## dd1e7ae9-5cd4-4d5e-bdfb-9d3cc77ec2ec = Base Applications
## 07761848-46ce-4bee-9aa0-95f7fdc99f9d = Business Applications
## 40b82f77-2299-433d-9b29-292933d68c7b - Standard Desktop


$targetIds = @()

$targetIds += “dd1e7ae9-5cd4-4d5e-bdfb-9d3cc77ec2ec”

# Add email addresses

$emailaddress = @()

$emailaddress += “mjones@redgold.com”

# Create new policy

$policy = New-MonitorNotificationPolicy -Name “MyTestPolicy” -Description “Policy created to test new cmdlets” -Enabled $true

Add-MonitorNotificationPolicyCondition -Uid $policy.Uid -ConditionType SessionsConcurrentCount -AlertThreshold $alertThreshold -AlarmThreshold $alarmThreshold  -AlertRenotification $timeSpan -AlarmRenotification $timeSpan

Add-MonitorNotificationPolicyCondition -Uid $policy.Uid -ConditionType SessionsPeakconnectedCount -AlertThreshold $alertThreshold -AlarmThreshold $alarmThreshold -AlertRenotification $timeSpan -AlarmRenotification $timeSpan

Add-MonitorNotificationPolicyTargets -Uid $policy.Uid -Scope “My Test Targets” -TargetKind DesktopGroup -TargetIds $targetIds

Add-MonitorNotificationPolicyEmailAddresses -Uid $policy.Uid -EmailAddresses $emailaddress -EmailCultureName “en-US”

$policy = Get-MonitorNotificationPolicy -Uid $policy.Uid

$policy
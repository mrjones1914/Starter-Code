$remoteserver = 'S007239'
$emaildomain = 'redgold.com'
$HubServers = get-exchangeserver | where { $_.ServerRole -match "HubTransport" }
$HubServers | new-ReceiveConnector -Name 'Relay' -Usage 'Custom' -Bindings '0.0.0.0:25' -Fqdn 'redgold.com' -RemoteIPRanges '10.0.0.1' -AuthMechanism ExternalAuthoritative -PermissionGroups ExchangeServers,AnonymousUsers
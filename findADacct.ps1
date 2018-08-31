$ldap = '(&(objectClass=computer)(samAccountName=mj*))'
$searcher = [adsisearcher]$ldap

$searcher.FindAll()
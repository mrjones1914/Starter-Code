﻿Get-ADGroup –Filter * -Properties Members | where { $_.Members.Count –eq 0 } |select groupcategory,samaccountname >c:\temp\nomembers.csv
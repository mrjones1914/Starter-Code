﻿    <#
        [Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-Warning "You are not running this as a domain administrator. Run it again in an elevated prompt."
	    Break
    }
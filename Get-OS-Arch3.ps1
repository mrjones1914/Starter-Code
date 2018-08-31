function Get-OSArchitecture {            
[cmdletbinding()]            
param(            
    [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]            
    [string[]]$ComputerName = $env:computername                        
)            

begin {}            

process {            

 foreach ($Computer in $ComputerName) {            
  if(Test-Connection -ComputerName $Computer -Count 1 -ea 0) {            
   Write-Verbose "$Computer is online"            
   $OS  = (Get-WmiObject -computername $computer -class Win32_OperatingSystem ).Caption            
   if ((Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer -ea 0).OSArchitecture -eq '64-bit') {            
    $architecture = "64-Bit"            
   } else  {            
    $architecture = "32-Bit"            
   }            

   $OutputObj  = New-Object -Type PSObject            
   $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()            
   $OutputObj | Add-Member -MemberType NoteProperty -Name Architecture -Value $architecture            
   $OutputObj | Add-Member -MemberType NoteProperty -Name OperatingSystem -Value $OS            
   $OutputObj            
  }            
 }            
}            

end {}            

}
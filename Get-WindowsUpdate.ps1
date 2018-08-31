function Get-WindowsUpdate
{
  [CmdletBinding()]
  param
  (
    [String[]]
    $ComputerName,
    $Title = '*',
    $Description = '*',
    $Operation = '*'
  )
  
  $code = {
    param
    (
      $Title,
      $Description
    )


    $Type = @{
      name='Operation'
      expression={
    
    switch($_.operation)
    {
            1 {'Installed'}
            2 {'Uninstalled'}
            3 {'Other'}
    }
 }
}
    
    
    $Session = New-Object -ComObject 'Microsoft.Update.Session'
    $Searcher = $Session.CreateUpdateSearcher()
    $historyCount = $Searcher.GetTotalHistoryCount()
    $Searcher.QueryHistory(0, $historyCount) | 
    Select-Object Title, Description, Date, $Type |
    Where-Object { $_.Title -like $Title } |
    Where-Object { $_.Description -like $Description } |
    Where-Object { $_.Operation -like $Operation }
  }

  $null = $PSBoundParameters.Remove('Title')
  $null = $PSBoundParameters.Remove('Description')
  $null = $PSBoundParameters.Remove('Operation')

  Invoke-Command -ScriptBlock $code @PSBoundParameters -ArgumentList $Title, $Description
}
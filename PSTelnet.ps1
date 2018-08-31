## PowerShell: Script To Telnet To Remote Hosts And Run Commands Against Them With Output to console
## Overview: Useful for Telnet connections to Cisco Switches and other devices. 
##           Customized to return data to PRTG via an EXE/Advanced sensor for a Citrix port 1494 ICA response code
## When creating a new sensor in PRTG for this, specify the remote server via IP address or hostname in the "Parameters" field
## If you are using this to monitor multiple computers, it's highly recommended to add a Mutex so they do not all simultaneously scan

param(
    [string] $remoteHost = "", 
    [int] $port = 1494,
    [string] $username = "",
    [string] $password = "",
    [string] $termlength = "term len 0", #Useful for older consoles that have line display limitations
    [string] $enable = "en", #Useful for appliances like Cisco switches that have an 'enable' command mode
    [string] $enablepassword = "",
    [string] $command1 = "show interface", #You can add additional commands below here with additonal strings if you want
    [int] $commandDelay = 1000
   )
 
[string] $output = ""

## Read output from a remote host
function GetOutput
{
  ## Create a buffer to receive the response
  $buffer = new-object System.Byte[] 1024
  $encoding = new-object System.Text.AsciiEncoding
 
  $outputBuffer = ""
  $foundMore = $false
 
  ## Read all the data available from the stream, writing it to the
  ## output buffer when done.
  do
  {
    ## Allow data to buffer for a bit
    start-sleep -m 1000
 
    ## Read what data is available
    $foundmore = $false
    $stream.ReadTimeout = 1000
 
    do
    {
      try
      {
        $read = $stream.Read($buffer, 0, 1024)
 
        if($read -gt 0)
        {
          $foundmore = $true
          $outputBuffer += ($encoding.GetString($buffer, 0, $read))
        }
      } catch { $foundMore = $false; $read = 0 }
    } while($read -gt 0)
  } while($foundmore)
 
  $outputBuffer
}
 
function Main
{
  ## Open the socket, and connect to the computer on the specified port

  ## Line below disabled for automated operation
  ## write-host "Connecting to $remoteHost on port $port"
 
  trap { Write-Error "Could not connect to remote computer: $_"; exit }
  $socket = new-object System.Net.Sockets.TcpClient($remoteHost, $port)
 
  ## Line below disabled for automated operation
  ## write-host "Connected. Press ^D followed by [ENTER] to exit.`n"
 
  $stream = $socket.GetStream()
 
  $writer = new-object System.IO.StreamWriter $stream

    ## Receive the output that has buffered so far
    $SCRIPT:output += GetOutput

        $writer.WriteLine($username)
        $writer.Flush()
        Start-Sleep -m $commandDelay
                $writer.WriteLine($password)
        $writer.Flush()
        Start-Sleep -m $commandDelay
                $writer.WriteLine($termlength)
        $writer.Flush()
        Start-Sleep -m $commandDelay
                $writer.WriteLine($enable)
        $writer.Flush()
        Start-Sleep -m $commandDelay
                $writer.WriteLine($enablepassword)
        $writer.Flush()
        Start-Sleep -m $commandDelay
                $writer.WriteLine($command1) #Add additional entries below here for additional 'strings' you created above
        $writer.Flush()
        Start-Sleep -m $commandDelay
        $SCRIPT:output += GetOutput
                
 
 
  ## Close the streams
  $writer.Close()
  $stream.Close()
 
  ## Test to see if string required is present in stream
  $StringPresent = $output -Match 'ICA'

  ## Output results in XML-formatted response to host console
  Write-Host "<prtg>"
  Write-Host "<result>"
  Write-Host "<channel>String Present</channel>"
  If ($StringPresent) {Write-Host "<value>1</value>"}
  Else {Write-Host "<value>0</value>"}
  Write-Host "</result>"
  Write-Host "</prtg>"
}
. Main
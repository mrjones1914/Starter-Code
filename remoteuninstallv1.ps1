##################################################################
####                                                          
####                 REMOTE UNINSTALL          
####                                                          
## Credits:                                                       
## Felipe Binotto (http://powershell.com/cs/media/p/7673.aspx)    
##################################################################
##################################################################

function listprograms {

Get-WmiObject win32_product -ComputerName $address.Text | Out-GridView

}

function remoteuninstall {

$app = Get-WmiObject win32_product -ComputerName $address.Text | Where-Object {$_.name -match $program.Text}
$returnvalue = $app.uninstall() | Select-Object -Property returnvalue
if($returnvalue.returnvalue -eq "0")
{[Windows.Forms.MessageBox]::Show("Installation was successful!")}
else{[Windows.Forms.MessageBox]::Show("Installation was not successful!")}
}


[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$Form = New-Object System.Windows.Forms.Form

$Form.width = 500
$Form.height = 350
$Form.Text = "Remote Uninstall"
$Form.backcolor = "#5D8AA8"
$Form.maximumsize = New-Object System.Drawing.Size(500, 350)
$Form.startposition = "centerscreen"
$Form.KeyPreview = $True
$Form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})

$ListButton = new-object System.Windows.Forms.Button
$ListButton.Location = new-object System.Drawing.Size(50,200)
$ListButton.Size = new-object System.Drawing.Size(130,30)
$ListButton.Text = "List Programs"
$ListButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(255, 255, 192);
$ListButton.ImageAlign = [System.Drawing.ContentAlignment]::MiddleLeft;
$Listbutton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ListButton.Add_Click({listprograms})

$Form.Controls.Add($ListButton)

$address = new-object System.Windows.Forms.TextBox
$address.Location = new-object System.Drawing.Size(65,60)
$address.Size = new-object System.Drawing.Size(100,20)

$Form.Controls.Add($address)

$addresslabel = new-object System.Windows.Forms.Label
$addresslabel.Location = new-object System.Drawing.Size(70,10)
$addresslabel.size = new-object System.Drawing.Size(100,50)
$addresslabel.Font = new-object System.Drawing.Font("Microsoft Sans Serif",12,[System.Drawing.FontStyle]::Bold)
$addresslabel.Text = "Computer"
$Form.Controls.Add($addresslabel)

$programlabel = new-object System.Windows.Forms.Label
$programlabel.Location = new-object System.Drawing.Size(270,10)
$programlabel.size = new-object System.Drawing.Size(200,50)
$programlabel.Font = new-object System.Drawing.Font("Microsoft Sans Serif",12,[System.Drawing.FontStyle]::Bold)
$programlabel.Text = "Program to Uninstall"
$Form.Controls.Add($programlabel)

$program = new-object System.Windows.Forms.TextBox
$program.Location = new-object System.Drawing.Size(300,60)
$program.Size = new-object System.Drawing.Size(100,20)


$Form.Controls.Add($program)

$UninstallButton = new-object System.Windows.Forms.Button
$UninstallButton.Location = new-object System.Drawing.Size(290,200)
$UninstallButton.Size = new-object System.Drawing.Size(130,30)
$UninstallButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(255, 255, 192);
$UninstallButton.ImageAlign = [System.Drawing.ContentAlignment]::MiddleLeft;
$UninstallButton.Text = "Uninstall"
$Uninstallbutton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$UninstallButton.Add_Click({remoteuninstall})

$viclabel = new-object System.Windows.Forms.Label
$viclabel.Location = new-object System.Drawing.Size(140,250)
$viclabel.size = new-object System.Drawing.Size(200,50)
$Form.Controls.Add($viclabel)

$Form.Controls.Add($UninstallButton)

$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()
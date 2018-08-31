##################################################################
####                 MAP DRIVE          
####             Written by Felipe Binotto    
####               Date: 19/10/10       
##################################################################
function mapdrive {

$map = New-Object -ComObject wscript.network
if($letter.Text -match ":"){
$letter = $letter.Text}
else{$letter = $letter.Text+":"}
$map.MapNetworkDrive($letter,$path.Text)

}



[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$Form = New-Object System.Windows.Forms.Form

$Form.width = 500
$Form.height = 350
$Form.Text = "Map Drive"
$Form.backcolor = "#5D8AA8"
$Form.maximumsize = New-Object System.Drawing.Size(500, 350)
$Form.startposition = "centerscreen"
$Form.KeyPreview = $True
$Form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})

$ListButton = new-object System.Windows.Forms.Button
$ListButton.Location = new-object System.Drawing.Size(200,200)
$ListButton.Size = new-object System.Drawing.Size(80,30)
$ListButton.Text = "MAP"
$ListButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(255, 255, 192);
$ListButton.ImageAlign = [System.Drawing.ContentAlignment]::MiddleLeft;
$Listbutton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ListButton.Add_Click({mapdrive})

$Form.Controls.Add($ListButton)

$letter = new-object System.Windows.Forms.TextBox
$letter.Location = new-object System.Drawing.Size(65,60)
$letter.Size = new-object System.Drawing.Size(100,20)

$Form.Controls.Add($letter)

$letterlabel = new-object System.Windows.Forms.Label
$letterlabel.Location = new-object System.Drawing.Size(60,10)
$letterlabel.size = new-object System.Drawing.Size(100,50)
$letterlabel.Font = new-object System.Drawing.Font("Microsoft Sans Serif",12,[System.Drawing.FontStyle]::Bold)
$letterlabel.Text = "Drive Letter"
$Form.Controls.Add($letterlabel)

$pathlabel = new-object System.Windows.Forms.Label
$pathlabel.Location = new-object System.Drawing.Size(310,10)
$pathlabel.size = new-object System.Drawing.Size(200,50)
$pathlabel.Font = new-object System.Drawing.Font("Microsoft Sans Serif",12,[System.Drawing.FontStyle]::Bold)
$pathlabel.Text = "UNC path"
$Form.Controls.Add($pathlabel)

$path = new-object System.Windows.Forms.TextBox
$path.Location = new-object System.Drawing.Size(300,60)
$path.Size = new-object System.Drawing.Size(100,20)


$Form.Controls.Add($path)


$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()
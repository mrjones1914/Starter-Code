Option Explicit

Dim myUserName, myNetwork, myEmail, myMessage, myAlertName, mySMTP, mySubject, mySender, myRecipient, myComputerName

'Get username of current user.
Set myNetwork = WScript.CreateObject("WScript.Network") 


'Set info for e-mail
'myAlertName: who am I looking for as a trigger?
'mySMTP: Who is my SMTP server?
'mySubject: Subject of the e-mail?
'mySender: Who is the sender of the e-mail?
'myRecipient: Who is the alert to be sent to?
myAlertName = "Administrator" 	
mySMTP = "SMTP.domain.tld"
mySubject = "Test Object"
mySender = "testobject@test.com"
myRecipient = "administrator@domain.tld"
myUserName = myNetwork.Username
myComputerName = myNetwork.ComputerName

'Check to see if the current logged on user is and if an alert should be sent out.
if (myUserName = myAlertName) Then
'Create Message
myMessage = myUserName & " Logged on to " & myComputerName & " at: " & FormatDateTime(Now(), vbGeneralDate)

Set myEmail = CreateObject("CDO.Message")
myEmail.From = mySender
myEmail.To = myRecipient
myEmail.Subject = mySubject 
myEmail.Textbody = myMessage
myEmail.Configuration.Fields.Item _
    ("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2
myEmail.Configuration.Fields.Item _
    ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = _
        mySMTP 
myEmail.Configuration.Fields.Item _
    ("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25
myEmail.Configuration.Fields.Update
myEmail.Send

End If
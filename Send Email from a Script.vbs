' Send Email from a Script


Set objEmail = CreateObject("CDO.Message")

objEmail.From = "S004969@regdold.com"
objEmail.To = "admin1@redgold.com"
objEmail.Subject = "Site server is down" 
objEmail.Textbody = "The site server is no longer accessible over the network."
objEmail.Send
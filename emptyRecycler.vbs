on error resume next

Const RECYCLE_BIN = &Ha&
Const NAME = 0
Const DATE_DELETED = 2
Const ORG_LOCATION = 1
Const DELETE_FILES_OLDER_THAN = 6
Const REDIRECTION_PATH = "\\S004425\Users"

Set objShell = CreateObject("Shell.Application")
Set objFolder = objShell.Namespace(RECYCLE_BIN)
Set fso = CreateObject("Scripting.FileSystemObject")
Set colItems = objFolder.Items

For Each objItem in colItems
   dtDateDeleted=""
   strName = objFolder.GetDetailsOf(objItem, NAME)
   strDateDeleted = objFolder.GetDetailsOf(objItem, DATE_DELETED)
   strOriginalLocation = objFolder.GetDetailsOf(objItem, ORG_LOCATION)

   for i = 1 to Len(strDateDeleted)
      strChar=Left(strDateDeleted,i)
      strChar=Right(strChar,1)
      intMatch=InStr("0123456789/:APM ", UCase(strChar))
      if intMatch>0 then dtDateDeleted=dtDateDeleted & strChar
   next

   if (Instr(LCase(strOriginalLocation), REDIRECTION_PATH)) > 0 then
      intDeletedAge=DateDiff("d", dtDateDeleted, Date)
      if intDeletedAge>DELETE_FILES_OLDER_THAN then 
         fso.DeleteFile objItem.Path, 1    
      End if
   End if
Next
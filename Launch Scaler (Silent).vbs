Set FSO      = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")

scriptDir = FSO.GetParentFolderName(WScript.ScriptFullName)
target    = scriptDir & "\vrchat_avatar_scaler.pyw"

' Launch pythonw silently (no console window, no UAC prompt needed).
WshShell.Run "pythonw """ & target & """", 0, False

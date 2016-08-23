#$path_src = "d:\mssqlbackup\"
#$path_dst = "\\192.168.0.126\Public\1CSERVER\MSSQLBackup\"

$path_src = "e:\mssqlbackup"
$path_dst = "e:\mssqlbackup_copy"
$7zpath = """c:\Program Files\7-Zip\7z.exe"""

foreach ($item in Get-ChildItem $path_src -Recurse -Include @("*.bak", "*.trn") | where {$_.Attributes -eq 'Archive'}){
    $acrcitem = $item.DirectoryName+"\"+$item.BaseName+".7z"

    $item.Attributes = 'Normal'

    $args = "u -mx "+$acrcitem+" "+$item.FullName
    Start-Process $7zpath $args -Wait
}

#$robocopyrun = "robocopy $path_src $path_dst *.7z /S /W:3 /R:3 /MOV"
Start-Process "robocopy" "$path_src $path_dst *.7z /S /W:3 /R:3 /MOV" -Wait
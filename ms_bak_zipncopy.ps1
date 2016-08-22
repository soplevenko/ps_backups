#$path_src = "d:\mssqlbackup\"
#$path_dst = "\\192.168.0.126\Public\1CSERVER\MSSQLBackup\"

$path_src = "f:\mssqlbackup\"
$path_dst = "f:\mssqlbackup_copy\"

foreach ($item in Get-ChildItem $path_src -Recurse -Include @("*.bak", "*.trn") -Attributes !Archive){

}
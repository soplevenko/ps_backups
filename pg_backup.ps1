$dump_exe = """c:\Program Files\PostgreSQL\9.2.4-1.1C\bin\pg_dump.exe"""
$7z_exe = """c:\Program Files\7-Zip\7z.exe"""
$arc_dir = "e:\PGSQL_Backup\bckp_data"

$baseslist = @("pbk-b", "usp-b")
foreach ($base in $baseslist) {
    $dump_args = "-f"+$arc_dir+"\"+$base+".bak -Fc -b -E UTF-8 -U postgres -w "+$base
    Start-Process $dump_exe $dump_args -Wait -NoNewWindow
}

$7z_args = "a "+$arc_dir+"_"+(Get-Date -UFormat %y%m%d_%H%M%S).ToString()+".7z "+$arc_dir+"\ -mx"

Start-Process $7z_exe $7z_args -Wait -NoNewWindow

$rem_path = $arc_dir+$backup_dir+"\*"
Remove-Item $rem_path -Recurse
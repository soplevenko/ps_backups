$base = Read-Host "Enter base name"
$dump_exe = """c:\Program Files\PostgreSQL\9.2.4-1.1C\bin\pg_dump.exe"""
$arc_dir = "d:\PGSQL_Backup\manbak"
$dump_args = "-f"+$arc_dir+"\"+$base+(Get-Date -UFormat %y%m%d_%H%M%S).ToString()+".bak -Fc -b -E UTF-8 -U postgres -W "+$base
Start-Process $dump_exe $dump_args -Wait -NoNewWindow

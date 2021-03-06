#Simple script that manually creates backup for selected PostgreSQL base

#set path to PostgreSQL binaries
$dump_exe = """d:\Program Files\PostgreSQL\9.4.2-1.1C\bin\pg_dump.exe"""

#set path to backup directory
$arc_dir = "e:\PGSQL_Backup\manbak"

$base = Read-Host "Enter base name"

$dump_args = "-f"+$arc_dir+"\"+$base+(Get-Date).ToString("yyMMdd_HHmm")+".bak -Fc -b -E UTF-8 -U postgres -W "+$base
Start-Process $dump_exe $dump_args -Wait -NoNewWindow

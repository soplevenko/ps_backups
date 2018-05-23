#Simple script that manually creates backup for selected PostgreSQL base

#set path to PostgreSQL binaries
$dump_exe = """c:\Program Files\PostgreSQL\9.2.4-1.1C\bin\pg_dump.exe"""

#set path to backup directory
$arc_dir = "e:\PGSQL_Backup\manbak"

$base = Read-Host "Enter base name"

$dump_args = "-f"+$arc_dir+"\"+$base+".bak -Fc -b -E UTF-8 -U postgres -W "+$base
Start-Process $dump_exe $dump_args -Wait -NoNewWindow

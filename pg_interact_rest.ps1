#Simple script that manually restores selected PostgreSQL base from backup

#set path to PostgreSQL binaries
$restore_exe = """c:\Program Files\PostgreSQL\9.2.4-1.1C\bin\pg_restore.exe"""

#set path to backup directory
$arc_dir = "e:\PGSQL_Backup\manbak"

$base = Read-Host "Enter base name"
$archive = Read-Host "Enter archive name"

$restore_args = "-d"+$base+" -Fc -c -Upostgres -W "+$arc_dir+"\"+$archive
Start-Process $restore_exe $restore_args -Wait -NoNewWindow

$base = Read-Host "Enter base name"
$archive = Read-Host "Enter archive name"

$replica_file = "e:\PGSQL_Backup\manbak\"+$archive
$restore_exe = """c:\Program Files\PostgreSQL\9.2.4-1.1C\bin\pg_restore.exe"""
$restore_args = "-d"+$base+" -Fc -c -Upostgres -W "+$replica_file

Start-Process $restore_exe $restore_args -Wait

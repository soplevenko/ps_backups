#это комментарий комментарий
$dump_exe = """c:\Program Files\PostgreSQL\9.2.4-1.1C\bin\pg_dump.exe"""
$restore_exe = """c:\Program Files\PostgreSQL\9.2.4-1.1C\bin\pg_restore.exe"""

$replica_file = "d:\1cproc\pg_replica\pbk-b.bak"

$dump_args = "-f"+$replica_file+" -Fc -b -E UTF-8 -U postgres -w pbk-b"
$restore_args = "-dpbk-test -Fc -c -Upostgres -w "+$replica_file

Start-Process $dump_exe $dump_args -Wait  -NoNewWindow
Start-Process $restore_exe $restore_args -Wait -NoNewWindow

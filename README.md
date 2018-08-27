
# SQL backup management scripts - simple samples set

## PostgreSQL interactive backup script

Script _pg_interact_bak.ps1_ manually creates backup for selected PostgreSQL base.

## PostgreSQL interactive restore script

Script _pg_interact_rest.ps1_ manually restores selected PostgreSQL base from backup.

## PostgreSQL auto backup script

Script _pg_backupncopy.ps1_ designed to automatically backup selected Postgres databases. Script uses pg_dump, so it is no continuous archiving. Script puts backup files to local and remote location. Script also distributes backup files by time lapse (daily, weekly, monthly). Each time lapse corresponds to separate subfolder and retention period. After the retention period expired, files being flushed.

## Microsoft SQL auto backup script

Script _ms_bak_zipncopy.ps1_ designed to perform automatic post-processing of backup files created by MS SQL server. Script zips newly created backup files and moves archives to remote location. The origin backup files remain at their location. Script determines retention period for each subfolder within local and remote location. After the retention period expired, files being flushed.

## Microsoft SQL Express auto backup script

Script _ms_backupncopy.ps1_ designed to perform automatically backup and maintenance selected MS SQL Express databases. Due to limitations of MS SQL Express, all maintenance should be performed by  script itsefl. Script uses osql client and sql template to generate and execute maintenance commands. After backup files created, script zips them and moves archives to remote location. Script determines retention period for each subfolder within local and remote location. After the retention period expired, files being flushed.
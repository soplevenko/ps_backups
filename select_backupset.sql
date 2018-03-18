DECLARE @srcbasename NVarchar(25) = N'base';
DECLARE @dstbasename NVarchar(25) = N'base-test';

DECLARE @maxfbckplsn Numeric(25,0);
DECLARE @maxibckplsn Numeric(25,0);
DECLARE @fullbckpphys NVarchar(260);
DECLARE @diffbckpphys NVarchar(260);
DECLARE @isdiffbackup bit = 1;

DECLARE @srcdata NVarchar(25);
DECLARE @srclog NVarchar(25);
DECLARE @dstdata NVarchar(260);
DECLARE @dstlog NVarchar(260);

SET @maxfbckplsn = (select
						MAX(backupset.first_lsn)
					from msdb..backupset as backupset
					where backupset.database_name = @srcbasename
						and backupset.type = 'D');

if @maxfbckplsn IS NULL
	THROW 51001, 'Full backup record not found.', 1;
	
SET @maxibckplsn = (select
						MAX(backupset.first_lsn)
					from msdb..backupset as backupset
					where backupset.database_name = @srcbasename
						and backupset.differential_base_lsn = @maxfbckplsn);

if @maxibckplsn IS NULL
	SET @isdiffbackup = 0;
	
SET @fullbckpphys = (select backupmediafamily.physical_device_name
					from msdb..backupset as backupset
					inner join msdb..backupmediafamily as backupmediafamily on
						backupset.media_set_id = backupmediafamily.media_set_id
					where backupset.database_name = @srcbasename
						and backupset.first_lsn = @maxfbckplsn
						and backupset.type = 'D');

if @fullbckpphys IS NULL
	THROW 51004, 'Full backup media record not found.', 1;


if @isdiffbackup = 1
	BEGIN
		SET @diffbckpphys = (select backupmediafamily.physical_device_name
					from msdb..backupset as backupset
					inner join msdb..backupmediafamily as backupmediafamily on
						backupset.media_set_id = backupmediafamily.media_set_id
					where backupset.database_name = @srcbasename
						and backupset.first_lsn = @maxibckplsn
						and backupset.type = 'I')

		if @fullbckpphys IS NULL
			THROW 51005, 'Diff backup media record not found.', 1;
	END

SET @srcdata = (select top 1 master_files.name
				from sys.master_files as master_files
				inner join sys.databases as databases on 
					databases.database_id = master_files.database_id
					and databases.name = @srcbasename
					and master_files.type = 0)

if @srcdata IS NULL
	THROW 51006, 'Source base data file name not found.', 1;

SET @srclog = (select top 1 master_files.name
				from sys.master_files as master_files
				inner join sys.databases as databases on 
					databases.database_id = master_files.database_id
					and databases.name = @srcbasename
					and master_files.type = 1)

if @srclog IS NULL
	THROW 51007, 'Source base log file name not found.', 1;

SET @dstdata = (select top 1 master_files.physical_name
				from sys.master_files as master_files
				inner join sys.databases as databases on 
					databases.database_id = master_files.database_id
					and databases.name = @dstbasename
					and master_files.type = 0)

if @dstdata IS NULL
	THROW 51008, 'Destination base data file location not found.', 1;

SET @dstlog = (select top 1 master_files.physical_name
				from sys.master_files as master_files
				inner join sys.databases as databases on 
					databases.database_id = master_files.database_id
					and databases.name = @dstbasename
					and master_files.type = 1)

if @dstlog IS NULL
	THROW 51009, 'Destination base log file location not found.', 1;

/*select @fullbckpphys, @diffbckpphys*/

USE [master]
if @isdiffbackup = 1
	BEGIN
		RESTORE DATABASE @dstbasename FROM  DISK = @fullbckpphys WITH  FILE = 1,  MOVE @srcdata TO @dstdata,  MOVE @srclog TO @dstlog,  NORECOVERY,  NOUNLOAD,  REPLACE,  STATS = 5
		RESTORE DATABASE @dstbasename FROM  DISK = @diffbckpphys WITH  FILE = 1,  NOUNLOAD,  STATS = 5
	END
else
	RESTORE DATABASE @dstbasename FROM  DISK = @fullbckpphys WITH  FILE = 1,  MOVE @srcdata TO @dstdata,  MOVE @srclog TO @dstlog,  NOUNLOAD,  REPLACE,  STATS = 5
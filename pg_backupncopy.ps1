#path to local and remote backup folders
$path_src = "g:\pgsqlbackup"
$path_dst = "g:\pgsqlbackup_copy"

#Paths to PostgreSQL commands
$dump_exe = """d:\Program Files\PostgreSQL\9.4.2-1.1C\bin\pg_dump.exe"""
$restore_exe = """d:\Program Files\PostgreSQL\9.4.2-1.1C\bin\pg_restore.exe"""

#Get current date, format for filename
$currentdate = Get-Date
$datefilepart = $currentdate.ToString("yyMMdd_HHmm")

#write backup log
$backuplog = "$path_src\backup.log"
Add-Content $backuplog "`r`n`r`nBackup log for $currentdate"


#What subfolder used for today file
$TLapseFolder = "Daily"
if($currentdate.Day -eq 1){
    $TLapseFolder = "Monthly"
}
elseif($currentdate.DayOfWeek -eq "Sunday"){
    $TLapseFolder = "Weekly"
}

#Create backup for every base from list
$baseslist = @("test-1", "test-2")
foreach ($base in $baseslist) {
    $filename = "$path_src\$TLapseFolder\$base" + "_" + "$datefilepart.bak"
    $dump_args = "-f$filename -Fc -b -E UTF-8 -U postgres -W $base"
    Start-Process $dump_exe $dump_args -Wait -NoNewWindow
    Add-Content $backuplog "`r`nCreate backup file $filename"
}

#Replicate backup to test base
$replicabase = "test-3"
$sourcebase = $baseslist[0]

$replica_file = "$path_src\$TLapseFolder\$sourcebase" + "_" + "$datefilepart.bak" 
$restore_args = "-d$replicabase -Fc -c -Upostgres -W $replica_file"

Start-Process $restore_exe $restore_args -Wait -NoNewWindow
Add-Content $backuplog "`r`nReplicate base $replicabase from file $replica_file"

Add-Content $backuplog "`r`n"

#if no access to remote folder - do nothing
if(-not (Test-Path $path_dst)) {
    Add-Content $backuplog "`r`nNo access to $path_dst"
    Add-Content $backuplog "`r`nBackup finished with error"
    Add-Content $backuplog "`r`n===================================================="
    exit 1
}


#copy all bak archives from local to remote location 
robocopy $path_src $path_dst *.bak /S /W:3 /R:3 /NP /LOG+:$backuplog

Add-Content $backuplog "`r`n"

#perform cleanup, delete old backup files

#backup files expiration interval in days for every timelapse
$path_expire = @{}

#local folders
$path_expire["$path_src\Daily"] = 5
$path_expire["$path_src\Weekly"] = 15
$path_expire["$path_src\Monthly"] = 32

#remote folders
$path_expire["$path_dst\Daily"] = 90
$path_expire["$path_dst\Weekly"] = 180
$path_expire["$path_dst\Monthly"] = 2000

#lookup through directories for expiresd files
foreach($path in $path_expire.Keys){
    if(Test-Path $path){
        $dateexpire = $currentdate.AddDays(-$path_expire[$path])
        foreach ($item in Get-ChildItem $path -Recurse -Include @("*.bak", "*.trn", "*.7z", "*.rar") | where {$_.CreationTime -le $dateexpire}){
            Add-Content $cleanuplog "`r`nFlush file $item"
            Remove-Item $item
        }
    }
    else{
        Add-Content $cleanuplog "`r`nNo access to $path"
    }
}
Add-Content $cleanuplog "`r`nCleanup finished"
Add-Content $cleanuplog "`r`n===================================================="

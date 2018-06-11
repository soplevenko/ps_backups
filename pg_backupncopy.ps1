#Simple script, that dedicated to automatically backup selected Postgres databases.
#Script puts backup files to local and remote location
#Script also distributes backup files by time lapse (daily, weekly, monthly).
#Each time lapse corresponds to separate subfolder and retention period.

#set path to local and remote backup folders
$path_src = "g:\pgsqlbackup"
$path_dst = "g:\pgsqlbackup_copy"

#set path to PostgreSQL binaries
$dump_exe = """d:\Program Files\PostgreSQL\9.4.2-1.1C\bin\pg_dump.exe"""

#set bases names for backup
$baseslist = @("test-1", "test-2")

#get current date, format for filename
$currentdate = Get-Date
$datefilepart = $currentdate.ToString("yyMMdd_HHmm")

#set backup log name and location
$backuplog = "$path_src\backup.log"
Add-Content $backuplog "`r`n`r`nBackup log for $currentdate"

#set backup files retention period in days for every subfolder (and time lapse respectively)
$path_expire = @{}

#local folders
$path_expire["$path_src\Daily"] = 5
$path_expire["$path_src\Weekly"] = 15
$path_expire["$path_src\Monthly"] = 32

#remote folders
$path_expire["$path_dst\Daily"] = 90
$path_expire["$path_dst\Weekly"] = 180
$path_expire["$path_dst\Monthly"] = 2000


#Determine subfolder by time lapse
#If it's 1st day of month - then "Monthly"
#Else if it's end of week - then "Weekly"
#Otherwise - "Daily"

$TLapseFolder = "Daily"
if($currentdate.Day -eq 1){
    $TLapseFolder = "Monthly"
}
elseif($currentdate.DayOfWeek -eq "Sunday"){
    $TLapseFolder = "Weekly"
}

#Create backup for every base from list
foreach ($base in $baseslist) {
    $filename = "$path_src\$TLapseFolder\$base" + "_" + "$datefilepart.bak"
    $dump_args = "-f$filename -Fc -b -E UTF-8 -U postgres -w $base"
    Start-Process $dump_exe $dump_args -Wait -NoNewWindow
    Add-Content $backuplog "`r`nCreate backup file $filename"
}

Add-Content $backuplog "`r`n"

#if no access to remote folder then log and exit
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

#lookup through directories for expired files
foreach($path in $path_expire.Keys){
    if(Test-Path $path){
        $dateexpire = $currentdate.AddDays(-$path_expire[$path])
        foreach ($item in Get-ChildItem $path -Recurse -Include @("*.bak", "*.trn", "*.7z", "*.rar") | where {$_.CreationTime -le $dateexpire}){
            Add-Content $backuplog "`r`nFlush file $item"
            Remove-Item $item
        }
    }
    else{
        Add-Content $backuplog "`r`nNo access to $path"
    }
}
Add-Content $backuplog "`r`nCleanup finished"
Add-Content $backuplog "`r`n===================================================="

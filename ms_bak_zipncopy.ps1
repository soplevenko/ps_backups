#A simple script designed to perform post-processing of backup files created by MS SQL server.
#Script zips newly created backup files and moves archives to remote location.
#The origin backup files remain at their location.
#Script determines retention period for each subfolder within local and remote location.
#After the retention period expired, files being flushed.

#set path to local and remote backup folders
$path_src = "g:\mssqlbackup"
$path_dst = "g:\mssqlbackup_copy"

#to add new line into log just write empty one
$CRLF = ""

#set path to 7-zip binaries
$7zpath = """c:\Program Files\7-Zip\7z.exe"""

#get current date
$currentdate = Get-Date

#set cleanup log name and location
$cleanuplog = "$path_src\cleanup.log"
Add-Content $cleanuplog ("Cleanup log for " + $currentdate.ToString("u"))
Add-Content $cleanuplog $CRLF

#set backup files retention period in days for every subfolder (and time lapse respectively)
$path_expire = @{}

#local folders
$path_expire["$path_src\Hourly"] = 14
$path_expire["$path_src\Daily"] = 14
$path_expire["$path_src\Weekly"] = 30
$path_expire["$path_src\Monthly"] = 60

#remote folders
$path_expire["$path_dst\Hourly"] = 30
$path_expire["$path_dst\Daily"] = 90
$path_expire["$path_dst\Weekly"] = 180
$path_expire["$path_dst\Monthly"] = 2000


#if no access to remote folder then log and exit
if(-not (Test-Path $path_dst)) {
    Add-Content $cleanuplog "No access to $path_dst"
    Add-Content $cleanuplog "Cleanup finished with error"
    Add-Content $cleanuplog "===================================================="
    Add-Content $cleanuplog $CRLF
    exit 1
}

#lookup for backup files with "archive" attribute, i.e., fresh ones
foreach ($item in Get-ChildItem $path_src -Recurse -Include @("*.bak", "*.trn") | Where-Object {$_.Attributes -eq 'Archive'}){
	#for every file clear "archive" attribute and create 7-zip archive
    $acrcitem = $item.DirectoryName+"\"+$item.BaseName+".7z"

    $item.Attributes = 'Normal'

    $args = "u -mx "+$acrcitem+" "+$item.FullName
    Start-Process $7zpath $args -Wait
    Add-Content $cleanuplog "$item 7-ziped to $acrcitem"
}

Add-Content $cleanuplog $CRLF

#move all 7-zip archives from local to remote location
robocopy $path_src $path_dst *.7z /S /W:3 /R:3 /COPY:D /MOV /NP /NFL /UNILOG+:$cleanuplog

Add-Content $cleanuplog $CRLF

#perform cleanup, lookup through directories for expired files to flush them
foreach($path in $path_expire.Keys){
    if(Test-Path $path){
        $dateexpire = $currentdate.AddDays(-$path_expire[$path])
        foreach ($item in Get-ChildItem $path -Recurse -Include @("*.bak", "*.trn", "*.7z", "*.rar") | Where-Object {$_.CreationTime -le $dateexpire}){
            Add-Content $cleanuplog "Flush file $item"
            Remove-Item $item
        }
    }
    else{
        Add-Content $cleanuplog $CRLF
        Add-Content $cleanuplog "No access to $path"
    }
}

Add-Content $backuplog $CRLF
$timetook = "{0:hh}:{0:mm}:{0:ss}" -f $(New-TimeSpan -Start $currentdate)
Add-Content $cleanuplog "`Cleanup finished at $(Get-Date -format u) in $timetook"
Add-Content $cleanuplog "`===================================================="
Add-Content $cleanuplog $CRLF
#A simple script designed to perform post-processing of backup files created by MS SQL server
#Script zips newly created backup files and moves them to remote location

#path to local and remote backup folders
$path_src = "g:\mssqlbackup"
$path_dst = "g:\mssqlbackup_copy"

#7-zip path
$7zpath = """c:\Program Files\7-Zip\7z.exe"""

$currentdate = Get-Date

#write cleanup log
$cleanuplog = "$path_src\cleanup.log"
Add-Content $cleanuplog ("`r`n`r`nCleanup log for " + $currentdate.ToString("u"))

#if no access to remote folder - do nothing
if(-not (Test-Path $path_dst)) {
    Add-Content $cleanuplog "`r`nNo access to $path_dst"
    Add-Content $cleanuplog "`r`nCleanup finished with error"
    Add-Content $cleanuplog "`r`n===================================================="
    exit 1
}

#lookup for backup files with "archive" attribute, i.e., fresh ones
foreach ($item in Get-ChildItem $path_src -Recurse -Include @("*.bak", "*.trn") | Where-Object {$_.Attributes -eq 'Archive'}){
	#for every file clear "archive" attribute and create 7-zip archive
	
    $acrcitem = $item.DirectoryName+"\"+$item.BaseName+".7z"

    $item.Attributes = 'Normal'

    $args = "u -mx "+$acrcitem+" "+$item.FullName
    Start-Process $7zpath $args -Wait
    
    Add-Content $cleanuplog "`r`n$item 7-ziped to $acrcitem"
}

Add-Content $cleanuplog "`r`n"

#move all 7-zip archives from local to remote location 

robocopy $path_src $path_dst *.7z /S /W:3 /R:3 /COPY:D /MOV /NP /NFL /UNILOG+:$cleanuplog

Add-Content $cleanuplog "`r`n"

#perform cleanup, delete old backup files

#backup files expiration interval in days for every timelapse
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

#lookup through directories for expired files
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

$timetook = "{0:hh}:{0:mm}:{0:ss}" -f $(New-TimeSpan -Start $currentdate)
Add-Content $cleanuplog "`r`nCleanup finished at $(Get-Date -format u) in $timetook"
Add-Content $cleanuplog "`r`n===================================================="
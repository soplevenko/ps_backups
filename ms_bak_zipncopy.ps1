#path to local and remote backup folders
$path_src = "g:\mssqlbackup"
$path_dst = "g:\mssqlbackup_copy"

#7-zip path
$7zpath = """c:\Program Files\7-Zip\7z.exe"""

#if no access to remote folder - do nothing
if(-not (Test-Path $path_dst)) {exit}

#lookup for backup files with "archive" attribute, i.e., fresh ones
foreach ($item in Get-ChildItem $path_src -Recurse -Include @("*.bak", "*.trn") | where {$_.Attributes -eq 'Archive'}){
	#for every file clear "archive" attribute and create 7-zip archive
	
    $acrcitem = $item.DirectoryName+"\"+$item.BaseName+".7z"

    $item.Attributes = 'Normal'

    $args = "u -mx "+$acrcitem+" "+$item.FullName
    Start-Process $7zpath $args -Wait
}

#move all 7-zip archives from local to remote location 
#Start-Process "robocopy" "$path_src $path_dst *.7z /S /W:3 /R:3 /MOV /LOG+:$path_src\movelog.log" -Wait
robocopy $path_src $path_dst *.7z /S /W:3 /R:3 /MOV /LOG+:$path_src\movelog.log

#perform cleanup, delete old backup files
$cleanuplog = "$path_src\cleanup.log"

#backup files expiration interval in days for every timelapse
$path_expire = @{}

#local folders
$path_expire["$path_src\Hourly"] = 14
$path_expire["$path_src\Daily"] = 14
$path_expire["$path_src\Weekly"] = 30
$path_expire["$path_src\Monthly"] = 60

#remote folders
$path_expire["$path_dst\Hourly"] = 21
$path_expire["$path_dst\Daily"] = 30
$path_expire["$path_dst\Weekly"] = 180
$path_expire["$path_dst\Monthly"] = 2000

$currentdate = Get-Date

#write cleanup log
Add-Content $cleanuplog "`r`n`r`nCleanup log for $currentdate"

#lookup through directories for expiresd files
foreach($path in $path_expire.Keys){
    if(Test-Path $path){
        $dateexpire = $currentdate.AddDays(-$path_expire[$path])
        foreach ($item in Get-ChildItem $path -Recurse -Include @("*.bak", "*.trn", "*.7z", "*.rar") | where {$_.CreationTime -le $dateexpire}){
            Add-Content $cleanuplog "`r`n$item"
            Remove-Item $item
        }
    }
}
Add-Content $cleanuplog "`r`nCleanup finished"
Add-Content $cleanuplog "`r`n===================================================="
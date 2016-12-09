#path to local and remote backup folders
$path_src = "d:\bak_ananta"
$path_dst = "\\Backupserver\BackUp\1CBackup"

#Path to 7zip command-line
$7zpath = """c:\Program Files\7-Zip\7z.exe"""

#Path to separated zup folder
$zup_src = "d:\1s\ЗУП\"

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

$zup_dst = $path_src + "\" + $TLapseFolder + "\zup"

#7zip zup folder to proper path
$args = "u -mx $zup_dst\zup_$datefilepart.7z $zup_src"
Start-Process $7zpath $args -Wait
Add-Content $backuplog "`r`n`r`nCreate backup for zup folder"

#7zip files from source folder
foreach ($item in Get-ChildItem $path_src -Recurse -Include *.bak){

	#Place every 7z archive to a proper path
	$parentdirname = Split-Path -Path $item.DirectoryName -Parent
	$leafdirname = Split-Path -Path $item.DirectoryName -Leaf
    $acrcitem = $parentdirname + "\" + $TLapseFolder + "\" + $leafdirname + "\" + $item.BaseName + ".7z"

    $args = "u -mx "+$acrcitem+" "+$item.FullName
    Start-Process $7zpath $args -Wait
    Remove-Item $item.FullName | out-null
	Add-Content $backuplog "`r`n`r`nCreate backup for $item"
}

Add-Content $backuplog "`r`n"

#if no access to remote folder - do nothing
if(-not (Test-Path $path_dst)) {
    Add-Content $backuplog "`r`nNo access to $path_dst"
    Add-Content $backuplog "`r`nBackup finished with error"
    Add-Content $backuplog "`r`n===================================================="
    exit 1
}


#copy all archives from local to remote location 
#
#robocopy $path_src $path_dst *.7z *.rar *.zip /S /PURGE /W:3 /R:3 /NP /LOG+:$backuplog
#
#if robocopy not availible - copying files one by one

foreach ($item in Get-ChildItem $path_src -Recurse -Include *.rar,*.7z,*.zip){
	$destdir = $item.DirectoryName.ToLower()
	$destdir = $destdir.Replace($path_src,$path_dst)
	$destitem = $destdir+"\"+$item.Name
	if(!(Test-Path $destitem)){
		if(!(Test-Path $destdir)){
			New-Item $destdir -Type Directory
		}
		Copy-Item $item $destitem -Force -Recurse
		Add-Content $backuplog "`r`nCopy $item to $destitem"
	}
}

Add-Content $backuplog "`r`n"

Add-Content $backuplog "`r`n"

#perform cleanup, delete old backup files

#backup files expiration interval in days for every timelapse
$path_expire = @{}

#local folders
$path_expire["$path_src\Daily"] = 90
$path_expire["$path_src\Weekly"] = 180
$path_expire["$path_src\Monthly"] = 2000

#remote folders
$path_expire["$path_dst\Daily"] = 90
$path_expire["$path_dst\Weekly"] = 180
$path_expire["$path_dst\Monthly"] = 2000

#lookup through directories for expiresd files
foreach($path in $path_expire.Keys){
    if(Test-Path $path){
        $dateexpire = $currentdate.AddDays(-$path_expire[$path])
        foreach ($item in Get-ChildItem $path -Recurse -Include @("*.7z", "*.rar") | where {$_.LastWriteTime -le $dateexpire}){
            Add-Content $backuplog "`r`nFlush file $item"
            Remove-Item $item
        }
    }
    else{
        Add-Content $backuplog "`r`nNo access to $path"
    }
}


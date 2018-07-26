#A simple script designed to perform automatically backup and maintenance selected MS SQL databases.
#Script uses osql client and command template to.
#Script puts backup files to local and remote location.
#Script also distributes backup files by time lapse (daily, weekly, monthly).
#Each time lapse corresponds to separate subfolder and retention period.
#After the retention period expired, files being flushed.


#path to local and remote backup folders
$path_src = "d:\mssqlbackup"
$path_dst = "\\BACKUPSERVER\BackUp\1C8Backup"

#Path to 7zip command-line
$7zpath = """c:\Program Files\7-Zip\7z.exe"""

#Get current date, format for filename basename
$currentdate = Get-Date
$datefilepart = $currentdate.ToString("yyyyMMdd_HHmmss")

#write backup log
$backuplog = "$path_src\backup.log"
$sqllog = "$path_src\sqlrun" + "_" + "$datefilepart.log"
Add-Content $backuplog "`r`n`r`nBackup log for $currentdate"

$templateFile = "$path_src\service.tpl"
if(-not (Test-Path $templateFile)){
    Add-Content $backuplog "Не найден файл шаблона запроса!"
    exit 1
}

$query_template = Get-Content $templateFile
$query_file = "$path_src\service" + "_" + "$datefilepart.sql"
Set-Content -Path $query_file -Value ""

#Create backup for every base from list
$baseslist = @("LatchClient", "Optim_83")
foreach ($basename in $baseslist) {
    $backupfile = $basename +"_" + $datefilepart
    $backuppath = "$path_src\$basename"

    if(-not(Test-Path $backuppath)){
        New-Item $backuppath -Type Directory
    }

    $backuppath = $backuppath + "\$backupfile.bak"

    $query = $query_template -replace "{basename}", $basename
    $query = $query -replace "{backupname}", $backupname
    $query = $query -replace "{backuppath}", $backuppath

    Add-Content -Path $query_file -Value $query 
}

$osqlargs = "-E -S VERASERGEEVNA\SQLEXPRESS -i $query_file -o $sqllog"

Start-Process osql $osqlargs -Wait -NoNewWindow

Remove-Item $query_file -Force  | out-null

#What subfolder used for today file
$TLapseFolder = "Daily"
if($currentdate.Day -eq 1){
    $TLapseFolder = "Monthly"
}
elseif($currentdate.DayOfWeek -eq "Sunday"){
    $TLapseFolder = "Weekly"
}

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
robocopy $path_src $path_dst *.7z *.rar *.zip /S /PURGE /W:3 /R:3 /NP /LOG+:$backuplog

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


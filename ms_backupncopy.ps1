#A simple script designed to perform automatically backup and maintenance selected MS SQL Express databases.
#Due to limitations of MS SQL Express, all maintenance should be performed by script itself.
#Script uses osql client and sql template to generate and execute maintenance commands.
#After backup files created, script zips them and moves archives to remote location.
#Script determines retention period for each subfolder within local and remote location.
#After the retention period expired, files being flushed.

#set MS SQL address
$mssqladdress = "localhost\SQLEXPRESS"

#path to local and remote backup folders
$path_src = "g:\mssqlbackup"
$path_dst = "g:\mssqlbackup_copy"

#to add new line into log just write empty one
$CRLF = ""

#path to 7zip command-line
$7zpath = """c:\Program Files\7-Zip\7z.exe"""

#get current date, format it for files naming
$currentdate = Get-Date
$datefilepart = $currentdate.ToString("yyyyMMdd_HHmmss")

#set backup log name and location
$backuplog = "$path_src\backup.log"
Add-Content $backuplog "Backup log for $currentdate"
Add-Content $backuplog $CRLF

#path to sql command template file
$templateFile = "$path_src\service.tpl"

#if no template file found then log and exit 
if(-not (Test-Path $templateFile)){
    Add-Content $backuplog "Query template file $templateFile not found!"
    exit 1
}

#set bases names for maintenance
$baseslist = @("test-1", "test-2")

#set sql command log name and location, separate file for every launch
$sqllog = "$path_src\sqlrun_" + "$datefilepart.log"

#set backup files retention period in days for every subfolder (and time lapse respectively)
$path_expire = @{}

#local folders
$path_expire["$path_src\Daily"] = 90
$path_expire["$path_src\Weekly"] = 180
$path_expire["$path_src\Monthly"] = 2000

#remote folders
$path_expire["$path_dst\Daily"] = 90
$path_expire["$path_dst\Weekly"] = 180
$path_expire["$path_dst\Monthly"] = 2000

#determine subfolder by time lapse
#if it's 1st day of month - then "Monthly"
#else if it's end of week - then "Weekly"
#otherwise - "Daily"
$TLapseFolder = "Daily"
if($currentdate.Day -eq 1){
    $TLapseFolder = "Monthly"
}
elseif($currentdate.DayOfWeek -eq "Sunday"){
    $TLapseFolder = "Weekly"
}

#generate query file from template
$query_template = Get-Content $templateFile
$query_file = "$path_src\service" + "_" + "$datefilepart.sql"
Set-Content -Path $query_file -Value ""

#cycle through bases list
foreach ($basename in $baseslist) {
    $backupfile = $basename +"_" + $datefilepart
    $backuppath = "$path_src\$TLapseFolder\$basename"

    if(-not(Test-Path $backuppath)){
        New-Item $backuppath -Type Directory
    }

    $backuppath = $backuppath + "\$backupfile.bak"

    $query = $query_template -replace "{basename}", $basename
    $query = $query -replace "{backupname}", $backupname
    $query = $query -replace "{backuppath}", $backuppath

    Add-Content -Path $query_file -Value $query 
}

#run generated sql query
$osqlargs = "-E -S $mssqladdress -i $query_file -o $sqllog"
Start-Process osql $osqlargs -Wait -NoNewWindow

#flush genrated sql 
Remove-Item $query_file -Force  | out-null

#move *.bak files from source folder to 7zip archives
foreach ($item in Get-ChildItem $path_src -Recurse -Include *.bak){

    #place every 7z archive to a proper path
    $acrcitem = $item.DirectoryName+"\"+$item.BaseName+".7z"

    $args = "u -mx "+$acrcitem+" "+$item.FullName
    Start-Process $7zpath $args -Wait
    Remove-Item $item.FullName | out-null
	Add-Content $backuplog "Create backup for $item"
}

Add-Content $backuplog $CRLF

#if no access to remote folder - do nothing
if(-not (Test-Path $path_dst)) {
    Add-Content $backuplog "No access to $path_dst"
    Add-Content $backuplog "Backup finished with error"
    Add-Content $backuplog "===================================================="
    exit 1
}

#copy all archives from local to remote location 
robocopy $path_src $path_dst *.7z *.rar *.zip /S /PURGE /W:3 /R:3 /NP /LOG+:$backuplog

Add-Content $backuplog $CRLF

#perform cleanup, lookup through directories for expired files to flush them
foreach($path in $path_expire.Keys){
    if(Test-Path $path){
        $dateexpire = $currentdate.AddDays(-$path_expire[$path])
        foreach ($item in Get-ChildItem $path -Recurse -Include @("*.7z", "*.rar") | Where-Object{$_.LastWriteTime -le $dateexpire}){
            Add-Content $backuplog "Flush file $item"
            Remove-Item $item
        }
    }
    else{
        Add-Content $backuplog "No access to $path"
    }
}

Add-Content $backuplog $CRLF
$timetook = "{0:hh}:{0:mm}:{0:ss}" -f $(New-TimeSpan -Start $currentdate)
Add-Content $backuplog "Backup finished at $(Get-Date -format u) in $timetook"
Add-Content $backuplog "===================================================="
Add-Content $backuplog $CRLF
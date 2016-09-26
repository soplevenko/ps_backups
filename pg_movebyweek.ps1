#path to local and remote backup folders
$path_src = "g:\pgsqlbackup"
$path_dst = "g:\pgsqlbackup_copy"

foreach ($item in Get-ChildItem -Path "$path_dst\*" -Include @("*.bak", "*.7z", "*.rar") | where {$_.CreationTime.DayOfWeek -eq "Sunday"}){
    Write-host $item $item.CreationTime.DayOfWeek
	$copyitem = $path_dst + "\Weekly\" + $item.Name
    Move-Item $item $copyitem
}

foreach ($item in Get-ChildItem -Path "$path_src\*" -Include @("*.bak", "*.7z", "*.rar") | where {$_.CreationTime.DayOfWeek -eq "Sunday"}){
    Write-host $item $item.CreationTime.DayOfWeek
	$copyitem = $path_src + "\Weekly\" + $item.Name
    Move-Item $item $copyitem
}

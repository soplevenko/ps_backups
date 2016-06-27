$path_src = "d:\bak_ananta\"
$path_dst = "\\Backupserver\BackUp\1CBackup\"

$7zpath = """c:\Program Files\7-Zip\7z.exe"""

$zup_src = "d:\1s\ЗУП\"
$zup_dst = $path_src+"zup\"

$args = "u -mx "+$zup_dst+"zup_"+(Get-Date -UFormat %y%m%d_%H%M).ToString()+".7z"+" "+$zup_src
Start-Process $7zpath $args -Wait


foreach ($item in Get-ChildItem $path_src -Recurse -Include *.bak){

    $acrcitem = $item.DirectoryName+"\"+$item.BaseName+".7z"

    $args = "u -mx "+$acrcitem+" "+$item.FullName
    Start-Process $7zpath $args -Wait
    Remove-Item $item.FullName | out-null
}

if(Test-Path $path_dst){
    foreach ($item in Get-ChildItem $path_src -Recurse -Include *.rar,*.7z,*.zip){
		$destdir = $item.DirectoryName.ToLower()
        $destdir = $destdir.Replace($path_src,$path_dst)
		$destitem = $destdir+"\"+$item.Name
        #$copyitem = Get-Item $acrcitem
		if(!(Test-Path $destitem)){
			if(!(Test-Path $destdir)){
				New-Item $destdir -Type Directory
			}
			Copy-Item $item $destitem -Force -Recurse
		}
    }
}
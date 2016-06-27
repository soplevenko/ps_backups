$path_src = "d:\mssqlbackup\"
$path_dst = "\\192.168.0.126\Public\1CSERVER\MSSQLBackup\"
#Удаляем файлы старше 5 дней
$limit = (Get-Date).AddDays(-5)


$7zpath = """c:\Program Files\7-Zip\7z.exe"""

$arrArchives = @()

foreach ($item in Get-ChildItem $path_src -Recurse -Include *.bak){

    $acrcitem = $item.DirectoryName+"\"+$item.BaseName+".7z"

    $args = "u -mx "+$acrcitem+" "+$item.FullName
    Start-Process $7zpath $args -Wait
    $arrArchives += $acrcitem
    Remove-Item $item.FullName | out-null
}

if(Test-Path $path_dst){
    foreach ($acrcitem in $arrArchives){
        $destitem = $acrcitem.ToLower()
        $destitem = $destitem.Replace($path_src,$path_dst)
        Copy-Item $acrcitem $destitem -Force
    }
    
    Get-ChildItem $path_src -Recurse -Include *.7z | Where {$_.CreationTime -lt $limit} | Remove-Item -Force
}
git ls-files | foreach { @{
	File = "$(pwd)\$_" -as [System.IO.FileInfo]
	Time = $(git log --pretty=format:%ci -n 1 -- "$_") -as [DateTime]
} } | where {
	$_.File
} | foreach { try {
	$_.File.LastWriteTime = $_.Time
} catch { Write-Error $_ } }
#git log @sakura/master... --reverse --format=format:%ci --name-only

$TopDir = git rev-parse --show-toplevel
$Oldest = (Get-Date).AddMonths(-1) # Of course, this is incorrect for the oldest timestamp. That's what "Roughly" means.

$t = $Oldest
@(
	"?$($Oldest.ToString("yyyy-MM-dd 00:00:00"))"
	, (git ls-files --full-name "$TopDir")
	, (git log --format=format:?%ci --name-only --since=$($Oldest.ToString("yyyy-MM-dd")) --reverse)
) | foreach { $_ | foreach { $_ } } | foreach {
	if ($_ -eq "") {
	} elseif ($_[0] -eq "?") {
		$t = $_.Substring(1) -as [DateTime]
	} else { try {
		([System.IO.FileInfo]"$TopDir\$_").LastWriteTime = $t
	} catch { Write-Debug($_) } }
}

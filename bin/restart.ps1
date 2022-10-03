### Configure path to restart_check.txt
$scriptAppPath=($MyInvocation.MyCommand.Source) -Replace ("\\bin\\restart.ps1","")
$metaPath = "$SplunkHome\etc\restart_meta.txt"
$restartMeta = $(Test-Path "$SplunkHome\etc\restart_meta.txt" -PathType Leaf)

### Filter to attach timestamps where necessary
filter timestamp {"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') ${env:COMPUTERNAME}: $_"}

if ($restartMeta -eq "True") {
 Write-output "Meta settings has been changed." | timestamp
 Write-output "Restarting forwarder." | timestamp
 if ($restartMeta -eq "True") {
	 Remove-Item -path "$metaPath"
 }
 Remove-Item -path "$scriptAppPath\DeleteMeToRestart"
} else {
 Write-output "No settings have been changed." | timestamp
 Write-output "No restart required." | timestamp
}

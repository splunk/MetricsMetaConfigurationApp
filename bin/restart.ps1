### Configure path to restart_check.txt
$metaPath = "$SPLUNKHOME\etc\restart_meta.txt"

### Filter to attach timestamps where necessary
filter timestamp {"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') ${env:COMPUTERNAME}: $_"}

if ($metaPath -eq "True") {
	Write-output "Meta settings has been changed." | timestamp
	Write-output "Restarting forwarder." | timestamp
	if ($metaPath -eq "True") {
		Remove-Item -path "$metaPath"
	}
	Remove-Item -path "$SPLUNKHOME\etc\apps\MetricsMetaConfigurationApp\DeleteMeToRestart"
} else {
	Write-output "No settings have been changed." | timestamp
	Write-output "No restart required." | timestamp
}

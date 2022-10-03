### Configure path to checkpoint file as well as customer name and app path
$scriptAppPath=($MyInvocation.MyCommand.Source) -Replace ("\\bin\\cleanMeta.ps1","")
$CHECKPOINT = $SplunkHome + "\etc\metricsCheckpoint"
$APPHOME = $SplunkHome + "\etc\apps\metrics_meta_settings"

### Nuke them all from orbit. It's the only way to be sure...
Remove-Item -path "$CHECKPOINT"
Remove-Item -path "$APPHOME" -recurse

### Remove the DeleteMeToRestart file to trigger a restart from the deployment server
Remove-Item -path "$scriptAppPath\DeleteMeToRestart"

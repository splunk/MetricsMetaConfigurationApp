## USED WHEN TESTING RUNNING MANUALLY
## If you're doing your own testing, be sure to comment out
## the checkpoint exit condition as well.
#$SplunkHome = "C:\Program Files\SplunkUniversalForwarder"

## Variables used in the script
$APPHOME = $SplunkHome + "\etc\apps\metrics_meta_settings"
$INPUTCONF = $APPHOME + "\local\inputs.conf"
$CHECKPOINT = $SplunkHome + "\etc\metricsCheckpoint"
$METAPATH = $SplunkHome + "\etc\restart_meta.txt"

## Check for checkpoint value and exit if it exists
if (Test-Path "$CHECKPOINT") {
exit
}

## Create the app directoy if it doesn't exist
if (-not (Test-Path "$APPHOME")) {
 New-Item "$APPHOME\local" -ItemType Directory | Out-Null
 New-Item "$APPHOME\metadata" -ItemType Directory | Out-Null
 Write-Output '[]
access = read : [ * ], write : [ admin ]
export = system' | Set-Content -Path "$APPHOME\metadata\local.meta"
}

## Determine if the host is in AWS and capture AWS related dimensions
if (Test-Path "$env:ProgramFiles\Amazon\SSM") {
 $instance_id = Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/instance-id
 $account_id = (Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/identity-credentials/ec2/info/).accountId
 $region = Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/placement/availability-zone
 $mac_address = Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/mac
 $vpc_id = Invoke-RestMethod http://169.254.169.254/latest/meta-data/network/interfaces/macs/$mac_address/vpc-id
 $cloud_dims = $cloud_dims + " region::" + "`"" + $region  + "`""
 $cloud_dims = $cloud_dims + " instance_id::" + "`"" + $instance_id  + "`""
 $cloud_dims = $cloud_dims + " vpc_id::"  + "`"" + $vpc_id + "`""
 $cloud_dims = $cloud_dims + " account_id::" + "`"" + $account_id  + "`""
 try { $public_ip = Invoke-RestMethod http://169.254.169.254/latest/meta-data/public-ipv4
	 } catch {
 }
 if (-not ([string]::IsNullOrEmpty($public_ip))) {
	 $cloud_dims = $cloud_dims + " public_ipv4::" + "`"" + $public_ip + "`""
 }
}

## Capture the OS and IP details of the host
$os_info = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version
$ipv4_info = Test-Connection -ComputerName $env:computername -count 1 | Select-Object IPV4Address
$ipv6_info = Test-Connection -ComputerName $env:computername -count 1 | Select-Object IPV6Address

## Construct the dimensions into a single string together
$dims = "os::" + "`"" + $os_info.Caption + "`""
$dims = $dims + " os_version::" + $os_info.Version
$dims = $dims + " ipv4::" + "`"" + $ipv4_info.IPV4Address.IPAddressToString + "`""
if (-not ([string]::IsNullOrEmpty($ipv6_info))) {
$dims = $dims + " ipv6::" + "`"" + $ipv6_info.IPV6Address.IPAddressToString + "`""
}
$dims = $dims + ' entity_type::Windows_Host'
if (-not ([string]::IsNullOrEmpty($cloud_dims))) {
$dims = $dims + $cloud_dims
}

## Create the inputs.conf in the app and populate it with a default configuration
Write-Output "[perfmon]
_meta = $dims" | Set-Content -Path "$INPUTCONF"

## Set up checkpoint value to ensure the script only runs once and create restart file
Write-Output "" | Set-Content -Path "$CHECKPOINT"
Write-Output "" | Set-Content -Path "$METAPATH"

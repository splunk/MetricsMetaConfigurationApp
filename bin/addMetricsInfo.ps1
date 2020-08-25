## Variables used in the script
$APPHOME = $SplunkHome + "\etc\apps\metrics_meta_settings"
$INPUTCONF = $APPHOME + "\local\inputs.conf"
$METRICSPARAM = "logical_disk,physical_disk,cpu,memory,network,system,process"
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
	echo '[]
access = read : [ * ], write : [ admin ]
export = system' > "$APPHOME\metadata\local.meta"
}

## Determine if the host is in AWS and capture AWS related dimensions
if (Test-Path "C:\Windows\Amazon\Ec2ConfigService") {
  $instance_id = Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/instance-id
  $account_id = (Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/identity-credentials/ec2/info/).accountId
  $region = Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/placement/availability-zone
  $cloud_dims = " region::$region instance_id::$instance_id account_id::$account_id"
}

## List of inputs that will be added to the inputs.conf
$m_cpu ="[perfmon://CPU]`r`n" `
+ "disabled = 0"

$m_memory ="[perfmon://Memory]`r`n" `
+ "disabled = 0"

$m_physical_disk ="[perfmon://PhysicalDisk]`r`n" `
+ "disabled = 0"

$m_logical_disk ="[perfmon://LogicalDisk]`r`n" `
+ "disabled = 0"

$m_network ="[perfmon://Network]`r`n" `
+ "disabled = 0"

$m_system ="[perfmon://System]`r`n" `
+ "disabled = 0"

$m_process ="[perfmon://Process]`r`n" `
+ "disabled = 0"

## Capture the OS and IP details of the host
$os_info = Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version
$ip_info = Test-Connection -ComputerName $env:computername -count 1 | Select-Object IPV4Address

## Construct the dimensions into a single string together
$dims = "os::" + "`"" + $os_info.Caption + "`""
$dims = $dims + " os_version::" + $os_info.Version
$dims = $dims + " ip::" + "`"" + $ip_info.IPV4Address.IPAddressToString + "`""
$dims = $dims + ' entity_type::Windows_Host'
if (-not ([string]::IsNullOrEmpty($cloud_dims))) {
$dims = $dims + $cloud_dims
}

## Create the inputs.conf in the app and populate it with the stanzas and dimensions
$metrics = $METRICSPARAM -split ','
echo '' > $INPUTCONF
For ($i=0; $i -lt $metrics.Length; $i++) {
  $m_name = "m_" + $metrics[$i]
  Get-Variable -Name $m_name -ValueOnly -ErrorAction 'Ignore' >> $INPUTCONF
  # Add dimensions
  echo "_meta = $dims" >> $INPUTCONF
  echo "`n" >> $INPUTCONF
}

## Set up checkpoint value to ensure the script only runs once and create restart file
echo '' > $CHECKPOINT
echo '' > $METAPATH

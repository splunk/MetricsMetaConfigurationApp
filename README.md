# MetricsMetaConfigurationApp
App designed to create an app that will tag Windows Perfmon inputs with the "_meta" field for each host uniquely. At the moment it is only designed for the out of the box configurations used by Splunk App for Infrastructure.

## Why does this app exist?
Because metrics collection requires at least 1 _meta value, Splunk Docs recommends using the configuration located here: https://docs.splunk.com/Documentation/InfraApp/2.1.0/Admin/ManualInstallWindowsUF#Sample_inputs.conf_file_for_metrics_and_logs_collection

The _metrics value is predefined in this configuration to contain this:
```
_meta =  os::"Microsoft Windows Server 2012 R2 Standard" os_version::6.3.9600 entity_type::Windows_Host
```
Because not every server will be that release of Windows at that version, you would likely shorten the value to this:
```
_meta =  entity_type::Windows_Host
```
This isn't a useful pivot point for SAI that could be useful later or in other situations. This app is meant to generate a unique value for each host locally outside of the path of a deployment server. The same logic is used in the scripts included with SAI when deploying the metrics locally on each host.

## Using the app
The app is intended to be deployed using a deployment server because a restart of the hosts after app installation is required for the _meta fields to take affect.

Below is the default inputs file. This configuration is responsible for running the scripts each time the forwarder restarts except for the restart script. The restart script is on a cron for every 2 minutes and is designed to only trigger a restart under specific circumstances.
```
[powershell://restart]
disabled = 1
index = _internal
sourcetype = restart:output
schedule = */2 * * * *
source = restart_output
script = . "$SplunkHome\etc\apps\MetricsMetaConfigurationApp\bin\restart.ps1"

[powershell://addMetricsInfo]
disabled = 1
index = _internal
script = . "$SplunkHome\etc\apps\MetricsMetaConfigurationApp\bin\addMetricsInfo.ps1"
sourcetype = addMetricsInfo

[powershell://cleanMeta]
disabled = 1
index = _internal
script = . "$SplunkHome\etc\apps\MetricsMetaConfigurationApp\bin\cleanMeta.ps1"
sourcetype = cleanMeta
```
Below is a recommended configuration of the inputs file. This will ensure the proper functionallity of the scripts is maintained. Copy/paste this configuration into the app's 'inputs.conf' in the 'local' directory
```
[powershell://restart]
disabled = 0

[powershell://addMetricsInfo]
disabled = 0

[powershell://cleanMeta]
disabled = 0
```
## Pre-planning
If you deployed metrics ingestion prior to using this app, you may have to make an alteration to the currently deployed inputs configuration to remove the static value assigned to `_meta`. It's important there be no static value assigned to ensure the proper `_meta` value takes precedence when the scripts are run.

## Deploy the app
Once the app is configured and staged on the deployment server, it should be deployed wherever the metrics collection is taking place. Below are entries in `serverclass.conf` that can be used to prepare the app for deployment.
```
[serverClass:MetricsMetaHosts]
machineTypesFilter = windows-x64

[serverClass:MetricsMetaHosts:app:MetricsMetaConfigurationApp]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled
```
Take note of the `restartSplunkd` setting. This should ALWAYS be '1' or 'true' for this app to ensure the restart mechanism works properly.

## Restarting the Forwarder
Because this configuration requires the forwarders be restarted, an additional script has been introduced that takes the outcome of each of the scripts used and determines if a restart is required. Each script is designed to create an empty file that the restart script uses to determine if a restart is necessary. If the restart script finds one of the files used to trigger a restart, it removes them as well as one other static file deployed with the app. Removing the other file should trigger a restart from the deployment server when the app re-syncs for the now missing file.

`restart.ps1`

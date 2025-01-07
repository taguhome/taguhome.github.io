#Requires -RunAsAdministrator

$scriptURL = "https://github.com/taguhome/setup-uec-paper-scripts/blob/main/windows.ps1"
$scriptPath = "$env:TEMP/setup-uec-paper-scripts.ps1"

Start-BitsTransfer -Source "$scriptURL" -Destination "$scriptPath"
powershell -ExecutionPolicy Bypass -File "$scriptPath"

Remove-Item -Path "$scriptPath"

#Requires -RunAsAdministrator

$scriptURL = "https://taguhome.github.io/setup-uec-paper-scripts/windows.ps1"
$scriptPath = "$env:TEMP/setup-uec-paper-scripts.ps1"

Start-BitsTransfer -Source "$scriptURL" -Destination "$scriptPath"
powershell -ExecutionPolicy Bypass -File "$scriptPath"

Remove-Item -Path "$scriptPath"

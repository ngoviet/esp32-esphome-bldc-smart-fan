# Flash T-Series Fan via OTA
# Usage: .\flash.ps1 -Device t1-fan -IP 192.168.20.201
#    or: .\flash.ps1 t1-fan 192.168.20.201

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Device,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$IP
)

$yamlFile = "$Device.yaml"
if (-not (Test-Path $yamlFile)) {
    Write-Error "File not found: $yamlFile"
    exit 1
}

Write-Host "Flashing $Device to $IP ..." -ForegroundColor Cyan
esphome run $yamlFile --device $IP

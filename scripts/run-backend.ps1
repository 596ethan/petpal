$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location (Join-Path $root "petpal-server")

mvn spring-boot:run

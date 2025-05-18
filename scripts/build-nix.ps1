param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('L', 'R')]
    [string]$Side = 'R'
)

$flashScriptPath = Join-Path "scripts" "flash.ps1"
$artifactsDownloadDir = Join-Path "build" "nix"

wsl --exec "./scripts/build-nix.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed"
    exit 1
}

$uf2FilePattern = "*_$($Side)*.uf2"
$firmwareFile = Get-ChildItem -Path $artifactsDownloadDir -Filter $uf2FilePattern | Select-Object -First 1

if (-not $firmwareFile) {
    Write-Error "Firmware file matching pattern '$uf2FilePattern' (for Side: $Side) not found in '$artifactsDownloadDir'."
    Write-Host "Available files in $artifactsDownloadDir :"
    Get-ChildItem -Path $artifactsDownloadDir | ForEach-Object { Write-Host $_.FullName }
    exit 1
}

& $flashScriptPath -Side $Side -BuildDir $artifactsDownloadDir -Uf2File $firmwareFile.Name
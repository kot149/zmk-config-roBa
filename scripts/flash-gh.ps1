param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('L', 'R')]
    [string]$Side = 'R'
)

# --------------------------------------------
# Set file paths
# --------------------------------------------
$cwd = Get-Location
$flashScriptPath = Join-Path $cwd "scripts" "flash.ps1"
$artifactsDownloadDir = Join-Path "build" "gh"
$firmwareExtractDir = Join-Path $artifactsDownloadDir "firmware"

# --------------------------------------------
# Get repository information
# --------------------------------------------
$gitUrl = git remote get-url origin
$gitUrl -match 'github\.com/(?<user>[^/]+)/(?<repo>[^/]+)\.git'
$repoOwner = $Matches.user
$repoName = $Matches.repo
Write-Host "Detected repository: $repoOwner/$repoName"

# --------------------------------------------
# Remove old artifacts download directory
# --------------------------------------------
if (Test-Path $artifactsDownloadDir) {
    Write-Host "Removing old artifacts download directory: $artifactsDownloadDir"
    Remove-Item -Recurse -Force $artifactsDownloadDir
}

# --------------------------------------------
# Create directories
# --------------------------------------------
New-Item -ItemType Directory -Path $artifactsDownloadDir | Out-Null
New-Item -ItemType Directory -Path $firmwareExtractDir | Out-Null

# --------------------------------------------
# Fetch latest successful workflow run
# --------------------------------------------
Write-Host "Fetching latest successful workflow run for $repoOwner/$repoName (branch main)..."
$latestRunId = gh run list --repo "$repoOwner/$repoName" --branch "main" --status "success" --json databaseId --limit 1 | ConvertFrom-Json | Select-Object -ExpandProperty databaseId

if (-not $latestRunId) {
    Write-Error "Failed to get the latest successful workflow run ID. Make sure 'gh' CLI is installed and authenticated, and the workflow/branch names are correct."
    exit 1
}

Write-Host "Latest successful run ID: $latestRunId"
Write-Host "Downloading artifact(s) from run ID: $latestRunId to $artifactsDownloadDir"

# --------------------------------------------
# Clear download directory
# --------------------------------------------
if (Test-Path $artifactsDownloadDir) {
    Write-Host "Removing old artifacts download directory: $artifactsDownloadDir"
    Remove-Item -Recurse -Force $artifactsDownloadDir
}

# --------------------------------------------
# Download artifact
# --------------------------------------------
$artifactName = "firmware"
gh run download $latestRunId --repo "$repoOwner/$repoName" --dir $artifactsDownloadDir -n $artifactName

# --------------------------------------------
# Find uf2 file
# --------------------------------------------
$uf2FilePattern = "*_$($Side)*.uf2"
$firmwareFile = Get-ChildItem -Path $artifactsDownloadDir -Filter $uf2FilePattern | Select-Object -First 1

if (-not $firmwareFile) {
    Write-Error "Firmware file matching pattern '$uf2FilePattern' (for Side: $Side) not found in '$artifactsDownloadDir'."
    Write-Host "Available files in $artifactsDownloadDir :"
    Get-ChildItem -Path $artifactsDownloadDir | ForEach-Object { Write-Host $_.FullName }
    exit 1
}

Write-Host "Found firmware file: $($firmwareFile.FullName)"

# --------------------------------------------
# Flash firmware
# --------------------------------------------
& .\scripts\flash.ps1 -Uf2File $($firmwareFile.Name) -Side $Side -BuildDir $artifactsDownloadDir

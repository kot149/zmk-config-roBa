# ID of ZMK container in which build.sh is executed
$CONTAINER_ID = "b72fa8b67fee1e7d49163023c9a09ddf8044cf2d7f6650805d570698e309466c"

# Check container status
try {
    # First, check if container exists
    $containerExists = docker container inspect $CONTAINER_ID 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error: Container ID ${CONTAINER_ID} not found."
        Write-Error "Please check if Docker is running and the container ID is correct."
        exit 1
    }

    $containerState = docker container inspect -f "{{.State.Running}}" $CONTAINER_ID
    if ($containerState -ne "true") {
        Write-Host "Starting container..."
        docker start $CONTAINER_ID | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Error: Failed to start container."
            Write-Error "Please check if Docker is running."
            exit 1
        }

        # Wait for container to start (max 10 seconds)
        $timeout = 10
        $startTime = Get-Date
        $containerReady = $false

        while (-not $containerReady) {
            $containerState = docker container inspect -f "{{.State.Running}}" $CONTAINER_ID 2>$null
            if ($containerState -eq "true") {
                $containerReady = $true
                Write-Host "Container startup completed."
            } else {
                if (((Get-Date) - $startTime).TotalSeconds -gt $timeout) {
                    Write-Error "Error: Container startup timed out."
                    exit 1
                }
                Start-Sleep -Milliseconds 500
            }
        }
    } else {
        Write-Host "Container is already running."
    }

    # Set up ../zmk-config symlink
    Write-Host "Setting up ../zmk-config symlink..."
    $cwdFullPath = $PWD.Path
    New-Item -ItemType SymbolicLink -Path "$cwdFullPath\..\zmk-config" -Target $cwdFullPath -Force | Out-Null

    # Execute build.sh
    Write-Host "Running build.sh in container..."
    docker exec $CONTAINER_ID /workspaces/zmk-config/scripts/build.sh $args

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build successful. Starting flash process..."
        & "$PSScriptRoot\flash.ps1"
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
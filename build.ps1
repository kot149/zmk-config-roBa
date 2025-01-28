# コンテナIDを設定
$CONTAINER_ID = "78cdf07e86e3"

# コンテナの状態をチェック
try {
    $containerState = docker container inspect -f "{{.State.Running}}" $CONTAINER_ID 2>$null
    if ($null -eq $containerState) {
        Write-Error "エラー: コンテナID ${CONTAINER_ID} が見つかりません。"
        Write-Error "Dockerが起動していることと、コンテナIDが正しいことを確認してください。"
        exit 1
    }

    if ($containerState -ne "true") {
        Write-Host "コンテナを起動しています..."
        docker start $CONTAINER_ID | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "エラー: コンテナの起動に失敗しました。"
            Write-Error "Dockerが起動していることを確認してください。"
            exit 1
        }

        # コンテナの起動を待機（最大10秒）
        $timeout = 10
        $startTime = Get-Date
        $containerReady = $false

        while (-not $containerReady) {
            $containerState = docker container inspect -f "{{.State.Running}}" $CONTAINER_ID 2>$null
            if ($containerState -eq "true") {
                $containerReady = $true
                Write-Host "コンテナの起動が完了しました。"
            } else {
                if (((Get-Date) - $startTime).TotalSeconds -gt $timeout) {
                    Write-Error "エラー: コンテナの起動がタイムアウトしました。"
                    exit 1
                }
                Start-Sleep -Milliseconds 500
            }
        }
    } else {
        Write-Host "コンテナはすでに起動しています。"
    }

    # build.shを実行
	Write-Host "ビルドを開始します..."
    docker exec $CONTAINER_ID /workspaces/zmk-config/build.sh $args
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
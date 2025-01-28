# コンテナIDを設定
$CONTAINER_ID = "78cdf07e86e3"

# コンテナの状態をチェック
try {
    $containerState = docker container inspect -f "{{.State.Running}}" $CONTAINER_ID 2>$null
    if ($null -eq $containerState) {
        Write-Error "エラー: コンテナID ${CONTAINER_ID} が見つかりません。"
        Write-Error "Docker Desktopが起動していることと、コンテナIDが正しいことを確認してください。"
        exit 1
    }

    if ($containerState -ne "true") {
        Write-Host "コンテナを起動しています..."
        docker start $CONTAINER_ID | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "エラー: コンテナの起動に失敗しました。"
            Write-Error "Docker Desktopが起動していることを確認してください。"
            exit 1
        }
        Write-Host "コンテナの起動中です。しばらくお待ちください..."
        Start-Sleep -Seconds 3
        Write-Host "コンテナの起動が完了しました。"
    }

    # build.shを実行
    docker exec $CONTAINER_ID /workspaces/zmk-config/build.sh $args
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
param (
    [string]$SourceDir = ".",
    [string]$TargetDir = "../zmk-config-moNa2",
    [string]$SourcePattern = "roBa",
    [string]$TargetPattern = "moNa2",
    [string[]]$ExcludeDirs = @(
		".git",
		".vscode",
		"build",
		"docs"
	),
    [string[]]$ExcludeFiles = @(
		"convert-to-moNa2.ps1",
		"README.md"
	)
)

# バナーを表示
Write-Host "ZMK設定ファイルコピースクリプト" -ForegroundColor Cyan
Write-Host "ソース: $SourceDir" -ForegroundColor Yellow
Write-Host "ターゲット: $TargetDir" -ForegroundColor Yellow
Write-Host "置換: '$SourcePattern' → '$TargetPattern'" -ForegroundColor Yellow
Write-Host "除外ディレクトリ: $($ExcludeDirs -join ", ")" -ForegroundColor Yellow
Write-Host "除外ファイル: $($ExcludeFiles -join ", ")" -ForegroundColor Yellow
Write-Host ""

# 相対パスを絶対パスに変換
$SourceDir = Resolve-Path $SourceDir
$TargetDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetDir)

# ターゲットディレクトリが存在するか確認
if (Test-Path $TargetDir) {
    $confirmation = Read-Host "ターゲットディレクトリが既に存在します。上書きしますか？ (Y/N)"
    if ($confirmation -ne "Y" -and $confirmation -ne "y") {
        Write-Host "処理を中止しました。" -ForegroundColor Red
        exit
    }

    # .gitディレクトリとREADME.mdを除いて既存の内容をクリア
    Write-Host "ターゲットディレクトリの内容をクリアしています..." -ForegroundColor Yellow
    Get-ChildItem -Path $TargetDir -Force | Where-Object {
        $_.Name -ne ".git" -and
        $_.Name -ne "README.md" -and
        $_.FullName -ne $TargetDir
    } | ForEach-Object {
        Remove-Item -Path $_.FullName -Recurse -Force
        Write-Host "削除: $($_.FullName)" -ForegroundColor Gray
    }
    Write-Host "ターゲットディレクトリをクリアしました。" -ForegroundColor Green
} else {
    # ターゲットディレクトリを作成
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Write-Host "ターゲットディレクトリを作成しました: $TargetDir" -ForegroundColor Green
}

# ファイルをコピーして内容を置換する関数
function Copy-AndReplaceContent {
    param (
        [string]$sourcePath,
        [string]$targetPath
    )

    # ファイルがバイナリファイルかどうかをチェック
    $isBinary = Test-BinaryFile $sourcePath

    if ($isBinary) {
        # バイナリファイルはそのままコピー
        Copy-Item -Path $sourcePath -Destination $targetPath -Force
        Write-Host "コピー: $sourcePath -> $targetPath" -ForegroundColor Gray
    } else {
        # テキストファイルは内容を置換してコピー
        $content = Get-Content -Path $sourcePath -Raw
        $newContent = $content -replace $SourcePattern, $TargetPattern

        # ターゲットディレクトリが存在しない場合は作成
        $targetDir = Split-Path -Path $targetPath -Parent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        # 新しい内容でファイルを作成
        Set-Content -Path $targetPath -Value $newContent -NoNewline -Encoding UTF8
        Write-Host "コピー+置換: $sourcePath -> $targetPath" -ForegroundColor Green
    }
}

# バイナリファイルかどうかをチェックする関数
function Test-BinaryFile {
    param (
        [string]$path
    )

    $textFileExtensions = @("yml", "yaml", "defconfig", "shield", "conf", "overlay", "dtsi", "json", "keymap", "md", "ps1", "sh", ".gitignore")

    if ($textFileExtensions -contains [System.IO.Path]::GetExtension($path).TrimStart('.')) {
        return $false # テキストファイルとみなす
    }

    try {
        $bytes = [System.IO.File]::ReadAllBytes($path)
        $charCount = 0
        $nullCount = 0

        # 最初の1000バイトをチェック
        $checkLength = [Math]::Min(1000, $bytes.Length)

        for ($i = 0; $i -lt $checkLength; $i++) {
            if ($bytes[$i] -eq 0) {
                $nullCount++
            } elseif (($bytes[$i] -ge 32 -and $bytes[$i] -le 126) -or $bytes[$i] -eq 10 -or $bytes[$i] -eq 13 -or $bytes[$i] -eq 9) {
                $charCount++
            }
        }

        # NULL文字が多い、または表示可能な文字が少ない場合はバイナリファイルと判断
        return ($nullCount -gt 0) -or ($charCount / $checkLength -lt 0.75)
    } catch {
        # エラーが発生した場合はバイナリファイルとして扱う
        return $true
    }
}

# ファイル数をカウント
$totalFiles = (Get-ChildItem -Path $SourceDir -Recurse -File |
    Where-Object {
        $relativePath = $_.FullName.Substring($SourceDir.Length + 1)
        $dirName = Split-Path -Path $relativePath -Parent
        $dirParts = $dirName -split [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)

        # 除外ディレクトリ内のファイルを除外
        $inExcludedDir = $false
        foreach ($dir in $dirParts) {
            if ($ExcludeDirs -contains $dir) {
                $inExcludedDir = $true
                break
            }
        }

        # 除外ファイルをチェック
        $inExcludedFile = $ExcludeFiles -contains $_.Name

        -not $inExcludedDir -and -not $inExcludedFile
    }).Count

$processedFiles = 0

# ファイルをコピーしながら内容とファイル名を置換
Get-ChildItem -Path $SourceDir -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Substring($SourceDir.Length + 1)
    $dirName = Split-Path -Path $relativePath -Parent
    $dirParts = $dirName -split [regex]::Escape([System.IO.Path]::DirectorySeparatorChar)

    # 除外ディレクトリ内のファイルを除外
    $inExcludedDir = $false
    foreach ($dir in $dirParts) {
        if ($ExcludeDirs -contains $dir) {
            $inExcludedDir = $true
            break
        }
    }

    # 除外ファイルをチェック
    $inExcludedFile = $ExcludeFiles -contains $_.Name

    if (-not $inExcludedDir -and -not $inExcludedFile) {
        # ファイル名に $SourcePattern が含まれる場合、置換する
        $newFileName = $_.Name -replace $SourcePattern, $TargetPattern

        # ターゲットパスを作成
        $targetFilePath = Join-Path -Path $TargetDir -ChildPath ($dirName -replace $SourcePattern, $TargetPattern)
        $targetFilePath = Join-Path -Path $targetFilePath -ChildPath $newFileName

        # ターゲットディレクトリを作成
        $targetFileDir = Split-Path -Path $targetFilePath -Parent
        if (-not (Test-Path $targetFileDir)) {
            New-Item -ItemType Directory -Path $targetFileDir -Force | Out-Null
        }

        # ファイルをコピーして内容を置換
        Copy-AndReplaceContent -sourcePath $_.FullName -targetPath $targetFilePath

        $processedFiles++
        Write-Progress -Activity "ファイルをコピー中..." -Status "$processedFiles / $totalFiles ファイル" -PercentComplete (($processedFiles / $totalFiles) * 100)
    }
}

Write-Host ""
Write-Host "コピー完了！" -ForegroundColor Green
Write-Host "$processedFiles ファイルを処理しました。" -ForegroundColor Green
Write-Host "ターゲットディレクトリ: $TargetDir" -ForegroundColor Green
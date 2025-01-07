param (
    [Parameter(Mandatory=$true)]
    [string]$texFilePath
)

# .tex 拡張子を追加する
$texFilePath += ".tex"

# ファイルの内容を読み込む
$texCode = Get-Content -Path $texFilePath -Raw

# \includegraphics の場合の置換
$includeGraphicsPattern = '\\includegraphics\s*(\[[^\]]*\])?\s*{("[^}]+")}'
$texCode = [System.Text.RegularExpressions.Regex]::Replace($texCode, $includeGraphicsPattern, { param($m) "`\includegraphics$($m.Groups[1].Value)`{$($m.Groups[2].Value -replace '\\', '/')}" })

# \includesvg の場合の置換
$includeSvgPattern = '\\includesvg\s*(\[[^\]]*\])?\s*{"([^}]+)"}'
$texCode = [System.Text.RegularExpressions.Regex]::Replace($texCode, $includeSvgPattern, { param($m) "`\includesvg$($m.Groups[1].Value)`{$($m.Groups[2].Value -replace '\\', '/')}" })

# \includegraphics の場合の置換
$includeGraphicsPattern2 = '\\includegraphics\s*(\[[^\]]*\])?\s*{([^}]+)}'
$texCode = [System.Text.RegularExpressions.Regex]::Replace($texCode, $includeGraphicsPattern2, { param($m) "`\includegraphics$($m.Groups[1].Value)`{$($m.Groups[2].Value -replace '\\', '/')}" })

# \includesvg の場合の置換
$includeSvgPattern2 = '\\includesvg\s*(\[[^\]]*\])?\s*{([^}]+)}'
$texCode = [System.Text.RegularExpressions.Regex]::Replace($texCode, $includeSvgPattern2, { param($m) "`\includesvg$($m.Groups[1].Value)`{$($m.Groups[2].Value -replace '\\', '/')}" })


# 変換後の内容を書き戻す
Set-Content -Path $texFilePath -Value $texCode -Encoding UTF8

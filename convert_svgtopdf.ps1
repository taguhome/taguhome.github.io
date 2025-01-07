param (
    [Parameter(Mandatory=$true)]
    [string]$texFilePath
)

# $inkscapePath= "C:\\Program Files\\Inkscape\\bin\\inkscape.exe"
# .tex 拡張子を追加する
$texFilePath += ".tex"
# 環境変数 $inkscapePath を取得
$inkscapePath = $env:inkscapePath  -replace '\\', '/'


# ファイルの内容を読み込む
$texCode = Get-Content -Path $texFilePath -Raw

# \includegraphics の場合の置換
$includeGraphicsPattern = '\\includegraphics\s*(\[[^\]]*\])?\s*{("[^}]+")}'
$texCode = [System.Text.RegularExpressions.Regex]::Replace($texCode, $includeGraphicsPattern, { param($m) "`\includegraphics$($m.Groups[1].Value)`{$($m.Groups[2].Value -replace '\\', '/')}" })



# \includesvg の場合の置換（パス変換とPDFへの変換を実行）
$includeSvgPattern = '\\includesvg\s*(\[[^\]]*\])?\s*{"([^}]+)"}'
$texCode = [System.Text.RegularExpressions.Regex]::Replace($texCode, $includeSvgPattern, {
    param($m)
    # SVGファイルのフルパスを取得
    $svgPath = $m.Groups[2].Value -replace '\\', '/'
    $svgFullPath = Resolve-Path -Path $svgPath

    # PDF出力先を設定
    $pdfPath = [System.IO.Path]::ChangeExtension($svgFullPath, ".pdf")

    # InkscapeでPDFに変換
    & $inkscapePath "--export-type=pdf" "--export-filename=$pdfPath" "$svgFullPath"
    
    # パス変換後の \includesvg コマンドを返す
    "`\includegraphics$($m.Groups[1].Value)`{$pdfPath}"
})


# \includegraphics の場合の置換
$includeGraphicsPattern2 = '\\includegraphics\s*(\[[^\]]*\])?\s*{([^}]+)}'
$texCode = [System.Text.RegularExpressions.Regex]::Replace($texCode, $includeGraphicsPattern2, { param($m) "`\includegraphics$($m.Groups[1].Value)`{$($m.Groups[2].Value -replace '\\', '/')}" })

# \includesvg の場合の置換（パス変換とPDFへの変換を実行）
$includeSvgPattern2 = '\\includesvg\s*(\[[^\]]*\])?\s*{([^}]+)}'
$texCode = [System.Text.RegularExpressions.Regex]::Replace($texCode, $includeSvgPattern, {
    param($m)
    # SVGファイルのフルパスを取得
    $svgPath = $m.Groups[2].Value -replace '\\', '/'
    $svgFullPath = Resolve-Path -Path $svgPath

    # PDF出力先を設定
    $pdfPath = [System.IO.Path]::ChangeExtension($svgFullPath, ".pdf")

    # InkscapeでPDFに変換
    & $inkscapePath "--export-type=pdf" "--export-filename=$pdfPath" "$svgFullPath"
    
    # パス変換後の \includesvg コマンドを返す
    "`\includegraphics$($m.Groups[1].Value)`{$pdfPath}"
})


# 変換後の内容を書き戻す
Set-Content -Path $texFilePath -Value $texCode -Encoding UTF8

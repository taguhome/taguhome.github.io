#Requires -RunAsAdministrator

function Find-Executable (
  [string] $command
) {
  $null -ne (Get-Command -Name $command -ErrorAction SilentlyContinue)
}

function Show-YesNoPrompt([string] $title, [string] $message) {
  $options = [System.Management.Automation.Host.ChoiceDescription[]](
    (New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "実行する"),
    (New-Object System.Management.Automation.Host.ChoiceDescription "&No", "実行しない")
  )
  $defaultChoice = 1
  $Host.UI.PromptForChoice($title, $message, $options, $defaultChoice) -eq 0
}

function Write-LabeledOutput (
  [string] $label,
  [string] $message
) {
  $esc = [char]27
  Write-Host "$esc[37;44;1m $label $esc[m $message"
}

$texLiveArchiveURL = "http://mirror.ctan.org/systems/texlive/tlnet/install-tl.zip"
$texLiveArchiveName = "install-tl.zip"
$texLiveProfileName = "texlive.profile"
$texLiveInstallerName = "install-tl-windows.bat"
$workDir = "$env:TEMP/install-tl"

$vscodeLocalExePath = "$env:LOCALAPPDATA/Programs/Microsoft VS Code/Code.exe"
$vscodeExePath = "$env:ProgramFiles/Microsoft VS Code/Code.exe"
$vscodeCmdPath = "$env:ProgramFiles/Microsoft VS Code/bin/code.cmd"
$vscodeInstallerURL = "https://update.code.visualstudio.com/latest/win32-x64/stable"
$vscodeSettingsDir = "$env:APPDATA/Code/User"
$vscodeSettingsName = "settings.json"
$vscodeArgvPath = "$env:USERPROFILE/.vscode/argv.json"

function Install-TeXLive () {
  New-Item -ItemType Directory -Path "$workDir" -Force > $null
  Push-Location "$workDir"
  Remove-Item -Recurse *

  @"
selected_scheme scheme-custom

collection-langjapanese 1
collection-latexextra 1
collection-mathscience 1
collection-binextra 1
collection-⁠bibtexextra 1
collection-⁠fontutils 1
collection-⁠latex 1
collection-⁠luatex 1

tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
"@ | Out-File $texLiveProfileName -Encoding ascii

  Write-LabeledOutput "TeX Live" "インストーラーのダウンロードを開始します"
  Start-BitsTransfer -Source $texLiveArchiveURL -Destination $texLiveArchiveName
  Expand-Archive -LiteralPath $texLiveArchiveName -DestinationPath .
  $installTLDir = (Get-ChildItem -Directory | Select-Object -First 1 -Property FullName).FullName

  Write-LabeledOutput "TeX Live" "ダウンロードを完了しました"
  Write-LabeledOutput "TeX Live" "インストールを開始します"

  $env:LANG = "C"
  Start-Process -Wait -NoNewWindow -FilePath "$installTLDir/$texLiveInstallerName" -Args "--profile=`"$workDir/$texLiveProfileName`""

  Pop-Location
  Remove-Item -Recurse $workDir

  Write-LabeledOutput "TeX Live" "インストールを完了しました"
}

function Install-VSCode() {
  $workDir = "$env:TEMP/install-vscode";

  $vscodeInstallerPath = "$workDir/VSCodeUserSetup.exe"

  $exampleDir = "$env:USERPROFILE/Desktop/latex-example"
  $exampleName = "hello.tex"
  $exampleAuthor = (Get-WMIObject Win32_UserAccount | Where-Object caption -eq $(whoami)).FullName
  if (-not $exampleAuthor) {
    $exampleAuthor = $env:USERNAME
  }

  New-Item -ItemType Directory -Path "$workDir" -Force > $null
  Push-Location "$workDir"
  Remove-Item -Recurse *

  Write-LabeledOutput "Visual Studio Code" "インストーラーのダウンロードを開始します"

  Start-BitsTransfer -Source "$vscodeInstallerURL" -Destination "$vscodeInstallerPath"

  Write-LabeledOutput "Visual Studio Code" "ダウンロードを完了しました"
  Write-LabeledOutput "Visual Studio Code" "インストールを開始します"


  Start-Process -Wait -NoNewWindow -FilePath "$vscodeInstallerPath" -Args "/VERYSILENT /NORESTART /MERGETASKS=!runcode,desktopicon,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"

  New-Item -ItemType Directory -Path "$vscodeSettingsDir" -Force > $null

  @"
{
    // 和文を使うため、助詞、句読点、全角括弧などを区切り文字として登録する
    "editor.wordSeparators": "./\\()\"'-:,.;<>~!@#$%^&*|+=[]{}`~?　、。「」【】『』（）！？てにをはがのともへでや",
    // 以下、LaTeX Workshopの設定
    // LaTeXでビルドする際の設定を「Tool」「Recipi」の2種類設定する
    //   Tool ...1つのコマンド。料理で言うところの、「焼く」「煮る」などの操作かな。
    //   "latex-workshop.latex.tools" で定義。
    //   Recipe ...Tool を組み合わせて料理（つまりは文書）を作るレシピ。
    //   "latex-workshop.latex.recipes"で定義。
    //   デフォルトの操作は、1番最初に定義されたレシピになる（他のレシピも選択可）
    // Tool の定義
    "latex-workshop.latex.tools": [
        // latexmk によるlualatex
        {
            "name": "Latexmk (LuaLaTeX)",
            "command": "latexmk",
            "args": [
                "-shell-escape",
                "-f",
                "-gg",
                "-pv",
                "-lualatex",
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "-outdir=%OUTDIR%",
                "%DOC%"
            ]
        },
        {
            "name": "Latexmk (LuaLaTeX) with Python",
            "command": "latexmk",
            "args": [
                "-f",
                "-gg",
                "-pv",
                "-lualatex",
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "-outdir=%OUTDIR%",
                "%DOC%"
            ],
            "env": {
                "INPUT_PDF": "%OUTDIR%/%DOC%.pdf" // PDFファイルのパスを環境変数として設定
            }
        },
        {
            "name": "Latexmk (LuaLaTeX_svg)",
            "command": "latexmk",
            "args": [
                "-shell-escape",
                "-f",
                "-gg",
                "-pv",
                "-lualatex",
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "-outdir=%OUTDIR%",
                "%DOC%"
            ]
        },
        // latexmk による xelatex
        {
            "name": "Latexmk (XeLaTeX)",
            "command": "latexmk",
            "args": [
                "-f",
                "-gg",
                "-pv",
                "-xelatex",
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "-outdir=%OUTDIR%",
                "%DOC%"
            ]
        },
        {
            "name": "Latexmk (pdfLaTeX)",
            "command": "latexmk",
            "args": [
                "-f",
                "-gg",
                "-pv",
                "-pdflatex",
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "-outdir=%OUTDIR%",
                "%DOC%"
            ]
        },
        // latexmk による uplatex
        {
            "name": "Latexmk (upLaTeX)",
            "command": "latexmk",
            "args": [
                "-f",
                "-gg",
                "-pv",
                "-pdfdvi",
                "-latex=uplatex",
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "-outdir=%OUTDIR%",
                "%DOC%"
            ]
        },
        // latexmk による platex
        {
            "name": "Latexmk (pLaTeX)",
            "command": "latexmk",
            "args": [
                "-f",
                "-gg",
                "-pv",
                "-pdfdvi",
                "-latex=platex",
                //"-latexoption='-kanji=utf8 -no-guess-input-env'",
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "-outdir=%OUTDIR%",
                "%DOC%"
            ]
        },
        {
            "name": "Pandoc (PDF to Word)",
            "command": "pandoc",
            "args": [
                "%DOC%.pdf",
                "-o",
                "%DOC%.docx"
            ],
        },
        {
            "name": "pdf2word",
            "command": "python",
            "args": [
                "C:\\Users\\tagur\\.vscode\\tex\\pdf_to_word.py", // Pythonスクリプトのパスを指定
                "%DOC%"
            ],
            "env": {
                "INPUT_PDF": "%OUTDIR%/%DOCFILE%.pdf" // PDFファイルのパスを環境変数として設定
            }
        },
        {
            "name": "convert_backslash_to_slash",
            "command": "python",
            "args": [
                "C:\\Users\\tagur\\.vscode\\tex\\kennkyuhoukokusyo\\BS_to_S.py",
                "%DOC%"
            ]
        },
        {
            "name": "convert-bs-to-s",
            "command": "powershell",
            "args": [
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "C:\\Users\\tagur\\.vscode\\convert_backslash_to_slash.ps1",
                // "cd ${env:USERPROFILE}/.vscode",
                //"convert_backslash_to_slash.ps1",
                //"C:\\Users\\tagur\\.vscode\\convert_backslash_to_slash2.ps1",
                //"${env:USERPROFILE}/.vscode/convert_backslash_to_slash.ps1",
                //"${env:USERPROFILE}\\.vscode\\convert_backslash_to_slash.ps1",
                // "C:\\Users\\tagur\\.vscode\\convert_backslash_to_slash.ps1",
                "%DOCFILE%",
            ],
        },
        {
            "name": "convert-svgtopdf",
            "command": "powershell",
            "args": [
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "C:\\Users\\tagur\\.vscode\\convert_svgtopdf.ps1",
                "%DOCFILE%",
            ],
            "env": {
                "inkscapePath": "C:\\Program Files\\Inkscape\\bin\\inkscape.exe" // PDFファイルのパスを環境変数として設定
            }
        }
    ],
    // Recipe の定義
    "latex-workshop.latex.recipes": [
        // LuaLaTeX のレシピ
        {
            "name": "LuaLaTeX",
            "tools": [
                // "convert_backslash_to_slash",
                "convert-bs-to-s",
                "Latexmk (LuaLaTeX)"
            ],
        },
        {
            "name": "LuaLaTeX_inkscape(svg)",
            "tools": [
                // "convert_backslash_to_slash",
                "convert-svgtopdf",
                "Latexmk (LuaLaTeX_svg)"
            ],
        },
        {
            "name": "LuaLaTeX_svg",
            "tools": [
                // "convert_backslash_to_slash",
                "convert-bs-to-s",
                "Latexmk (LuaLaTeX_svg)"
            ],
        },
        {
            "name": "LuaLaTeX_normal",
            "tools": [
                "Latexmk (LuaLaTeX)"
            ],
        },
        // XeLaTeX のレシピ
        {
            "name": "XeLaTeX",
            "tools": [
                "Latexmk (XeLaTeX)"
            ]
        },
        // upLaTeX のレシピ
        {
            "name": "upLaTeX",
            "tools": [
                "Latexmk (upLaTeX)"
            ]
        },
        {
            "name": "pdfLaTeX",
            "tools": [
                "Latexmk (pdfLaTeX)"
            ]
        },
        // pLaTeX のレシピ
        {
            "name": "pLaTeX",
            "tools": [
                "convert-bs-to-s",
                "Latexmk (pLaTeX)"
            ]
        },
        {
            "name": "lualatex ➔ pdf ➔ word",
            "tools": [
                "convert_backslash_to_slash",
                "Latexmk (LuaLaTeX) with Python",
                "pdf2word"
            ]
        }
    ],
    // マジックコメント付きの LaTeX ドキュメントのビルド設定
    // 特に記事では扱わないが、いつか使うことを考えて書いとく。
    // 参考: https://blog.miz-ar.info/2016/11/magic-comments-in-tex/
    "latex-workshop.latex.magic.args": [
        "-f",
        "-gg",
        "-pv",
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%"
    ],
    // 不要なファイルをクリーンアップする時の目印となる拡張子
    // 不要な一時ファイルや中間ファイルを自動削除する機能がある。
    "latex-workshop.latex.clean.fileTypes": [
        "*.aux",
        "*.log",
        "*.bbl",
        "*.blg",
        "*.idx",
        "*.ind",
        "*.lof",
        "*.lot",
        "*.out",
        "*.toc",
        "*.acn",
        "*.acr",
        "*.alg",
        "*.glg",
        "*.glo",
        "*.gls",
        "*.ist",
        "*.fls",
        "*.fdb_latexmk",
        // "*.synctex.gz",
        // for Beamer files
        "_minted*",
        "*.nav",
        "*.snm",
        "*.vrb",
    ],
    // PDFビューワの開き方。画面分割で開く。
    //"latex-workshop.view.pdf.viewer": "tab",
    // LaTeXファイル保存時にPDFも更新するかどうか。
    // LuaLaTeXはビルドが遅いので、かえって煩わしいので無効化
    "latex-workshop.latex.autoBuild.run": "never",
    "[tex]": {
        // スニペット補完中にも補完を使えるようにする
        "editor.suggest.snippetsPreventQuickSuggestions": false,
        // インデント幅を2にする
        "editor.tabSize": 2
    },
    "[latex]": {
        // スニペット補完中にも補完を使えるようにする
        "editor.suggest.snippetsPreventQuickSuggestions": false,
        // インデント幅を2にする
        "editor.tabSize": 2,
        "files.encoding": "utf8bom"
    },
    "[bibtex]": {
        // インデント幅を2にする
        "editor.tabSize": 2
    },
    // 使用パッケージのコマンドや環境の補完を有効化
    "latex-workshop.intellisense.package.enabled": true,
    // 作成したファイルを、直下の "out" フォルダへ出力
    "latex-workshop.latex.outDir": "out",
    "latex-workshop.latex.clean.method": "glob",
    "code-runner.executorMapByFileExtension": {
        ".plt": "gnuplot $fullFileName",
        ".gp": "gnuplot $fullFileName",
    },
    "code-runner.executorMap": {
        "javascript": "node",
        "java": "cd $dir && javac $fileName && java $fileNameWithoutExt",
        "c": "cd $dir && gcc $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
        "zig": "zig run",
        "cpp": "cd $dir && g++ $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
        "objective-c": "cd $dir && gcc -framework Cocoa $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
        "php": "php",
        "python": "python -u",
        "perl": "perl",
        "perl6": "perl6",
        "ruby": "ruby",
        "go": "go run",
        "lua": "lua",
        "groovy": "groovy",
        "powershell": "powershell -ExecutionPolicy ByPass -File",
        "bat": "cmd /c",
        "shellscript": "bash",
        "fsharp": "fsi",
        "csharp": "scriptcs",
        "vbscript": "cscript //Nologo",
        "typescript": "ts-node",
        "coffeescript": "coffee",
        "scala": "scala",
        "swift": "swift",
        "julia": "julia",
        "crystal": "crystal",
        "ocaml": "ocaml",
        "r": "Rscript",
        "applescript": "osascript",
        "clojure": "lein exec",
        "haxe": "haxe --cwd $dirWithoutTrailingSlash --run $fileNameWithoutExt",
        "rust": "cd $dir && rustc $fileName && $dir$fileNameWithoutExt",
        "racket": "racket",
        "scheme": "csi -script",
        "ahk": "autohotkey",
        "autoit": "autoit3",
        "dart": "dart",
        "pascal": "cd $dir && fpc $fileName && $dir$fileNameWithoutExt",
        "d": "cd $dir && dmd $fileName && $dir$fileNameWithoutExt",
        "haskell": "runghc",
        "nim": "nim compile --verbosity:0 --hints:off --run",
        "lisp": "sbcl --script",
        "kit": "kitc --run",
        "v": "v run",
        "sass": "sass --style expanded",
        "scss": "scss --style expanded",
        "less": "cd $dir && lessc $fileName $fileNameWithoutExt.css",
        "FortranFreeForm": "cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
        "fortran-modern": "cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
        "fortran_fixed-form": "cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
        "fortran": "cd $dir && gfortran $fileName -o $fileNameWithoutExt && $dir$fileNameWithoutExt",
        "sml": "cd $dir && sml $fileName"
    },
    // "C_Cpp.default.compilerPath": "$ENV{'USERPROFILE'}\\.vscode\\.vscode\\launch.json",
    "C_Cpp.default.compilerPath": "C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\VC\\Tools\\MSVC\\14.40.33807\\bin\\Hostx64\\x64\\cl.exe",
    "C_Cpp.default.browse.path": [],
    "settingsSync.ignoredExtensions": [
        "ms-ceintl.vscode-language-pack-ja"
    ],
    "editor.bracketPairColorization.independentColorPoolPerBracketType": true,
    "markdown-preview-enhanced.enableScriptExecution": true,
    "markdown-preview-enhanced.enableWikiLinkSyntax": false,
    "latex-workshop.synctex.afterBuild.enabled": true,
    "editor.formatOnSave": true,
    "black-formatter.path": [
        "python"
    ],
    "cSpell.userWords": [
        "arange",
        "autohotkey",
        "autoit",
        "ceintl",
        "coeff",
        "Dainyu",
        "dmath",
        "dsolve",
        "funcs",
        "gfortran",
        "haxe",
        "kitc",
        "latexmk",
        "lessc",
        "logcombine",
        "ltjsarticle",
        "lualatex",
        "numer",
        "powsimp",
        "PSIM",
        "Racf",
        "Racφ",
        "radsimp",
        "ratsimp",
        "runghc",
        "rustc",
        "sbcl",
        "separatevars",
        "sympy",
        "sysode",
        "tagur",
        "textasciitilde",
        "trigsimp"
    ],
    // ...
    "terminal.integrated.copyOnSelection": true,
    "terminal.integrated.rightClickBehavior": "default",
    // "python.analysis.extraPaths": [
    //     "\"C:\\Program Files\\gnuplot\\bin\"",
    //     "\"C:\\Altair\\Altair_PSIM_2023.1\\Python\""
    // ],
    "terminal.integrated.profiles.windows": {
        "Command Prompt": {
            //上側にあるコマンドプロンプトが使用される。ビット数で変更してください。
            "path": [
                "C:\\Windows\\SysWOW64\\cmd.exe",
                "C:\\Windows\\System32\\cmd.exe",
            ],
            // "sourse": "PowerShell" または "Git Bush",  // windows限定。
            "args": [
                // 起動オプション。これまでterminal.integrated.shellArgs.windowsなどで設定したいたもの。
            ],
            "overrideName": true, // タブに表示される名前に関する設定。trueに設定を推奨。詳しくは後述。
            "env": {
                "環境変数名": "値"
                // "JAVA_HOME": "C:\\Program Files\\Java\\jdk-13.0.1" など
            },
            "icon": "terminal-cmd", // アイコンID。色々ある。後述。
            "color": "terminal.ansiRed" // アイコンの色を設定する。後述。
        },
    },
    "code-runner.runInTerminal": true,
    "terminal.external.windowsExec": "C:\\Windows\\SysWOW64\\cmd.exe",
    //上記と連動して下さい。
    "code-runner.saveFileBeforeRun": true,
    "terminal.integrated.shellIntegration.enabled": false,
    "files.autoGuessEncoding": true,
    "terminal.integrated.defaultProfile.windows": "Command Prompt",
    "terminal.integrated.defaultProfile.osx": "",
    "editor.unicodeHighlight.allowedCharacters": {
        "α": true,
        "，": true
    },
    "terminal.integrated.confirmOnExit": "always",
    "workbench.startupEditor": "none",
    "latex-workshop.latex.clean.subfolder.enabled": true,
    //"latex-workshop.view.pdf.viewer": "tab",
    "latex-workshop.view.pdf.viewer": "external",
    //ここから下は、コマンドアウトするかしてください。
    "latex-workshop.view.pdf.external.synctex.command": "$ENV{'USERPROFILE'} /AppData/Local/SumatraPDF/SumatraPDF.exe",
    "latex-workshop.view.pdf.external.synctex.args": [
        "-reuse-instance",
        "%PDF%",
        "-forward-search",
        "%TEX%",
        "%LINE%",
        "-inverse-search",
        "\"$ENV{'USERPROFILE'}\\AppData\\Local\\Programs\\Microsoft VS Code\\bin\\code.cmd\" -r -g \"%f:%l\""
        // "C:\Users\tagur\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd" -r -g "%f:%l"
    ],
    "editor.multiCursorModifier": "ctrlCmd",
    "path-intellisense.autoSlashAfterDirectory": true,
    "path-intellisense.autoTriggerNextSuggestion": true,
    "path-intellisense.extensionOnImport": true,
    "path-intellisense.ignoreTsConfigBaseUrl": true,
    "path-intellisense.showHiddenFiles": true,
    "latex-workshop.latex.autoClean.run": "onSucceeded",
    "C_Cpp.default.intelliSenseMode": "windows-msvc-x64",
    "files.associations": {
        "*.txt": "tsv"
    },
    "python.REPL.enableREPLSmartSend": false,
    "python.REPL.sendToNativeREPL": false,
    "latex-workshop.formatting.latex": "latexindent",
    "lldb.launch.expressions": "python",
    "python.analysis.cacheLSPData": true,
    "python.analysis.autoFormatStrings": true,
    "editor.snippetSuggestions": "bottom",
    "editor.suggest.showKeywords": true,
    "[python]": {
        "editor.wordBasedSuggestions": "matchingDocuments"
    },
    "python.languageServer": "Pylance",
    "python.analysis.completeFunctionParens": true,
    "python.analysis.extraPaths": [
        "パッケージの保存場所"
    ],
    "python.autoComplete.extraPaths": [
        "パッケージの保存場所"
    ],
    "C_Cpp_Runner.cppStandard": "c++14",
    "C_Cpp.default.cppStandard": "c++14",
    "security.allowedUNCHosts": [
        "150.84.42.166"
    ],
    // "editor.formatOnPaste": true,
}
"@ | Out-File -FilePath "$vscodeSettingsDir/$vscodeSettingsName" -Encoding ascii

  Start-Process -Wait -NoNewWindow -FilePath "$vscodeCmdPath" -Args "--install-extension MS-CEINTL.vscode-language-pack-ja"
  Start-Process -Wait -NoNewWindow -FilePath "$vscodeCmdPath" -Args "--install-extension James-Yu.latex-workshop"


  $vscodeProcess = Start-Process -WindowStyle Hidden -FilePath "$vscodeExePath" -PassThru
  Start-Sleep -Seconds 5
  Stop-Process -Force -InputObject $vscodeProcess


  @"
{
  "locale": "ja",
}
"@ | Out-File -FilePath "$vscodeArgvPath" -Encoding ascii

  New-Item -ItemType Directory -Path "$exampleDir" -Force > $null
  @"
\documentclass[11pt,a4j]{jsarticle}

\begin{document}

\title{Hello \LaTeX\ World!}
\author{$exampleAuthor}
\date{\today}
\maketitle

VSCode + \LaTeX の環境構築が完了しました！

この文書は、画面右上の右三角マーク(Build LaTeX project)をクリックすることでコンパイルされ、PDFファイルが生成されます。

\end{document}
"@ | ForEach-Object { [Text.Encoding]::UTF8.GetBytes($_) } | Set-Content -Path "$exampleDir/$exampleName" -Encoding Byte

  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

  runas /machine:$(${env:PROCESSOR_ARCHITECTURE}.ToLower()) /trustlevel:0x20000 "$vscodeExePath `"$exampleDir`" `"$exampleDir/$exampleName`""

  Pop-Location
  Start-Sleep -Seconds 5
  Remove-Item -Recurse "$workDir"

  Write-LabeledOutput  "Visual Studio Code" "インストールを完了しました"
}

$latexmkrcPath = "$env:TEMP/.latexmkrc"
$convertBackslashToSlashPath = "$env:TEMP/convert_backslash_to_slash.ps1"
$convertSvgToPdfPath = "$env:TEMP/convert_svgtopdf.ps1"
$latexJsonPath = "$env:TEMP/latex.json"

function Copy-AdditionalFiles() {
  Write-LabeledOutput "ファイルコピー" ".latexmkrc をユーザーディレクトリにコピーしています..."
  Copy-Item -Path "$latexmkrcPath" -Destination "$env:USERPROFILE/.latexmkrc" -Force

  Write-LabeledOutput "ファイルコピー" "convert_backslash_to_slash.ps1 を .vscode にコピーしています..."
  New-Item -ItemType Directory -Path "$env:USERPROFILE/.vscode" -Force > $null
  Copy-Item -Path "$convertBackslashToSlashPath" -Destination "$env:USERPROFILE/.vscode/convert_backslash_to_slash.ps1" -Force

  Write-LabeledOutput "ファイルコピー" "convert_svgtopdf.ps1 を .vscode にコピーしています..."
  Copy-Item -Path "$convertSvgToPdfPath" -Destination "$env:USERPROFILE/.vscode/convert_svgtopdf.ps1" -Force

  Write-LabeledOutput "ファイルコピー" "latex.json を VSCode ユーザースペースに反映しています..."
  Copy-Item -Path "$latexJsonPath" -Destination "$vscodeSettingsDir/latex.json" -Force
}



if (Find-Executable "tlmgr") {
  if (Show-YesNoPrompt "TeX Live はすでにインストールされています。" "それでも TeX Live をインストールしますか?") {
    Install-TeXLive
  }
}
else {
  Install-TeXLive
}

if ((Test-Path "$vscodeLocalExePath") -or (Test-Path "$vscodeExePath")) {
  if (Show-YesNoPrompt "Visual Studio Code はすでにインストールされています。" "それでも Visual Studio Code をインストールしますか?") {
    Install-VSCode
  }
}
else {
  Install-VSCode
}

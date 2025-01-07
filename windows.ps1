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
  "security.workspace.trust.enabled": false,
  "latex-workshop.latex.recipe.default": "lastUsed",
  "latex-workshop.latex.recipes": [
    {
      "name": "platex and dvipdfmx",
      "tools": ["platex", "platex", "dvipdfmx"]
    }, {
      "name": "uplatex and dvipdfmx",
      "tools": ["uplatex", "uplatex", "dvipdfmx"]
    }
  ],
  "latex-workshop.latex.tools": [
    {
      "name": "platex",
      "command": "platex",
      "args": [
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%"
      ]
    },
    {
      "name": "uplatex",
      "command": "uplatex",
      "args": [
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%"
      ]
    },
    {
      "name": "dvipdfmx",
      "command": "dvipdfmx",
      "args": ["%DOCFILE%.dvi"]
    }
  ]
}

"@ | Out-File -FilePath "$vscodeSettingsDir/$vscodeSettingsName" -Encoding ascii

  Start-Process -Wait -NoNewWindow -FilePath "$vscodeCmdPath" -Args "--install-extension MS-CEINTL.vscode-language-pack-ja"
  Start-Process -Wait -NoNewWindow -FilePath "$vscodeCmdPath" -Args "--install-extension James-Yu.latex-workshop"

  Copy-AdditionalFiles

  Pop-Location
  Remove-Item -Recurse "$workDir"

  Write-LabeledOutput  "Visual Studio Code" "インストールを完了しました"
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

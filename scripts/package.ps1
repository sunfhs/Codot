[CmdletBinding()]
param(
    [string]$BinaryPath = 'target\release\codex-usage.exe'
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$CargoText = Get-Content -LiteralPath (Join-Path $ProjectRoot 'Cargo.toml') -Raw
$PackageVersion = [regex]::Match($CargoText, '(?m)^version\s*=\s*"([^"]+)"').Groups[1].Value
if (-not $PackageVersion) { throw 'Package version is missing.' }
if (-not [IO.Path]::IsPathRooted($BinaryPath)) {
    $BinaryPath = Join-Path $ProjectRoot $BinaryPath
}
if (-not (Test-Path -LiteralPath $BinaryPath -PathType Leaf)) {
    throw "Build the program first: $BinaryPath"
}

$DistDirectory = Join-Path $ProjectRoot 'dist'
$BundleName = "codex-usage-compact-v$PackageVersion-windows-x64"
$BundleDirectory = Join-Path $DistDirectory $BundleName
New-Item -ItemType Directory -Path $BundleDirectory -Force | Out-Null
Copy-Item -LiteralPath $BinaryPath -Destination (Join-Path $DistDirectory 'codex-usage.exe') -Force
$Digest = (Get-FileHash -LiteralPath (Join-Path $DistDirectory 'codex-usage.exe') -Algorithm SHA256).Hash.ToLowerInvariant()
"$Digest  codex-usage.exe" | Set-Content -LiteralPath (Join-Path $DistDirectory 'codex-usage.exe.sha256') -Encoding ascii
foreach ($Helper in @('install.ps1', 'uninstall.ps1', 'install.cmd')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $Helper) -Destination $DistDirectory -Force
}
foreach ($Asset in @('codex-usage.exe', 'codex-usage.exe.sha256', 'install.ps1', 'uninstall.ps1', 'install.cmd')) {
    Copy-Item -LiteralPath (Join-Path $DistDirectory $Asset) -Destination $BundleDirectory -Force
}
foreach ($Document in @('README.md', 'README.en.md', 'README.ja.md', 'LICENSE', 'NOTICE.md', 'CHANGELOG.md')) {
    Copy-Item -LiteralPath (Join-Path $ProjectRoot $Document) -Destination $BundleDirectory -Force
}
Copy-Item -LiteralPath (Join-Path $ProjectRoot 'docs') -Destination $BundleDirectory -Recurse -Force
$ZipPath = Join-Path $DistDirectory "$BundleName.zip"
Compress-Archive -Path (Join-Path $BundleDirectory '*') -DestinationPath $ZipPath -Force
$ZipDigest = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
"$ZipDigest  $BundleName.zip" | Set-Content -LiteralPath "$ZipPath.sha256" -Encoding ascii
Get-ChildItem -LiteralPath $DistDirectory -File | Select-Object Name, Length

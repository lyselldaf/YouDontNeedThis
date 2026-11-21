<#
.SYNOPSIS
Builds the CurseForge upload zip: dist\YouDontNeedThis-<version>.zip

.DESCRIPTION
The zip holds a single YouDontNeedThis\ folder with the .toc, every file the .toc loads, and
LICENSE.md / CREDITS.md, minus the developer-only Export.lua (and its YDNT_Export saved variable,
which is removed from the packaged .toc). The version comes from "## Version:" in the .toc, so bump that first.
Fails if the .toc lists a file that doesn't exist, or if CHANGELOG.md has no "## <version>" section.
Also writes that section to dist\changelog-<version>.md for the CurseForge "Changelog" field.

.EXAMPLE
.\tools\Build-Package.ps1
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$addonName = 'YouDontNeedThis'
$addonDir = Join-Path $root $addonName
$tocPath = Join-Path $addonDir "$addonName.toc"
$tocLines = [IO.File]::ReadAllLines($tocPath)

$versionLine = $tocLines | Where-Object { $_ -match '^##\s*Version:\s*(\S+)' } | Select-Object -First 1
if (-not $versionLine) { throw "No '## Version:' line in $tocPath" }
$version = ([regex]::Match($versionLine, '^##\s*Version:\s*(\S+)')).Groups[1].Value

# The .toc, every file it loads (non-comment, non-empty lines), and the license/credits.
$files = @("$addonName.toc")
$files += $tocLines | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') }

# Developer-only pieces stay out of the release: Export.lua (/ydnt export) and its saved variable.
$devFiles = @('Export.lua')
$devSavedVariables = @('YDNT_Export')
$files = $files | Where-Object { $devFiles -notcontains $_ }
$releaseToc = foreach ($line in $tocLines) {
    if ($devFiles -contains $line.Trim()) { continue }
    if ($line -match '^(##\s*SavedVariables:\s*)(.*)$') {
        $names = $Matches[2] -split '\s*,\s*' | Where-Object { $_ -and $devSavedVariables -notcontains $_ }
        if (-not $names) { continue }
        $line = $Matches[1] + ($names -join ', ')
    }
    $line
}
# Bindings.xml is loaded by the game on its own, so it isn't in the .toc.
$files += 'Bindings.xml', 'LICENSE.md', 'CREDITS.md', 'icon.png'

foreach ($f in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $addonDir $f))) { throw "Missing file listed for the package: $f" }
}

# Every release needs a CHANGELOG.md section headed "## <version>".
$changelogLines = [IO.File]::ReadAllLines((Join-Path $root 'CHANGELOG.md'))
$start = [Array]::IndexOf($changelogLines, "## $version")
if ($start -lt 0) { throw "CHANGELOG.md has no '## $version' section. Add one before packaging." }
$section = @()
for ($i = $start + 1; $i -lt $changelogLines.Length -and -not $changelogLines[$i].StartsWith('## '); $i++) {
    $section += $changelogLines[$i]
}
$changelogText = ($section -join "`n").Trim()
if (-not $changelogText) { throw "The '## $version' section in CHANGELOG.md is empty." }

$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$zipPath = Join-Path $dist "$addonName-$version.zip"
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }

# Build the zip by hand: Compress-Archive in Windows PowerShell 5.1 writes "\" in entry names,
# which some unzip tools (and addon managers) treat as part of the file name.
$zip = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($f in $files) {
        $entryName = "$addonName/" + ($f -replace '\\', '/')
        if ($f -eq "$addonName.toc") {
            # The release .toc, without the developer-only lines.
            $entry = $zip.CreateEntry($entryName, [IO.Compression.CompressionLevel]::Optimal)
            $writer = New-Object IO.StreamWriter($entry.Open(), (New-Object System.Text.UTF8Encoding $false))
            try { $writer.Write(($releaseToc -join "`r`n") + "`r`n") } finally { $writer.Dispose() }
            continue
        }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip, (Join-Path $addonDir $f), $entryName, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally {
    $zip.Dispose()
}

$changelogPath = Join-Path $dist "changelog-$version.md"
[IO.File]::WriteAllText($changelogPath, $changelogText + "`n", (New-Object System.Text.UTF8Encoding $false))

Write-Host "Built $zipPath"
$files | ForEach-Object { Write-Host "  $addonName/$_" }
Write-Host ""
Write-Host "Changelog for CurseForge (also saved to $changelogPath):"
Write-Host ""
Write-Host $changelogText

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$archivePath = Join-Path (Split-Path $projectRoot) 'MirroredDungeon_Godot_Pass07_20261101.zip'
$files = @(Get-ChildItem -LiteralPath $projectRoot -File -Recurse | Where-Object {
    $_.FullName -notmatch '[\\/](\.godot|exports|__pycache__)[\\/]' -and $_.Extension -ne '.tmp'
})
$stream = [System.IO.File]::Open($archivePath,[System.IO.FileMode]::CreateNew)
$zip = [System.IO.Compression.ZipArchive]::new($stream,[System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $files) {
        $relative = [System.IO.Path]::GetRelativePath($projectRoot,$file.FullName).Replace('\','/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$file.FullName,('godot-poc/'+$relative),[System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $zip.Dispose(); $stream.Dispose() }
$zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    if ($zip.Entries.Count -ne $files.Count) { throw 'Archive member count mismatch' }
    foreach ($entry in $zip.Entries) {
        $source = Join-Path $projectRoot $entry.FullName.Substring(10)
        $entryStream = $entry.Open()
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try { $entryHash = [Convert]::ToHexString($sha.ComputeHash($entryStream)) }
        finally { $sha.Dispose(); $entryStream.Dispose() }
        if ($entryHash -ne (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash) { throw "Archive differs: $source" }
    }
} finally { $zip.Dispose() }
Write-Output "PASS: $($files.Count) archive entries verified byte-for-byte."
Get-FileHash -LiteralPath $archivePath -Algorithm SHA256 | Format-List


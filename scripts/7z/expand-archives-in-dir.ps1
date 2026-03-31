#!/usr/bin/env pwsh
#Requires -Version 5.1

param(
    [Parameter(Mandatory = $true)]
    [string]$ArchiveDir,

    [Parameter(Mandatory = $false)]
    [bool]$DeleteArchive = $false,

    [Parameter(Mandatory = $false)]
    [string]$Password = ''
)

$ErrorActionPreference = 'Stop'

$archiveExtensions = @('*.7z', '*.zip', '*.rar', '*.tar', '*.gz', '*.bz2', '*.xz', '*.iso')

function Get-ArchiveFiles {
    param([string]$dir)

    $archives = @()
    
    foreach ($ext in $archiveExtensions) {
        $archives += Get-ChildItem -Path $dir -Filter $ext -File
    }

    return $archives
}

function Get-MultipartArchiveGroup {
    param([System.IO.FileInfo]$archiveFile)

    $name = $archiveFile.BaseName
    $ext = $archiveFile.Extension.ToLower()

    $multipartPatterns = @(
        @(,'\.(part|r)\d+$'),
        @(,'\.\d{3}$'),
        @('_part\d+$'),
        @('.part\d+\.rar$'),
        @('.r\d+$')
    )

    $isVolume = $false
    $basePattern = $name

    foreach ($pattern in $multipartPatterns) {
        if ($name -match $pattern[0]) {
            $isVolume = $true
            $basePattern = $name -replace $pattern[0], ''
            break
        }
    }

    if ($isVolume) {
        $allVolumes = Get-ChildItem -Path $archiveFile.Directory -Filter "$basePattern*" -File | 
                      Where-Object { $_.Extension -in $archiveExtensions.Replace('*.', '') } |
                      Sort-Object Name

        return $allVolumes
    }

    return @($archiveFile)
}

function Expand-ArchiveFile {
    param(
        [System.IO.FileInfo]$archiveFile,
        [string]$password
    )

    $sevenZip = '7z'
    
    $archivePath = $archiveFile.FullName
    $extractDir = $archiveFile.Directory.FullName

    $arguments = @('x', '-y', $archivePath, "-o$extractDir")
    
    if ($password) {
        $arguments += "-p$password"
    }

    Write-Verbose "Extracting: $archivePath"

    $process = Start-Process -FilePath $sevenZip -ArgumentList $arguments -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\7z-output.txt" -RedirectStandardError "$env:TEMP\7z-error.txt"

    return $process.ExitCode -eq 0
}

$archives = Get-ArchiveFiles -dir $ArchiveDir

if ($archives.Count -eq 0) {
    Write-Verbose "No archives found in $ArchiveDir"
    exit 0
}

$processedArchives = @()
$extractionSuccess = $true

foreach ($archive in $archives) {
    if ($archive.FullName -in $processedArchives) {
        continue
    }

    $archiveGroup = Get-MultipartArchiveGroup -archiveFile $archive

    $firstArchive = $archiveGroup[0]
    $archivesToDelete = $archiveGroup

    Write-Verbose "Processing archive group: $($firstArchive.Name) with $($archiveGroup.Count) volume(s)"

    if (Expand-ArchiveFile -archiveFile $firstArchive -password $Password) {
        Write-Verbose "Successfully extracted: $($firstArchive.Name)"
        
        if ($DeleteArchive) {
            foreach ($archiveToDelete in $archivesToDelete) {
                try {
                    Remove-Item -Path $archiveToDelete.FullName -Force -ErrorAction Stop
                    Write-Verbose "Deleted: $($archiveToDelete.Name)"
                }
                catch {
                    Write-Warning "Failed to delete $($archiveToDelete.Name): $_"
                }
            }
        }
    }
    else {
        Write-Error "Failed to extract: $($firstArchive.Name)"
        $extractionSuccess = $false
        break
    }

    $processedArchives += $archiveGroup.FullName
}

if (-not $extractionSuccess) {
    exit 1
}

exit 0

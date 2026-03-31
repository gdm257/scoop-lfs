#!/usr/bin/env pwsh
#Requires -Version 5.1

param(
    [switch]$Overwrite,
    [string[]]$IgnoreList = @()
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$bucketDir = Join-Path $repoRoot 'bucket'
$docsDir = Join-Path $repoRoot 'docs'
$templatePath = Join-Path $bucketDir 'galgame-ttloli.json.template'
$ttloliDocPath = Join-Path $docsDir 'ttloli.md'

if (-not (Test-Path $templatePath)) {
    Write-Error "Template file not found: $templatePath"
    exit 1
}

if (-not (Test-Path $ttloliDocPath)) {
    Write-Error "TTLoli doc file not found: $ttloliDocPath"
    exit 1
}

$templateContent = Get-Content $templatePath -Raw

function Expand-IDRange {
    param([string]$prefix, [int]$start, [int]$end)

    $ids = @()
    for ($i = $start; $i -le $end; $i++) {
        $ids += "$prefix$($i.ToString('000'))"
    }
    return $ids
}

$ids = @()
$ids += Expand-IDRange -prefix 'A' -start 1 -end 672
$ids += Expand-IDRange -prefix 'B' -start 1 -end 53

$generatedCount = 0
$skippedCount = 0
$overwrittenCount = 0

foreach ($id in $ids) {
    $manifestPath = Join-Path $bucketDir "galgame-ttloli-$id.json"

    if ($id -in $IgnoreList) {
        $skippedCount++
        Write-Host "Skipped: $manifestPath (in ignore list)" -ForegroundColor Yellow
        continue
    }

    if ((Test-Path $manifestPath) -and (-not $Overwrite)) {
        $skippedCount++
        Write-Host "Skipped: $manifestPath (already exists, use -Overwrite to replace)" -ForegroundColor Yellow
        continue
    }

    $manifestContent = $templateContent -replace '<ID>', $id

    $manifestObj = $manifestContent | ConvertFrom-Json
    $manifestContent = $manifestObj | ConvertTo-Json -Depth 10

    $fileExisted = Test-Path $manifestPath
    Set-Content -Path $manifestPath -Value $manifestContent -Encoding UTF8 -NoNewline

    if ($fileExisted) {
        $overwrittenCount++
        Write-Host "Overwritten: $manifestPath" -ForegroundColor Cyan
    } else {
        $generatedCount++
        Write-Host "Generated: $manifestPath" -ForegroundColor Green
    }
}

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  Generated: $generatedCount manifests" -ForegroundColor Green
Write-Host "  Overwritten: $overwrittenCount manifests" -ForegroundColor Cyan
Write-Host "  Skipped: $skippedCount" -ForegroundColor Yellow
Write-Host "  Total: $($ids.Count) IDs" -ForegroundColor Cyan

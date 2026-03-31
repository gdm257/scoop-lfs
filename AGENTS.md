# AGENTS.md - Scoop LFS Bucket Repository Guide

This repository is a Scoop bucket for managing software package manifests. Agents working here should follow these conventions.

## Essential Commands

### Running Tests

- **All tests**: `pwsh bin/test.ps1` or `bin/test.ps1`
- **Single manifest test**: Use Pester filter with manifest name:
    ```pwsh
    $env:SCOOP_HOME = Convert-Path (scoop prefix scoop)
    pwsh bin/test.ps1 -Filter "*manifest-name*"
    ```
- **CI environment**: `$env:SCOOP_HOME` must be set to Scoop core path

### Validation Commands

- **Check versions**: `pwsh bin/checkver.ps1` or `bin/checkver.ps1`
- **Check URLs**: `pwsh bin/checkurls.ps1` or `bin/checkurls.ps1`
- **Check hashes**: `pwsh bin/checkhashes.ps1`
- **Auto PR**: `pwsh bin/auto-pr.ps1` (creates/update PRs)
- **Format JSON**: `pwsh bin/formatjson.ps1`
- **Find missing checkver**: `pwsh bin/missing-checkver.ps1`

### Environment Setup

```pwsh
if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Convert-Path (scoop prefix scoop) }
```

## Code Style Guidelines

### PowerShell Formatting

- **Indentation**: 4 spaces (OTBS - One True Brace Style)
- **Line endings**: CRLF (Windows-style)
- **Charset**: UTF-8
- **Format on save**: Enabled for PowerShell files
- **Alignment**: Property value pairs aligned
- **One-line blocks**: Ignored in formatting

### PowerShell Conventions

- **Shebang**: Use `#!/usr/bin/env pwsh` for standalone scripts
- **Version requirement**: Add `#Requires -Version 5.1` or higher
- **Modules**: Specify module versions:
    ```pwsh
    #Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }
    ```
- **Variable naming**: camelCase (`$myVariable`)
- **Function naming**: PascalCase (`Invoke-MyFunction`)
- **Parameters**: Use `[Parameter()]` attributes for validation
- **Error handling**: Use try/catch/finally blocks
- **Comments**: Single-line `#`, multi-line `<# ... #>`

### JSON Manifest Style

- **Indentation**: 2 spaces
- **Schema**: Always include `$schema` field referencing Scoop schema
- **Template**: Use `bucket/app-name.json.template` as starting point
- **Fields order**: version, description, homepage, license, architecture, pre/post_install, uninstaller
- **URLs**: Use HTTPS where possible
- **Hashes**: Provide SHA256 hashes for all binaries
- **Architecture**: Specify 64bit, 32bit, arm64 separately if needed

### Import Guidelines

- **PowerShell**: Use fully qualified module names when necessary
- **Scripts**: Use `$PSScriptRoot` for relative paths
- **Scoop core**: Reference via `$env:SCOOP_HOME`
- **Bucket scripts**: Use `$bucketsdir` for bucket-relative paths

### Testing Patterns

- **Test files**: Use `*.Tests.ps1` suffix (Pester 5.x)
- **Test structure**: Use `Describe`, `Context`, `It` blocks
- **Test discovery**: Pester auto-discovers tests in bucket directory
- **Mocking**: Use Pester's `Mock` command
- **Assertions**: Use `Should` matchers

### Error Handling

- **PowerShell**: Use `try/catch` with specific exceptions
- **Manifests**: Use `checkver` and `checkurls` for validation
- **Exit codes**: Return non-zero exit codes on failure
- **Verbose output**: Use `Write-Verbose` for debugging

### Naming Conventions

- **Manifest files**: `kebab-case.json` (lowercase with hyphens)
- **PowerShell functions**: `Verb-Noun` (approved PowerShell verbs)
- **Variables**: camelCase
- **Constants**: UPPER_SNAKE_CASE
- **Scripts**: `.ps1` suffix with descriptive names

### Script Templates

- Use templates in `bucket/` directory as starting points
- `app-name.json.template` - Standard application manifest
- `galgame-ttloli-template.json` - Specialized LFS-based installer

### CI/CD Notes

- Tests run on both Windows PowerShell and PowerShell Core
- CI triggered on push to main/master and pull requests
- Use workflow_dispatch for manual CI triggers
- Scoop core is checked out as `scoop_core` in CI

### LFS Integration

- Some manifests use LFS (Large File Storage) via rclone
- Pattern: `rclone copy "lfs:<path>" $dir`
- Archive expansion: Use bucket scripts in `scripts/7z/` (e.g., expand-archives-in-dir.ps1)
- Multipart archive handling: Script auto-detects volume patterns (part/rXX, .001, \_partX, .partX.rar, .rXX)

### Repository Structure

- `bucket/` - Package manifests (JSON)
- `bin/` - Utility scripts (PowerShell)
- `scripts/` - Helper scripts
- `.vscode/` - Editor settings and PSScriptAnalyzer config
- `.github/workflows/` - CI/CD workflows

### VS Code Configuration

- Required extensions: EditorConfig, PowerShell
- JSON validation: Scoop schema for bucket/\*.json files
- PSScriptAnalyzer: Configured via `PSScriptAnalyzerSettings.psd1`

### Best Practices

1. Always test manifests before committing
2. Use `checkver` to ensure version detection works
3. Validate URLs with `checkurls` before PR
4. Format JSON manifests with `formatjson`
5. Run full test suite before pushing
6. Use descriptive commit messages
7. Follow Scoop's manifest guidelines
8. Include `$schema` in all manifests
9. Specify license when known
10. Provide meaningful descriptions

### Quick Reference

```pwsh
# Run tests
pwsh bin/test.ps1

# Check a specific manifest
pwsh bin/checkver.ps1 manifest-name

# Format all JSON
pwsh bin/formatjson.ps1

# Validate URLs
pwsh bin/checkurls.ps1
```

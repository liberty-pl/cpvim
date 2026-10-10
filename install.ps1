#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Repo = '',
    [ValidateNotNullOrEmpty()][string]$Branch = 'main',
    [string]$Target = '',
    [switch]$InstallDeps
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($env:OS -ne 'Windows_NT') {
    throw 'Use install.sh on Linux/macOS.'
}

function Refresh-Path {
    $paths = @(
        [Environment]::GetEnvironmentVariable('Path', 'Machine'),
        [Environment]::GetEnvironmentVariable('Path', 'User'),
        $env:Path
    )
    $env:Path = ($paths | Where-Object { $_ }) -join ';'
}

function Install-WingetPackage([string]$Id) {
    & winget install --exact --id $Id --source winget --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget could not install $Id (exit $LASTEXITCODE)." }
    Refresh-Path
}

if ($InstallDeps) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'Install App Installer / winget first: https://learn.microsoft.com/windows/package-manager/winget/'
    }
    foreach ($package in @(
        @{ Command = 'nvim'; Id = 'Neovim.Neovim' },
        @{ Command = 'git'; Id = 'Git.Git' },
        @{ Command = 'rg'; Id = 'BurntSushi.ripgrep.MSVC' },
        @{ Command = 'fd'; Id = 'sharkdp.fd' }
    )) {
        if (-not (Get-Command $package.Command -ErrorAction SilentlyContinue)) {
            Install-WingetPackage $package.Id
        }
    }
    # MSYS2's initial system update may require restarting its terminal.
    # Leave that step explicit rather than interrupting an unattended installer.
    Write-Host 'For GNU C/C++ and tree-sitter CLI, follow the Windows dependency steps in README.md.'
}

if (-not $Target) {
    if (Get-Command nvim -ErrorAction SilentlyContinue) {
        $Target = (& nvim --headless -u NONE -i NONE -n -c "lua io.write(vim.fn.stdpath('config'))" -c qa | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or -not $Target) { throw 'Could not read the Neovim config directory.' }
    } else {
        $appName = if ($env:NVIM_APPNAME) { $env:NVIM_APPNAME } else { 'nvim' }
        if ($appName -in @('.', '..') -or $appName -match '[/\\]') { throw 'Invalid NVIM_APPNAME.' }
        $configHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $env:LOCALAPPDATA }
        if (-not $configHome) { throw 'LOCALAPPDATA is not set; supply -Target.' }
        $Target = Join-Path $configHome $appName
    }
}
$Target = [IO.Path]::GetFullPath($Target).TrimEnd('\', '/')
$root = [IO.Path]::GetPathRoot($Target).TrimEnd('\', '/')
if (-not $Target -or $Target -eq $root -or $Target -eq $env:USERPROFILE) {
    throw 'Refusing to replace the drive root or your user profile.'
}
$sourceDir = ''
if ($PSScriptRoot) {
    $sourceDir = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\', '/')
} elseif (-not $Repo) {
    throw 'When running a downloaded script block, supply -Repo URL.'
}
$parent = Split-Path -Parent $Target

$stage = $null
$backup = $null
$installed = $false
try {
    if (-not $Repo -and (
        -not (Test-Path -LiteralPath (Join-Path $sourceDir 'init.lua') -PathType Leaf) -or
        -not (Test-Path -LiteralPath (Join-Path $sourceDir 'lua/config/lazy.lua') -PathType Leaf))) {
        throw 'No local configuration found; supply -Repo URL.'
    }
    if (-not $Repo -and $Target -eq $sourceDir) {
        Write-Host "This configuration is already installed at $Target"
    } else {
        if (-not $Repo) {
            if ($Target.StartsWith($sourceDir + '\', [StringComparison]::OrdinalIgnoreCase) -or
                $sourceDir.StartsWith($Target + '\', [StringComparison]::OrdinalIgnoreCase)) {
                throw 'Source and target must not contain each other.'
            }
        } elseif (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw 'Git is required; install it or use -InstallDeps.'
        }
        [IO.Directory]::CreateDirectory($parent) | Out-Null
        $stage = Join-Path $parent ('.nvim-install.' + [Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($stage) | Out-Null
        if ($Repo) {
            & git clone --depth 1 --branch $Branch -- $Repo $stage
            if ($LASTEXITCODE -ne 0) { throw 'Repository clone failed; existing configuration is unchanged.' }
        } else {
            $excluded = @('.git', 'local.lua', 'lazy', 'node_modules', '.repro')
            Get-ChildItem -LiteralPath $sourceDir -Force | Where-Object {
                $_.Name -notin $excluded -and $_.Name -notmatch '\.sw[op]$'
            } | ForEach-Object {
                Copy-Item -LiteralPath $_.FullName -Destination $stage -Recurse -Force
            }
        }
        if (-not (Test-Path -LiteralPath (Join-Path $stage 'init.lua') -PathType Leaf) -or
            -not (Test-Path -LiteralPath (Join-Path $stage 'lua/config/lazy.lua') -PathType Leaf)) {
            throw 'The source does not contain this Neovim configuration.'
        }
        $localConfig = Join-Path $Target 'local.lua'
        if (Test-Path -LiteralPath $localConfig -PathType Leaf) {
            Copy-Item -LiteralPath $localConfig -Destination (Join-Path $stage 'local.lua') -Force
            Write-Host 'Preserving the existing local.lua'
        }
        if (Test-Path -LiteralPath $Target) {
            $backup = $Target + '.backup.' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.' + [Guid]::NewGuid().ToString('N')
            Move-Item -LiteralPath $Target -Destination $backup
            Write-Host "Backup: $backup"
        }
        Move-Item -LiteralPath $stage -Destination $Target
        $stage = $null
        $installed = $true
        Write-Host "Installed configuration: $Target"
    }
} finally {
    if (-not $installed -and $backup -and (Test-Path -LiteralPath $backup) -and -not (Test-Path -LiteralPath $Target)) {
        Move-Item -LiteralPath $backup -Destination $Target
    }
    if ($stage -and (Test-Path -LiteralPath $stage)) {
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
}

foreach ($tool in @('nvim', 'git', 'curl.exe', 'rg', 'fd', 'tree-sitter', 'gcc', 'g++')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Warning "Missing dependency: $tool (see README.md)"
    }
}
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    $versionText = (& nvim --version | Select-Object -First 1)
    if ($versionText -match 'v(\d+\.\d+\.\d+)' -and [version]$Matches[1] -lt [version]'0.12.0') {
        Write-Warning "Neovim is too old: $versionText. Upgrade to >= 0.12.0 before starting."
    }
}
Write-Host 'Next: launch nvim, run :Lazy restore, restart, then run :checkhealth.'
Write-Host 'For a custom -Target, configure XDG_CONFIG_HOME/NVIM_APPNAME to use that directory.'

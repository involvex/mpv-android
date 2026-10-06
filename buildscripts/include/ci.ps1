#Requires -Version 5.1

$BuildscriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$BuildscriptsDir\include\depinfo.ps1"

function Write-Msg {
    Write-Host "==> $args"
}

function Fetch-Prefix {
    param([string]$CacheMode, [string]$CacheFolder)
    
    if ($CacheMode -eq "folder") {
        $idFile = Join-Path $CacheFolder "id.txt"
        if (Test-Path $idFile) {
            $text = Get-Content $idFile -Raw
        } else {
            Write-Host "Cache seems to be empty"
        }
        Write-Host "Expecting '$ci_tarball', found '$text'"
        if ($text -eq $ci_tarball) {
            $dataFile = Join-Path $CacheFolder "data.tgz"
            if (Test-Path $dataFile) {
                tar -xzf $dataFile -C prefix
                return 0
            }
        }
    }
    return 1
}

function Build-Prefix {
    Write-Msg "Building the prefix ($ci_tarball)..."
    
    Write-Msg "Fetching deps"
    $env:IN_CI = 1
    & "$BuildscriptsDir\include\download-deps.ps1"
    
    Write-Msg "Compiling"
    & "$BuildscriptsDir\buildall.ps1" --only-deps mpv
    
    if ($CacheMode -eq "folder" -and (Test-Path $CacheFolder -PathType Container)) {
        Write-Msg "Compressing the prefix"
        $prefixDir = Join-Path $BuildscriptsDir "prefix"
        tar -cvzf "$CacheFolder\data.tgz" -C $prefixDir .
        $ci_tarball | Out-File -FilePath "$CacheFolder\id.txt" -Encoding ASCII
    }
}

$script:WGET = "wget --progress=bar:force"

$action = $args[0]

if ($action -eq "export") {
    Write-Host "CACHE_IDENTIFIER=$ci_tarball"
    exit 0
} elseif ($action -eq "install") {
    if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) {
        Write-Msg "Linking existing SDK"
        $sdkDir = Join-Path $BuildscriptsDir "sdk"
        if (-not (Test-Path $sdkDir)) {
            New-Item -ItemType Directory -Path $sdkDir | Out-Null
        }
        $linkTarget = Join-Path $sdkDir "android-sdk-windows"
        if (-not (Test-Path $linkTarget)) {
            # On Windows, create a junction instead of symlink
            cmd /c mklink /J "$linkTarget" $env:ANDROID_HOME 2>$null
        }
    }
    
    Write-Msg "Fetching SDK + NDK"
    $env:IN_CI = 1
    & "$BuildscriptsDir\include\download-sdk.ps1"
    
    Write-Msg "Fetching mpv"
    $depsDir = Join-Path $BuildscriptsDir "deps"
    $mpvDir = Join-Path $depsDir "mpv"
    if (-not (Test-Path $mpvDir)) {
        New-Item -ItemType Directory -Path $mpvDir | Out-Null
    }
    Invoke-WebRequest -Uri "https://github.com/mpv-player/mpv/archive/master.tar.gz" -UseBasicParsing -OutFile "master.tgz"
    tar -xzf "master.tgz" -C $mpvDir --strip-components=1
    Remove-Item "master.tgz" -Force
    
    Write-Msg "Trying to fetch existing prefix"
    $prefixDir = Join-Path $BuildscriptsDir "prefix"
    if (-not (Test-Path $prefixDir)) {
        New-Item -ItemType Directory -Path $prefixDir | Out-Null
    }
    Fetch-Prefix -CacheMode $CacheMode -CacheFolder $CacheFolder
    exit 0
} elseif ($action -eq "build") {
    # run build
} else {
    exit 1
}

Write-Msg "Building mpv"
& "$BuildscriptsDir\buildall.ps1" -n mpv
if ($LASTEXITCODE -ne 0) {
    if (-not (Test-Path "deps\mpv\_build\config.h")) {
        Get-Content "deps\mpv\_build\meson-logs\meson-log.txt" -ErrorAction SilentlyContinue
    }
    exit 1
}

Write-Msg "Building mpv-android"
& "$BuildscriptsDir\buildall.ps1" -n

exit 0
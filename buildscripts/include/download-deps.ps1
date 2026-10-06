#Requires -Version 5.1

. "$PSScriptRoot\depinfo.ps1"

if (-not $env:IN_CI) { $env:IN_CI = 0 }
if (-not $env:WGET) { $env:WGET = "wget" }

$BuildscriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DepsDir = Join-Path $BuildscriptsDir "deps"

if (-not (Test-Path $DepsDir)) {
    New-Item -ItemType Directory -Path $DepsDir | Out-Null
}

Push-Location $DepsDir

# mbedtls
if (-not (Test-Path "mbedtls")) {
    New-Item -ItemType Directory -Path "mbedtls" | Out-Null
    $url = "https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-$v_mbedtls/mbedtls-$v_mbedtls.tar.bz2"
    Invoke-WebRequest -Uri $url -UseBasicParsing | Expand-Archive -DestinationPath "mbedtls" -Force
    Get-ChildItem "mbedtls" | Move-Item -Destination "mbedtls\temp" -Force
    Get-ChildItem "mbedtls\temp" | Move-Item -Destination "mbedtls" -Force
    Remove-Item "mbedtls\temp" -Recurse -Force
}

# dav1d
if (-not (Test-Path "dav1d")) {
    git clone https://github.com/videolan/dav1d
}

# ffmpeg
if (-not (Test-Path "ffmpeg")) {
    $args = @()
    if ($env:IN_CI -eq 1) { $args = @("--depth=1", "-b", $v_ci_ffmpeg) }
    git clone https://github.com/FFmpeg/FFmpeg ffmpeg @args
}

# freetype2
if (-not (Test-Path "freetype2")) {
    $v_freetype_dash = $v_freetype -replace '\.', '-'
    git clone --recurse-submodules https://gitlab.freedesktop.org/freetype/freetype.git freetype2 -b "VER-$v_freetype_dash"
}

# fribidi
if (-not (Test-Path "fribidi")) {
    New-Item -ItemType Directory -Path "fribidi" | Out-Null
    $url = "https://github.com/fribidi/fribidi/releases/download/v$v_fribidi/fribidi-$v_fribidi.tar.xz"
    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile "fribidi.tar.xz"
    tar -xJ -f "fribidi.tar.xz" -C "fribidi" --strip-components=1
    Remove-Item "fribidi.tar.xz" -Force
}

# harfbuzz
if (-not (Test-Path "harfbuzz")) {
    New-Item -ItemType Directory -Path "harfbuzz" | Out-Null
    $url = "https://github.com/harfbuzz/harfbuzz/releases/download/$v_harfbuzz/harfbuzz-$v_harfbuzz.tar.xz"
    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile "harfbuzz.tar.xz"
    tar -xJ -f "harfbuzz.tar.xz" -C "harfbuzz" --strip-components=1
    Remove-Item "harfbuzz.tar.xz" -Force
}

# unibreak
if (-not (Test-Path "unibreak")) {
    New-Item -ItemType Directory -Path "unibreak" | Out-Null
    $v_unibreak_underscore = $v_unibreak -replace '\.', '_'
    $url = "https://github.com/adah1972/libunibreak/releases/download/libunibreak_${v_unibreak_underscore}/libunibreak-${v_unibreak}.tar.gz"
    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile "unibreak.tar.gz"
    tar -xz -f "unibreak.tar.gz" -C "unibreak" --strip-components=1
    Remove-Item "unibreak.tar.gz" -Force
}

# libxml2
if (-not (Test-Path "libxml2")) {
    New-Item -ItemType Directory -Path "libxml2" | Out-Null
    $url = "https://gitlab.gnome.org/GNOME/libxml2/-/archive/v${v_libxml2}/libxml2-v${v_libxml2}.tar.gz"
    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile "libxml2.tar.gz"
    tar -xz -f "libxml2.tar.gz" -C "libxml2" --strip-components=1
    Remove-Item "libxml2.tar.gz" -Force
}

# fontconfig
if (-not (Test-Path "fontconfig")) {
    New-Item -ItemType Directory -Path "fontconfig" | Out-Null
    $url = "https://gitlab.freedesktop.org/fontconfig/fontconfig/-/archive/${v_fontconfig}/fontconfig-${v_fontconfig}.tar.gz"
    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile "fontconfig.tar.gz"
    tar -xz -f "fontconfig.tar.gz" -C "fontconfig" --strip-components=1
    Remove-Item "fontconfig.tar.gz" -Force
}

# libass
if (-not (Test-Path "libass")) {
    git clone https://github.com/libass/libass
}

# lua
if (-not (Test-Path "lua")) {
    New-Item -ItemType Directory -Path "lua" | Out-Null
    $url = "https://www.lua.org/ftp/lua-$v_lua.tar.gz"
    Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile "lua.tar.gz"
    tar -xz -f "lua.tar.gz" -C "lua" --strip-components=1
    Remove-Item "lua.tar.gz" -Force
}

# libplacebo
if (-not (Test-Path "libplacebo")) {
    git clone --recursive https://github.com/haasn/libplacebo
}

# mpv
if (-not (Test-Path "mpv")) {
    git clone https://github.com/mpv-player/mpv
}

Pop-Location
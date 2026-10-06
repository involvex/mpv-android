#Requires -Version 5.1

$BuildscriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$BuildscriptsDir\include\depinfo.ps1"

$cleanbuild = 0
$nodeps = 0
$onlydeps = 0
$target = "mpv-android"
$arch = "armv7l"

# Get dependencies hashtable
function Get-Deps {
    param([string]$depName)
    $varName = "dep_$($depName -replace '-','_')"
    return Get-Variable -Name $varName -ValueOnly -ErrorAction SilentlyContinue
}

$script:built_mpv = $null
$script:built_mpv_android = $null

function Was-Built {
    param([string]$name)
    $varName = "built_$($name -replace '-','_')"
    $val = Get-Variable -Name $varName -ValueOnly -ErrorAction SilentlyContinue
    return ($val -ne $null)
}

function Mark-Built {
    param([string]$name)
    $varName = "built_$($name -replace '-','_')"
    Set-Variable -Name $varName -Value 0 -Scope script
}

function Load-Arch {
    param([string]$archName)
    
    # Clear environment variables
    Remove-Item Env:\CC -ErrorAction SilentlyContinue
    Remove-Item Env:\CXX -ErrorAction SilentlyContinue
    Remove-Item Env:\CPATH -ErrorAction SilentlyContinue
    Remove-Item Env:\LIBRARY_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:\C_INCLUDE_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:\CPLUS_INCLUDE_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:\CFLAGS -ErrorAction SilentlyContinue
    Remove-Item Env:\CXXFLAGS -ErrorAction SilentlyContinue
    Remove-Item Env:\CPPFLAGS -ErrorAction SilentlyContinue
    Remove-Item Env:\LDFLAGS -ErrorAction SilentlyContinue
    
    $apilvl = 21
    
    if ($archName -eq "armv7l") {
        $script:ndk_suffix = ""
        $script:ndk_triple = "arm-linux-androideabi"
        $cc_triple = "armv7a-linux-androideabi$apilvl"
        $script:prefix_name = "armv7l"
    } elseif ($archName -eq "arm64") {
        $script:ndk_suffix = "-arm64"
        $script:ndk_triple = "aarch64-linux-android"
        $cc_triple = "$script:ndk_triple$apilvl"
        $script:prefix_name = "arm64"
    } elseif ($archName -eq "x86") {
        $script:ndk_suffix = "-x86"
        $script:ndk_triple = "i686-linux-android"
        $cc_triple = "$script:ndk_triple$apilvl"
        $script:prefix_name = "x86"
    } elseif ($archName -eq "x86_64") {
        $script:ndk_suffix = "-x64"
        $script:ndk_triple = "x86_64-linux-android"
        $cc_triple = "$script:ndk_triple$apilvl"
        $script:prefix_name = "x86_64"
    } else {
        Write-Error "Invalid architecture: $archName"
        exit 1
    }
    
    $script:prefix_dir = "$BuildscriptsDir\prefix\$script:prefix_name"
    $env:CC = "$cc_triple-clang"
    $env:CXX = "$cc_triple-clang++"
    $env:LDFLAGS = "-Wl,-O1,--icf=safe -Wl,-z,max-page-size=16384"
    $env:AR = "llvm-ar"
    $env:RANLIB = "llvm-ranlib"
}

function Setup-Prefix {
    if (-not (Test-Path $script:prefix_dir)) {
        New-Item -ItemType Directory -Path $script:prefix_dir -Force | Out-Null
        # enforce flat structure (/usr/local -> /)
        $usrLink = Join-Path $script:prefix_dir "usr"
        $localLink = Join-Path $script:prefix_dir "local"
        if (-not (Test-Path $usrLink)) {
            New-Item -ItemType Junction -Path $usrLink -Target $script:prefix_dir | Out-Null
        }
        if (-not (Test-Path $localLink)) {
            New-Item -ItemType Junction -Path $localLink -Target $script:prefix_dir | Out-Null
        }
    }
    
    $cpu_family = $script:ndk_triple -replace '-.*', ''
    if ($cpu_family -eq "i686") { $cpu_family = "x86" }
    
    $pkgConfig = Get-Command pkg-config -ErrorAction SilentlyContinue
    if (-not $pkgConfig) {
        Write-Error "pkg-config is missing!"
        return 1
    }
    
    # meson wants this file, so create it ahead of time
    # also define: release build, static libs and no source downloads at runtime
    $crossfile = @"
[built-in options]
buildtype = 'release'
default_library = 'static'
wrap_mode = 'nodownload'
prefix = '/usr/local'
[binaries]
c = '$($env:CC)'
cpp = '$($env:CXX)'
ar = 'llvm-ar'
nm = 'llvm-nm'
strip = 'llvm-strip'
pkgconfig = 'pkg-config'
pkg-config = 'pkg-config'
[host_machine]
system = 'android'
cpu_family = '$cpu_family'
cpu = '$($env:CC -replace '-.*', '')'
endian = 'little'
"@
    
    $crossfileTmp = Join-Path $script:prefix_dir "crossfile.tmp"
    $crossfileTxt = Join-Path $script:prefix_dir "crossfile.txt"
    $crossfile | Out-File -FilePath $crossfileTmp -Encoding ASCII
    
    # Avoid rewriting unnecessarily
    if ((Test-Path $crossfileTmp) -and (Test-Path $crossfileTxt)) {
        $tmpContent = Get-Content $crossfileTmp -Raw
        $txtContent = Get-Content $crossfileTxt -Raw -ErrorAction SilentlyContinue
        if ($tmpContent -eq $txtContent) {
            Remove-Item $crossfileTmp -Force
        } else {
            Move-Item -Path $crossfileTmp -Destination $crossfileTxt -Force
        }
    } elseif (Test-Path $crossfileTmp) {
        Move-Item -Path $crossfileTmp -Destination $crossfileTxt -Force
    }
}

function Build {
    param([string]$depName)
    
    $depsDir = Join-Path $BuildscriptsDir "deps"
    
    if ($depName -ne "mpv-android" -and -not (Test-Path "$depsDir\$depName")) {
        Write-Host "Target $depName not found" -ForegroundColor Red
        return 1
    }
    
    if (Was-Built -name $depName) {
        return 0
    }
    
    if ($nodeps -eq 0) {
        Write-Host "Preparing $depName..." -ForegroundColor Cyan
        $deps = Get-Deps -depName $depName
        Write-Host "Dependencies: $deps"
        if ($deps) {
            foreach ($dep in $deps) {
                Build -depName $dep
            }
        }
    }
    
    Write-Host "Building $depName..." -ForegroundColor Cyan
    
    if ($depName -eq "mpv-android") {
        Push-Location "$BuildscriptsDir\.."
        $buildscript = "buildscripts\scripts\$depName.ps1"
    } else {
        Push-Location "$depsDir\$depName"
        $buildscript = "..\..\scripts\$depName.ps1"
    }
    
    if ($cleanbuild -eq 1 -and (Test-Path $buildscript)) {
        & $buildscript clean
    }
    if (Test-Path $buildscript) {
        & $buildscript build
    }
    
    Pop-Location
    Mark-Built -name $depName
}

function Show-Usage {
    Write-Host @"
Usage: buildall.ps1 [options] [target]
Builds the specified target (default: $target)

-n             Do not build dependencies
--only-deps    Build only dependencies of the specified target
--clean        Clean build dirs before compiling
--arch <arch>  Build for specified architecture (default: $arch; supported: armv7l, arm64, x86, x86_64)
"@
    exit 0
}

# Parse arguments
$args = $MyInvocation.UnboundArguments
while ($args.Count -gt 0) {
    $arg = $args[0]
    switch ($arg) {
        "--clean" { $cleanbuild = 1; $args = $args[1..($args.Count-1)] }
        "-n" { $nodeps = 1; $args = $args[1..($args.Count-1)] }
        "--no-deps" { $nodeps = 1; $args = $args[1..($args.Count-1)] }
        "--only-deps" { $onlydeps = 1; $args = $args[1..($args.Count-1)] }
        "--arch" { 
            $args = $args[1..($args.Count-1)]
            $arch = $args[0]
            $args = $args[1..($args.Count-1)]
        }
        "-h" { Show-Usage }
        "--help" { Show-Usage }
        default { $target = $arg; $args = $args[1..($args.Count-1)] }
    }
}

Load-Arch -archName $arch
Setup-Prefix

if ($onlydeps -eq 1) {
    $deps = Get-Deps -depName $target
    if ($deps) {
        foreach ($dep in $deps) {
            Build -depName $dep
        }
    }
} else {
    Build -depName $target
}

# List output APKs if they exist
$appDir = Join-Path $BuildscriptsDir "..\app"
$outputsDir = Join-Path $appDir "build\outputs\apk"

if (Was-Built -name "mpv-android" -and (Test-Path $outputsDir)) {
    Get-ChildItem -Path $outputsDir -Recurse -Filter "*.apk" | ForEach-Object {
        Write-Host "Found APK: $($_.FullName)"
    }
}

exit 0
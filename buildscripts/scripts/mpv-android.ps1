#Requires -Version 5.1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir = Split-Path -Parent $ScriptDir
$MpAndroid = Split-Path -Parent $BuildDir

. "$BuildDir\include\path.ps1"
. "$BuildDir\include\depinfo.ps1"

$action = $args[0]

if ($action -eq "build") {
    # do nothing, just continue
} elseif ($action -eq "clean") {
    $mainDir = Join-Path $MpAndroid "app\src\main"
    $buildDir = Join-Path $MpAndroid "app\build"
    $libsDir = Join-Path $mainDir "libs"
    $objDir = Join-Path $mainDir "obj"
    
    if (Test-Path $buildDir) {
        Remove-Item $buildDir -Recurse -Force
    }
    if (Test-Path $libsDir) {
        Remove-Item $libsDir -Recurse -Force
    }
    if (Test-Path $objDir) {
        Remove-Item $objDir -Recurse -Force
    }
    exit 0
} else {
    exit 255
}

if ($env:ANDROID_SIGNING_KEY) {
    $BUNDLE = 1
}

function Get-NativePrefix {
    param([string]$arch)
    $prefixArch = Join-Path $BuildDir "prefix\$arch"
    $libPath = Join-Path $prefixArch "lib\libmpv.so"
    if (Test-Path $libPath) {
        return $prefixArch
    } else {
        Write-Host "Warning: libmpv.so not found in native prefix for $arch, support will be omitted" -ForegroundColor Yellow
        return $null
    }
}

$prefix32 = Get-NativePrefix -arch "armv7l"
$prefix64 = Get-NativePrefix -arch "arm64"
$prefix_x64 = Get-NativePrefix -arch "x86_64"
$prefix_x86 = Get-NativePrefix -arch "x86"

if (-not $prefix32 -and -not $prefix64 -and -not $prefix_x64 -and -not $prefix_x86) {
    Write-Error "Error: no mpv library detected."
    exit 255
}

$env:PREFIX32 = $prefix32
$env:PREFIX64 = $prefix64
$env:PREFIX_X64 = $prefix_x64
$env:PREFIX_X86 = $prefix_x86

# Run ndk-build
Push-Location (Join-Path $MpAndroid "app\src\main")
$ndkBuild = "$env:ANDROID_HOME\ndk-build"
if (Test-Path $ndkBuild) {
    & $ndkBuild -j$cores
}
Pop-Location

# Run gradlew
$gradlew = Join-Path $MpAndroid "gradlew.bat"
$targets = @("assembleDebug")

if (-not $env:DONT_BUILD_RELEASE) {
    $targets += "assembleRelease"
    if ($BUNDLE) {
        $targets += "bundleRelease"
    }
}

& $gradlew @targets

# Sign APKs if needed
if ($env:ANDROID_SIGNING_KEY) {
    $outputsDir = Join-Path $MpAndroid "app\build\outputs\apk"
    $apksigner = Join-Path $env:ANDROID_HOME "build-tools\$v_sdk_build_tools\apksigner.bat"
    
    @("default", "api29") | ForEach-Object {
        $v = $_
        $vDir = Join-Path $outputsDir $v
        if (Test-Path $vDir) {
            Push-Location $vDir
            # Sign the universal debug APK
            $debugApk = "debug\app-$v-universal-debug.apk"
            if (Test-Path $debugApk) {
                & $apksigner sign --ks $env:ANDROID_SIGNING_KEY --in $debugApk --out "debug\app-$v-universal-debug-signed.apk"
            }
            # Sign release APKs
            Get-ChildItem -Path "release" -Filter "*-unsigned.apk" | ForEach-Object {
                $inFile = $_.FullName
                $outFile = $inFile -replace "-unsigned", "-signed"
                & $apksigner sign --ks $env:ANDROID_SIGNING_KEY --in $inFile --out $outFile
            }
            Pop-Location
        }
    }
    
    # Sign the bundle
    if ($BUNDLE) {
        $bundleDir = Join-Path $outputsDir "bundle\defaultRelease"
        if ($env:ANDROID_SIGNING_ALIAS -and (Test-Path $bundleDir)) {
            Push-Location $bundleDir
            if (-not $env:ANDROID_SIGNING_ALIAS) {
                Write-Error "Error: ANDROID_SIGNING_ALIAS must be set to use jarsigner"
                exit 1
            }
            jarsigner -keystore $env:ANDROID_SIGNING_KEY -signedjar "app-default-release-signed.aab" "app-default-release.aab" $env:ANDROID_SIGNING_ALIAS
            Pop-Location
        }
    }
}
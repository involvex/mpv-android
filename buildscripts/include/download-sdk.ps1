#Requires -Version 5.1

. "$PSScriptRoot\depinfo.ps1"
. "$PSScriptRoot\path.ps1"

if (-not $env:IN_CI) { $env:IN_CI = 0 }
if (-not $env:WGET) { $env:WGET = "wget" }

$os_ndk = $null

if ($os -eq "linux") {
    if ($env:IN_CI -eq 0) {
        $hasYum = Get-Command yum -ErrorAction SilentlyContinue
        $hasApt = Get-Command apt-get -ErrorAction SilentlyContinue
        if ($hasYum) {
            Write-Host "Installing dependencies with yum..."
            # Requires elevated privileges
        } elseif ($hasApt) {
            Write-Host "Installing dependencies with apt-get..."
            # Requires elevated privileges
        } else {
            Write-Host "Note: dependencies were not installed, you have to do that manually."
        }
    }

    $javac = Get-Command javac -ErrorAction SilentlyContinue
    if (-not $javac) {
        Write-Host "Error: missing Java Development Kit."
        exit 255
    }
    $os_ndk = "linux"
} elseif ($os -eq "mac") {
    if ($env:IN_CI -eq 0) {
        $hasBrew = Get-Command brew -ErrorAction SilentlyContinue
        if (-not $hasBrew) {
            Write-Host "Error: brew not found. You need to install Homebrew: https://brew.sh/"
            exit 255
        }
        # brew install automake autoconf libtool pkg-config coreutils gnu-sed wget meson ninja gperf
    }
    $javac = Get-Command javac -ErrorAction SilentlyContinue
    if (-not $javac) {
        Write-Host "Error: missing Java Development Kit. Install it manually."
        exit 255
    }
} elseif ($os -eq "windows") {
    Write-Host "Windows detected - assuming Android Studio SDK is available"
    # On Windows, we typically use Android Studio or pre-installed SDK
}

$BuildscriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SdkDir = Join-Path $BuildscriptsDir "sdk"

if (-not (Test-Path $SdkDir)) {
    New-Item -ItemType Directory -Path $SdkDir | Out-Null
}
Push-Location $SdkDir

# Android SDK
$androidSdkDir = "android-sdk-${os}"
$cmdlineToolsUrl = "https://dl.google.com/android/repository/commandlinetools-${os}-${v_sdk}.zip"

if (-not (Test-Path $androidSdkDir)) {
    Write-Host "Android SDK not found. Downloading commandline tools."
    Invoke-WebRequest -Uri $cmdlineToolsUrl -UseBasicParsing -OutFile "commandlinetools.zip"
    New-Item -ItemType Directory -Path $androidSdkDir | Out-Null
    Expand-Archive -Path "commandlinetools.zip" -DestinationPath $androidSdkDir -Force
    Remove-Item "commandlinetools.zip" -Force
}

# sdkmanager
function Get-SdkManager {
    $exe = Join-Path $androidSdkDir "cmdline-tools\latest\bin\sdkmanager.bat"
    if (-not (Test-Path $exe)) {
        $exe = Join-Path $androidSdkDir "cmdline-tools\bin\sdkmanager.bat"
    }
    return $exe
}

$sdkmanager = Get-SdkManager
& cmd /c echo y | "$sdkmanager" --sdk_root=$env:ANDROID_HOME "platforms;android-${v_sdk_platform}" "build-tools;${v_sdk_build_tools}" "extras;android;m2repository"

# Android NDK
$ndkDir = "android-ndk-${v_ndk}"
$ndkInstallDir = Join-Path $androidSdkDir "ndk\$v_ndk_n"

if (Test-Path $ndkDir) {
    Write-Host "Android NDK directory found."
} elseif (Test-Path $ndkInstallDir) {
    Write-Host "Creating NDK symlink to SDK."
    New-Item -ItemType Junction -Path $ndkDir -Target $ndkInstallDir | Out-Null
} elseif (-not $os_ndk) {
    Write-Host "Downloading NDK with sdkmanager."
    & cmd /c echo y | "$sdkmanager" "ndk;${v_ndk_n}"
    New-Item -ItemType Junction -Path $ndkDir -Target $ndkInstallDir | Out-Null
} else {
    Write-Host "Downloading NDK."
    $ndkUrl = "http://dl.google.com/android/repository/android-ndk-${v_ndk}-${os_ndk}.zip"
    Invoke-WebRequest -Uri $ndkUrl -UseBasicParsing -OutFile "android-ndk.zip"
    Expand-Archive -Path "android-ndk.zip" -Force
    Remove-Item "android-ndk.zip" -Force
}

# Verify NDK version
$sourceProps = Join-Path $ndkDir "source.properties"
if (Test-Path $sourceProps) {
    $content = Get-Content $sourceProps -Raw
    if (-not $content.Contains($v_ndk_n)) {
        Write-Host "Error: NDK exists but is not the correct version (expecting ${v_ndk_n})"
        exit 255
    }
}

# gas-preprocessor
$binDir = Join-Path $BuildscriptsDir "bin"
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir | Out-Null
}
$gasPreprocessor = Join-Path $binDir "gas-preprocessor.pl"
if (-not (Test-Path $gasPreprocessor)) {
    Invoke-WebRequest -Uri "https://github.com/FFmpeg/gas-preprocessor/raw/master/gas-preprocessor.pl" -UseBasicParsing -OutFile $gasPreprocessor
}

Pop-Location
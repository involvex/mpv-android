#Requires -Version 5.1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ParentDir = Split-Path -Parent $ScriptDir

. "$ScriptDir\depinfo.ps1"

$_isWindows = $IsWindows
$isWindows = $IsWindows
$isMac = $IsMacOS
$isLinux = $IsLinux

if ($isWindows) {
    $script:os = "windows"
} elseif ($isMac) {
    $script:os = "mac"
} else {
    $script:os = "linux"
}

if (-not $script:cores) {
    if ($isWindows) {
        $script:cores = (Get-WmiObject Win32_Processor).NumberOfCores | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        if (-not $script:cores) { $script:cores = 4 }
    } elseif ($isMac) {
        $script:cores = sysctl -n hw.ncpu
    } else {
        $script:cores = (Get-Content /proc/cpuinfo | Select-String "^processor" | Measure-Object).Count
    }
}
if (-not $script:cores) { $script:cores = 4 }

$script:INSTALL = if ($isMac) { Get-Command ginstall -ErrorAction SilentlyContinue } else { Get-Command install -ErrorAction SilentlyContinue }
$script:SED = if ($isMac) { "gsed" } else { "sed" }

# configure pkg-config paths if inside buildscripts
if ($script:ndk_triple) {
    $env:PKG_CONFIG_SYSROOT_DIR = $script:prefix_dir
    $env:PKG_CONFIG_LIBDIR = "$script:prefix_dir\lib\pkgconfig"
    Remove-Item Env:\PKG_CONFIG_PATH -ErrorAction SilentlyContinue
}

$toolchain = Get-ChildItem "$ScriptDir\..\sdk\android-ndk-${v_ndk}\toolchains\llvm\prebuilt\*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($toolchain) {
    $env:PATH = "$($toolchain.FullName);$ScriptDir\..\sdk\android-ndk-${v_ndk};$ScriptDir\..\sdk\bin;$env:PATH"
}
$env:ANDROID_HOME = "$ScriptDir\..\sdk\android-sdk-${script:os}"
Remove-Item Env:\ANDROID_SDK_ROOT -ErrorAction SilentlyContinue
Remove-Item Env:\ANDROID_NDK_ROOT -ErrorAction SilentlyContinue
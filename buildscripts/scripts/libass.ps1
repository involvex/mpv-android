#Requires -Version 5.1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$ScriptDir\..\include\path.ps1"

$action = $args[0]

if ($action -eq "build") {
    # do nothing
} elseif ($action -eq "clean") {
    $buildDir = "_build$ndk_suffix"
    if (Test-Path $buildDir) {
        Remove-Item $buildDir -Recurse -Force
    }
    exit 0
} else {
    exit 255
}

$autogen = Join-Path $ScriptDir "configure"
if (-not (Test-Path $autogen)) {
    $script:autogen = Join-Path $ScriptDir "autogen.ps1"
    if (Test-Path $script:autogen) {
        & $script:autogen
    }
}

$buildDir = "_build$ndk_suffix"
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}
Push-Location $buildDir

$configure = Join-Path $ScriptDir "configure"
& $configure --host=$ndk_triple --with-pic --enable-static --disable-shared --enable-libunibreak --enable-fontconfig

make -j$cores
make DESTDIR=$prefix_dir install

Pop-Location
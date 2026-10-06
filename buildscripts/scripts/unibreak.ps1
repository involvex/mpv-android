#Requires -Version 5.1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$ScriptDir\..\include\path.ps1"

$build = "_build$ndk_suffix"

$action = $args[0]

if ($action -eq "build") {
    # do nothing
} elseif ($action -eq "clean") {
    if (Test-Path $build) {
        Remove-Item $build -Recurse -Force
    }
    exit 0
} else {
    exit 255
}

if (-not (Test-Path $build)) {
    New-Item -ItemType Directory -Path $build | Out-Null
}
Push-Location $build

$configure = Join-Path $ScriptDir "configure"
& $configure --host=$ndk_triple --with-pic --enable-static --disable-shared

make -j$cores
make DESTDIR=$prefix_dir install

Pop-Location
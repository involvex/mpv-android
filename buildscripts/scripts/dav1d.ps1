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

Remove-Item Env:\CC -ErrorAction SilentlyContinue
Remove-Item Env:\CXX -ErrorAction SilentlyContinue

$crossfile = Join-Path $prefix_dir "crossfile.txt"

meson setup $build --cross-file $crossfile -Denable_tests=false -Db_lto=true -Dstack_alignment=16

ninja -C $build -j$cores
DESTDIR=$prefix_dir ninja -C $build install
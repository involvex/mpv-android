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

meson setup $build --cross-file $crossfile -Dvulkan=disabled -Ddemos=false

ninja -C $build -j$cores
DESTDIR=$prefix_dir ninja -C $build install

# Add missing library for static linking
$pcFile = Join-Path $prefix_dir "lib\pkgconfig\libplacebo.pc"
if (Test-Path $pcFile) {
    $content = Get-Content $pcFile -Raw
    if ($content -notmatch " -lc\+\+$") {
        $content = $content -replace "(\|Libs:.*)`$", '$1 -lc++'
        Set-Content -Path $pcFile -Value $content -NoNewline
    }
}
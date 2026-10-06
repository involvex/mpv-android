#Requires -Version 5.1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$ScriptDir\..\include\path.ps1"

$action = $args[0]

if ($action -eq "build") {
    # do nothing
} elseif ($action -eq "clean") {
    make clean
    exit 0
} else {
    exit 255
}

# Building separately from source tree is not supported
& $MyInvocation.InvocationName clean

$mycflags = @(
    "-fPIC",
    "-Dgetlocaledecpoint\(.\)=\(46)",
    "-Dlua_fseek"
)

$build = "linux"
$env:LUA_T = ""
$env:LUAC_T = ""

$env:CC = $CC
$env:AR = "$AR rc"
$env:RANLIB = $RANLIB
$env:MYCFLAGS = $mycflags -join " "
$env:PLAT = $build

make -j$cores

$installCmd = if ($env:INSTALL) { $env:INSTALL } else { "install" }
make INSTALL=$installCmd INSTALL_TOP=$prefix_dir TO_BIN=/dev/null install

# Generate pkg-config file
$pcDir = Join-Path $prefix_dir "lib\pkgconfig"
if (-not (Test-Path $pcDir)) {
    New-Item -ItemType Directory -Path $pcDir | Out-Null
}
$version = "5.2"
$pcContent = @"
Name: Lua
Description: 
Version: $version
Libs: -L`${libdir} -llua
Cflags: -I`${includedir}
"@
$pcFile = Join-Path $pcDir "lua.pc"
Set-Content -Path $pcFile -Value $pcContent
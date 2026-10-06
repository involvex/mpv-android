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

& $MyInvocation.InvocationName clean

if ($ndk_triple -match "i686.*") {
    python scripts/config.py unset MBEDTLS_AESNI_C
} else {
    python scripts/config.py set MBEDTLS_AESNI_C
}

make -j$cores no_test
make DESTDIR=$prefix_dir install
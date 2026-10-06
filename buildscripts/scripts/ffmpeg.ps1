#Requires -Version 5.1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$ScriptDir\..\include\path.ps1"

$action = $args[0]

if ($action -eq "build") {
    # do nothing, just continue
} elseif ($action -eq "clean") {
    $buildDir = "_build$ndk_suffix"
    if (Test-Path $buildDir) {
        Remove-Item $buildDir -Recurse -Force
    }
    exit 0
} else {
    exit 255
}

$buildDir = "_build$ndk_suffix"
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}
Push-Location $buildDir

$cpu = "armv7-a"
if ($ndk_triple -match "aarch64.*") { $cpu = "armv8-a" }
if ($ndk_triple -match "x86_64.*") { $cpu = "generic" }
if ($ndk_triple -match "i686.*") { $cpu = "i686" }

$cpuflags = ""
if ($ndk_triple -match "arm.*") { $cpuflags = "-mfpu=neon -mcpu=cortex-a8" }

$args = @(
    "--target-os=android",
    "--enable-cross-compile",
    "--cross-prefix=$ndk_triple-",
    "--cc=$CC",
    "--pkg-config=pkg-config",
    "--nm=llvm-nm",
    "--arch=$($ndk_triple -replace '-.*', '')",
    "--cpu=$cpu",
    "--extra-cflags=-I$prefix_dir\include $cpuflags",
    "--extra-ldflags=-L$prefix_dir\lib",
    
    "--enable-jni",
    "--enable-mediacodec",
    "--enable-mbedtls",
    "--enable-libdav1d",
    "--enable-libxml2",
    "--disable-vulkan",
    
    "--disable-static",
    "--enable-shared",
    "--enable-gpl",
    "--enable-version3",
    
    "--disable-stripping",
    "--disable-doc",
    "--disable-programs",
    
    "--disable-muxers",
    "--disable-encoders",
    "--disable-devices",
    
    "--enable-encoder=mjpeg,png",
    "--enable-muxer=mov,matroska,mpegts"
)

$configure = Join-Path $ScriptDir "..\..\deps\ffmpeg\configure"
& $configure @args

# Run make (on Windows, this needs MSYS or equivalent)
make -j$cores
make DESTDIR=$prefix_dir install

Pop-Location
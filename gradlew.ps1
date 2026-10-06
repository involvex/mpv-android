#Requires -Version 5.1

param(
    [string]$Tasks,
    [switch]$Debug,
    [switch]$Info,
    [switch]$Stacktrace
)

$AppDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$GradleOpts = @()
if ($Debug) { $GradleOpts += "--debug" }
if ($Info) { $GradleOpts += "--info" }
if ($Stacktrace) { $GradleOpts += "--stacktrace" }

$env:GRADLE_OPTS = $GradleOpts -join " "

$gradlewBat = Join-Path $AppDir "gradlew.bat"

if ($Tasks) {
    & $gradlewBat $Tasks
} else {
    & $gradlewBat
}
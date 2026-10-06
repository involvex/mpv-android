#Requires -Version 5.1

$BuildscriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path

& "$BuildscriptsDir\include\download-sdk.ps1"
& "$BuildscriptsDir\include\download-deps.ps1"
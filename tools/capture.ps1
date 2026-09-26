# Records a play session of the exported Steam build for store screenshots and trailers.
# Runs the game fullscreen on the main 1920x1080 monitor and records the screen until you quit the game.
#
#   powershell -ExecutionPolicy Bypass -File tools/capture.ps1

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$game = Join-Path $repo "builds\steam\windows\Slush Rush.exe"
if (-not (Test-Path $game)) { throw "Run tools/build.ps1 first" }

$outDir = Join-Path $repo "builds\capture"
New-Item -ItemType Directory -Force $outDir | Out-Null
$out = Join-Path $outDir ("session_{0}.mp4" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

$play = Start-Process $game -ArgumentList "--fullscreen", "--screen", "0" -PassThru
Start-Sleep -Seconds 2

# NVENC keeps the encoding off the CPU so the game doesn't stutter
$ffmpeg = New-Object System.Diagnostics.Process
$ffmpeg.StartInfo.FileName = "ffmpeg"
$ffmpeg.StartInfo.Arguments = "-hide_banner -loglevel error -f gdigrab -framerate 60 -offset_x 0 -offset_y 0 -video_size 1920x1080 -draw_mouse 1 -i desktop -c:v h264_nvenc -preset p5 -rc vbr -cq 17 -pix_fmt yuv420p `"$out`""
$ffmpeg.StartInfo.UseShellExecute = $false
$ffmpeg.StartInfo.RedirectStandardInput = $true
$ffmpeg.Start() | Out-Null

Write-Host "Recording to $out. Quit the game to stop."
$play.WaitForExit()
$ffmpeg.StandardInput.Write("q")
$ffmpeg.WaitForExit()
Write-Host "Saved $out"

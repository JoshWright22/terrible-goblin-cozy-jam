# Records store footage with no one at the keyboard. The game plays itself (Scripts/autoplay.gd)
# while Godot's movie mode renders every frame at 1920x1080, 60 fps, with the game's own audio.
# The window opens off-screen, so it runs in the background without covering anything.
# Uses a clean checkout of the last commit and a fresh save, so the default look is recorded and
# your own save is put back afterwards. Movie mode renders slower than real time, so a few
# minutes of footage takes about half an hour.
#
#   powershell -ExecutionPolicy Bypass -File tools/record_footage.ps1
#   powershell -ExecutionPolicy Bypass -File tools/record_footage.ps1 -Segments "summer:3,endless" -Seconds 30

param(
	[string]$Segments = "summer:6,summer:10,summer:13,endless",
	[int]$Seconds = 40,
	[string]$Godot = $env:GODOT
)

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
if (-not $Godot) {
	$Godot = "$env:USERPROFILE\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe"
}

$outDir = Join-Path $repo "builds\capture"
New-Item -ItemType Directory -Force $outDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$avi = Join-Path $outDir "footage_$stamp.avi"
$mp4 = Join-Path $outDir "footage_$stamp.mp4"

$saveDir = Join-Path $env:APPDATA "Slush Rush"
$save = Join-Path $saveDir "save.cfg"
$backup = Join-Path $saveDir "save.cfg.footage-backup"
$work = Join-Path $env:TEMP "slushrush-footage"

if (Test-Path $work) { git -C $repo worktree remove --force $work }
git -C $repo worktree add --detach $work HEAD | Out-Null
if (Test-Path $save) { Copy-Item $save $backup -Force; Remove-Item $save }

try {
	& $Godot --headless --path $work --import | Out-Null
	& $Godot --path $work --windowed --resolution 1920x1080 --position -10000,-10000 --write-movie $avi -- "--autoplay=$Segments" "--autoplay-seconds=$Seconds"
	# Smaller H.264 copy for the stores and for cutting
	ffmpeg -hide_banner -loglevel error -y -i $avi -c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p -c:a aac -b:a 192k $mp4
	Remove-Item $avi -ErrorAction Continue
	Write-Host "Saved $mp4"
}
finally {
	if (Test-Path $backup) { Move-Item $backup $save -Force } elseif (Test-Path $save) { Remove-Item $save }
	git -C $repo worktree remove --force $work
}

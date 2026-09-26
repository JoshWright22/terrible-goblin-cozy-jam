# Exports the release builds into builds/.
# Builds from a clean checkout of the last commit, so the local MCP autoloads in
# project.godot and any uncommitted work never end up in a build. Commit first.
#
#   powershell -ExecutionPolicy Bypass -File tools/build.ps1
#   powershell -ExecutionPolicy Bypass -File tools/build.ps1 -Presets "Steam Windows"

param(
	[string[]]$Presets = @("Steam Windows", "Steam Linux", "Android"),
	[string]$Godot = $env:GODOT,
	[string]$Keystore = "$env:USERPROFILE\keystores\slushrush-upload.jks"
)

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent

if (-not $Godot) {
	$Godot = "$env:USERPROFILE\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe"
}
if (-not (Test-Path $Godot)) { throw "Godot not found at $Godot. Pass -Godot or set GODOT." }

$outputs = @{
	"Steam Windows" = "builds\steam\windows\Slush Rush.exe"
	"Steam Linux"   = "builds\steam\linux\SlushRush.x86_64"
	"Android"       = "builds\android\SlushRush.aab"
}

# The upload key password sits next to the keystore, outside the repo
if ($Presets -contains "Android") {
	$info = Get-Content ([IO.Path]::ChangeExtension($Keystore, ".txt"))
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $Keystore
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = (($info | Select-String "^alias: ") -replace "^alias: ", "")
	$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = (($info | Select-String "^password: ") -replace "^password: ", "")
}

$work = Join-Path $env:TEMP "slushrush-build"
if (Test-Path $work) { git -C $repo worktree remove --force $work }
git -C $repo worktree add --detach $work HEAD | Out-Null

try {
	& $Godot --headless --path $work --import | Out-Null
	if ($Presets -contains "Android") {
		& $Godot --headless --path $work --install-android-build-template | Out-Null
	}
	foreach ($preset in $Presets) {
		$out = Join-Path $repo $outputs[$preset]
		New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
		Write-Host "Exporting $preset -> $out"
		& $Godot --headless --path $work --export-release $preset $out
		if (-not (Test-Path $out)) { throw "$preset export failed" }
	}
}
finally {
	git -C $repo worktree remove --force $work
}

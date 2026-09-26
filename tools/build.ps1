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
	# Play rejects an upload that reuses a version code, so it follows the commit count.
	# The version name comes from application/config/version in project.godot.
	$code = git -C $repo rev-list --count HEAD
	$name = (Select-String -Path "$work\project.godot" -Pattern '^config/version="(.*)"').Matches[0].Groups[1].Value
	$presetsFile = "$work\export_presets.cfg"
	$lines = (Get-Content $presetsFile) -replace '^version/code=.*', "version/code=$code" -replace '^version/name=.*', "version/name=`"$name`""
	[IO.File]::WriteAllLines($presetsFile, $lines, (New-Object Text.UTF8Encoding $false))
	Write-Host "Building $name (Android version code $code)"

	& $Godot --headless --path $work --import | Out-Null
	if ($Presets -contains "Android") {
		# Same as Project > Install Android Build Template, which the headless export checks for first
		$version = "4.6.3.stable"
		New-Item -ItemType Directory -Force "$work\android\build" | Out-Null
		Expand-Archive "$env:APPDATA\Godot\export_templates\$version\android_source.zip" "$work\android\build" -Force
		Set-Content "$work\android\.build_version" $version -NoNewline
		New-Item -ItemType File -Force "$work\android\build\.gdignore" | Out-Null
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

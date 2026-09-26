# Uploads builds/steam to Steam with SteamPipe. Run tools/build.ps1 first.
# Depots follow the Steamworks defaults: app ID + 1 for Windows, app ID + 2 for Linux.
# Uploads never go live by themselves; set the build live on a branch in Steamworks > Builds.
#
#   powershell -ExecutionPolicy Bypass -File tools/steam_upload.ps1 -AppId 1234560 -User yoursteamlogin -Description "0.2.0 playtest"

param(
	[Parameter(Mandatory)] [int]$AppId,
	[Parameter(Mandatory)] [string]$User,
	[string]$Description = "",
	[string]$SteamCmd = "C:\steamcmd\steamcmd.exe"
)

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$content = Join-Path $repo "builds\steam"
$scripts = Join-Path $repo "builds\steampipe"
New-Item -ItemType Directory -Force $scripts | Out-Null

if (-not (Test-Path $SteamCmd)) {
	New-Item -ItemType Directory -Force (Split-Path $SteamCmd) | Out-Null
	$zip = Join-Path $env:TEMP "steamcmd.zip"
	Invoke-WebRequest "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -OutFile $zip
	Expand-Archive $zip (Split-Path $SteamCmd) -Force
}

function Write-Depot($depot, $folder) {
	@"
"DepotBuildConfig"
{
	"DepotID" "$depot"
	"ContentRoot" "$(Join-Path $content $folder)"
	"FileMapping"
	{
		"LocalPath" "*"
		"DepotPath" "."
		"recursive" "1"
	}
}
"@ | Set-Content (Join-Path $scripts "depot_$depot.vdf") -Encoding ascii
}

$windows = $AppId + 1
$linux = $AppId + 2
Write-Depot $windows "windows"
Write-Depot $linux "linux"

@"
"AppBuild"
{
	"AppID" "$AppId"
	"Desc" "$Description"
	"BuildOutput" "$scripts\output"
	"Depots"
	{
		"$windows" "depot_$windows.vdf"
		"$linux" "depot_$linux.vdf"
	}
}
"@ | Set-Content (Join-Path $scripts "app_build.vdf") -Encoding ascii

# steamcmd asks for the password and Steam Guard code itself the first time, then caches the login
& $SteamCmd +login $User +run_app_build (Join-Path $scripts "app_build.vdf") +quit

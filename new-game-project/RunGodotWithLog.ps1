# Launches Godot with ALL engine output copied to a file immediately (stderr flushes on errors).
# Use this when the editor crashes before you can read the Output panel.
#
# Usage (from PowerShell, in this folder):
#   .\RunGodotWithLog.ps1              # opens the project in the editor
#   .\RunGodotWithLog.ps1 -Game        # runs the game (main scene) without editor UI
#   .\RunGodotWithLog.ps1 -Godot "C:\Path\Godot_v4.6-stable_win64_console.exe"
#
# Tip: set a permanent path:
#   [Environment]::SetEnvironmentVariable("GODOT", "C:\Path\Godot_console.exe", "User")

param(
	[switch]$Game,
	[string]$Godot = ""
)

$ErrorActionPreference = "Stop"
$ProjectDir = $PSScriptRoot
$LogDir = Join-Path $ProjectDir "_logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path $LogDir "godot_$stamp.log"

function Resolve-GodotExecutable {
	param([string]$Explicit)
	if ($Explicit -ne "" -and (Test-Path -LiteralPath $Explicit)) {
		return (Resolve-Path -LiteralPath $Explicit).Path
	}
	if ($env:GODOT -ne "" -and (Test-Path -LiteralPath $env:GODOT)) {
		return (Resolve-Path -LiteralPath $env:GODOT).Path
	}
	$cmd = Get-Command "godot" -ErrorAction SilentlyContinue
	if ($null -ne $cmd -and (Test-Path -LiteralPath $cmd.Source)) {
		return $cmd.Source
	}
	$roots = @(
		(Join-Path $env:LOCALAPPDATA "Programs\Godot"),
		"C:\Program Files\Godot",
		"C:\Program Files (x86)\Godot"
	)
	foreach ($root in $roots) {
		if (-not (Test-Path -LiteralPath $root)) { continue }
		$exe = Get-ChildItem -Path $root -Filter "Godot*.exe" -File -ErrorAction SilentlyContinue |
			Where-Object { $_.Name -notmatch "Uninstall" } |
			Sort-Object Name -Descending |
			Select-Object -First 1
		if ($null -ne $exe) { return $exe.FullName }
	}
	return ""
}

$godotExe = Resolve-GodotExecutable -Explicit $Godot
if ($godotExe -eq "") {
	Write-Host "Could not find Godot.exe. Do one of the following:" -ForegroundColor Yellow
	Write-Host "  1) Add Godot to PATH, or"
	Write-Host "  2) Set user env var GODOT to the full path of Godot (console build recommended), or"
	Write-Host "  3) Run: .\RunGodotWithLog.ps1 -Godot `"C:\full\path\to\Godot_v4.x_win64_console.exe`""
	exit 1
}

$argList = New-Object System.Collections.Generic.List[string]
$argList.Add("--path")
$argList.Add($ProjectDir)
$argList.Add("--verbose")
$argList.Add("--log-file")
$argList.Add($LogFile)
if (-not $Game) {
	$argList.Add("--editor")
}

Write-Host "Godot:  $godotExe"
Write-Host "Args:   $($argList -join ' ')"
Write-Host "Log:    $LogFile"
Write-Host ""

try {
	$p = Start-Process -FilePath $godotExe -ArgumentList $argList -NoNewWindow -PassThru -Wait
	$code = $p.ExitCode
} catch {
	Write-Host $_ -ForegroundColor Red
	$code = 1
}

Write-Host ""
Write-Host "Exit code: $code"
Write-Host "Opening log in Notepad..."
Start-Process notepad.exe -ArgumentList "`"$LogFile`""

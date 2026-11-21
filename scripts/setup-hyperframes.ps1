param(
    [string]$ProjectFolder = ""
)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
$VenvDir = Join-Path $RootDir ".venv-tts"

Set-Location $RootDir

function Refresh-SessionPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   Setting up HyperFrames Studio Environment      " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 0. Check Custom Workflow Skill (.agents/skills/hyperframes-creator/SKILL.md)
$CustomSkillPath = Join-Path $RootDir ".agents\skills\hyperframes-creator\SKILL.md"
if (Test-Path $CustomSkillPath) {
    Write-Host "[✓] Custom workflow skill found (.agents\skills\hyperframes-creator\SKILL.md)" -ForegroundColor Green
} else {
    Write-Host "[!] Warning: .agents\skills\hyperframes-creator\SKILL.md is missing!" -ForegroundColor Yellow
    Write-Host "    (Make sure hidden '.agents\' folder was included when zipping/unzipping.)" -ForegroundColor Yellow
}

# 1. Check & Install Git (required by `hyperframes skills update` to fetch core skills)
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Git not found. Installing via winget..." -ForegroundColor Yellow
    winget install Git.Git --accept-package-agreements --accept-source-agreements
    Refresh-SessionPath
} else {
    Write-Host "[✓] Git installed: $(git --version)" -ForegroundColor Green
}

# 2. Check & Install Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue) -or -not (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Node.js not found. Installing via winget..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
    Refresh-SessionPath
} else {
    Write-Host "[✓] Node.js installed: $(node -v)" -ForegroundColor Green
}

# 3. Check & Install FFmpeg + FFprobe (required for render & audio mixing)
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue) -or -not (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
    Write-Host "[!] FFmpeg/FFprobe not found. Installing via winget..." -ForegroundColor Yellow
    winget install Gyan.FFmpeg --accept-package-agreements --accept-source-agreements
    Refresh-SessionPath
} else {
    Write-Host "[✓] FFmpeg installed." -ForegroundColor Green
}

# 4. Check & Install Python 3.10+ (prefer Python 3.12)
function Find-Python310Plus {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        foreach ($ver in @("-3.12", "-3.13", "-3.11", "-3.10")) {
            try {
                & py $ver -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" 2>$null
                if ($LASTEXITCODE -eq 0) { return @("py", $ver) }
            } catch {}
        }
    }
    if (Get-Command python -ErrorAction SilentlyContinue) {
        try {
            & python -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" 2>$null
            if ($LASTEXITCODE -eq 0) { return @("python") }
        } catch {}
    }
    return $null
}

$PythonCmd = Find-Python310Plus
if (-not $PythonCmd) {
    Write-Host "[!] Python 3.10+ not found. Installing Python 3.12 via winget..." -ForegroundColor Yellow
    winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements
    Refresh-SessionPath
    $PythonCmd = Find-Python310Plus
    if (-not $PythonCmd) {
        Write-Host "[✗] Python 3.12 installed, please restart your terminal to refresh PATH and re-run this script." -ForegroundColor Red
        exit 1
    }
}
Write-Host "[✓] Python 3.10+ ready." -ForegroundColor Green

# 5. Create Shared Workspace Voiceover Virtualenv (.venv-tts) & Install TTS Libraries
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
if (-not (Test-Path $VenvPython)) {
    Write-Host "[*] Creating shared TTS virtualenv at $VenvDir..." -ForegroundColor Cyan
    if ($PythonCmd.Count -eq 2) {
        & $PythonCmd[0] $PythonCmd[1] -m venv $VenvDir
    } else {
        & $PythonCmd[0] -m venv $VenvDir
    }
} else {
    Write-Host "[✓] Existing TTS virtualenv found at $VenvDir" -ForegroundColor Green
}

try {
    & $VenvPython -c "import edge_tts, kokoro_onnx, soundfile" 2>$null
    $ttsInstalled = ($LASTEXITCODE -eq 0)
} catch {
    $ttsInstalled = $false
}

if ($ttsInstalled) {
    Write-Host "[✓] Voiceover TTS libs already installed (edge-tts, kokoro-onnx, soundfile)" -ForegroundColor Green
} else {
    Write-Host "[*] Installing voiceover libraries (edge-tts, kokoro-onnx, soundfile)..." -ForegroundColor Cyan
    & $VenvPython -m pip install --upgrade pip --quiet
    & $VenvPython -m pip install edge-tts kokoro-onnx soundfile --quiet
    & $VenvPython -c "import edge_tts, kokoro_onnx, soundfile; print('[✓] Voiceover TTS libs ready (edge-tts, kokoro-onnx, soundfile)')"
}

# 6. Verify HyperFrames CLI, Headless Browser & Core Skills
Write-Host "[*] Ensuring HyperFrames headless browser (Chrome) is available..." -ForegroundColor Cyan
npx --yes hyperframes browser ensure

Write-Host "[*] Syncing HyperFrames core skills (requires git + network)..." -ForegroundColor Cyan
npx --yes hyperframes skills update

Write-Host "[*] Running HyperFrames environment diagnostics..." -ForegroundColor Cyan
npx --yes hyperframes doctor

# 7. Optional: Initialize a Specific Video Subfolder (never initialize the workspace root)
if ($ProjectFolder -ne "") {
    $TargetDir = Join-Path $RootDir $ProjectFolder
    if (Test-Path (Join-Path $TargetDir "hyperframes.json")) {
        Write-Host "[✓] Video project '$ProjectFolder' is already initialized." -ForegroundColor Green
    } else {
        Write-Host "[*] Initializing new video project in '$ProjectFolder'..." -ForegroundColor Cyan
        npx --yes hyperframes init $TargetDir --skip-skills
    }
} else {
    Write-Host "[i] Workspace root kept clean for multi-video projects." -ForegroundColor Gray
    Write-Host "    To create a new video project, run: npx hyperframes init <project-folder> --skip-skills" -ForegroundColor Gray
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   Setup Complete! You are ready to create videos." -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

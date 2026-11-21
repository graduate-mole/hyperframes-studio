#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_DIR="$ROOT_DIR/.venv-tts"

# Ensure Homebrew paths are available in non-login subshells
for brew_dir in /opt/homebrew/bin /usr/local/bin; do
    if [ -d "$brew_dir" ] && [[ ":$PATH:" != *":$brew_dir:"* ]]; then
        export PATH="$brew_dir:$PATH"
    fi
done

cd "$ROOT_DIR"

echo "=================================================="
echo "   Setting up HyperFrames Studio Environment      "
echo "=================================================="

ensure_brew() {
    if ! command -v brew &> /dev/null; then
        echo "[✗] Homebrew not found. Please install Homebrew first: https://brew.sh"
        exit 1
    fi
}

# 0. Check & Verify Custom Workflow Skill (.agents/skills/hyperframes-creator/SKILL.md)
if [ -f "$ROOT_DIR/.agents/skills/hyperframes-creator/SKILL.md" ]; then
    echo "[✓] Custom workflow skill found (.agents/skills/hyperframes-creator/SKILL.md)"
else
    echo "[!] Warning: .agents/skills/hyperframes-creator/SKILL.md is missing!"
    echo "    (If you unzipped this studio, make sure hidden '.agents/' folder was included in the zip.)"
fi

# 1. Check & Install Git (required by `hyperframes skills update` to fetch core skills)
if ! command -v git &> /dev/null; then
    echo "[!] Git not found. Installing via Homebrew..."
    ensure_brew
    brew install git
else
    echo "[✓] Git installed: $(git --version)"
fi

# 2. Check & Install Node.js (v22+)
if ! command -v node &> /dev/null || ! command -v npx &> /dev/null; then
    echo "[!] Node.js not found. Installing node@22 via Homebrew..."
    ensure_brew
    brew install node@22
    NODE22_BIN="$(brew --prefix node@22)/bin"
    if [ -d "$NODE22_BIN" ]; then
        export PATH="$NODE22_BIN:$PATH"
    fi
else
    echo "[✓] Node.js installed: $(node -v)"
fi

# 3. Check & Install FFmpeg + FFprobe (required for render & audio mixing)
if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "[!] FFmpeg/FFprobe not found. Installing via Homebrew..."
    ensure_brew
    brew install ffmpeg
else
    echo "[✓] FFmpeg installed: $(ffmpeg -version | head -n 1)"
fi

# 4. Check & Install Python 3.10+ (macOS system Python 3.9 is too old for TTS deps)
find_python310_plus() {
    for candidate in python3.12 python3.13 python3.11 python3.10 python3 /opt/homebrew/bin/python3.12 /usr/local/bin/python3.12; do
        if command -v "$candidate" &> /dev/null; then
            if "$candidate" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" 2>/dev/null; then
                command -v "$candidate"
                return 0
            fi
        fi
    done
    return 1
}

PYTHON_BIN="$(find_python310_plus || true)"
if [ -z "$PYTHON_BIN" ]; then
    echo "[!] Python 3.10+ not found (system Python may be 3.9). Installing python@3.12 via Homebrew..."
    ensure_brew
    brew install python@3.12
    PY312_BIN="$(brew --prefix python@3.12)/bin"
    if [ -d "$PY312_BIN" ]; then
        export PATH="$PY312_BIN:$PATH"
    fi
    PYTHON_BIN="$(find_python310_plus || true)"
    if [ -z "$PYTHON_BIN" ]; then
        BREW_PY="$PY312_BIN/python3.12"
        if [ -x "$BREW_PY" ]; then
            PYTHON_BIN="$BREW_PY"
        else
            echo "[✗] Failed to locate Python 3.12 after installation."
            exit 1
        fi
    fi
fi
echo "[✓] Python 3.10+ found: $PYTHON_BIN ($($PYTHON_BIN --version))"

# 5. Create Shared Workspace Voiceover Virtualenv (.venv-tts) & Install TTS Libraries
# - edge-tts: natural neural TTS (e.g., zh-CN-YunxiNeural / zh-CN-XiaoxiaoNeural)
# - kokoro-onnx + soundfile: local offline ONNX TTS (e.g., zf_xiaobei / af_heart)
if [ ! -x "$VENV_DIR/bin/python" ]; then
    echo "[*] Creating shared TTS virtualenv at $VENV_DIR..."
    "$PYTHON_BIN" -m venv "$VENV_DIR"
else
    echo "[✓] Existing TTS virtualenv found at $VENV_DIR"
fi

if "$VENV_DIR/bin/python" -c "import edge_tts, kokoro_onnx, soundfile" 2>/dev/null; then
    echo "[✓] Voiceover TTS libs already installed (edge-tts, kokoro-onnx, soundfile)"
else
    echo "[*] Installing voiceover libraries (edge-tts, kokoro-onnx, soundfile)..."
    "$VENV_DIR/bin/python" -m pip install --upgrade pip --quiet
    "$VENV_DIR/bin/python" -m pip install edge-tts kokoro-onnx soundfile --quiet
    "$VENV_DIR/bin/python" -c "import edge_tts, kokoro_onnx, soundfile; print('[✓] Voiceover TTS libs ready (edge-tts, kokoro-onnx, soundfile)')"
fi

# 6. Verify HyperFrames CLI, Headless Browser & Core Skills
echo "[*] Ensuring HyperFrames headless browser (Chrome) is available..."
npx --yes hyperframes browser ensure

echo "[*] Syncing HyperFrames core skills (requires git + network)..."
npx --yes hyperframes skills update

echo "[*] Running HyperFrames environment diagnostics..."
npx --yes hyperframes doctor || true

# 7. Optional: Initialize a Specific Video Subfolder (never initialize the workspace root)
if [ -n "$1" ]; then
    TARGET_DIR="$ROOT_DIR/$1"
    if [ -f "$TARGET_DIR/hyperframes.json" ]; then
        echo "[✓] Video project '$1' is already initialized."
    else
        echo "[*] Initializing new video project in '$1'..."
        npx --yes hyperframes init "$TARGET_DIR" --skip-skills
    fi
else
    echo "[i] Workspace root kept clean for multi-video projects."
    echo "    To create a new video project, run:"
    echo "    npx hyperframes init <project-folder> --skip-skills"
fi

echo "=================================================="
echo "   Setup Complete! You are ready to create videos."
echo "=================================================="

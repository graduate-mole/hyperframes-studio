# **HyperFrames Video Generation Playbook**

This playbook serves as the human-readable reference for setting up, planning, voicing, storyboarding, and rendering code-driven videos using **HeyGen HyperFrames** and an AI coding agent (Antigravity, Codex, Cursor, or Claude Code).

---

# **1\. Environment Verification Scripts**

Run the one-click setup script from the workspace root (`bash scripts/setup-hyperframes.sh` on macOS, or `powershell -ExecutionPolicy Bypass -File .\scripts\setup-hyperframes.ps1` on Windows) — or run the manual check blocks below — to install and verify all prerequisites (**Git, Node.js 22, FFmpeg/FFprobe, Python 3.10+ with `.venv-tts` voiceover libraries, HyperFrames headless Chrome, and core skills**).

## **macOS Setup (zsh / bash)**

```bash
# Quick one-click setup (recommended):
bash scripts/setup-hyperframes.sh

# Or manual steps:
# 1. Verify Git (required for syncing HyperFrames skills)
if ! command -v git &> /dev/null; then
    brew install git
fi

# 2. Verify Node.js
if ! command -v node &> /dev/null; then
    echo "Node.js not found. Installing via Homebrew..."
    brew install node@22
else
    echo "Node.js version: $(node -v)"
fi

# 3. Verify FFmpeg / FFprobe
if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "FFmpeg/FFprobe not found. Installing via Homebrew..."
    brew install ffmpeg
else
    echo "FFmpeg version: $(ffmpeg -version | head -n 1)"
fi

# 4. Verify Python 3.12 & shared TTS virtualenv (.venv-tts)
# (macOS system Python 3.9 is too old for TTS dependencies)
if ! command -v python3.12 &> /dev/null; then
    brew install python@3.12
fi
python3.12 -m venv .venv-tts
.venv-tts/bin/python -m pip install --upgrade pip
.venv-tts/bin/python -m pip install edge-tts kokoro-onnx soundfile

# 5. Ensure HyperFrames Chrome browser, sync core skills & run diagnostics
npx --yes hyperframes browser ensure
npx --yes hyperframes skills update
npx --yes hyperframes doctor
```

## **Windows Setup (PowerShell)**

```powershell
# Quick one-click setup (recommended):
powershell -ExecutionPolicy Bypass -File .\scripts\setup-hyperframes.ps1

# Or manual steps:
# 1. Verify Git, Node.js, FFmpeg, and Python 3.12
winget install Git.Git
winget install OpenJS.NodeJS.LTS
winget install Gyan.FFmpeg
winget install Python.Python.3.12

# (Restart PowerShell if newly installed tools are not in PATH yet)
# 2. Create shared TTS virtualenv (.venv-tts)
py -3.12 -m venv .venv-tts
.\.venv-tts\Scripts\python.exe -m pip install --upgrade pip
.\.venv-tts\Scripts\python.exe -m pip install edge-tts kokoro-onnx soundfile

# 3. Ensure HyperFrames Chrome browser, sync core skills & run diagnostics
npx --yes hyperframes browser ensure
npx --yes hyperframes skills update
npx --yes hyperframes doctor
```

---

# **2\. Phase 1: Initialize, Plan & Develop the Script**

When starting a new video task, determine the project subfolder first. As soon as its name is known, create and initialize that subfolder before asking creative questions. Check that the selected subfolder is not already initialized; **do not initialize the workspace root**.

```bash
npx hyperframes init <project-folder> --skip-skills
```

Then use this prompt in your AI agent's chat interface:

```text
Act as a professional creative director and video producer. I want to create a video using HyperFrames in subfolder `<project-folder>`.

Create and initialize the project subfolder first if it is not already initialized. Then ask me only 3 quick setup questions:
1. Video goal and audience
2. Duration and format (aspect ratio)
3. Visual style and palette

Do not ask for full copy, narration, or CTA in this initial step.

After I answer, guide me through developing the story, scene beats, concise on-screen copy, spoken voiceover narration, and ending by asking ONE focused question at a time. Propose concrete options or draft headlines for me to react to rather than open-ended blanks, and wait for my answer before asking the next question.

Save confirmed details, story beats, voiceover scripts, relevant creative rules, and unresolved questions to `<project-folder>/story-plan.md`, updating it as we refine the story.

Do not write video HTML, CSS, or animation code during planning. After I approve the script, generate/measure voiceover timing (if using voiceover), prepare a timeline spec and static storyboard for review, and wait for my approval before implementing or rendering the video.
```

---

## 3. Phase 2: Voiceover Timing, Timeline Matrix & Static SVG Storyboard

After the script is approved:
1. **Generate & measure voiceover first (if narration is enabled):** Use `.venv-tts` (`edge-tts` for natural multilingual neural voices such as `zh-CN-YunxiNeural`, or `kokoro-onnx` / `npx hyperframes tts` for offline synthesis), measure each clip's actual duration with `ffprobe`, and set each scene's `data-duration` to match real audio length + `0.8s–1.2s` breathing pause (so chapters never have awkward dead air).
2. **Create `storyboard.html`:** Render static SVG/HTML layout mockups for each scene to verify framing (`16:9` / `9:16`), typography hierarchy, and colors before writing runtime animation code.

```text
Generate the voiceover audio from our approved script in `story-plan.md` (using `.venv-tts`), measure the exact duration of each chapter with `ffprobe`, and build our timeline spec matrix driven by real audio durations.
Then generate a static HTML file named `storyboard.html` containing SVG layout mockups for each scene in our timeline (no runtime animation scripts yet) so I can inspect the static composition visually.
```

---

# **4\. Phase 3: Implement, Verify (`check` + `snapshot`), Preview & Render**

After approving the static layout, instruct the agent to implement `index.html`, pass HyperFrames lint/runtime checks with zero errors, inspect snapshots, preview playback, and export the final MP4:

```text
Using `/hyperframes`, construct `<project-folder>/index.html` with seekable GSAP timelines (`window.__timelines["main"]`), `data-start`/`data-duration`, relative `./assets/` paths, and declarative `<audio class="clip">` tracks.
Run `npm run check` inside `<project-folder>` and fix all errors, capture key frames with `npx hyperframes snapshot`, launch `npx hyperframes preview` for review, and render the final MP4 with `npx hyperframes render`.
```

---

# **CLI Command Quick Reference**

| Action | Command | Purpose |
| :---- | :---- | :---- |
| **Validate & Lint** | `npm run check` | Runs lint, runtime, layout, motion, and contrast checks (`0 errors` required before render). |
| **Inspect Keyframes** | `npx hyperframes snapshot --at 0,18,44` | Captures PNG frames at exact timestamps to visually verify layout before rendering. |
| **Live Preview** | `npx hyperframes preview` | Opens a real-time browser preview with seekable scrubbing controls. |
| **Export MP4** | `npx hyperframes render` | Compiles the code project + audio into a local production-ready `.mp4` in `renders/`. |
| **Generate Local TTS** | `npx hyperframes tts "text" -o out.wav` | Optional built-in local Kokoro-82M TTS fallback (`edge-tts` in `.venv-tts` is used for natural neural voices). |
| **Environment Check** | `npx hyperframes doctor` | Verifies Node.js, FFmpeg, FFprobe, and headless Chrome readiness. |
| **Sync Skills** | `npx hyperframes skills update` | Installs or refreshes the HyperFrames core skills (`hyperframes`, `hyperframes-cli`, `media-use`). |

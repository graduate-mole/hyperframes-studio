# 🎬 HyperFrames Multi-Video Studio

Welcome to your master video workspace! This setup lets you plan, storyboard, voice, preview, and render as many code-driven videos as you want inside one root folder without duplicating setups or skills.

---

## 🚀 Quick Start: How to Create a New Video

### Step 0: Run the One-Click Environment Setup (First Time Only)
Before opening your AI agent, run the setup script from the root `HyperFrames-Studio` folder to install all prerequisites (**Git, Node.js 22, FFmpeg/FFprobe, Python 3.12 + `.venv-tts` voiceover libraries `edge-tts`/`kokoro-onnx`/`soundfile`, HyperFrames headless Chrome, and core skills**):

- **macOS (Terminal):**
  ```bash
  bash scripts/setup-hyperframes.sh
  ```
- **Windows (PowerShell):**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\setup-hyperframes.ps1
  ```

### Step 1: Open This Master Folder in Your AI Agent
Open the root `HyperFrames-Studio` directory in your AI coding agent (Antigravity, Codex, Cursor, Claude Code, etc.) so it automatically loads `.agents/skills/hyperframes-creator/SKILL.md`.

### Step 2: Initialize Subfolder & Collect the 3-Spec Brief
Specify a new project subfolder. The agent initializes that subfolder (`npx hyperframes init <project-folder> --skip-skills`) and asks only **3 quick setup questions** (goal/audience, duration/aspect ratio, and visual style)—saving copy and scripts for Step 3:
> *"Act as a creative director. Start a new video project in subfolder `01-my-video`: create and initialize the folder first, then ask me only 3 quick setup questions about my video goal and audience, duration and aspect ratio, and visual style. Do not ask for full copy yet and do not write video code yet."*

### Step 3: Co-Create Script, Copy & Voiceover One Question at a Time
Work through the core takeaway, source material, chapter arc, concise **on-screen copy**, **spoken voiceover script**, and audio choices interactively—with the agent asking **one focused question at a time** and proposing concrete options. Confirmed decisions are continuously saved to `<project-folder>/story-plan.md`.
> *"Let's develop the story, on-screen copy, and voiceover script one question at a time. Propose options for each beat as we go, update `01-my-video/story-plan.md`, and wait for my approval before preparing the timeline spec and static storyboard."*

### Step 4: Approve Storyboard, Generate Voiceover & Render
Once the script is approved, the agent generates voiceover audio (if enabled) so **real audio durations drive the timeline** (preventing awkward silent gaps), builds a static `storyboard.html` for your visual sign-off, and then implements `index.html`, runs `npm run check`, previews, and renders the final `.mp4` into `<project-folder>/renders/`.
> *"The script, timeline, and storyboard are approved. Generate the voiceover, build `index.html`, run `npm run check`, preview playback, and render the final MP4."*

---

## 📁 Workspace Structure

```text
HyperFrames-Studio/                   <-- Open your AI agent HERE
├── README.md                         <-- This quick-start guide
├── BEGINNER_GUIDE.md                 <-- Detailed setup, phase prompts & CLI reference
├── scripts/
│   ├── setup-hyperframes.sh          <-- macOS one-click environment installer
│   └── setup-hyperframes.ps1         <-- Windows PowerShell one-click installer
├── .agents/skills/
│   └── hyperframes-creator/SKILL.md  <-- Planning-first AI workflow skill
├── .venv-tts/                        <-- Shared Python 3.12 TTS env (created by setup script)
│
├── 01-fall-through-earth/            <-- Sample Video Project 1
└── 02-promo-video/                   <-- Sample Video Project 2
    ├── story-plan.md                 <-- Approved brief, copy, VO script & motion rules
    ├── storyboard.html               <-- Static SVG layout review sheet
    ├── index.html                    <-- Seekable GSAP + Canvas/SVG composition
    ├── assets/                       <-- Voiceover MP3s, music, images
    └── renders/                      <-- Final exported .mp4 videos
```

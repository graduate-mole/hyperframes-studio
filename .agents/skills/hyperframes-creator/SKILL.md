---
name: hyperframes-creator
description: 'Plan, storyboard, voice, build, preview, and render HyperFrames videos in separate project subfolders. Use when creating a new video with HyperFrames.'
---

# **HyperFrames Creator Skill**

Autonomous workflow guide for AI agents to plan, voice, storyboard, preview, and render code-driven HTML videos using HeyGen HyperFrames inside a multi-video studio workspace.

# **Overview**

* **Name:** `hyperframes-creator`
* **Target Environment:** Node.js + FFmpeg/FFprobe + Python `.venv-tts` (`edge-tts`, `kokoro-onnx`, `soundfile`)
* **Core Dependency:** HeyGen HyperFrames CLI (`npx hyperframes`)

# **Agent Operating Guidelines**

## **Rule 1: Follow the Planning-First Protocol**

* Never jump directly to writing dynamic `index.html` motion code upon receiving a video request.
* Initialize the project subfolder as soon as its name is known, before beginning creative planning. Project scaffolding is setup, not video implementation; do not write video code during planning.
* Ask only 3 quick setup questions first: goal/audience, duration/format (aspect ratio), and visual style/palette. Do not ask for full copy, narration, or CTA in this initial intake.
* After the user answers, lead an interactive **one-question-at-a-time** discovery loop to develop the core takeaway, source material, chapter arc, concise **on-screen copy**, **spoken voiceover narration**, and audio/ending. Propose concrete options to react to rather than asking open-ended blanks, and continue until the user approves the script.
* Save the agreed creative brief, confirmed beats, on-screen copy, voiceover scripts, and still-open decisions to `<project-folder>/story-plan.md`, updating it after each milestone.
* Only after the user approves the script, generate/measure voiceover audio (when narration is used), build the **audio-driven** timeline spec matrix, and create a static `storyboard.html` for review before writing animation code.
* Implement and render only after the user approves the script, timeline, and storyboard.

## **Rule 2: Refer to Local Documentation**

When executing environment setup or planning steps, read rules from `BEGINNER_GUIDE.md` at the workspace root and `<project-folder>/AGENTS.md` (created by `hyperframes init`).

# **Autonomous Execution Pipeline**

## **Step 1: Initialize the Project Folder**

Determine the project subfolder for the current video. Use the folder name specified by the user; if not specified, derive a concise, descriptive slug from the topic and inform the user.

As soon as the folder name is known, check whether `<project-folder>/hyperframes.json` exists. If not, immediately run `init` on that subfolder before asking creative-planning questions:

```bash
npx hyperframes init <project-folder> --skip-skills
```

Never initialize the workspace root (`.`) when it contains multiple video projects.

## **Step 2: Quick Project Brief (3 Setup Specs Only)**

Collect only the 3 fast project constraints so the user can answer in one short reply:

1. **Video goal and audience** (what the video is for and who is watching)
2. **Duration and format** (target length and aspect ratio, e.g., `16:9` for a meeting or `9:16` for social)
3. **Visual style and palette** (mood, color direction, typography, or motion feel)

Do not ask for full copy, narration, or call to action in Step 2.

## **Step 3: One-Question-at-a-Time Story, Copy & Voiceover Discovery**

Use the 3 setup specs to run an interactive discovery conversation piece by piece.

**Discovery Rules:**

* **One question per turn:** Ask only ONE focused question per message, then wait for the user's answer.
* **Propose options instead of blank-page prompts:** Propose a rough chapter arc or 2–3 concrete headline/narration drafts for the user to pick, tweak, or replace.
* **Solve the puzzle in sequence (skipping anything already answered):**
  1. **Core takeaway:** Single most important thing viewers should remember or do.
  2. **Source material:** Existing notes, URLs, docs, or data points to verify facts from.
  3. **Chapter arc:** Agree on the main chapters/beats and rough pacing.
  4. **Beat-by-beat copy & voiceover:** Lock in **both** concise on-screen headlines/cards and fluent spoken narration (keeping them distinct: screen text is scannable; voiceover tells the story).
  5. **Audio & ending:** Decide on voiceover voice/language, background music/SFX (or silent live-presentation backdrop), and the closing CTA/Q&A hold.

Continuously archive confirmed details, copy, voiceover scripts, and motion rules in `<project-folder>/story-plan.md`. Do not write animation code in this phase.

## **Step 4: Generate Voiceover & Build Audio-Driven Timeline Matrix**

After script approval, if the video includes voiceover:

1. **Synthesize voiceover tracks first:** Use the workspace Python environment (`<workspace-root>/.venv-tts/bin/python` on macOS or `Scripts\python.exe` on Windows) with `edge-tts` (e.g., `zh-CN-YunxiNeural`, `zh-CN-XiaoxiaoNeural`, `en-US-AndrewNeural`) for natural human-like prosody—or `kokoro-onnx` / `npx hyperframes tts` for offline local synthesis. Save per-chapter clips and a combined master track into `<project-folder>/assets/`.
2. **Measure real durations with `ffprobe`:** Never guess chapter durations when voiceover exists. Set each chapter's `data-duration` to its measured narration duration plus a clean `0.8s–1.2s` breathing gap before the next transition (eliminating multi-second dead air).
3. **Review the Timeline Spec Matrix** with the user:

| Scene | Time Window | Audio Window | Primary Focus | Content Elements |
| :---- | :---- | :---- | :---- | :---- |
| **Scene 1** | `0.0s – 18.0s` | `0.3s – 16.8s` | Intro & Framing | Title reveal, orbital glow |
| **Scene 2** | `18.0s – 44.0s` | `18.4s – 43.2s` | Core Comparison | Animated cards & diagram |

## **Step 5: Create and Approve a Static Storyboard**

Create `<project-folder>/storyboard.html` with static SVG/HTML layout mockups for every chapter in the approved aspect ratio (`1920×1080` or `1080×1920`). Confirm layout density, color contrast, and typography hierarchy with the user before adding runtime animation.

## **Step 6: Implement HTML & Seekable Animations**

Write `<project-folder>/index.html` adhering strictly to HyperFrames standards (and `<project-folder>/AGENTS.md`):

* **Timed elements & root timeline:** Every scene uses `class="scene clip"` with `data-start` and `data-duration`; register one paused GSAP root timeline on `window.__timelines["main"]` and handle `hf-seek` events.
* **No blank `0:00` frame:** Ensure opening scene elements and background visuals are visible immediately (`0.0s–0.3s`).
* **Deterministic & lint-clean:** Never use `Math.random()` or `Date.now()` (use a seeded PRNG such as `mulberry32`). Use Google Fonts (`Inter`, `JetBrains Mono`) or explicit `@font-face` rules—never undeclared OS-only font names like `PingFang SC` or `SFMono-Regular`.
* **Declarative managed audio:** Mount voiceover/music with `<audio class="clip" src="./assets/..." data-start="0" data-duration="...">`. Never call `.play()`, `.pause()`, `.currentTime`, or `.muted` on managed `<audio>` elements in scripts read by HyperFrames (`imperative_media_control` lint error).
* **Standalone browser fallback (optional):** If adding a direct-browser auto-play/chapter-HUD fallback for human review, guard it behind `if (!navigator.webdriver && window.self === window.top)` and keep its `Audio` instance completely separate from the declarative HyperFrames `<audio class="clip">` element.

## **Step 7: Verification & Autonomous Export**

1. **Lint & Check:** Run `npm run check` inside `<project-folder>` and fix all errors (`0 error(s)`).
2. **Frame Inspection:** Capture key timestamps with `npx hyperframes snapshot --at <seconds>` and visually inspect the PNGs.
3. **Local Preview:** Launch `npx hyperframes preview --background` (or `npm run dev` for interactive user review).
4. **Final Render:** Export the production MP4 into `<project-folder>/renders/` via `npx hyperframes render` (e.g., `npx hyperframes render -o renders/output.mp4`), and verify duration/streams with `ffprobe`.

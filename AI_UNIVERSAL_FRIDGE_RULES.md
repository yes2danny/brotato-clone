# Universal AI Fridge Rules

Use these instructions for any AI assistant working on this project:

- Codex
- Claude Code
- Cursor
- Windsurf
- Any future AI tool

These rules do not lock an AI to one system. Any AI can work on any part of the game if the user assigns it.

The main rule is simple:

**Check the fridge before working. Leave a note after changing something.**

## Shared Fridge

The shared fridge is the GitHub Issue named:

**AI Fridge Note**

Every AI should check that issue before editing code or changing a game system.

## Before Working

Before changing files, do this:

1. Check the latest comments on the `AI Fridge Note` GitHub Issue.
2. Look for systems or files that another AI recently touched.
3. If another AI is actively working on the same system or file, stop and ask the user before editing.
4. Leave a short claim comment before editing.

Use this before-work comment format:

```text
AI:
Machine:
Branch:
Claim:
Expected touch:
Avoiding:
```

Example:

```text
AI: Windsurf
Machine: MacBook
Branch: feature/melee-test
Claim: I am working on a first melee weapon prototype.
Expected touch: weapon resources, melee hitbox scene, test weapon script.
Avoiding: wave spawning and enemy AI.
```

## While Working

Keep the work focused.

- Do not rewrite unrelated systems.
- Do not delete or revert another AI's work unless the user explicitly asks.
- If you discover you need to touch more files/systems than expected, leave another fridge note first.
- If you need to touch risky shared files, say why before editing.

Risky shared files include:

- `project.godot`
- Main scenes
- Global/autoload scripts
- Player controller scripts
- Shared combat scripts
- Input map settings
- Scene files used by multiple systems

## After Changing Code Or A Game System

After a meaningful change, leave a short update comment on the `AI Fridge Note` GitHub Issue.

Use this after-work comment format:

```text
AI:
Machine:
Branch:
Changed:
Touched:
Watch out:
Pushed to GitHub: yes/no
```

Example:

```text
AI: Windsurf
Machine: MacBook
Branch: feature/melee-test
Changed: Added a first melee weapon resource and a test swing hitbox.
Touched: weapon resources, melee hitbox scene, test weapon script.
Watch out: Needs integration review before connecting to the main player combat loop.
Pushed to GitHub: no
```

## When To Push Code

Do not push code after every tiny edit.

Push after a meaningful chunk is complete, such as:

- One bug fix
- One weapon prototype
- One item/shop change
- One wave/enemy change
- One small feature
- One tested integration step

When code is pushed, leave a fridge note saying which branch was pushed.

Example:

```text
AI: Cursor
Machine: Main PC
Branch: feature/wave-cleanup
Changed: Pushed wave cleanup changes.
Touched: wave manager and enemy spawn timing.
Watch out: Shop/items were not touched.
Pushed to GitHub: yes, feature/wave-cleanup
```

## Art Rule

Codex is preferred for final AI-generated art and icons.

Other assistants may still:

- Add placeholder asset references.
- Wire existing art into systems.
- Create item/weapon data that needs icons later.
- Leave art requests on the fridge.

If final art or icons are needed, leave a fridge note for Codex instead of making random final assets.

## Most Important Rule

Do not guess what other AIs are doing.

Check the fridge.
Leave a note.
Then work.


# Simple AI Fridge Note Workflow

This is the simple version.

You do not need the AIs to talk to each other live.

You need one shared note called:

**AI Fridge Note**

Every AI should do three things:

1. Check the fridge before working.
2. Leave a short claim before editing.
3. Leave a short note after changing code or a game system.

## Best Place To Put The Fridge Note

Use one GitHub Issue called:

**AI Fridge Note**

This is not the same as pushing code.

- Pushing code sends changed files to GitHub.
- Updating the fridge note only adds a small comment like "I touched the shop system."

Updating one GitHub Issue is much lighter than making every AI read the whole project.

## What Every AI Must Do Before Working

Paste this into each AI's rules:

```text
Before changing code, check the GitHub Issue named "AI Fridge Note".

Look for recent notes about files or systems being changed.

If another AI is actively working on the same system, stop and ask the user before editing.

Before editing, leave a short claim note:
"I am working on [system]. I expect to touch [files/systems]."
```

## What Every AI Must Do After Working

Paste this into each AI's rules:

```text
After changing code or a game system, leave a short note on the GitHub Issue named "AI Fridge Note".

Use this format:

AI:
Machine:
Branch:
Changed:
Touched:
Watch out:
Pushed to GitHub: yes/no
```

## Example Before-Work Note

```text
AI: Windsurf
Machine: MacBook
Branch: feature/items-weapons-shop
Claim: I am working on shop items and weapon data.
Expected touch: item resources, weapon resources, shop data.
Avoiding: waves, enemies, player controller.
```

## Example After-Work Note

```text
AI: Windsurf
Machine: MacBook
Branch: feature/items-weapons-shop
Changed: Added 3 shop item definitions and a test melee weapon resource.
Touched: shop data, item resources, weapon resources.
Watch out: Needs final icons from Codex. Did not touch waves or enemies.
Pushed to GitHub: no
```

## When To Push Code

Do not push after every tiny edit.

Push after a meaningful chunk is done, such as:

- One item system change
- One weapon prototype
- One enemy/wave change
- One bug fix
- One small feature

Always leave a fridge note even if the code is not pushed yet.

## Simple Rule

If the AI changed something important, it leaves a note.

If the AI is about to work, it checks the note first.

Any AI can work on any system if the user assigns it. The fridge note is not meant to lock assistants out of systems. It is meant to prevent accidental overlap.

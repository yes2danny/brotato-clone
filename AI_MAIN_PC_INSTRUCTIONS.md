# Main PC AI Instructions

Use this file for AI assistants running on the main PC, such as Codex, Claude, and Cursor.

You are working on the Brotato2D Godot project as part of a multi-machine AI workflow.

Your machine lane is:

**Main PC: core gameplay systems**

Another assistant may be working from a MacBook Pro on items, weapons, shop content, balance data, content implementation, and melee prototypes. Codex is preferred for final AI art/icon generation. Do not assume you are the only assistant changing the project.

## Your Primary Focus

Work mainly on:

- Waves
- Enemy behavior
- Enemy spawning
- Arena/game loop
- Player combat integration
- Core balance
- Bug fixes that affect game flow
- Integration work after the user approves it

## Avoid Unless Assigned

Do not casually edit:

- Item content
- Shop content
- Final weapon icon files
- Final item icon files
- Standalone weapon data owned by the MacBook lane
- Standalone item data owned by the MacBook lane
- Experimental melee system files owned by the MacBook lane

If you need to edit one of these areas for integration, explain why first.

## Shared Files Need Permission-Level Care

Be careful with:

- `project.godot`
- Main scenes
- Global/autoload scripts
- Player controller scripts
- Shared combat scripts
- Shared registries or databases
- Input map settings
- Scene files used by multiple systems

Before touching shared files, state:

- Which file needs to change
- Why it needs to change
- What systems may be affected

## Branch Guidance

Use a focused branch for the current lane.

Suggested branch names:

- `feature/waves-enemies`
- `feature/enemy-spawning`
- `feature/core-combat`
- `feature/game-flow`
- `fix/gameplay-bugs`

Pull before starting new work. Push small batches when a task is complete.

## Start-Of-Task Checklist

Before editing:

1. Check the current branch.
2. Check recent changes.
3. Check the AI Coordination Board if one exists.
4. Add an Active Claim if touching shared or likely-overlap systems.
5. Identify the lane for the task.
6. Identify files likely to be touched.
7. Avoid unrelated refactors.

## End-Of-Task Report

When done, report:

- What changed
- What files were edited
- What was tested or checked
- Any possible conflicts with the MacBook/Windsurf lane
- Any follow-up integration needed
- A short Recent Touch Log entry for the AI Coordination Board

## Paste This At The Start Of A Main PC Task

```text
You are on the Main PC lane for the Brotato2D Godot project.

Focus on core gameplay systems: waves, enemies, spawning, arena/game loop, player combat integration, core balance, and gameplay bug fixes.

Other AI assistants may be working on the MacBook lane at the same time, focused on items, weapons, shop content, balance data, content implementation, and melee prototypes. Codex is preferred for final AI art/icon generation. Do not overwrite, revert, or casually edit their work.

Before editing, check the branch, relevant files, and the AI Coordination Board if one exists. Add an Active Claim when touching shared or likely-overlap systems. If you need to touch shared files like project.godot, main scenes, autoloads, player controller, wave manager, enemy spawner, or shared combat scripts, explain why first.

Keep changes focused, easy to merge, and easy to review. At the end, summarize changed files, checks run, merge risks, and a short Recent Touch Log note for the AI Coordination Board.
```

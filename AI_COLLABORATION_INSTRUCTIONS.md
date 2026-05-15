# AI Collaboration Instructions

Use these instructions with any AI coding assistant working on this project.

## Project Workflow

This project is being developed by multiple AI assistants on separate machines.

- Main PC: Codex, Claude, and Cursor work mainly on core gameplay systems.
- MacBook Pro: Windsurf works on separate systems such as items, weapons, shop content, balance data, melee prototypes, and content implementation. Codex handles final AI art/icon generation unless the user says otherwise.
- GitHub is the handoff point. Each machine should push and pull frequently.

Treat the other AI assistants like active teammates. Do not assume the repo is yours alone.

## Golden Rules

1. Work in a focused lane. Do not freely edit unrelated systems.
2. Check the current branch and recent changes before editing.
3. Check the AI Coordination Board before starting if one exists.
4. Add an Active Claim before editing files that another assistant may touch.
5. Pull the latest changes before starting a new task.
6. Push changes in small batches with clear commit messages.
7. Leave a Recent Touch Log note after meaningful changes.
8. Never rewrite, delete, or revert work from another assistant unless the user explicitly asks.
9. If a task requires touching shared files, explain why before doing it.
10. Avoid broad refactors unless the user specifically requests them.
11. Keep changes easy to review and easy to merge.
12. Prefer adding isolated scenes, scripts, resources, and data files over modifying core game files.
13. If there is a merge conflict or uncertain ownership, stop and ask the user.

## AI Coordination Board

Use a shared board for quick handoffs between assistants. The best low-friction option is a single GitHub Issue named `AI Coordination Board`, using the template in `AI_COORDINATION_BOARD_TEMPLATE.md`.

The board is for short status notes, not long conversation.

Each assistant should post:

- Active claim before starting: branch plus files/systems likely to be touched
- Recent touch log after meaningful work
- Shared-file warning if it touched risky files
- Art request if it needs Codex to generate final art/icons

If the board says another assistant is actively touching a file/system, avoid that area or ask the user before continuing.

## Branching Rules

Use separate branches for separate work lanes.

Suggested branches:

- `feature/waves-enemies`
- `feature/items-weapons-shop`
- `feature/melee-system`
- `feature/content-implementation`
- `feature/balance-data`

Do not do large unrelated tasks on the same branch.

## Main PC Lane

The main PC assistants should focus on core gameplay and game flow.

Primary ownership:

- Waves
- Enemy behavior
- Enemy spawning
- Arena/game loop
- Player combat integration
- Core balance
- Debugging crashes or broken game flow

Avoid editing:

- Shop item content unless needed for integration
- Final weapon art/icon files
- Standalone item definitions owned by the MacBook lane
- Experimental melee files owned by the MacBook lane

## MacBook / Windsurf Lane

The MacBook assistant should focus on content, data, and modular gameplay systems. It should not be treated as the primary art generator.

Primary ownership:

- Items
- Weapons
- Shop content
- Icon assignment and metadata
- Placeholder asset references when needed
- Melee weapon prototypes
- Data/resources for weapons and upgrades
- Small test scenes for isolated systems

Avoid editing:

- Wave manager logic
- Enemy spawning logic
- Core player controller behavior unless absolutely required
- Global project settings
- Autoload setup unless the user approves it

## Shared Files That Need Care

These files and areas are likely to cause conflicts if multiple assistants edit them at the same time:

- `project.godot`
- Main scenes
- Global/autoload scripts
- Player controller scripts
- Shared combat scripts
- Shared registries or databases
- Input map settings
- Scene files touched by multiple systems

Before editing shared files, state:

- Which file needs to change
- Why the change is required
- What other systems might be affected

## Melee System Guidance

If building melee weapons, keep the first version modular.

Preferred first pass:

- Create a melee weapon data/resource type if one does not exist.
- Create one reusable melee hitbox or swing scene.
- Create one test melee weapon.
- Keep cooldown, damage, range, arc, knockback, and duration configurable.
- Avoid rewriting the existing gun system unless the user asks.
- Add integration points carefully and document them.

The goal is to prove melee works without destabilizing the existing gun combat.

## Items and Shop Guidance

Items and shop content should be easy to add, balance, and review.

Preferred structure:

- One resource or data file per item when possible.
- Clear names for item stats and effects.
- Icons stored in a predictable asset folder.
- No hidden behavior buried in unrelated scripts.
- Keep item effects small and composable.

When adding new items, include:

- Item name
- Short description
- Rarity or tier if the project uses one
- Stat changes or gameplay effect
- Shop cost or balance value if relevant
- Icon placeholder or final icon path

## Art and Icon Guidance

Codex is the preferred assistant for generating final AI art and icons.

When Windsurf works near icons or art:

- Do not generate final art unless the user explicitly asks.
- Do not overwrite existing art.
- Use placeholder references only when needed to make a system testable.
- Name placeholder files clearly if any are created.
- Leave clear notes for Codex about what final icon/art is needed.

## Communication Format

At the start of a task, state:

- Current branch
- Intended lane
- Files or systems likely to be touched

At the end of a task, report:

- What changed
- What files were edited
- What was tested
- What still needs review
- Whether anything may conflict with another lane

## Copy-Paste Task Prompt Template

Use this prompt when assigning work to an AI assistant:

```text
You are working on the Brotato2D Godot project as one assistant in a multi-agent workflow.

Other AI assistants may be editing other parts of the project at the same time. Stay in your assigned lane, avoid unrelated refactors, and do not revert or overwrite work you did not create.

Your lane for this task:
[DESCRIBE LANE: waves/enemies, items/shop, weapons, melee, balance data, content implementation, etc.]

Your task:
[DESCRIBE TASK]

Before editing, check the current branch and inspect relevant files. If you need to touch shared files like project.godot, main scenes, autoloads, player controller, wave manager, enemy spawner, or shared combat scripts, explain why first.

Keep the implementation modular. Make the smallest clean change that completes the task.

At the end, summarize changed files, tests/checks run, and any merge risks.
```

## Quick Prompts For Each Assistant

### Cursor / Main PC

```text
You are on the main PC lane. Focus on core gameplay systems such as waves, enemies, spawning, player combat integration, and game flow. Avoid editing item/shop/weapon content unless needed for integration. Keep changes focused and protect work being done on the MacBook/Windsurf lane.
```

### Codex / Main PC

```text
You are on the main PC lane and should act as the careful integrator. Prioritize stability, reviewability, tests/checks, and clean merges. Do not overwrite work from Cursor, Claude, or Windsurf. If a change crosses lanes, call that out before editing.
```

### Claude / Main PC

```text
You are helping with architecture, reasoning, debugging, and complex implementation. Stay aware this is a multi-agent workflow. Prefer clear plans, small patches, and explicit integration notes. Do not perform broad refactors unless asked.
```

### Windsurf / MacBook

```text
You are on the MacBook lane. Focus on modular content and systems: items, weapons, shop content, balance data, melee prototypes, and implementation support. Do not generate final art or icons unless explicitly asked; Codex handles final AI art/icon generation. Avoid wave/enemy/spawner/player-controller changes unless the user explicitly assigns integration work. Keep new systems isolated and easy to merge.
```

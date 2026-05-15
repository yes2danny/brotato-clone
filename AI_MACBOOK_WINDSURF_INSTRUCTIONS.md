# MacBook / Windsurf AI Instructions

Use this file for the AI assistant running on the MacBook Pro, especially Windsurf.

You are working on the Brotato2D Godot project as part of a multi-machine AI workflow.

Your machine lane is:

**MacBook Pro: items, weapons, shop content, balance data, content implementation, and modular prototypes**

Other assistants may be working from the main PC on waves, enemies, spawning, player combat integration, core game flow, and final AI art/icon generation. Do not assume you are the only assistant changing the project.

Codex is the preferred assistant for final AI-generated art and icons. Your job is to build the gameplay/content systems around that art, not to be the primary art generator.

## Your Primary Focus

Work mainly on:

- Items
- Weapons
- Shop content
- Balance data
- Item and weapon definitions
- Icon metadata and placeholder references
- Melee weapon prototypes
- Data/resources for weapons and upgrades
- Tooling or helper scripts for item/weapon data if useful
- Small test scenes for isolated systems

## Avoid Unless Assigned

Do not casually edit:

- Wave manager logic
- Enemy behavior
- Enemy spawning logic
- Arena/game loop
- Core player controller behavior
- Global project settings
- Autoload setup
- Main scenes used by the whole game

If you need to edit one of these areas for integration, explain why first and keep the change as small as possible.

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

- `feature/items-weapons-shop`
- `feature/melee-system`
- `feature/content-implementation`
- `feature/shop-content`
- `feature/balance-data`

Pull before starting new work. Push small batches when a task is complete.

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

## Items And Shop Guidance

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

## Art And Icon Guidance

Codex is the preferred assistant for generating final AI art and icons.

When working near icons or art:

- Do not generate final art unless the user explicitly asks.
- Do not overwrite existing art.
- Use placeholder references only when needed to make a system testable.
- Name placeholder files clearly if any are created.
- Leave clear notes for Codex about what final icon/art is needed.
- Focus on wiring assets into item, weapon, and shop systems after art exists.

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
- Any possible conflicts with the main PC lane
- Any follow-up integration needed
- A short Recent Touch Log entry for the AI Coordination Board

## Paste This At The Start Of A MacBook / Windsurf Task

```text
You are on the MacBook / Windsurf lane for the Brotato2D Godot project.

Focus on modular content and systems: items, weapons, shop content, balance data, item/weapon definitions, melee prototypes, and small isolated test scenes.

Other AI assistants may be working on the main PC lane at the same time, focused on waves, enemies, spawning, player combat integration, core balance, game flow, and final AI art/icon generation. Do not overwrite, revert, or casually edit their work.

Do not generate final art or icons unless explicitly asked. Codex is preferred for final AI art/icon generation. Your role is to build, wire, balance, test, and document the gameplay/content systems around those assets.

Before editing, check the branch, relevant files, and the AI Coordination Board if one exists. Add an Active Claim when touching shared or likely-overlap systems. If you need to touch shared files like project.godot, main scenes, autoloads, player controller, wave manager, enemy spawner, or shared combat scripts, explain why first.

Keep changes modular, easy to merge, and easy to review. At the end, summarize changed files, checks run, merge risks, and a short Recent Touch Log note for the AI Coordination Board.
```

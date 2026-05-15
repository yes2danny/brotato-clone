# AI Coordination Board Template

Use this as the shared update board for all AI assistants.

Best place to use it:

1. GitHub Issue named `AI Coordination Board`
2. Notion page named `Brotato2D AI Coordination`
3. Slack/Discord pinned message if you prefer chat

The goal is not conversation. The goal is fast handoff notes.

## Current Lanes

| Lane | Owner | Current Focus | Branch | Status |
| --- | --- | --- | --- | --- |
| Main PC / Core Gameplay | Codex / Claude / Cursor | Waves, enemies, spawning, combat flow | `feature/waves-enemies` | Not started |
| MacBook / Windsurf | Windsurf | Items, weapons, shop, melee prototypes, balance data | `feature/items-weapons-shop` | Not started |
| Art / Icons | Codex | Final generated art and icons | `feature/art-icons` | Not started |

## Active Claims

Before editing, add a short claim here so other assistants know what you are touching.

| Time | Assistant | Branch | Files / Systems Claimed | Expected Finish |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## Recent Touch Log

After a meaningful change, add a short update.

Use this format:

```text
[DATE/TIME] [ASSISTANT] [BRANCH]
Touched:
- file_or_system_a
- file_or_system_b

Changed:
- short summary of what changed

Watch out:
- possible conflict, dependency, or follow-up

Next:
- what another assistant should know or do next
```

## Shared Files Watchlist

These files require extra care because multiple lanes may need them:

- `project.godot`
- Main scenes
- Global/autoload scripts
- Player controller scripts
- Shared combat scripts
- Shared registries or databases
- Input map settings
- Scene files used by multiple systems

If you touch one of these, add a note here:

| Time | Assistant | Shared File | Reason | Risk |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## Art Requests For Codex

Windsurf or other assistants can add art requests here instead of generating final art.

| Request | Needed For | Size / Style Notes | Priority | Status |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## Integration Questions

Use this section when an assistant is blocked or unsure.

| Question | Asked By | Related Files / Systems | Status |
| --- | --- | --- | --- |
|  |  |  |  |

## Rules For Updates

- Keep notes short.
- Do not paste huge code blocks.
- Mention file paths and systems touched.
- Mention branch names.
- Mention risks or conflicts.
- Do not use this board for long brainstorming.
- If a change is not pushed yet, clearly write `LOCAL ONLY`.
- If a change is pushed, include the branch name.

## Quick Update Prompt For Any AI

```text
Before starting, check the AI Coordination Board. Add a short Active Claim with your branch and the files/systems you expect to touch.

When done, add a Recent Touch Log entry with what changed, files/systems touched, tests/checks run, merge risks, and next steps.

Do not use the board for long discussion. Keep it short enough that another assistant can scan it quickly.
```


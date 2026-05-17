# Sound Plan Handoff — 2026-05-16

Purpose: lightweight plan for adding sound later. This is intentionally **not** an implementation spec yet.

## Current state

- No real audio folder or sound library is wired yet.
- No obvious SFX manager / audio bus system exists yet.
- The only audio-related hook I found is `music_override` in `WaveData.gd`, marked as future-facing.

## Best first pass

Do **not** try to sound-design the whole game at once.

Start with the handful of sounds that make the game immediately feel responsive:

1. player weapon fire  
2. enemy hit  
3. enemy death  
4. player hurt  
5. XP / gold pickup  
6. shop open / buy item  
7. wave start / wave clear  

That small set will make the game feel much more alive before bespoke enemy voices or fancy ambience are needed.

## Suggested structure

Create one simple central audio layer first, then let gameplay systems ask it to play sounds.

Suggested shape:

- `AudioManager` or `SFXManager` autoload
- separate buses for:
  - Master
  - Music
  - SFX
  - UI
- shared one-shot playback for ordinary sound effects
- music kept separate from SFX from the start

The point is to avoid every scene inventing its own audio logic.

## Enemy sound philosophy

For now, avoid giving every enemy a unique full sound set.

Better first layer:

- **small enemy family** sound
- **medium enemy family** sound
- **heavy enemy family** sound
- **ranged enemy** sound
- **special enemy** sound

Then later, once the roster is stable, unique sounds can be added where identity really matters:

- treasure goblin
- bosses
- elite / mini-boss enemies
- maybe a few especially recognizable enemies

This keeps production realistic while still making the roster readable.

## Good implementation order

1. Make the audio buses / manager.
2. Wire the core global feedback sounds:
   - weapon shot
   - player hurt
   - pickup
   - shop UI
3. Wire generic enemy hit/death sounds.
4. Add wave transition stings.
5. Only after that, add enemy-family-specific sounds.
6. Add music last or in parallel if Danny already has a direction for soundtrack.

## Questions Claude should answer before implementation

1. Should this game sound more:
   - punchy arcade,
   - crunchy fantasy,
   - or lightly goofy to match the item humor?
2. Should enemies be mostly abstract SFX, or should some have creature-like vocal sounds?
3. Does Danny want music early, or should the first pass stay focused on feel / readability?

## Small warning

Do not overbuild the first pass.

The game needs a **sound foundation** before it needs a sound museum.

Get the most repeated actions sounding good first, then expand only where the player’s ear will actually notice the difference.

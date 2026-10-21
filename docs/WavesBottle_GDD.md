# WAVESBOTTLE: THE WAKE FREQUENCY

## Game Design Document — v2.1 (as built)

A fast, top-down naval action roguelike. Pilot a prototype warship through a hostile neon ocean, line up port and starboard broadsides, and turn your wake into a visible and musical measure of mastery.

| | |
|---|---|
| **Genre** | Top-down arcade naval combat / action roguelike |
| **Players** | Single player |
| **Engine** | Godot 4.6 (GDScript) |
| **Renderer** | GL Compatibility |
| **Target** | PC (Windows), web-ready |
| **Base resolution** | 1600 x 900, fullscreen by default |
| **Input** | Keyboard + mouse |

### Credits

| Role | Name |
|---|---|
| Game Design & Development | azenenen & amukuLafaek |
| Visuals | azenenen |
| Audio | azenenen |

### At a glance

| Run length | Enemies | Upgrades | Hazards | Wake tiers |
|---|---|---|---|---|
| 10 waves (9 + Galleon boss) | 4 types | 19 | 5 types | 0 – V (x1.0 to x5.0) |

---

## Table of Contents

1. [Vision & Design Pillars](#1-vision--design-pillars)
2. [Core Loop & Run Flow](#2-core-loop--run-flow)
3. [Player Ship, Movement & Controls](#3-player-ship-movement--controls)
4. [Broadside Combat & Ammunition](#4-broadside-combat--ammunition)
5. [Enemy Roster](#5-enemy-roster)
6. [The Galleon — Flagship Boss](#6-the-galleon--flagship-boss)
7. [Wake Multiplier & Score](#7-wake-multiplier--score)
8. [Wave Plan & Difficulty Curve](#8-wave-plan--difficulty-curve)
9. [Arena & Environmental Hazards](#9-arena--environmental-hazards)
10. [Shipyard, Upgrades & Salvage Economy](#10-shipyard-upgrades--salvage-economy)
11. [Permanent Unlocks, Records & Save Data](#11-permanent-unlocks-records--save-data)
12. [HUD, Menus & Accessibility](#12-hud-menus--accessibility)
13. [Visual Identity & Audio Direction](#13-visual-identity--audio-direction)
14. [Architecture & Code Map](#14-architecture--code-map)

---

## 1. Vision & Design Pillars

### Player fantasy

A daring captain who reads the ocean, controls a heavy vessel with precision, and turns a dangerous engagement into a flowing performance.

### Final principle

> "WavesBottle should feel like a performance of controlled chaos." The ship has weight, the sea has influence, cannons create danger and opportunity, and the Wake celebrates growing command of the battlefield.

### Five design pillars

| # | Pillar | Meaning in the game |
|---|---|---|
| 1 | **Movement is mastery** | Heavy but responsive momentum. Throttle, inertia, drift and recoil reward skilled steering. |
| 2 | **Positioning matters** | Facing, side-mounted cannons, range and enemy orientation beat simply holding fire. |
| 3 | **Style is systemic** | Hits, kills, dodges, drifts and positional shots feed the Wake: score, visuals and music. |
| 4 | **Runs create stories** | Shipyard upgrades, loadouts and hazards make every run play differently. |
| 5 | **Clarity beats spectacle** | Every threat is telegraphed. Hostile projectiles and warnings always stay readable. |

### Target experience

| Time scale | What the player does |
|---|---|
| Moment to moment | Steer, reposition, fire a broadside, evade, exploit openings. |
| Short term | Build a combo, clear a wave, collect Salvage, buy an upgrade. |
| Run level | Adapt a build to escalating waves and hazards, then sink the Galleon. |
| Long term | Unlock loadouts and wake colors, chase records, fill the bestiary. |

---

## 2. Core Loop & Run Flow

### Core gameplay loop

Read the battlefield → Maneuver → Engage broadside → Evade & reposition → Build Wake → Earn Salvage → Upgrade → Survive escalation → *(repeat)*

### Game state flow

Main Menu → Wave N (combat) → Wave cleared (2.2 s grace) → Shipyard → Wave N+1 → … → Wave 10: Galleon → Run Summary

| State | Behaviour |
|---|---|
| **Pause** (Esc / P) | Freezes the run and hides the HUD. Resume, Settings or Abandon Run. Fire input stays locked until buttons are released. |
| **Defeat** | Hull reaches 0: "HULL BREACHED", 1.8 s, then the summary. Records and unlocks are saved; run upgrades are discarded. Quick Retry. |
| **Victory** | Sinking the Galleon sinks every escort, clears enemy fire and ends the run with a victory summary after 3 s. |
| **Sea Trials** | Practice mode: invulnerable by default, spawn any enemy or hazard on demand, toggle reefs, force wind shifts. |

### Run summary contents

Time survived · Wave reached · Score · Kills by type · Accuracy · Highest Wake tier · Bosses defeated · Salvage earned / spent · Damage by source · Upgrades fitted · Loadout · Run seed · New records & unlocks

---

## 3. Player Ship, Movement & Controls

Each side of the ship (port = left, starboard = right) has its own cannons, reload timer and firing arc. Arcs fade while reloading and fill as they recover. Port is shown in cyan, starboard in pink.

### Base stats

| Stat | Value |
|---|---|
| Max Hull | 100 |
| Top speed / Acceleration | 320 / 230 |
| Brake / Reverse | 340 / 30% of top speed |
| Turn rate (low-speed factor) | 2.4 rad/s (45%) |
| Lateral grip / while drifting | 3.4 / 0.9 |
| Cannons per side / Reload | 3 / 1.5 s |
| Range / Shot speed | 520 / 660 |
| Recoil impulse | 55 |
| Collision radius | 18 |

### Movement model

- Persistent throttle from -30% to 100%; the ship keeps its speed setting.
- Speed moves toward *throttle x top speed x wind factor*.
- Sideways velocity decays by lateral grip. Holding **Drift** lowers grip and boosts turning by 30%.
- Turning scales with speed but never drops below 45%.
- Firing pushes the ship away from the firing side (recoil).
- Speed is capped at 135% of top speed.

### Controls (rebindable)

| Keys | Action |
|---|---|
| `W` / `S` | Raise / lower throttle; hold `S` at speed to brake |
| `A` / `D` | Turn left / right |
| `Shift` | Drift (hold while turning) |
| `J` / `←` / Left mouse | Fire port broadside |
| `L` / `→` / Right mouse | Fire starboard broadside |
| `Q` / `E` | Previous / next ammunition |
| `P` / `Esc` | Pause |
| `F11` / `Alt+Enter` | Toggle fullscreen |

Only the first key of each action is rebindable. Alternate keys and mouse buttons always stay bound, so no action can become unreachable.

### Wind

- One global wind vector with strength 35–100%.
- Sailing with the wind adds up to +15% propulsion, against it up to -15% (never below 70%).
- Crosswind adds sideways drift.
- Every 22–32 s the wind shifts. A "WIND SHIFT" banner and a ghost arrow on the compass give 3 s warning, then the wind turns at 0.7 rad/s.

### Collisions

- Reefs and the arena edge bounce the ship.
- Impacts above 110 speed deal 4 + overspeed damage, then grant 0.5 s of protection.
- Ramming enemies deals contact damage to both ships.

---

## 4. Broadside Combat & Ammunition

### Broadside rules

- Port and starboard fire independently with separate reloads.
- Shots leave from the firing side, inherit 50% of the ship's velocity, travel through the world and can miss.
- Holding fire re-fires on reload; a tap is buffered for 0.18 s.
- One target per projectile.

### Aiming

Directional manual aiming: the ship's facing is the aim. A small random spread (0.05 rad) keeps volleys readable and predictable. No aim assist.

### Feedback chain

| Step | Feedback |
|---|---|
| Intent | Side arcs and READY labels |
| Action | Muzzle flash, smoke, recoil, stereo cannon sound |
| Result | Sparks, impact sound or water splash |
| Consequence | Hull bars, slow ring, smoke, explosion |

### Ammunition

| Type | Damage | Range | Shot speed | Projectiles | Special | Availability |
|---|---|---|---|---|---|---|
| **Round Shot** | 10 | 100% | 100% | 1 per cannon | Reliable hull damage | All loadouts |
| **Chain Shot** | 4 | 85% | 90% | 1 per cannon | Slows speed and turning 25% for 2 s. Refresh cap 3 s. Bosses half, elites 70% duration. | Line Captain, Heavy Duelist |
| **Heavy Canister** | 4 per pellet | 45% | 105% | 3 pellets per cannon, wide spread | High close-range burst, weak at range | Close Quarters loadout or Canister Rack upgrade |

### Crossing the T

A hit counts as crossing the T when the shot was fired from the target's blind arc, inside 110% of your range:

- **Side-gunned ships** (Frigate, Galleon): from the bow or stern, within 35 degrees.
- **Bow-gunned ships** (Gunboat, Fireship): from the stern only.

| Effect | Value |
|---|---|
| Damage bonus | x1.25 |
| Wake / Score | +12 / +150 (0.6 s cooldown) |

### Damage model

- Hull is the only survival resource. Damage applies once per confirmed hit.
- Collisions grant 0.5 s of protection; Emergency Bulkheads grant 1.5 s after a saved lethal hit.
- Tracked damage sources: Gunboat, Frigate, Galleon, Mortar, Fireship blast, Mine, Lightning, Ramming, Reef collision.

---

## 5. Enemy Roster

| | Gunboat | Frigate | Fireship |
|---|---|---|---|
| **Role** | Swarm / harassment | Broadside duelist | Area denial / pursuit |
| **Hull** | 20 | 60 | 24 |
| **Speed / Turn** | 210 / 3.0 | 140 / 1.3 | 185 / 2.2 |
| **Attack** | Bow gun: 6 dmg, range 380, every ~2.4 s | Broadside: 3 x 9 dmg, range 430, every ~3.6 s | Blast: 26 dmg, radius 110 |
| **Telegraph** | 0.4 s flashing bow line | 0.95 s red fire lanes | 1.15 s fuse ring + ticking |
| **Contact damage** | 6 | 10 | — (contact sets a 0.3 s fuse) |
| **Reward** | 3 Salvage, 100 score | 8 Salvage, 300 score | 5 Salvage, 200 score |

### Behaviour & counterplay

- **Gunboat** — Orbits at about 250 px in its own direction and fires its bow gun when facing you. *Counter:* hit it from the side or stern; keep turning under pressure.
- **Frigate** — Holds about 330 px and turns a side toward you, then shows red fire lanes before firing. *Counter:* leave the red lane, or cross its bow or stern.
- **Fireship** — Leads your course and arms when close. If sunk before it detonates, its blast only hurts other enemies. *Counter:* sink it early, or outrun the blast ring.

### Spawn director

- Authored wave lists. The first two spawns stay easy; the rest are shuffled with the run seed.
- Spawns 650–950 px from the player (never closer than 520 px), clear of reefs, with a 1 s red arrival ring and edge arrows.
- Max alive: 6–10. Max simultaneous Frigates/Fireships: 2–5. Spawn interval: 1.3 s down to 0.55 s.

### Elites & scaling

- Elites have one clear modifier: Hull x1.6 and +8% speed, shown with a gold ring and diamond marker. They give +3 Salvage and x1.5 score.
- From wave 6, enemy Hull scales by +6% per wave.
- Pressure rises through composition before stats.

### Shared behaviour

All enemies separate from each other, bounce off reefs, ram for contact damage, show hull bars when damaged, smoke below 50% Hull, and drift with currents, whirlpools and storms.

---

## 6. The Galleon — Flagship Boss

Appears in wave 10.

| Stat | Value |
|---|---|
| Hull | 800 |
| Speed / Turn | 75 / 0.45 |
| Contact damage | 16 (always applies) |
| Reward | 60 Salvage + 5,000 score |

### Attack patterns

- **Broadside salvo** — Turns a side toward you, shows red fan lanes for 1.2 s, then fires 7 shots x 12 damage (range 560).
- **Mortar barrage** — 5 markers (one on your predicted path) fill up over 1.5 s, then explode: radius 70, 16 damage.
- **Reposition** — Sails to a new clear point at 140% speed.

### EXPOSED windows

After each salvo (2.2 s) and each barrage (1.6 s), the Galleon glows cyan and takes **x1.5 damage**. Chain Shot slows it for only half the usual time.

### State machine

Approach (5 s) → Aim → Windup → Recover / EXPOSED → Mortar → Recover / EXPOSED → Reposition → *(repeat)*

| Phase | Behaviour |
|---|---|
| **Phase 1** (100–50% Hull) | Cycle: Aim → Mortar → Reposition. 7-gun salvo, fan 0.12 rad, 5 mortars. |
| **Escalation** (at 50%) | "ESCALATION" banner and horn, forced reposition, 2 Gunboat escorts arrive. The phase change is an explicit state switch, never a timer. |
| **Phase 2** (below 50%) | Cycle: Aim → Mortar → Aim → Reposition. 9-gun salvo, fan 0.18 rad, two staggered volleys, 8 mortars. |
| **Defeat** | Chain of explosions, every escort sinks, enemy fire is cleared, +5,000 score, victory. |

---

## 7. Wake Multiplier & Score

The Wake is the game's signature system. It rewards consistent, expressive play and drives score, visuals and music.

### Tiers

| Tier | Name | Multiplier | Progress to next tier | Default color |
|---|---|---|---|---|
| 0 | Still | x1.0 | 50 | `#D9EBFF` |
| I | Ripple | x1.5 | 70 | `#9EF2FF` |
| II | Swell | x2.0 | 90 | `#40E6FF` |
| III | Surge | x3.0 | 110 | `#4DFFD9` |
| IV | Tempest | x4.0 | 130 | `#F273D9` |
| V | Resonance | x5.0 | max | `#FF4DB3` |

### Wake gains

| Event | Wake | Score |
|---|---|---|
| Cannon hit | +6 (scaled by damage) | damage x2 |
| Kill | +18 | enemy value (x1.5 for elites) |
| Crossed the T | +12 | +150 |
| Close dodge (shot, blast, mortar, lightning) | +12 | +50 |
| Drift pass / Close pass | +10 (16 with Slipstream Keel) | +40 |
| Wreck salvaged | +8 | +100 |
| Clean wave (no damage taken) | +40 | +8 Salvage |

### Wake losses

| Event | Effect |
|---|---|
| Damage below 15 | -35 progress |
| Damage of 15 or more | Drop one tier |
| Miss | -1.5 progress (silent) |
| Idle past grace period (2.5 s) | -18 progress per second |

The HUD shows the state (STEADY / DECAYING / HOLD), a grace bar and the reason for the last change. The Wake is on HOLD between waves.

### Score formula

- All points are multiplied by the current Wake multiplier.
- With Resonant Wake, score gets an extra +25% at tier III or higher.
- Wave clear = 500 x wave number.

### Audiovisual reward

- Wake trail color and width follow the tier and the chosen palette.
- Music combat percussion rises from 35% to full by tier II.
- A bright arpeggio fades in from tier I to III.
- The boss layer takes over while the Galleon is alive.

---

## 8. Wave Plan & Difficulty Curve

| Wave | Composition | Elites | Enemy Hull | New hazards | Design intent |
|---|---|---|---|---|---|
| 1 | 3 Gunboat | 0 | 100% | 1 Salvage wreck | Teach movement, sides and aiming. Tutorial prompts. |
| 2 | 5 Gunboat | 0 | 100% | — | Target priority while turning under pressure. |
| 3 | 3 Gunboat, 1 Frigate | 0 | 100% | Current | Introduce broadside telegraphs. |
| 4 | 4 Gunboat, 2 Frigate | 0 | 100% | Minefield | Mixed roles, mines to lure enemies into. |
| 5 | 3 Gunboat, 2 Fireship | 0 | 100% | 2 wrecks | Introduce area denial and fuse reading. |
| 6 | 2 Frigate, 3 Gunboat, 2 Fireship | 1 | 106% | Whirlpools (timed) | First elite, all three roles together. |
| 7 | 6 Gunboat, 2 Frigate, 2 Fireship | 1 | 112% | 2 currents, 2 minefields, storms | Swarm density plus weather. |
| 8 | 3 Frigate, 4 Gunboat, 3 Fireship | 2 | 118% | — | Battle line: overlapping broadsides. |
| 9 | 4 Frigate, 5 Gunboat, 3 Fireship | 3 | 124% | — | Final exam before the flagship. |
| 10 | Galleon (+2 escorts at 50%) | 0 | 800 Hull | Mines, whirlpools and storms cleared | Boss movement and timing test with room to maneuver. |

### Pacing rules

- **Introduce before punishing.** Every new enemy and hazard gets a "NEW THREAT" or "NEW HAZARD" banner with a one-line counter the first time it appears in a run.
- **One axis at a time.** Composition and elites grow first. Hull scaling starts only at wave 6 and stays mild (+6% per wave).
- **Seeded runs.** Each run has a 6-digit seed shown in the summary. Reefs, spawn order, wind and hazards are reproducible for balancing and bug reports.

---

## 9. Arena & Environmental Hazards

### Bounded arena

- 3200 x 2200 world with a pulsing dashed border and fog beyond it.
- The camera follows with velocity look-ahead at 0.85 zoom.
- 6–9 reefs (radius 40–95) placed at least 480 px from the start and 260 px apart, always leaving open lanes.

### Fair-play rules

- Hazards never spawn near the player (300–520 px minimum), avoid reefs and each other, and telegraph before they act.
- Mines, whirlpools and storms are cleared for the boss wave.
- Chained mine blasts hit the player at most once per 0.5 s.

### Hazards

| Hazard | Appears | How it works | Key numbers |
|---|---|---|---|
| **Salvage Wreck** | Wave 1 (1), wave 5+ (2) | Slow below 140 speed inside the gold ring for 2.5 s to salvage it. "SLOW DOWN" hint when too fast. Gold edge arrows point to it. | Reward 8 + 2 x wave Salvage, +100 score, +8 Wake |
| **Current** | Wave 3 (1), wave 7+ (2) | A 900 x 190 band of moving water with animated chevrons. Pushes every ship along the arrows, strongest in the middle. | Flow speed 110 |
| **Minefield** | Wave 4 (1 field), wave 7+ (2 fields) | 4–6 mines in a dashed 150 px field labelled MINES. They arm when any ship comes within 75 px, flash for 0.7 s, then explode. Shoot them to detonate early; blasts chain. | Blast radius 95, 18 dmg (bosses take half) |
| **Whirlpool** | Wave 6+, every 30–45 s | 3 s "FORMING" dashed ring, then a rotating spiral pulls ships inward and around for 26 s, then fades over 3 s. Escape by sailing along the edge. | Radius 170, pull 90, swirl 140 |
| **Storm Front** | Wave 7+, every 50–70 s | 4 s "INCOMING" ring, then a 300 px dark storm drifts with the wind for 40 s. Gusts push ships; yellow lightning markers strike after 1.2 s (on you every 2.2–3.5 s while inside). | Gust push 75 + 35 random; lightning radius 55, 12 dmg, hits enemies too |

### Sea Trials keys

| Key | Action | Key | Action |
|---|---|---|---|
| `1` | Spawn Gunboat | `5` | Spawn minefield |
| `2` | Spawn Frigate | `6` | Spawn whirlpool |
| `3` | Spawn Fireship | `7` | Spawn storm |
| `4` | Spawn Galleon | `8` | Spawn wreck |
| `0` | Clear enemies and hazards | `9` | Spawn current |
| `H` | Repair | `R` | Toggle reefs |
| `I` | Toggle invulnerability | `T` | Force wind shift |

---

## 10. Shipyard, Upgrades & Salvage Economy

### Salvage sources

| Source | Amount |
|---|---|
| Kills | Gunboat 3 · Fireship 5 · Frigate 8 · Galleon 60 |
| Elite bonus | +3 |
| Wave clear | 10 + 3 x wave |
| Clean wave | +8 |
| Wreck | 8 + 2 x wave |
| Resonant Wake (tier III+) | +1 per kill |

### Shipyard (after every wave)

- 4 random offers with exact before/after stat lines and costs.
- Current ship stats, owned upgrades and a preview of the next wave.
- **Repair +30 Hull:** costs 10, then +4 each use.
- **Reroll offers:** costs 5, then +5 each use.

### Upgrades

| Category | Upgrade | Effect | Cost | Max |
|---|---|---|---|---|
| Hull | Reinforced Plating | +25 max Hull and restores 25 | 30 | 3 |
| Hull | Shock-Absorbing Frame | Collision damage and knockback halved | 22 | 1 |
| Hull | Emergency Bulkheads | Survive one lethal hit per run with 1 Hull | 55 | 1 |
| Sails | Storm Canvas | +20% acceleration, +8% top speed | 24 | 3 |
| Sails | Tailwind Catcher | Favorable wind bonus doubled | 18 | 1 |
| Sails | Crosswind Rigging | Headwind penalty and crosswind drift halved | 18 | 1 |
| Rudder | Precision Rudder | +18% turn, +12% low-speed handling | 24 | 2 |
| Keel | Deep Keel | +40% lateral grip, shorter drifts | 20 | 1 |
| Keel | Slipstream Keel | Longer drifts, drift passes give 16 Wake | 24 | 1 |
| Cannons | Quick-Load Crew | Reload -15% | 32 | 3 |
| Cannons | Long-Bore Barrels | +20% range, +10% shot speed | 28 | 2 |
| Cannons | Dense Volley | +1 cannon per side, reload +12% | 40 | 2 |
| Cannons | Stabilized Carriages | Recoil -65% | 14 | 1 |
| Cannons | Recoil Rigging | Recoil +60%, part becomes a forward surge | 20 | 1 |
| Cannons | Canister Rack | Unlocks Heavy Canister ammunition | 26 | 1 |
| Cannons | Barbed Chains | Chain Shot slow +10%, +0.5 s | 22 | 1 |
| Wake | Resonant Wake | +25% score and +1 Salvage per kill at tier III+ | 28 | 1 |
| Wake | Wake Buffer | +1.5 s grace, decay 40% slower | 24 | 1 |
| Utility | Emergency Repair Kit | Restore 15 Hull after every cleared wave | 30 | 1 |

Canister Rack is not offered if the loadout already has Heavy Canister. Barbed Chains is only offered when Chain Shot is available.

### Build archetypes

| Archetype | Core upgrades |
|---|---|
| Broadside Specialist | Quick-Load Crew, Long-Bore Barrels, Dense Volley |
| Drifter | Precision Rudder, Slipstream Keel, Recoil Rigging |
| Windrunner | Storm Canvas, Tailwind Catcher, Crosswind Rigging |
| Control Captain | Barbed Chains, Canister Rack |
| Combo Hunter | Resonant Wake, Wake Buffer |

---

## 11. Permanent Unlocks, Records & Save Data

Permanent unlocks add options, not raw power. Run upgrades never carry over.

### Starting loadouts (sidegrades)

| Loadout | Ammo | Modifier | Unlock |
|---|---|---|---|
| Line Captain | Round, Chain | Balanced | Default |
| Close Quarters | Round, Canister | Turn +10%, range -10% | Reach wave 5 |
| Heavy Duelist | Round, Chain | +1 cannon per side, reload +20% | Defeat the Galleon |

### Wake color palettes

| Palette | Unlock | Tier colors (0 → V) |
|---|---|---|
| Bioluminescent | Default | `#D9EBFF` `#9EF2FF` `#40E6FF` `#4DFFD9` `#F273D9` `#FF4DB3` |
| Ember Tide | Reach Wake tier V | `#F2EBE0` `#FFD999` `#FFA64D` `#FF7A38` `#FF5259` `#FF3880` |
| Aurora | Reach wave 8 | `#E0F2EB` `#B3FFBF` `#66FF99` `#66E6FF` `#9980FF` `#D966FF` |

### Records

Best score, furthest wave, highest Wake tier, longest run, runs, victories, total kills and Galleons sunk. Shown in the main menu and the Hangar. Sea Trials never writes records.

### Bestiary

Each enemy type is revealed in the Hangar, with its counter-tip, after it is first encountered.

### Save file

- Location: `user://wavesbottle_save.json`
- Versioned (v1) with migration and default merging for missing fields.
- Stores settings, key bindings, records, unlocks, seen enemies, chosen loadout and palette, and tutorial completion.
- Run upgrades are never saved.

---

## 12. HUD, Menus & Accessibility

### In-run HUD layout (1600 x 900 logical)

| Area | Element | Content |
|---|---|---|
| Top left | Status panel | Hull bar, Salvage, wave / score, enemies left |
| Left, below status | Sea Trials controls | Practice keys (practice mode only) |
| Top center | Boss bar | Galleon Hull, phase, EXPOSED state |
| Top right | Wake panel | Tier, multiplier, progress, state, grace bar, last reason |
| Right, below Wake | Wind panel | Compass, strength, sailing %, shift warning, storm alert |
| Upper center | Banner queue | Waves, new threats, new hazards, wind shifts, escalation |
| Lower center | Tutorial prompt | One onboarding step at a time |
| Bottom center | Weapons panel | Port / starboard reload bars, ammo slots, `Q`/`E`, ammo description |
| Bottom right of center | Throttle panel | Throttle %, knots, DRIFT / BRAKE state |
| Bottom left | Footer | `[P] Pause`, `[F11] Fullscreen` |
| Screen edges | Indicators | Off-screen enemies, incoming spawns and wrecks; arrows avoid HUD panels |

### Screens

Main Menu · Sea Trials · Hangar · Settings · Credits · Pause · Shipyard · Run Summary

Every panel is centered and auto-scales down when the window is smaller than its content. The HUD is hidden during Pause, Shipyard and the Run Summary.

### Onboarding

Throttle → Turn → Port → Starboard → Brake → Drift → Ammo → Wake

Each prompt disappears once the player performs the action, uses the current key bindings, and is saved as completed.

### Accessibility & comfort

- Rebind keys (alternates always kept)
- Master / Music / Effects / UI volume
- Screen shake slider
- Reduce flashing
- Effects density: Low / Medium / High
- Fullscreen toggle (`F11` / `Alt+Enter`)
- Pause anywhere
- Status never shown by color alone
- Audio cues always mirrored visually
- Long text auto-fits its box

---

## 13. Visual Identity & Audio Direction

### Color palette

| Role | Color |
|---|---|
| Deep ocean | `#030A1A` / `#071326` (water shader) |
| Player & port side | `#4CE6FF` (cyan) |
| Starboard side & accent | `#FF6BC7` (pink) |
| Enemies | `#FF7340` (orange) |
| Warnings | `#FF3340` (red lanes, markers) |
| Salvage & elites | `#FFD866` (gold) |
| Lightning markers | yellow-white |

### Visual hierarchy

1. Hostile projectiles (bright orange with a white core)
2. Player ship and facing
3. Attack telegraphs (red lanes, fuse rings, mortar and lightning markers)
4. HUD: Hull, reloads, Wake
5. Water, wake trails, wind streaks, decoration

### Rendering

- All art is procedural vector drawing; there are no texture assets.
- Noise-based water shader with glints and edge fog.
- Particle budget of 1,200, with pooled projectiles (max 700).
- Wake trails are ribbons of fading foam tinted by tier.

### Dynamic music (procedural, 120 BPM loop)

| Layer | Content | When |
|---|---|---|
| Base | Pad chords, soft kick, ocean noise | Always |
| Combat | Hats, snare, bass line | During fights, rises with tier |
| High Wake | Plucked arpeggio | Fades in from tier I to III |
| Boss | Low saw drone, toms | While the Galleon is alive |

### Sound effects (synthesized at startup)

Cannon (stereo by side) · Enemy cannon · Impact · Splash · Explosion · Hurt · Reload ready · Tier up / down · Salvage · Warning · Fuse tick · Wind · Dodge · Boss horn · UI click / confirm / deny

Audio is routed through separate Master, Music, SFX and UI buses.

---

## 14. Architecture & Code Map

### Scene tree at runtime

```
Main (state: menu / combat / paused / shipyard / results)
├─ Backdrop layer (menu ocean)
├─ UI layer (current screen)
└─ Run
   ├─ Ocean shader · FxUnder · Arena (reefs)
   ├─ Hazards · Enemies · PlayerShip
   ├─ ProjectileSystem · FxOver · Camera2D
   └─ HUD layer
```

### Autoload singletons

| Autoload | Responsibility |
|---|---|
| `GameData` | All tuning tables |
| `SaveData` | Settings, records, unlocks |
| `Controls` | Input map and rebinding |
| `Sound` | Synthesis, audio buses, music layers |

Plain GDScript, no external assets or plugins. The simulation clamps the frame delta to 0.05 s.

### Systems and scripts

| System | Script | Responsibility |
|---|---|---|
| Game state | `main.gd` | Screen switching, pause, shipyard, summary, retry, fullscreen hotkey |
| Run manager | `run/run.gd` | Waves, score, Salvage, Wake events, tutorial, camera, music mix, practice keys |
| Spawn director | `run/spawn_director.gd` | Wave queues, spawn safety, threat caps, arrival cues |
| Player & stats | `ship/player_ship.gd`, `ship/ship_stats.gd` | Movement model, broadsides, recoil, damage, upgrade math and previews |
| Enemies | `enemies/enemy.gd` + 4 subclasses | Steering, telegraphs, attacks, slow, crossing check, boss state machine |
| Projectiles | `combat/projectile_system.gd` | Pooled shots, segment hits, mines, mortars and lightning, dodge detection |
| Wake | `combat/wake_system.gd` | Tiers, progress, grace and decay, reasons |
| World | `world/arena.gd`, `world/wind.gd`, `world/hazards.gd` | Reefs and bounds, wind shifts, currents, whirlpools, storms, mines, wrecks |
| Effects | `fx/fx_layer.gd` | Particles, rings, wake foam, stacking floating text |
| UI | `ui/*.gd` (10 scripts) | HUD, menus, shipyard, summary, settings, theme and auto-fit containers |

### Project layout

```
WavesBottle/
├─ project.godot
├─ icon.svg
├─ scenes/main.tscn
├─ shaders/ocean.gdshader
├─ docs/WavesBottle_GDD.md
└─ scripts/
   ├─ main.gd
   ├─ core/      game_data.gd, save_data.gd, controls.gd, sound.gd
   ├─ ship/      player_ship.gd, ship_stats.gd
   ├─ combat/    projectile_system.gd, wake_system.gd
   ├─ enemies/   enemy.gd, gunboat.gd, frigate.gd, fireship.gd, galleon.gd
   ├─ world/     arena.gd, wind.gd, hazards.gd
   ├─ fx/        fx_layer.gd
   ├─ run/       run.gd, spawn_director.gd
   └─ ui/        ui_kit.gd, fit_center.gd, hud.gd, main_menu.gd, hangar_screen.gd,
                 settings_screen.gd, pause_menu.gd, shipyard_screen.gd,
                 summary_screen.gd, credits_screen.gd
```

All balance values live in `scripts/core/game_data.gd` (`PLAYER`, `AMMO`, `ENEMIES`, `WAVES`, `HAZARDS`, `UPGRADES`, `LOADOUTS`, `PALETTES`, Wake tables).

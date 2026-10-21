# WAVESBOTTLE
## Game Design Document — v3.0: Long-Term Naval Action

**Document status:** Expanded design proposal  
**Genre:** Top-down naval action, fleet progression, mission-based campaign  
**Players:** Single-player first; co-op is a future stretch goal  
**Engine:** Godot 4.6 / GDScript  
**Target:** Windows PC, with web-ready architecture where practical  
**Core identity:** Momentum-based ship handling, tactical broadsides, modular weapons, expressive Wake combat, and long-term fleet mastery.

> **Design direction:** WavesBottle is no longer structured around a single ten-wave run. It is a long-form naval action game built around a 50-stage campaign, a growing fleet of distinct ships, modular weapon layouts, enemy factions, five major boss encounters, permanent progression, and replayable endgame challenges.

This document expands the existing WavesBottle design. Existing features such as momentum, port/starboard broadsides, wind, salvage, hazards, the Wake system, the Shipyard, and the neon ocean aesthetic remain the foundation. New values and content below are design targets, not final balance or implementation claims.

---

# 1. Executive Summary

## 1.1 High concept

Command a customizable warship across a dangerous ocean divided into five regions. Every ship has a different handling model and combat identity. Every weapon has a tactical purpose. Build a fleet, unlock modules, learn enemy behavior, defeat five regional bosses, and uncover the cause of the ocean's unstable Wake phenomenon.

## 1.2 What changes from v2.1

| Area | Current direction | New direction |
|---|---|---|
| Campaign | 10 waves and one final boss | 50 campaign stages across five regions |
| Player fleet | One core ship with a few loadout sidegrades | At least 10 playable ships with unique mechanics |
| Enemy roster | 3 regular enemies plus the Galleon | At least 15 regular/elite enemy types plus 5 bosses |
| Bosses | One Galleon boss | Five major bosses, one per region |
| Weapons | Three ammunition types and upgrade-based additions | Modular weapon stations, weapon families, utility modules, and ship-specific layouts |
| Customization | Run upgrades and a few permanent choices | Ship fitting, weapon placement, modules, cosmetics, saved builds |
| Progression | Mainly run score, unlocks, and records | Campaign progression, ship mastery, research, contracts, collection, endgame |
| Replayability | Repeat short runs | Mission modifiers, challenge contracts, alternate builds, elite variants, endgame operations |
| Narrative | Light premise | Environmental storytelling, faction identity, boss motives, and a mystery tied to the Wake |
| Long-term goals | High score and unlocks | Complete fleet, master ships, collect blueprints, optimize builds, clear advanced operations |

## 1.3 Design pillars

1. **Every ship changes how you play.** A new ship must offer a new decision-making pattern, not merely larger statistics.
2. **Customization changes tactics.** Weapon placement, weapon families, and modules should create meaningful trade-offs.
3. **Fifty stages must feel authored and varied.** Stage count alone is not content; each region introduces mechanics, enemy combinations, and a memorable boss.
4. **Progression should broaden options, not erase skill.** Better equipment adds strategic choices but does not make earlier combat systems irrelevant.
5. **Readable danger comes first.** Every powerful enemy attack has a clear tell, response window, and counterplay.
6. **Replayability comes from builds and encounters.** Random modifiers remix the experience, but important story and boss stages remain deliberately designed.
7. **The Wake remains WavesBottle's signature.** Skillful movement, risky positioning, clean dodges, and effective broadsides build the Wake and influence score and combat rewards.

---

# 2. Scope and Content Targets

These targets define the intended full game, not the minimum viable prototype.

| Content | Full-game target |
|---|---:|
| Campaign stages | 50 |
| Regions | 5 |
| Playable ships | At least 10 |
| Regular enemy types | At least 15 |
| Major bosses | 5 |
| Weapon families | 8–10 initially |
| Weapon/module slots | Varies by ship, generally 5–8 fitting points |
| Utility modules | 12+ |
| Passive systems | 12+ |
| Environmental hazard families | 8+ |
| Main mission archetypes | 6+ |
| Difficulty tiers | 4, unlocked progressively |
| Ship mastery levels | 10 per ship |
| Build save slots | 5 per ship, expandable later |
| Campaign completion | Around 12–20 hours for a first clear, depending on skill and optional content |
| Broad completion | Around 40–80+ hours, depending on collection and mastery goals |

**Scope note:** The time estimates are targets to validate through playtesting. Do not pad missions with empty travel time just to increase hours. Long-term engagement should come from variety, mastery, meaningful unlocks, and replayable challenges.

---

# 3. Game Structure

## 3.1 Main game loop

**Choose operation → Select ship and saved build → Enter stage → Fight and complete objectives → Collect salvage/intel/blueprints → Return to Harbor → Repair, refit, research, unlock → Select the next stage or an optional operation.**

## 3.2 Long-term loop

1. Advance through the campaign.
2. Unlock ships, weapon blueprints, modules, and new fitting options.
3. Learn enemy patterns and regional mechanics.
4. Experiment with different ship-and-weapon combinations.
5. Complete contracts and optional objectives for extra resources.
6. Improve ship mastery and unlock alternate ship perks.
7. Revisit earlier stages with new builds, higher difficulty, or challenge modifiers.
8. Unlock endgame operations after the main campaign.

## 3.3 Main screens

- **Main Menu:** Continue, Campaign, Operations, Hangar, Codex, Settings, Credits.
- **Campaign Map:** Five regional maps with stage nodes, mission details, rewards, and optional objectives.
- **Harbor:** Main hub for fleet management, ship fitting, research, contracts, repairs, and lore.
- **Hangar:** View, compare, unlock, test, and select ships.
- **Fitting Dock:** Place weapons and modules into valid slots; inspect arcs, weight, energy, and compatibility.
- **Research Board:** Spend research data to unlock equipment families and advanced variants.
- **Codex:** Enemies, bosses, regions, weapons, ship lore, discovered tactics.
- **Operations Board:** Repeatable missions, daily/weekly-style contracts if supported, and endgame activities.
- **Mission Debrief:** Results, rewards, performance grade, records, new unlocks, and optional objective status.
- **Sea Trials:** Practice movement, weapons, ship builds, enemy behavior, and hazards without affecting campaign records.

## 3.4 Mission types

| Mission type | Goal | Design purpose |
|---|---|---|
| Fleet Engagement | Defeat a set of enemy waves | Core combat test |
| Convoy Intercept | Stop enemy transports before they escape | Target priority and pursuit |
| Escort | Protect allied ships or a moving convoy | Threat management and route control |
| Survival | Survive escalating enemy groups for a set duration | Build endurance and positioning |
| Salvage Operation | Recover wrecks while enemy patrols interfere | Risk/reward and navigation |
| Stronghold Assault | Destroy defensive installations and support vessels | Multi-target planning |
| Elite Hunt | Track and defeat a named elite target | Focused combat challenge |
| Boss Encounter | Defeat a regional flagship with distinct phases | Major skill check |
| Navigation Trial | Reach checkpoints under time or hazard constraints | Movement mastery |
| Rescue/Extraction | Reach and secure a target, then survive an escape phase | Multi-part objective |

Not every mission type needs to appear in every region. Each region should introduce a small number of mission variations, then recombine them later.

---

# 4. Campaign: Five Regions, Fifty Stages

## 4.1 Structure

The campaign is divided into five regions of ten stages each. Each region introduces a new environmental identity, a new enemy faction emphasis, one major boss, and a permanent progression reward.

- **Stages 1–9:** Regional missions and escalating enemy combinations.
- **Stage 10:** Regional boss encounter.
- After a boss, the player returns to Harbor, receives a major unlock, and gains access to the next region.
- Earlier stages remain replayable for resources, mastery, optional objectives, and higher difficulty.
- A failed mission does not erase the entire campaign. The player keeps previously earned permanent unlocks, but mission rewards are only granted according to the mission's extraction/completion rules.

## 4.2 Region overview

| Region | Stages | Theme | Main pressure | Boss |
|---|---:|---|---|---|
| I. The Shattered Shoals | 1–10 | Open water, reefs, wrecks, tutorialized combat | Learning movement and broadside positioning | The Ironwake |
| II. The Rusted Reach | 11–20 | Industrial wreckage, mine lanes, armored patrols | Armor, mines, and defensive formations | Dreadnought Kharon |
| III. The Tempest Belt | 21–30 | Storm systems, currents, lightning, poor visibility | Navigation and environmental control | Storm Matriarch |
| IV. The Abyssal Trench | 31–40 | Deep ocean, bioluminescent hazards, stealth hunters | Ambushes, tracking, and target identification | The Leviathan Engine |
| V. The Resonant Expanse | 41–50 | Distorted water, Wake anomalies, elite mixed fleets | Combined mechanics and build mastery | The Resonant Sovereign |

## 4.3 Stage plan

The following is a content blueprint. It provides enough structure to plan production while leaving individual encounters open to iteration.

### Region I — The Shattered Shoals (Stages 1–10)

| Stage | Mission | Main encounter/design beat | New mechanic or reward |
|---:|---|---|---|
| 1 | First Wake | Small gunboat group in open water | Movement, aiming, port/starboard fire |
| 2 | Broken Formation | Gunboats attack from two directions | Target priority and turning |
| 3 | Reef Passage | Combat around safe navigation lanes | Reefs and collision risk |
| 4 | Wreckers | Enemy patrol guards salvage wrecks | Salvage under pressure |
| 5 | First Intercept | Stop fast couriers before escape | Timed objectives |
| 6 | The Broadside Lesson | Frigates establish firing lanes | Telegraphs and crossing the T |
| 7 | Burning Water | Fireships enter mixed combat | Area denial and blast baiting |
| 8 | The Lost Convoy | Protect a damaged allied vessel | Escort and threat prioritization |
| 9 | Shoal Breaker | Elite formation with varied enemy roles | Pre-boss test |
| 10 | **Boss: The Ironwake** | Armored flagship with broadside and ram attacks | Unlock Region II and first advanced fitting slot |

### Region II — The Rusted Reach (Stages 11–20)

| Stage | Mission | Main encounter/design beat | New mechanic or reward |
|---:|---|---|---|
| 11 | Scrapline | Armored patrols protect salvage points | Armor and weak points |
| 12 | Mine Ledger | Clear a route through minefields | Mine control |
| 13 | Foundry Escort | Protect a slow salvage barge | Escort pressure |
| 14 | Gunmetal Rain | Long-range artillery threatens marked zones | Mortar counterplay |
| 15 | Dead Man's Convoy | Ambush a heavily escorted convoy | Mixed target priorities |
| 16 | Break the Screen | Destroy shield-support vessels first | Support enemy behavior |
| 17 | The Rusted Maze | Fight around wreckage and narrow channels | Arena routing |
| 18 | Supply Denial | Destroy supply ships before reinforcements arrive | Reinforcement prevention |
| 19 | Kharon's Guard | Elite armored fleet | Armor-breaking build check |
| 20 | **Boss: Dreadnought Kharon** | Fortified battleship with rotating defenses | Unlock heavy weapon research |

### Region III — The Tempest Belt (Stages 21–30)

| Stage | Mission | Main encounter/design beat | New mechanic or reward |
|---:|---|---|---|
| 21 | Windward | Combat under strong crosswinds | Wind reading |
| 22 | Lightning Route | Navigate marked lightning zones | Telegraph timing |
| 23 | Current Divide | Enemies use currents to reposition | Environmental positioning |
| 24 | The Blind Squall | Reduced visibility with clear warning cues | Detection and silhouette reading |
| 25 | Storm Courier | Intercept a fast target through weather | Speed and route planning |
| 26 | Whirlpool Line | Multiple whirlpools divide the arena | Momentum mastery |
| 27 | The Weather Fleet | Enemies exploit wind and currents | Environmental enemy synergy |
| 28 | Eye of the Storm | Survive rotating attack lanes and weather changes | Multi-hazard control |
| 29 | Matriarch's Vanguard | Elite fleet with storm support | Pre-boss movement test |
| 30 | **Boss: Storm Matriarch** | A mobile boss that manipulates wind, lightning, and currents | Unlock advanced sail and rudder systems |

### Region IV — The Abyssal Trench (Stages 31–40)

| Stage | Mission | Main encounter/design beat | New mechanic or reward |
|---:|---|---|---|
| 31 | Below the Glow | Enter a deep-ocean zone with bioluminescent threats | New visual language and hazards |
| 32 | Silent Hunters | Stealth-oriented enemies reveal themselves before attacks | Detection and anticipation |
| 33 | Echo Buoys | Activate signal points while under attack | Multi-objective navigation |
| 34 | False Signal | Decoy targets and sensor interference | Target identification |
| 35 | The Drowned Archive | Recover data from guarded wrecks | Lore and research data |
| 36 | Pressure Line | Fight through narrow channels and moving hazards | Arena control |
| 37 | The Devourer's Trail | Track a powerful hunter through encounters | Pursuit and ambush |
| 38 | Dark Current | Limited visibility with readable projectile tells | Situational awareness |
| 39 | Engine Guardians | Elite mechanical fleet protects the trench core | Counter specialized enemies |
| 40 | **Boss: The Leviathan Engine** | Multi-part mechanical sea monster/engine with exposed components | Unlock advanced utility modules |

### Region V — The Resonant Expanse (Stages 41–50)

| Stage | Mission | Main encounter/design beat | New mechanic or reward |
|---:|---|---|---|
| 41 | Wake Distortion | Familiar enemies with altered timing and Wake interactions | Resonance hazards |
| 42 | Mirror Fleet | Enemies imitate or counter player positioning | Adaptability |
| 43 | Fractured Current | Currents shift during combat | Dynamic navigation |
| 44 | Resonant Convoy | Protect a convoy while anomaly waves disrupt combat | Objective and combat management |
| 45 | The Long Hunt | Multi-part elite hunt across linked arenas | Extended mission structure |
| 46 | Echoes of Kharon | Advanced armored fleet with support ships | Armor and support counterplay |
| 47 | Broken Weather | Storm, mine, and current systems overlap in fair combinations | Combined-mechanic mastery |
| 48 | The Last Signal | Destroy anomaly anchors to disable reinforcements | Priority objectives |
| 49 | Sovereign's Armada | Final elite fleet, several enemy roles, no cheap surprises | Comprehensive build test |
| 50 | **Boss: The Resonant Sovereign** | Multi-phase final battle built around Wake, positioning, and modular builds | Main campaign conclusion and endgame unlock |

## 4.4 Stage length and pacing

- Standard combat mission target: 5–9 minutes.
- Multi-objective mission target: 8–14 minutes.
- Regional boss target: 8–15 minutes on a first successful clear.
- Optional challenge missions may be shorter and repeatable.
- Long missions should contain distinct phases or objectives, not just larger enemy health pools.
- Use checkpoints only where the mission structure justifies them. Boss attempts should be learnable without requiring a long, repetitive prelude.

## 4.5 Mission grade

Each mission can award a grade based on:
- Objective completion.
- Hull remaining.
- Optional objectives.
- Time performance, where relevant.
- Wake performance and tactical actions.
- Allied units protected, if applicable.

The grade should primarily reward skill and objectives, not merely fast kills. Lower grades still grant core completion rewards so players do not become trapped by a score requirement.

---

# 5. Playable Fleet: At Least Ten Distinct Ships

## 5.1 Fleet design rules

Each ship must have:
- A distinct gameplay identity.
- At least one unique mechanic or meaningful system interaction.
- A clear strength and a clear weakness.
- A different ideal weapon layout.
- A reason to be selected even after later ships are unlocked.

Do not make each new ship strictly better than the previous one. New ships are alternative playstyles, not mandatory upgrades.

## 5.2 Ship roster

The following ten ships are the launch target.

| # | Ship | Class/role | Handling | Unique mechanic | Weakness |
|---:|---|---|---|---|---|
| 1 | **Wayfarer** | Balanced starter | Responsive, moderate inertia | Balanced port/starboard broadsides and flexible fitting | No extreme specialty |
| 2 | **Needlefin** | Interceptor | Very fast, tight turning | Builds a speed charge; releasing it creates a short evasive burst | Low hull and limited heavy weapon capacity |
| 3 | **Bulwark** | Heavy battleship | Slow acceleration, wide turn | Deploys a directional armor brace that reduces incoming frontal/side damage | Poor pursuit and repositioning |
| 4 | **Tempest** | Storm runner | Strong acceleration, sensitive to wind | Converts favorable wind and close dodges into temporary charge | Performance varies with weather |
| 5 | **Corsair** | Raider | Strong drift, agile broadside setup | Salvage bonus from risky close passes and disabling enemies | Fragile in prolonged stand-up fights |
| 6 | **Longshot** | Artillery vessel | Slow, stable, low drift | Charged long-range weapon gains accuracy when the ship holds a steady heading | Weak at close range and during rapid turns |
| 7 | **Manta** | Flanker | Excellent lateral control | A successful rear/side attack marks a target for bonus damage from the next volley | Requires precise positioning |
| 8 | **Warden** | Support/control | Moderate speed, reliable handling | Deploys a limited defensive buoy that intercepts or redirects some hostile shots | Lower direct burst damage |
| 9 | **Riptide** | Close-range brawler | Fast turning, high recoil interaction | Close-range volleys build pressure; a full pressure meter triggers a short knockback pulse | Inefficient at long range |
| 10 | **Echoforge** | Resonance specialist | Unusual acceleration and drift | Converts Wake tiers into temporary weapon effects; higher Wake rewards accurate volleys | Complex to master and vulnerable when Wake drops |

### Unlock philosophy

- Wayfarer is available at the start.
- Ships 2–4 are unlocked through early campaign milestones and shipyard contracts.
- Ships 5–7 are unlocked through regional progression, blueprints, and optional objectives.
- Ships 8–10 are unlocked through later regions, boss rewards, or specialized contracts.
- A ship should not require a random drop to become obtainable. Random rewards may accelerate progress, but deterministic unlock paths must exist.

## 5.3 Ship stats

Each ship uses a shared stat schema:
- Hull.
- Mass/inertia.
- Acceleration.
- Top speed.
- Reverse/braking.
- Turn rate.
- Lateral grip.
- Drift efficiency.
- Weapon station count.
- Weapon energy budget.
- Module capacity.
- Signature/visibility, if detection mechanics are used.
- Unique ability cooldown or charge rules.

Stats should be tuned around role. Avoid using hull and damage as the only differences.

## 5.4 Ship mastery

Each ship has ten mastery levels. XP is earned by completing missions and performing role-relevant actions.

Possible unlocks:
- Alternate passive choices.
- Cosmetic hull markings.
- Wake trail variants.
- Ship-specific challenge missions.
- Additional saved build slots.
- Lore entries and profile badges.

Mastery should not grant unlimited raw damage. If a mastery perk increases power, pair it with a meaningful trade-off or keep the increase modest.

---

# 6. Enemy Roster: At Least Fifteen Types

## 6.1 Enemy design principles

Every enemy needs:
1. A readable silhouette.
2. A recognizable role.
3. A clear attack tell.
4. At least one counterplay option.
5. A reason to prioritize or ignore it.
6. A distinct behavior, not just different health and damage.

The 15 types below are regular enemies. Bosses are counted separately.

## 6.2 Regular enemy roster

| # | Enemy | Role | Signature behavior | Counterplay |
|---:|---|---|---|---|
| 1 | **Skiff Gunboat** | Basic harasser | Fast, fires a narrow bow gun | Turn across its firing line and hit its side |
| 2 | **Broadside Frigate** | Standard duelist | Lines up side-mounted volleys | Leave telegraphed lanes; attack bow/stern |
| 3 | **Fireship** | Area denial | Pursues and detonates after a clear fuse | Destroy early or bait the blast away |
| 4 | **Mortar Monitor** | Long-range artillery | Marks predicted positions before shelling | Keep moving and change course after the marker locks |
| 5 | **Rammer** | Heavy melee threat | Telegraphs a high-speed charge | Bait the charge, then dodge laterally |
| 6 | **Mine Layer** | Arena control | Drops mines along likely routes | Eliminate it early or use its mines against the fleet |
| 7 | **Shield Tender** | Support | Projects a shield onto nearby allies | Break line of sight or destroy the tender first |
| 8 | **Repair Barge** | Support | Repairs damaged enemies if not interrupted | Focus it before it restores high-value targets |
| 9 | **Harpooner** | Disabler | Fires a harpoon that reduces turning until broken or expired | Dodge the line; use a defensive module or break tether range |
| 10 | **Longbow Sloop** | Sniper | Charges a precise long-range shot | Watch the laser/aim line and evade late |
| 11 | **Swarm Skater** | Swarm | Small fast craft attacks in groups and surrounds the player | Use area damage and avoid being boxed in |
| 12 | **Ghost Runner** | Ambusher | Briefly disappears into fog, then reappears with a telegraphed strike | Track its signal and avoid predictable routes |
| 13 | **Jammer Vessel** | Disruption | Temporarily interferes with minimap/target markers | Use visual tells and prioritize it when navigation matters |
| 14 | **Siege Barge** | Armored area control | Deploys a temporary gun platform or fortified firing lane | Attack during deployment/recovery or flank the platform |
| 15 | **Resonant Drone Carrier** | Summoner/support | Releases small drones that harass or mark the player | Destroy drones for breathing room or attack the carrier |

## 6.3 Enemy variants

Variants add depth without requiring every variant to be a wholly new AI:
- **Veteran:** Better timing and one additional behavior.
- **Armored:** Reduced damage from light weapons, weak point or armor-break counter.
- **Stormbound:** Uses weather to reposition or charge attacks.
- **Resonant:** Interacts with Wake tiers or anomaly hazards.
- **Commander:** Buffs a small group; has a clear command radius.
- **Elite named target:** A special silhouette/name, modified behavior, and guaranteed bounty reward.

Variants should alter decisions, not simply multiply health. Avoid filling every wave with elite enemies, which would make elites feel ordinary.

## 6.4 Enemy faction distribution

| Region | Common types | New types emphasized |
|---|---|---|
| Shattered Shoals | Skiff Gunboat, Frigate, Fireship, Rammer | Basic combat and pursuit |
| Rusted Reach | Mortar Monitor, Mine Layer, Shield Tender, Repair Barge, Siege Barge | Armor and formations |
| Tempest Belt | Harpooner, Longbow Sloop, Rammer, Mine Layer | Wind, interruption, long-range pressure |
| Abyssal Trench | Ghost Runner, Jammer Vessel, Swarm Skater, Drone Carrier | Detection and ambush |
| Resonant Expanse | Resonant Drone Carrier plus mixed roster | Synergies and advanced variants |

Not every enemy should appear in every stage. Introduce one new threat at a time, then teach the player to deal with combinations.

---

# 7. Five Major Bosses

Bosses should be distinct encounters with readable phases, unique arena interactions, and a clear weakness window. A boss must not be a regular enemy with a huge health bar.

## 7.1 Boss roster

| Boss | Region/stage | Identity | Main skill test | Major reward |
|---|---|---|---|---|
| **The Ironwake** | I / 10 | Armored broadside flagship | Reading volleys and exploiting recovery | Advanced fitting access |
| **Dreadnought Kharon** | II / 20 | Fortified artillery battleship | Breaking defenses and managing support units | Heavy weapon research |
| **Storm Matriarch** | III / 30 | Fast weather-controlling flagship | Steering, timing, and environmental positioning | Advanced sail/rudder modules |
| **The Leviathan Engine** | IV / 40 | Multi-part mechanical sea monster/engine | Target prioritization and moving weak points | Advanced utility modules |
| **The Resonant Sovereign** | V / 50 | Anomaly-powered final flagship | Combining all learned systems and adapting the build | Endgame operations and final story resolution |

## 7.2 Boss 1 — The Ironwake

- **Phase 1:** Slow approach and broadside volleys with large, readable firing lanes.
- **Phase 2:** Deploys armored plates on one side; the player must reposition to attack the exposed side.
- **Phase 3:** Performs a clearly telegraphed ram, then remains vulnerable during recovery.
- **Lesson:** A heavier ship cannot be defeated by circling randomly; positioning and recovery windows matter.

## 7.3 Boss 2 — Dreadnought Kharon

- **Phase 1:** Protected by frontal armor and two support vessels.
- **Phase 2:** Deploys mortar markers and temporary defensive turrets.
- **Phase 3:** Armor plates open after the player destroys or disables key support components.
- **Lesson:** Target priority, armor counterplay, and handling multiple attack types.

## 7.4 Boss 3 — Storm Matriarch

- **Phase 1:** Changes direction with the wind and fires fast volleys.
- **Phase 2:** Creates storm lanes and lightning markers, always leaving a navigable route.
- **Phase 3:** Pulls the fight toward a moving current; attacks become more dangerous but recovery windows are longer.
- **Lesson:** Environmental awareness and movement mastery.

## 7.5 Boss 4 — The Leviathan Engine

- **Phase 1:** Several external components attack independently.
- **Phase 2:** The core becomes vulnerable after a component sequence is interrupted.
- **Phase 3:** The arena changes shape or opens new lanes, with clear visual warnings.
- **Lesson:** Multi-target planning, reading the battlefield, and choosing the correct weapon range.

## 7.6 Boss 5 — The Resonant Sovereign

- **Phase 1:** Uses familiar attacks from earlier regions in new combinations.
- **Phase 2:** Creates Wake distortions that temporarily change the risk/reward of aggressive play.
- **Phase 3:** The player must destroy resonance anchors while avoiding focused fire.
- **Final phase:** A direct duel with narrow but fair damage windows. High Wake rewards skill, but the fight remains possible without maintaining the highest tier.
- **Lesson:** Mastery of movement, broadsides, build choices, target priority, and the Wake system.

## 7.7 Boss fairness rules

- Every major attack has a distinct tell, audio cue, and response window.
- Do not hide a lethal attack beneath screen effects.
- A boss phase change must be explicit and state-driven, not triggered by a fragile timer.
- Damage windows must be long enough for multiple ship archetypes to contribute.
- Bosses should react differently to weapon types without making a specific ship mandatory.
- Add a practice option for previously encountered bosses in Sea Trials after the first clear.

---

# 8. Weapon Customization and Fitting Dock

This is a core system, not a cosmetic menu. Players should be able to create different weapon layouts within the limits of each ship.

## 8.1 Weapon station types

Each ship has a layout made from compatible station types:

- **Port Broadside:** Fires toward the port side.
- **Starboard Broadside:** Fires toward the starboard side.
- **Bow Mount:** Fires forward.
- **Stern Mount:** Fires backward.
- **Turret Mount:** Rotates within a limited arc.
- **Utility Mount:** Deploys defensive or tactical devices.
- **Special Mount:** Accepts a ship-specific weapon or signature system.

Not every ship has every station. A heavy ship may have more broadside stations; an interceptor may have bow mounts and fewer heavy slots; an artillery ship may have a specialized long-range station.

## 8.2 Weapon families

Initial target: eight weapon families, each with a distinct tactical purpose.

| Weapon family | Role | Strength | Limitation |
|---|---|---|---|
| **Roundshot Cannon** | Reliable general damage | Balanced range and reload | No special effect |
| **Chainshot Launcher** | Control/disabling | Slows enemy movement or turn rate | Lower hull damage |
| **Canister Broadside** | Close-range burst | High damage against nearby targets | Poor range and wide spread |
| **Long-Bore Cannon** | Precision/range | Strong against exposed weak points | Slow reload and demanding aim |
| **Mortar Rack** | Area denial | Attacks marked ground/water zones | Delayed impact; poor against fast targets |
| **Harpoon Battery** | Tether/control | Restricts a target or pulls the player toward a heavy target, depending on variant | Requires a hit and has a cooldown |
| **Arc Projector** | Chain/energy damage | Can jump between clustered enemies | Lower single-target performance; energy cost |
| **Torpedo Tube** | Forward burst | High damage in a narrow lane | Limited ammunition or long reload; can be evaded |

Later expansion candidates: drone launcher, mine dispenser, resonant lance, smoke screen, and defensive flak.

## 8.3 Weapon properties

Each weapon definition should include:
- Damage and damage type.
- Effective range.
- Projectile speed.
- Reload/cooldown.
- Spread and accuracy behavior.
- Station compatibility.
- Energy/weight cost.
- Projectile behavior and status effect.
- Upgrade path.
- Visual/audio identity.
- Countered armor types or target roles, if applicable.

Do not add too many damage types at launch. Start with a small number of understandable interactions such as standard hull damage, armor penetration, and energy damage.

## 8.4 Layout customization rules

- Players select a weapon for each compatible station.
- The fitting screen previews firing arcs, effective range, reload, energy use, weight, and the ship's turn/speed changes.
- Weapon stations can be asymmetric. A player may choose long-range weapons on one side and close-range weapons on the other.
- Asymmetric builds must be viable, but the interface should warn players if one side becomes dramatically weaker.
- Weapons can be saved into named builds.
- The player can freely refit in Harbor; field refitting is restricted unless a mission provides a repair station.
- Some signature weapons are ship-specific, but every ship should still have multiple viable build paths.
- Avoid random slot compatibility. The fitting screen must clearly explain why a weapon can or cannot be equipped.

## 8.5 Trade-offs: mass, energy, and heat

Use two primary fitting constraints first:
- **Mass:** Heavy weapons and modules reduce acceleration, turning, and sometimes top speed.
- **Power budget:** Energy weapons and active utility modules consume the ship's available power capacity.

Optional later system:
- **Heat:** Sustained fire increases heat; overheating temporarily slows firing. Only add this if playtests show it creates meaningful decisions rather than busywork.

Do not launch with mass, power, heat, ammunition stock, crew, durability, and five other overlapping constraints all at once. Two clear constraints are better than many opaque ones.

## 8.6 Weapon modification tiers

- **Mk I:** Standard blueprint.
- **Mk II:** Improved performance with a modest cost or trade-off.
- **Mk III:** Specialized variant that changes a behavior, not only a number.

Example: Roundshot Cannon Mk III could become a heavy penetrator with slower reload, or a rapid-fire light cannon with reduced damage per hit. It should not simply be the objectively best version.

## 8.7 Build examples

| Build | Ship | Layout idea | Intended playstyle |
|---|---|---|---|
| Broadside Wall | Bulwark | Heavy cannons on both sides, armor module, repair utility | Durable sustained engagements |
| Needle Strike | Needlefin | Bow torpedoes, light side cannons, speed module | Hit-and-run attacks |
| Storm Dancer | Tempest | Balanced broadsides, arc projector, wind module | Movement and multi-target pressure |
| Trench Hunter | Manta | Long-bore side weapon, harpoon, detection utility | Flanking and weak-point attacks |
| Wake Orchestra | Echoforge | Resonant weapons on compatible stations, Wake support module | Skillful combo and timing |
| Salvage Raider | Corsair | Fast reload side cannons, salvage utility, drift module | Risk/reward close passes |

---

# 9. Utility Modules and Passive Systems

Weapons decide how a ship deals damage; modules shape how it survives and controls the battlefield.

## 9.1 Active utility modules

Initial target:
1. **Repair Drone:** Restores a limited amount of hull over time.
2. **Flak Burst:** Destroys or deflects nearby light projectiles.
3. **Smoke Screen:** Breaks some enemy targeting and creates a brief escape opportunity.
4. **Decoy Buoy:** Draws eligible enemy attacks away from the player.
5. **Boost Jets:** Short burst of acceleration with a cooldown.
6. **Mine Dispenser:** Drops a mine behind the ship.
7. **Shock Pulse:** Short-range disruption against drones and nearby light enemies.
8. **Target Scanner:** Highlights weak points and reveals hidden/marked threats for a short duration.

Each active module has a clear activation cue, cooldown, and UI indicator. Do not let modules silently activate unless the design specifically calls for automation.

## 9.2 Passive systems

Initial target:
- Reinforced Hull.
- Shock-Absorbing Frame.
- Precision Rudder.
- Deep Keel.
- Slipstream Keel.
- Storm Canvas.
- Crosswind Rigging.
- Quick-Load Crew.
- Long-Bore Stabilizers.
- Salvage Magnet.
- Wake Buffer.
- Emergency Bulkheads.
- Energy Capacitor.
- Reinforced Weapon Mounts.
- Anomaly Insulation.

Passive modules must compete for a limited number of slots or capacity. The player should not eventually equip every benefit at once.

## 9.3 Repair and maintenance

- Repairs are available at Harbor using earned currency.
- Mission repairs may be limited to pickups, objectives, or special stations.
- Damage should not persist indefinitely by default; persistent damage can be an optional high-difficulty rule.
- If persistent damage is added, it must be communicated clearly and must not turn ordinary failures into a long repair grind.

---

# 10. Permanent Progression and Economy

Long-term progression should give the player several parallel goals without forcing them to grind one repetitive activity.

## 10.1 Resource types

Start with three resources:

| Resource | Main source | Main use |
|---|---|---|
| **Salvage** | Standard missions, wrecks, enemy ships | Repairs, common modules, basic refits |
| **Research Data** | New enemies, optional objectives, elite hunts, boss discoveries | Unlock weapon blueprints and advanced modules |
| **Regional Intel** | Campaign objectives, hidden signal points, boss missions | Unlock stage branches, contracts, lore, and regional upgrades |

Avoid adding a premium currency to the single-player economy unless there is a clear, player-friendly reason. The game should not depend on real-money purchases.

## 10.2 Progression layers

1. **Campaign progress:** Opens new regions and mission branches.
2. **Fleet collection:** Unlocks playable ships.
3. **Ship mastery:** Rewards playing a ship well.
4. **Weapon research:** Unlocks new weapon families and variants.
5. **Module collection:** Expands defensive and tactical options.
6. **Harbor upgrades:** Adds useful services and fitting options.
7. **Codex completion:** Records discovered enemies, tactics, and lore.
8. **Challenge records:** Rewards performance and consistency.
9. **Cosmetics:** Hull paint, wake trails, banners, decals, and UI themes.

## 10.3 Harbor upgrades

Suggested permanent Harbor facilities:
- **Shipyard:** Unlock and maintain ships.
- **Weapons Lab:** Research weapon families and variants.
- **Navigation Room:** Reveal optional mission nodes and regional intel.
- **Signal Archive:** Store lore and enemy data.
- **Training Basin:** Unlock advanced Sea Trials and boss practice.
- **Salvage Exchange:** Convert surplus materials at a controlled rate.
- **Fleet Registry:** Compare ship mastery, saved builds, and records.

Facilities should unlock new capabilities rather than provide endless percentage bonuses.

## 10.4 Avoiding grind

- Every important ship and weapon has a deterministic unlock path.
- Repeating missions should remain useful through mastery, optional objectives, and challenge modifiers.
- Resource rewards should scale with mission length and risk, not only enemy count.
- A player should not need to replay a trivial early stage dozens of times to afford a basic module.
- Failed missions may award a smaller consolation reward for meaningful progress, but full rewards require mission completion.
- Use clear reward previews before launching a mission.

---

# 11. Long-Term Replayability and Endgame

The 50-stage campaign is the main journey, but the game should remain interesting after stage 50.

## 11.1 Operations

After completing a region, unlock a pool of repeatable operations:
- **Patrol Sweep:** Short mixed encounters.
- **Elite Bounty:** One named enemy with unique behavior.
- **Salvage Rush:** Recover several wrecks under pressure.
- **Convoy Breaker:** Stop a reinforced convoy.
- **Boss Rematch:** Replay a boss with selectable difficulty.
- **Navigation Trial:** Movement and route challenges.
- **Fleet Gauntlet:** Several encounters with limited repair opportunities.
- **Anomaly Operation:** High-risk missions with Wake-related modifiers.

## 11.2 Difficulty tiers

| Tier | Purpose | Changes |
|---|---|---|
| Standard | First clear and learning | Baseline enemy behavior and readable telegraphs |
| Veteran | Test build quality | More coordinated compositions, modest stat increases |
| Elite | Test mastery | Additional enemy variants, tighter attack windows, stronger objective pressure |
| Abyssal | Endgame challenge | Carefully designed combinations, stricter resource management, special boss modifiers |

Higher difficulty must change encounter decisions and enemy behavior, not only inflate health. Reward cosmetic prestige and specialized resources, not exclusive mandatory power.

## 11.3 Mission modifiers

Examples:
- Heavy crosswind.
- Limited visibility.
- Reinforced enemy armor.
- Increased salvage value with more elite enemies.
- No repair pickups.
- Faster enemy reloads with stronger telegraphs.
- Anomaly pulses that alter Wake decay.
- Escort hull is reduced but the reward is higher.
- Limited utility charges.

Use a small, tested number of modifiers per mission. Avoid stacking several modifiers that all reduce player control at once.

## 11.4 Seasonal/rotating content

The initial game should not depend on live-service infrastructure. If a rotation system is added later, it can be local or weekly challenge seeds with fixed rewards. The single-player game must remain complete if no online service exists.

---

# 12. Wake System: From Score Meter to Combat Identity

The Wake system remains central and should reward mastery without making one playstyle mandatory.

## 12.1 Wake gains

Retain and expand the current gain categories:
- Cannon hits and kills.
- Crossing the T.
- Close dodges.
- Drift passes.
- Salvaging wrecks.
- Clean mission objectives.
- Weak-point hits and interrupting enemy attacks.
- Boss phase transitions triggered by player actions.

## 12.2 Wake tiers

The existing six tiers—Still, Ripple, Swell, Surge, Tempest, Resonance—can remain. Their main effects are:
- Score multiplier.
- Wake trail and music intensity.
- Small tactical bonuses from selected ship/module interactions.
- Extra rewards for high-skill mission performance.

## 12.3 Preventing one optimal strategy

- A player should not be forced to dodge close to every projectile to remain viable.
- A long-range artillery build should have its own Wake-generating skill actions, such as weak-point hits or interrupting attacks.
- Damage should be a setback, not an automatic end to all progress.
- The final boss must be beatable at lower Wake tiers.
- Wake decay should be predictable and clearly shown.

## 12.4 Wake specializations

Optional modules or ship perks may specialize the Wake:
- **Steady Wake:** Slower decay and smaller peak bonus.
- **Predator Wake:** More reward for flanking and weak-point hits.
- **Storm Wake:** Gains from movement through weather and currents.
- **Resonant Wake:** More effects at high tiers, but a bigger loss when hit.

These are build choices. Do not let all Wake specializations stack together.

---

# 13. Regions, Hazards, and Environmental Variety

Keep the existing hazards—reefs, currents, mines, whirlpools, storms, and salvage wrecks—and add new ones only where they create a distinct decision.

## 13.1 Hazard roster

| Hazard | Primary effect | Counterplay |
|---|---|---|
| Reef | Collision and route restriction | Read the map and keep safe lanes |
| Current | Pushes ships along a direction | Use it to accelerate or route around it |
| Minefield | Delayed area damage | Shoot mines, lure enemies, or route around |
| Whirlpool | Pulls and rotates nearby ships | Escape toward the edge and avoid overcorrecting |
| Storm Front | Gusts and lightning markers | Read warnings and move between strike zones |
| Wreck Field | Blocks movement and may contain salvage | Navigate carefully and choose whether to stop |
| Resonance Rift | Periodic anomaly pulse | Time movement and avoid marked pulse zones |
| Pressure Vent | Creates a delayed vertical/area burst | Leave the marked region before eruption |

## 13.2 Environmental fairness

- Every damaging hazard must telegraph its active area and timing.
- Hazards should create choices, not randomly remove player control.
- Do not place unavoidable hazards on the player's spawn point.
- Boss arenas should be designed for their boss, not simply filled with every hazard.
- Avoid excessive visual noise. Projectiles, warning markers, and the player ship must remain readable.
- Difficulty should come from combinations the player can understand and respond to.

---

# 14. Story, Factions, and Worldbuilding

The original GDD emphasizes gameplay more than story. A long campaign can benefit from a light narrative framework without turning every mission into a cutscene.

## 14.1 Narrative premise

The ocean's Wake is more than a trail left by ships: it is an unstable resonance that appears to react to movement, weapon fire, and large-scale naval conflict. Five regions show increasingly abnormal behavior. The player is a captain operating from a remote Harbor, investigating the cause while recovering technology and confronting fleets that exploit the phenomenon.

This premise is intentionally modular. It can be renamed or rewritten without changing core gameplay.

## 14.2 Factions

- **Harbor Compact:** The player's home network; repairs, research, and mission contracts.
- **Rusted Reach Authority:** Industrial fleets that value armor, artillery, and territory.
- **Tempest Cartographers:** Navigators who study and weaponize storms.
- **Abyssal Foundry:** A hidden force behind the mechanical threats in the trench.
- **Resonant Fleet:** A faction altered by or aligned with the Wake phenomenon.

These names are placeholders and should be reviewed for originality before final release.

## 14.3 Story delivery

Prefer short, skippable delivery:
- Harbor conversations or brief radio transmissions.
- Mission briefing and debrief text.
- Boss introductions with a short visual moment.
- Codex entries unlocked by exploration.
- Environmental details in wrecks and arenas.

Do not interrupt every mission with long unskippable exposition. Gameplay remains the primary experience.

---

# 15. HUD, UX, Accessibility, and Feedback

## 15.1 In-mission HUD

Show only what the player needs during combat:
- Hull and current defensive state.
- Current ship and active ability cooldown.
- Port and starboard weapon status.
- Weapon ammo/energy if applicable.
- Wake tier, multiplier, progress, and decay state.
- Mission objective and progress.
- Boss health and phase when applicable.
- Wind/weather direction and major hazard warnings.
- Salvage pickups and off-screen threat indicators when useful.

Do not permanently fill the screen with every stat. Detailed fitting and weapon information belongs in the Harbor or pause screen.

## 15.2 Fitting Dock UX

The fitting screen should include:
- Ship silhouette with selectable weapon stations.
- Current weapon and available compatible weapons.
- Before/after stat comparison.
- Firing arc preview.
- Weight and power usage bars.
- Warnings for incompatible or inefficient configurations.
- Save build, rename build, duplicate build, and restore previous build.
- A clear confirmation step before discarding unsaved changes.

## 15.3 Accessibility

- Fully rebindable controls.
- Keyboard/mouse support first; controller support can be added as a planned milestone.
- Separate Master, Music, SFX, and UI volume.
- Screen shake and flash intensity controls.
- Reduced visual effects option.
- Distinct shape/icon as well as color for warnings and status.
- Adjustable text/UI scale.
- Pause during single-player missions.
- Optional aim assistance setting that does not replace positioning skill.
- Remappable toggle/hold options for drift and other sustained actions.
- Clear explanation of damage sources in the debrief.

---

# 16. Art and Audio Direction

## 16.1 Preserve the visual identity

Retain the deep neon ocean, cyan/pink player accents, orange enemy projectiles, red danger telegraphs, gold salvage, and bioluminescent Wake trails.

As the campaign advances, regions should add visual variation:
- Shoals: open water, reefs, wrecks, readable silhouettes.
- Rusted Reach: corroded metal, industrial lights, heavy silhouettes.
- Tempest Belt: rain streaks, cloud bands, lightning silhouettes.
- Abyssal Trench: dark water, bioluminescent forms, sonar-like pulses.
- Resonant Expanse: refracted lines, distorted wake trails, controlled anomaly effects.

Visual effects must never obscure the combat information needed to survive.

## 16.2 Ship readability

- Each ship needs a distinct silhouette at gameplay scale.
- Weapon stations should be visible enough to communicate likely attack directions.
- Enemy role should be identifiable before the first attack lands.
- Bosses need strong silhouette and phase-change cues.
- Cosmetic skins must not hide attack tells or make enemy factions difficult to identify.

## 16.3 Audio

Retain layered dynamic music and the relationship between Wake tier and musical intensity. Expand the sound library by region and weapon family:
- Weapon-specific firing and impact cues.
- Distinct boss phase stingers.
- Warning sounds that remain identifiable in a dense mix.
- Wind, current, storm, and anomaly ambience.
- Harbor music distinct from combat.
- Optional reduced-intensity audio mode for repeated operations.

---

# 17. Technical Architecture and Data-Driven Content

The existing Godot 4.6/GDScript approach remains appropriate for this game's scale. The expanded content makes data-driven definitions more important.

## 17.1 Architecture goals

- Separate gameplay simulation from presentation.
- Keep ship, enemy, weapon, module, mission, and boss definitions in data resources.
- Avoid one giant script containing all balance values.
- Use reusable behavior components for common enemy abilities.
- Use explicit state machines for bosses and mission phases.
- Pool projectiles and frequent visual effects where profiling shows a benefit.
- Keep saves versioned and migration-friendly.
- Build debug tools for spawning enemies, changing region modifiers, testing weapon arcs, and skipping mission phases.

## 17.2 Suggested content data

- `ShipDefinition`: stats, stations, passive, active ability, unlock requirement.
- `WeaponDefinition`: weapon family, damage, reload, range, compatibility, effects.
- `ModuleDefinition`: slot type, capacity cost, effect, cooldown.
- `EnemyDefinition`: stats, role, behavior components, rewards, region availability.
- `BossDefinition`: phase states, attacks, thresholds, rewards.
- `MissionDefinition`: objectives, spawn groups, hazards, modifiers, reward table.
- `RegionDefinition`: visuals, music, enemy pool, stage list, boss.
- `UnlockDefinition`: prerequisite, resource cost, reward.
- `ContractDefinition`: objective, target, reward, completion conditions.

## 17.3 Suggested project organization

```text
WavesBottle/
├── project.godot
├── scenes/
│   ├── main/
│   ├── harbor/
│   ├── combat/
│   ├── ships/
│   ├── enemies/
│   ├── bosses/
│   └── ui/
├── scripts/
│   ├── core/
│   ├── combat/
│   ├── ships/
│   ├── weapons/
│   ├── modules/
│   ├── enemies/
│   ├── bosses/
│   ├── missions/
│   ├── progression/
│   ├── save/
│   ├── world/
│   └── ui/
├── data/
│   ├── ships/
│   ├── weapons/
│   ├── modules/
│   ├── enemies/
│   ├── bosses/
│   ├── missions/
│   ├── regions/
│   └── unlocks/
└── docs/
    └── WavesBottle_GDD_v3.md
```

This is a recommended future structure, not a claim that these files already exist.

## 17.4 Save data

Persist:
- Campaign progress and completed stages.
- Unlocked ships, weapons, modules, and blueprints.
- Ship mastery.
- Saved builds.
- Harbor upgrades.
- Codex discoveries.
- Settings and controls.
- Records and challenge results.

Do not save transient mission state as permanent progress unless the mission explicitly supports checkpoints. Use a version field and migrations when the save schema changes.

## 17.5 Performance and testing

- Establish a target frame rate and minimum test hardware.
- Profile projectile counts, collision checks, particle counts, and AI updates.
- Use deterministic mission seeds where practical for reproducible bug reports.
- Add debug overlays for enemy state, telegraph timing, weapon arcs, and collision shapes.
- Test save migration and recovery from interrupted saves.
- Test every weapon station against every compatible weapon family.
- Test boss phases with multiple ship archetypes, not only the starter ship.

---

# 18. Balancing Principles

The numbers below are starting hypotheses. They must be adjusted through playtesting.

## 18.1 General combat principles

- A standard enemy should usually have one dominant threat and one clear counter.
- A player should have time to react to a new attack after its telegraph becomes visible.
- Large damage should be tied to a readable commitment or a preventable positioning mistake.
- Weapon types should trade off range, burst, control, and ease of use.
- Ship roles should be viable in the same mission without all having identical performance.
- Enemy health scaling should be restrained; add behavior and composition variety before adding large health multipliers.

## 18.2 Economy tuning

Track:
- Average salvage earned per mission.
- Average repair cost.
- Time to unlock the next ship.
- Time to research the next weapon family.
- Frequency of meaningful fitting changes.
- Percentage of missions where players cannot afford any useful upgrade.

If players routinely finish a mission without being able to make a meaningful decision, rewards or costs may be out of balance. If players can buy everything immediately, resource choices are not meaningful.

## 18.3 Telemetry for internal playtests

Even in a single-player game, internal telemetry or manual test logs can help:
- Mission completion rate by stage.
- Death/defeat location and source.
- Ship selection and completion rates.
- Weapon usage and damage share.
- Average Wake tier.
- Boss attempt count and phase reached.
- Time spent in fitting menus.
- Unused modules and weapons.
- Optional objective completion rates.

Collect only what is needed for balancing and debugging; do not require online telemetry for the game to function.

---

# 19. Development Roadmap

A 50-stage game with 10 ships, 15 enemies, 5 bosses, and modular weapons is a substantial project. Build the systems in a sequence that proves the core loop before multiplying content.

## Phase 1 — Combat foundation

**Goal:** Prove that one ship and a small encounter are fun.

- Player movement, inertia, drift, wind.
- Port/starboard weapon stations.
- Three baseline weapons.
- Three enemy types.
- Wake system and readable combat feedback.
- One small arena and one repeatable test mission.

**Exit criteria:** Combat is understandable, responsive, and enjoyable before progression is added.

## Phase 2 — Vertical slice

**Goal:** Build a representative 10–20 minute piece of the final game.

- Harbor and basic fitting screen.
- Three playable ships with distinct mechanics.
- Six enemy types.
- One complete region segment.
- One boss with multiple phases.
- Mission debrief, rewards, and save data.
- One complete weapon upgrade path.

**Exit criteria:** The game demonstrates the intended combination of combat, customization, mission structure, and progression.

## Phase 3 — Campaign framework

- Campaign map and mission definitions.
- Region data and stage unlocking.
- Mission objectives and optional objectives.
- Persistent resources and research.
- Three to five mission archetypes.
- Replayable completed stages.

**Exit criteria:** The campaign can support many stages without duplicating mission logic.

## Phase 4 — Fleet and weapon systems

- Expand to all 10 ship definitions.
- Complete fitting rules and saved builds.
- Add weapon families and utility modules.
- Add ship mastery.
- Balance asymmetric weapon layouts.
- Add Sea Trials support for all ships and weapons.

**Exit criteria:** Each ship has a distinct viable role and multiple meaningful build options.

## Phase 5 — Enemy and boss production

- Expand to 15 regular enemy types.
- Build reusable enemy behavior components.
- Complete five boss encounters.
- Add region-specific variants and hazards.
- Validate telegraphs, counterplay, and difficulty.

**Exit criteria:** Each region has its own identity and each boss tests different skills.

## Phase 6 — Content completion

- Complete 50 campaign stages.
- Add Harbor facilities, Codex, contracts, and optional missions.
- Finish art/audio variation by region.
- Add endgame operations and difficulty tiers.
- Complete tutorial and accessibility options.

**Exit criteria:** All core content is playable from a fresh save to the campaign ending.

## Phase 7 — Polish and release readiness

- Performance profiling.
- Balance and usability tests.
- Save migration and recovery tests.
- Input/device testing.
- Bug fixing and content pass.
- Final UI, audio, and visual consistency pass.

**Exit criteria:** No known progression blockers, no broken core builds, and all bosses are beatable using more than one viable ship/build.

---

# 20. Risks and Scope Control

## 20.1 Main risks

- **Content volume:** 50 stages and five bosses can exceed the available production capacity.
- **Ship balance:** Ten ships and many weapon combinations create a large testing matrix.
- **Feature creep:** Adding heat, crew management, crafting, trading, multiplayer, and procedural seas simultaneously could prevent completion.
- **Repetitive stages:** A large stage count can feel empty if missions only increase enemy health.
- **Overloaded UI:** Fitting systems can become confusing if too many stats are shown at once.
- **Progression grind:** Too many currencies or expensive unlocks can turn long-term play into repetition.

## 20.2 Scope rules

- Prioritize one polished vertical slice before creating all content.
- Implement data-driven systems before entering high-volume content production.
- Add one new major mechanic per region, then recombine existing mechanics.
- Every ship must change a decision, not merely a statistic.
- Every enemy must create a distinct response.
- Every boss must have a distinct encounter structure.
- If a feature does not improve combat decisions, build variety, world identity, or replayability, defer it.
- Do not add online multiplayer until the single-player game is stable and content-complete.

---

# 21. Additional Recommended Features

These ideas are optional additions intended to strengthen the long-term structure.

## 21.1 Ship test drive

Let players trial an unlocked or previewed ship in a controlled arena before spending a large amount of resources. This reduces the risk of unlocking a ship whose playstyle they dislike.

## 21.2 Saved build presets

Allow players to save named builds per ship, such as “Boss Killer,” “Salvage Runner,” or “Storm Build.” This makes experimentation easier and gives the player a reason to revisit the Harbor.

## 21.3 Enemy codex with tactical advice

After encountering an enemy, the Codex records its role, attacks, telegraphs, weaknesses, and recommended counterplay. This turns the 15+ enemy roster into a learning system rather than a collection list.

## 21.4 Optional objectives

Examples:
- Finish with a minimum Hull threshold.
- Destroy a support vessel first.
- Recover all marked wrecks.
- Prevent a convoy ship from escaping.
- Defeat an elite without using a repair.
- Finish with a specified Wake tier.

Optional objectives should reward mastery and resources, but should not block the main campaign.

## 21.5 Dynamic mission events

A small number of events can occur during a mission:
- A salvage wreck drifts into the arena.
- An enemy reinforcement group enters from a warned edge.
- A storm changes the safest route.
- An optional rescue signal appears.
- A support ship requests protection.

Events should be authored from a controlled pool and clearly communicated. Avoid random events that invalidate the current objective without warning.

## 21.6 Nemesis/elite bounty system

Occasionally, a named elite appears with a modified attack pattern and a guaranteed bounty. The player can pursue the bounty in a dedicated operation after the first encounter. This provides memorable recurring threats without requiring a full boss for every appearance.

## 21.7 New Game+ or campaign remixes

After completing Stage 50, unlock a remixed campaign:
- Different enemy compositions.
- Additional elite variants.
- Boss modifiers.
- New optional objectives.
- Higher difficulty and cosmetics.
- No mandatory story repetition if the player chooses a quick replay.

This is a better post-campaign extension than endlessly raising enemy health.

## 21.8 Photo/replay mode (later feature)

If feasible, let players review a short mission replay or capture a clean ship showcase. This supports the game's stylish Wake trails and customization without affecting balance. It is lower priority than combat and progression.

---

# 22. Definition of Done

The expanded design should not be considered complete merely because the content exists in the project. The full game is ready for release only when:

- All 50 stages can be completed in campaign order.
- All 10 ships are unlockable and have distinct, documented mechanics.
- At least 15 regular enemy types are implemented with readable counterplay.
- All five bosses have multiple phases and can be defeated by multiple viable builds.
- Weapon stations, compatibility, mass/power limits, and saved builds work reliably.
- Research and permanent progression persist correctly across sessions.
- The player can replay stages and access endgame operations.
- The save system supports versioning and safe migration.
- Core UI is readable at target resolutions and supports key accessibility settings.
- The game does not require online services for core progression.
- A new player can understand movement, broadsides, Wake, fitting, and mission objectives through play and UI feedback.
- No known bug prevents campaign progression or permanently blocks a major unlock.

---

# 23. Open Decisions

These should be answered during prototyping rather than assumed now.

1. Is WavesBottle strictly single-player at launch? **Recommendation:** yes; treat co-op as a later expansion.
2. Is the world map mission-based or freely navigable? **Recommendation:** mission-based campaign with a navigable strategic map, not a seamless open ocean.
3. Should hull damage persist between missions? **Recommendation:** no for the standard mode; consider an optional challenge modifier later.
4. Should weapons use ammunition stock? **Recommendation:** begin with cooldown/reload and limited special charges only; test before adding ammo logistics.
5. Should heat be a launch mechanic? **Recommendation:** not initially. Start with mass and power capacity.
6. Should missions use procedural generation? **Recommendation:** authored core encounters with seeded spawn variations, not fully procedural mission objectives.
7. How much story should be shown? **Recommendation:** brief mission briefings, boss moments, and optional Codex lore.
8. What is the intended price/release scope? This should be decided after the vertical slice and a realistic content production estimate.

---

# 24. Final Design Statement

**WavesBottle is a game about learning to command the sea, mastering a fleet of radically different ships, and building a weapon configuration that expresses the player's style.** The 50-stage campaign provides the journey; ships, weapons, modules, enemies, bosses, contracts, and endgame operations provide the reasons to keep playing.

The goal is not simply to make WavesBottle longer. The goal is to make every new stage teach, test, or reward something meaningful—and to make every new ship or weapon create a different way to approach the ocean.

*End of design proposal.*

---

# Appendix A. Implementation Status (Production Phase 5: full campaign, Regions I-V)

This appendix records what exists in the project today. Everything below is playable from a fresh save.

## A.1 Systems implemented

| Area | Status |
|---|---|
| Campaign framework | Region map with 5 regions, stage unlocking across regions, replayable stages, best grade per difficulty, optional objectives, par times |
| Region I - The Shattered Shoals | All 10 stages (1-1 to 1-10) with authored waves, briefings, debriefs and lore |
| Region II - The Rusted Reach | All 10 stages (2-1 to 2-10): Scrapline, Mine Ledger, Foundry Escort, Gunmetal Rain, Dead Man's Convoy, Break the Screen, The Rusted Maze, Supply Denial, Kharon's Guard, Dreadnought Kharon |
| Region III - The Tempest Belt | All 10 stages (3-1 to 3-10): Windward, Lightning Route, Current Divide, The Blind Squall, Storm Courier, Whirlpool Line, The Weather Fleet, Eye of the Storm, Matriarch's Vanguard, The Storm Matriarch; stage weather (crosswind, fog, faster wind shifts, permanent storms and whirlpools) |
| Region IV - The Abyssal Trench | All 10 stages (4-1 to 4-10): Below the Glow, Silent Hunters, Echo Buoys, False Signal, The Drowned Archive, Pressure Line, The Devourer's Trail, Dark Current, Engine Guardians, The Leviathan Engine |
| Region V - The Resonant Expanse | All 10 stages (5-1 to 5-10): Wake Distortion, Mirror Fleet, Fractured Current, Resonant Convoy, The Long Hunt, Echoes of Kharon, Broken Weather, The Last Signal, Sovereign's Armada, The Resonant Sovereign |
| New Game+ Remix | Unlocked by finishing Stage 5-10: replay any of the 50 stages with remixed fleets (extra ships and variants), 30% tougher bosses, an extra rift, a Wake V objective and x1.5 rewards; remix grades recorded separately |
| Mission types | Fleet Engagement, Salvage Operation, Convoy Intercept (with escorted couriers), Escort, Elite Engagement, Boss Encounter, Supply Strike, Signal Survey (echo buoys), Hunt (a named elite that dives and resurfaces), Anchor Strike (destroy reinforcement anchors), Mirror Fleet spawns, Survival, Elite Hunt, Navigation Trial, Gauntlet |
| Mission grade | S/A/B/C/D from objective, Hull, optional objectives, Wake, time and escort Hull |
| Optional objectives | Hull, Wake tier, time, no escape, ally Hull, crossings, interrupts, blast kills, no reef, all wrecks, weak-point hits, mine kills, close dodges, no mine damage, no lightning damage |
| Playable fleet | Wayfarer, Needlefin, Bulwark, Tempest, Corsair (Plunder Raid), Longshot (Focused Fire), Manta (Side Slip and flank marks), Warden (Ward Buoys), Riptide (Pressure Pulse, forward recoil), Echoforge (Wake-scaled weapons and Cascade) - all 10 ships, each with A/B perks and 10 mastery levels |
| Weapon stations | Port, starboard, bow, stern and a turret mount (Turret Ring research) that tracks the nearest enemy in a wide forward arc |
| Weapon families | All 8: Roundshot, Chainshot, Canister, Long-Bore, Harpoon, Torpedo, Mortar Rack, Arc Projector |
| Weapon marks | Mk II for every family; Mk III for every family: Penetrator and Rapid (Roundshot), Breaker Chain, Flechette, Railbore, Grapnel, Seeker, Cluster Rack, Overload |
| Fitting Dock | Per-station weapons including the turret, utility and passive slots, mass and power limits, asymmetry warning, arc preview, named builds (3-5 slots) |
| Utility modules | 11: Repair Drone, Boost Jets, Flak Burst, Decoy Buoy, Smoke Screen, Mine Dispenser, Shock Pulse, Target Scanner, Sonar Pulse, Depth Charges, Overdrive |
| Passive systems | 19 passives (including Lightning Rod, Vane Rudder, Storm Rigging, Phase Anchor) plus 4 exclusive Wake specializations |
| Enemies | Skiff Gunboat, Broadside Frigate, Fireship, Rammer, Courier, Mortar Monitor, Mine Layer, Shield Tender, Repair Barge, Siege Barge (with deployable Gun Platforms), Harpooner (tether), Longbow Sloop (sniper), Ghost Runner (cloaking ambusher), Jammer Vessel (sensor jamming, false contacts), Swarm Skater (packs), Resonant Drone Carrier (drones), Resonance Anchor, plus Galleon (Classic Run) |
| Variants | Elite, Veteran, Armored, Commander, Stormbound, Resonant; eleven named elites for Elite Bounty plus two hunt targets |
| Bosses | The Ironwake (3 phases), Dreadnought Kharon (3 phases: shield screen and bow armor, mortars and gun platforms, sealed plates opened by sinking support barges) The Storm Matriarch (3 phases: wind-running volleys and wind shifts, lightning lanes and storm cells, a moving current with long recovery windows) and The Leviathan Engine (multi-part: weapon pods guard a sealed core, a lit-conduit sequence ending in a pressure surge, a crawling advance with vent lines and overheat windows) and The Resonant Sovereign (4 phases: earlier bosses' attacks in new combinations, a Wake distortion field, three anchors under focused fire, a final duel that rewards high Wake) |
| Hazards | Reefs, currents (including moving currents), minefields, layer mines, whirlpools, storm fronts, salvage wrecks, wreck fields, lightning fields, lightning lanes, pressure vents, glow blooms (reveal cloaked ships), echo buoys, resonance rifts, shifting currents |
| Resources | Salvage, Research Data, Regional Intel |
| Research board | 51 deterministic research items gated by stage clears and facilities |
| Harbor facilities | Weapons Lab, Signal Archive, Training Basin, Navigation Room, Salvage Exchange, Fleet Registry |
| Contracts | 32 rotating Harbor Compact contracts with progress tracking and rewards |
| Operations | Classic Run, Patrol Sweep, Salvage Rush, Convoy Breaker, Holdout, Elite Bounty, Boss Rematch (any defeated regional boss), Navigation Trial, Fleet Gauntlet, Anomaly Operation; regional variants as regions open |
| Difficulty tiers | Standard, Veteran, Elite, Abyssal, unlocked progressively |
| Mission modifiers | Heavy Crosswind, Fog Bank, Reinforced Armor, Rich Salvage, Rapid Reload, Limited Charges, No Repairs, Wake Anomaly |
| Codex | Enemies, variants, bosses, ships, weapons, modules, regions, factions, twenty-one lore entries, tactics, records |
| Controls | Keyboard and mouse, full gamepad support in missions and menus (LB/RB switch tabs), separate keyboard and gamepad rebinding, on-screen prompts follow the active device |
| Accessibility | Rebinding, separate volumes, shake, reduced flashing, effect density, drift toggle, gentle aim assistance, menu text scale |
| Save data | Version 2 with automatic migration from version 1 and atomic writes |
| Data-driven content | `data/ships.gd`, `weapons.gd`, `modules.gd`, `enemies.gd`, `missions.gd`, `progression.gd`, `world.gd` |

## A.2 Default gamepad layout

| Action | Gamepad |
|---|---|
| Throttle up / down | RT / LT or left stick up / down |
| Turn | Left stick or D-pad left / right |
| Drift | B |
| Fire port / starboard | LB / RB |
| Fire bow / stern | Y / X |
| Fire turret | Right stick click or right stick up |
| Ship ability | A |
| Utility modules 1 / 2 | D-pad up / down |
| Pause | Start |

## A.3 Possible future additions

- Ship-specific special mounts.
- Photo/replay mode.
- Optional co-op.

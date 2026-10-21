extends RefCounted

const ORDER := ["gunboat", "frigate", "fireship", "rammer", "courier", "mortar_monitor", "mine_layer", "shield_tender", "repair_barge", "siege_barge", "siege_platform", "harpooner", "longbow_sloop", "ghost_runner", "jammer", "swarm_skater", "leviathan_pod", "resonant_carrier", "resonant_drone", "resonance_anchor", "galleon", "ironwake", "kharon", "matriarch", "leviathan", "sovereign"]

const BOSS_KINDS := ["galleon", "ironwake", "kharon", "matriarch", "leviathan", "sovereign"]

const REGION_TWO := ["mortar_monitor", "mine_layer", "shield_tender", "repair_barge", "siege_barge"]

const REGION_THREE := ["harpooner", "longbow_sloop"]

const REGION_FOUR := ["ghost_runner", "jammer", "swarm_skater"]

const REGION_FIVE := ["resonant_carrier", "resonance_anchor"]

const ENEMIES := {
	"gunboat": {"name": "Skiff Gunboat", "role": "Basic harasser", "hull": 20.0, "speed": 210.0, "accel": 260.0, "turn": 3.0, "radius": 14.0, "damage": 6.0, "range": 380.0, "cooldown": 2.4, "salvage": 3, "score": 100, "contact": 6.0, "interrupt": 8.0,
		"intro": "Fast swarm boat with a bow gun. Strike from the side or stern.",
		"attacks": "Single bow shot, 6 damage, range 380.", "telegraph": "Flashing red bow line for 0.4 s.", "counter": "Turn across its firing line and hit its side. A solid hit during the tell cancels the shot."},
	"frigate": {"name": "Broadside Frigate", "role": "Standard duelist", "hull": 60.0, "speed": 140.0, "accel": 120.0, "turn": 1.3, "radius": 22.0, "damage": 9.0, "range": 430.0, "cooldown": 3.6, "windup": 0.95, "salvage": 8, "score": 300, "contact": 10.0, "interrupt": 18.0,
		"intro": "Broadside duelist. Red lanes appear before it fires - leave the lane.",
		"attacks": "Three-gun broadside, 9 damage each, range 430.", "telegraph": "Red fire lanes for 0.95 s.", "counter": "Leave the lanes, attack from the bow or stern, or break the windup with 18+ damage."},
	"fireship": {"name": "Fireship", "role": "Area denial", "hull": 24.0, "speed": 185.0, "accel": 200.0, "turn": 2.2, "radius": 16.0, "damage": 26.0, "blast": 110.0, "fuse": 1.15, "salvage": 5, "score": 200, "contact": 0.0,
		"intro": "Explodes when close. Watch the fuse ring - sink it early or outrun the blast.",
		"attacks": "26 damage blast, radius 110.", "telegraph": "Fuse ring and ticking for 1.15 s.", "counter": "Sink it early - its blast then only hurts its own fleet. Bait it into enemy groups."},
	"rammer": {"name": "Rammer", "role": "Heavy melee threat", "hull": 70.0, "speed": 150.0, "accel": 160.0, "turn": 1.6, "radius": 20.0, "damage": 24.0, "charge_speed": 430.0, "windup": 1.0, "cooldown": 4.5, "salvage": 7, "score": 280, "contact": 10.0, "interrupt": 20.0,
		"intro": "Charges in a straight line after a red lane appears. Dodge sideways, then punish the recovery.",
		"attacks": "Straight high-speed charge, 24 damage on impact.", "telegraph": "Red charge lane and engine glow for 1 s.", "counter": "Bait the charge, dodge laterally, then hit it while it recovers. 20+ damage during the tell stalls it."},
	"courier": {"name": "Courier", "role": "Fleeing transport", "hull": 45.0, "speed": 165.0, "accel": 140.0, "turn": 1.8, "radius": 16.0, "damage": 0.0, "salvage": 10, "score": 250, "contact": 4.0,
		"intro": "Unarmed transports racing for the edge of the map. Stop them before they escape.",
		"attacks": "None.", "telegraph": "Gold escape marker on its destination.", "counter": "Cut it off, use chain shot or harpoons to slow it down."},
	"mortar_monitor": {"name": "Mortar Monitor", "role": "Long-range artillery", "hull": 70.0, "speed": 95.0, "accel": 90.0, "turn": 1.2, "radius": 22.0, "damage": 14.0, "blast": 65.0, "range": 760.0, "min_range": 260.0, "cooldown": 5.0, "windup": 1.2, "salvage": 8, "score": 320, "contact": 8.0, "interrupt": 22.0,
		"intro": "Lobs shells at where you are going. Change course once the rings lock, then close in - it cannot fire up close.",
		"attacks": "Three-shell barrage, 14 damage each, aimed ahead of your course.", "telegraph": "Glowing tubes and a ranging bracket for 1.2 s, then red target rings.", "counter": "Turn hard after the rings appear, or close inside 260 range where it cannot fire. 22+ damage during the tell cancels the barrage."},
	"mine_layer": {"name": "Mine Layer", "role": "Arena control", "hull": 50.0, "speed": 150.0, "accel": 140.0, "turn": 1.8, "radius": 18.0, "damage": 0.0, "cooldown": 2.6, "max_mines": 8, "salvage": 6, "score": 240, "contact": 6.0,
		"intro": "Seeds mines across your route. Sink it early - or shoot its mines when its friends drift close.",
		"attacks": "Drops a mine behind it every few seconds, cutting across your course.", "telegraph": "Mines blink as they arm; the layer turns across your bow before dropping.", "counter": "Never tail it. Shoot its mines to detonate them near other enemies."},
	"shield_tender": {"name": "Shield Tender", "role": "Support", "hull": 55.0, "speed": 140.0, "accel": 120.0, "turn": 1.8, "radius": 19.0, "damage": 0.0, "shield_range": 230.0, "shield": 0.6, "salvage": 7, "score": 300, "contact": 6.0,
		"intro": "Projects a shield that cuts damage to nearby ships by 60%. Sink the tender first.",
		"attacks": "None. Shields every ally within 230 px.", "telegraph": "Blue links and bubbles around shielded ships.", "counter": "Flank around the screen and sink the tender, or drag its escorts out of range."},
	"repair_barge": {"name": "Repair Barge", "role": "Support", "hull": 90.0, "speed": 90.0, "accel": 80.0, "turn": 1.0, "radius": 24.0, "damage": 0.0, "heal": 14.0, "heal_range": 210.0, "channel": 4.5, "cooldown": 2.5, "salvage": 9, "score": 320, "contact": 8.0, "interrupt": 20.0,
		"intro": "Repairs damaged ships with a green beam. Hit it hard while it channels to cut the beam.",
		"attacks": "None. Heals one damaged ally 14 Hull per second.", "telegraph": "A green beam to its patient.", "counter": "Focus it before it restores a heavy target. 20+ damage during the beam cuts it."},
	"siege_barge": {"name": "Siege Barge", "role": "Armored area control", "hull": 140.0, "speed": 70.0, "accel": 60.0, "turn": 0.8, "radius": 28.0, "damage": 0.0, "range": 520.0, "cooldown": 9.0, "windup": 2.2, "salvage": 12, "score": 420, "contact": 12.0,
		"intro": "An armored barge that deploys gun platforms. Its plating opens while it deploys - strike then, or flank the platforms.",
		"attacks": "Deploys up to two gun platforms that fire paired shots.", "telegraph": "A pulsing deploy ring beside the barge for 2.2 s.", "counter": "Hit it while it deploys (x1.5 damage), use armor-piercing weapons, or sink the platforms from their blind side."},
	"siege_platform": {"name": "Gun Platform", "role": "Deployed turret", "hull": 45.0, "speed": 0.0, "accel": 0.0, "turn": 2.5, "radius": 18.0, "damage": 8.0, "range": 520.0, "cooldown": 2.6, "windup": 0.6, "life": 22.0, "salvage": 2, "score": 80, "contact": 6.0, "interrupt": 10.0,
		"intro": "A stationary gun platform. It cannot turn its guns quickly - circle it.",
		"attacks": "Two shots, 8 damage each, range 520.", "telegraph": "A red aim lane for 0.6 s.", "counter": "Keep moving across its aim and sink it; it scuttles itself after 22 s."},
	"harpooner": {"name": "Harpooner", "role": "Disabler", "hull": 55.0, "speed": 175.0, "accel": 170.0, "turn": 2.2, "radius": 18.0, "damage": 5.0, "range": 430.0, "cooldown": 6.0, "windup": 0.9, "tether": 4.0, "break_range": 560.0, "salvage": 7, "score": 280, "contact": 6.0, "interrupt": 14.0,
		"intro": "Fires a tethered harpoon that halves your turning. Sail away from it to snap the line.",
		"attacks": "Harpoon line, 5 damage, tethers you for 4 s and halves your turning.", "telegraph": "A green aim line for 0.9 s before the harpoon flies.", "counter": "Turn off the aim line, or snap the tether by opening 560 px of distance. Flak Burst and Shock Pulse cut the line."},
	"longbow_sloop": {"name": "Longbow Sloop", "role": "Sniper", "hull": 45.0, "speed": 150.0, "accel": 130.0, "turn": 1.9, "radius": 17.0, "damage": 20.0, "range": 950.0, "cooldown": 5.5, "windup": 1.8, "lock": 0.45, "shot_speed": 1150.0, "salvage": 8, "score": 300, "contact": 5.0, "interrupt": 12.0,
		"intro": "A sniper. Its red aim line tracks you, then locks - turn hard the moment it locks.",
		"attacks": "One fast long-range shot, 20 damage, range 950.", "telegraph": "A tracking red line for 1.8 s that turns solid when it locks.", "counter": "Change course after the line locks, or close in fast - it is fragile and slow to turn."},
	"ghost_runner": {"name": "Ghost Runner", "role": "Ambusher", "hull": 60.0, "speed": 210.0, "accel": 220.0, "turn": 2.6, "radius": 17.0, "damage": 7.0, "range": 320.0, "cooldown": 5.0, "windup": 0.9, "cloak": 4.0, "salvage": 9, "score": 340, "contact": 8.0, "interrupt": 14.0,
		"intro": "Vanishes into the dark and reappears behind you. Watch for its ping - and for the glow that gives it away.",
		"attacks": "Decloaks with a 0.9 s tell, then fires a close three-shot spread, 7 damage each.", "telegraph": "A sonar ping every 1.5 s while hidden; a bright ripple and red fan before it strikes.", "counter": "Keep moving, never sail predictable lines, and hit it during the 3 s it stays visible. Glow blooms, Target Scanner and Sonar Pulse reveal it."},
	"jammer": {"name": "Jammer Vessel", "role": "Disruption", "hull": 50.0, "speed": 160.0, "accel": 150.0, "turn": 2.0, "radius": 18.0, "damage": 0.0, "jam_range": 900.0, "decoy_cd": 7.0, "salvage": 8, "score": 300, "contact": 6.0,
		"intro": "Scrambles your sensors: edge markers lie, the turret loses lock, false contacts appear. Sink it first.",
		"attacks": "None. Jams sensors within 900 px and seeds false contacts.", "telegraph": "Static on the HUD and a pulsing violet ring.", "counter": "Trust your eyes, not the markers, and hunt it down. Sonar Pulse burns through the jamming."},
	"swarm_skater": {"name": "Swarm Skater", "role": "Swarm", "hull": 12.0, "speed": 300.0, "accel": 380.0, "turn": 4.2, "radius": 10.0, "damage": 3.0, "range": 260.0, "cooldown": 1.6, "salvage": 2, "score": 60, "contact": 3.0,
		"intro": "Tiny, fast craft that hunt in packs and try to surround you. Use area weapons.",
		"attacks": "Rapid bow darts, 3 damage, from every side.", "telegraph": "A pack tightening its circle around you.", "counter": "Canister, Arc Projectors, Shock Pulse and mines tear through packs. Do not let them box you in."},
	"leviathan_pod": {"name": "Engine Pod", "role": "Boss component", "hull": 170.0, "speed": 0.0, "accel": 0.0, "turn": 3.0, "radius": 20.0, "damage": 9.0, "range": 560.0, "cooldown": 3.2, "windup": 0.8, "salvage": 6, "score": 400, "contact": 8.0, "interrupt": 18.0,
		"intro": "A weapon pod bolted to the Leviathan Engine.",
		"attacks": "Gun pods fire bursts, launcher pods lob shells.", "telegraph": "Red lanes and target rings.", "counter": "Destroy every pod to open the core."},
	"resonant_carrier": {"name": "Resonant Drone Carrier", "role": "Summoner / support", "hull": 110.0, "speed": 110.0, "accel": 100.0, "turn": 1.2, "radius": 26.0, "damage": 0.0, "cooldown": 8.0, "max_drones": 6, "salvage": 12, "score": 420, "contact": 10.0,
		"intro": "Launches resonant drones that swarm and snipe at you. Clear the drones for breathing room, or go for the carrier.",
		"attacks": "Launches two drones every 8 s, up to six at once.", "telegraph": "Its launch bay glows pink before drones fly.", "counter": "Area weapons wipe drones; armor-piercing fire and flanking runs sink the carrier."},
	"resonant_drone": {"name": "Resonant Drone", "role": "Carrier drone", "hull": 8.0, "speed": 330.0, "accel": 500.0, "turn": 5.0, "radius": 8.0, "damage": 3.0, "range": 300.0, "cooldown": 2.2, "salvage": 1, "score": 30, "contact": 2.0,
		"intro": "A small resonant drone.",
		"attacks": "Tiny bolts, 3 damage.", "telegraph": "A pink glow before each bolt.", "counter": "Any area weapon or a single hit."},
	"resonance_anchor": {"name": "Resonance Anchor", "role": "Anomaly anchor", "hull": 220.0, "speed": 0.0, "accel": 0.0, "turn": 0.5, "radius": 28.0, "damage": 0.0, "cooldown": 16.0, "salvage": 14, "score": 500, "contact": 10.0,
		"intro": "A floating anomaly anchor. It pulls reinforcements through the Wake until it is destroyed.",
		"attacks": "Summons reinforcements every 16 s, and shields the Sovereign.", "telegraph": "Its rings tighten and flare before a summon.", "counter": "Destroy it - the reinforcements stop."},
	"galleon": {"name": "Galleon", "role": "Classic flagship", "hull": 800.0, "speed": 75.0, "accel": 50.0, "turn": 0.45, "radius": 50.0, "damage": 12.0, "range": 560.0, "salvage": 60, "score": 5000, "contact": 16.0,
		"intro": "Flagship. Every salvo is telegraphed. Strike hard while it is EXPOSED.",
		"attacks": "Seven-gun broadsides, mortar barrages, escorts at half Hull.", "telegraph": "Red fan lanes, mortar target rings.", "counter": "Stay off its sides, keep moving through mortar fields, punish EXPOSED windows."},
	"ironwake": {"name": "The Ironwake", "role": "Armored broadside flagship", "hull": 1100.0, "speed": 70.0, "accel": 50.0, "turn": 0.5, "radius": 46.0, "damage": 12.0, "range": 560.0, "salvage": 90, "score": 8000, "contact": 18.0, "ram_damage": 30.0, "ram_speed": 340.0,
		"intro": "The Shoals' iron flagship. Read its lanes, flank its plating, and dodge the ram.",
		"attacks": "Wide broadsides, armored plating on one side, a full-speed ram.", "telegraph": "Red fan lanes, glowing plates before they shift, a long red ram lane.", "counter": "Hit the unplated side, sidestep the ram and strike during the long recovery."},
	"kharon": {"name": "Dreadnought Kharon", "role": "Fortified artillery battleship", "hull": 1600.0, "speed": 60.0, "accel": 40.0, "turn": 0.42, "radius": 54.0, "damage": 13.0, "bow_damage": 22.0, "range": 600.0, "salvage": 120, "score": 10000, "contact": 20.0,
		"intro": "The Rusted Reach's fortress. Break its screen, stay off its bow, and tear out its support.",
		"attacks": "Bow battery salvos, seven-gun broadsides, mortar barrages and deployed gun platforms.", "telegraph": "A wide bow lane, red fan lanes, mortar target rings and pulsing deploy rings.", "counter": "Sink the shield tenders, avoid the bow, and destroy the support barges to open its plates."},
	"matriarch": {"name": "The Storm Matriarch", "role": "Weather-controlling flagship", "hull": 1500.0, "speed": 135.0, "accel": 90.0, "turn": 0.9, "radius": 44.0, "damage": 10.0, "range": 520.0, "salvage": 140, "score": 12000, "contact": 16.0, "strike_damage": 14.0,
		"intro": "The Tempest Belt's flagship. She sails with the wind, calls lightning and drags the sea with her.",
		"attacks": "Fast broadside volleys, wind shifts, lightning lanes, storm cells and a moving current.", "telegraph": "Short red fan lanes, a wind-shift warning, lightning lane markers that always leave one open route.", "counter": "Keep to the open lane, sail with the wind she calls, and punish the long recovery after each storm."},
	"leviathan": {"name": "The Leviathan Engine", "role": "Multi-part mechanical engine", "hull": 2000.0, "speed": 45.0, "accel": 30.0, "turn": 0.35, "radius": 70.0, "damage": 12.0, "range": 600.0, "salvage": 160, "score": 15000, "contact": 24.0,
		"intro": "Something enormous is running in the dark. Its weapon pods guard a sealed core - tear them off.",
		"attacks": "Gun and launcher pods, a conduit sequence that ends in a pressure surge, vent lines and a slow crushing advance.", "telegraph": "Pod lanes and rings, lit conduits, pulsing vent markers.", "counter": "Destroy the pods, then each lit conduit in turn, and strike the core while it is open."},
	"sovereign": {"name": "The Resonant Sovereign", "role": "Anomaly-powered final flagship", "hull": 2600.0, "speed": 90.0, "accel": 70.0, "turn": 0.7, "radius": 56.0, "damage": 13.0, "bow_damage": 20.0, "range": 600.0, "salvage": 220, "score": 25000, "contact": 22.0,
		"intro": "The source of the singing. It fights with everything the sea has taught you.",
		"attacks": "Broadsides, bow salvos, lightning lanes, vent lines and mortar rings in new combinations; a Wake distortion field; focused fire from three anchors; a final duel.", "telegraph": "Every attack keeps the tell you learned in its home region.", "counter": "Read each tell as you did before, break the anchors, and strike in the windows after each volley. A high Wake hits harder in the duel."},
}

const VARIANTS := {
	"elite": {"name": "Elite", "desc": "Hull x1.6, faster, gold ring. Guaranteed pickup.", "color": Color(1.0, 0.85, 0.3)},
	"veteran": {"name": "Veteran", "desc": "Fires 25% more often and leads its shots.", "color": Color(0.9, 0.6, 1.0)},
	"armored": {"name": "Armored", "desc": "Takes 40% less damage from weapons that do not pierce armor.", "color": Color(0.75, 0.8, 0.85)},
	"resonant": {"name": "Resonant", "desc": "Grows faster and fiercer as your Wake tier rises, but sinking one feeds your Wake.", "color": Color(1.0, 0.45, 0.85)},
	"commander": {"name": "Commander", "desc": "Allies within 280 px reload 30% faster and move 15% faster.", "color": Color(1.0, 0.6, 0.3)},
	"stormbound": {"name": "Stormbound", "desc": "Ignores currents and storm gusts, moves and reloads faster in rough weather, and calls a lightning strike where it sinks.", "color": Color(0.6, 0.8, 1.0)},
}

const NAMED := {
	"grey_widow": {"name": "The Grey Widow", "kind": "frigate", "variants": ["elite", "veteran", "armored"], "hull_mult": 2.2, "bounty": {"salvage": 120, "research": 15}, "desc": "A plated frigate captain who never misses a lane."},
	"saltjaw": {"name": "Saltjaw", "kind": "rammer", "variants": ["elite", "veteran"], "hull_mult": 2.4, "bounty": {"salvage": 120, "research": 15}, "desc": "A rammer that has sunk forty hulls and kept every figurehead."},
	"cinder_bell": {"name": "Cinder Bell", "kind": "frigate", "variants": ["elite", "commander"], "hull_mult": 2.0, "bounty": {"salvage": 110, "research": 15}, "desc": "Commands a fireship pack from a bell-tower frigate."},
	"iron_tithe": {"name": "The Iron Tithe", "kind": "siege_barge", "variants": ["elite", "commander"], "hull_mult": 1.8, "bounty": {"salvage": 140, "research": 18}, "desc": "A toll-collector barge that fortifies every channel it enters.", "region": 2},
	"devourer": {"name": "The Devourer", "kind": "ghost_runner", "variants": ["elite", "veteran"], "hull_mult": 6.0, "bounty": {"salvage": 120, "research": 20}, "desc": "A Foundry hunter that dives when wounded and surfaces somewhere else.", "region": 4, "hunt_only": true},
	"long_shadow": {"name": "The Long Shadow", "kind": "frigate", "variants": ["elite", "veteran", "resonant"], "hull_mult": 6.0, "bounty": {"salvage": 150, "research": 24}, "desc": "A resonant frigate that has outrun every fleet sent after it.", "region": 5, "hunt_only": true},
	"mirror_captain": {"name": "The Mirror Captain", "kind": "frigate", "variants": ["elite", "resonant", "commander"], "hull_mult": 2.6, "bounty": {"salvage": 190, "research": 26}, "desc": "Turns when you turn. Fires when you fire.", "region": 5},
	"hymn_carrier": {"name": "The Hymn Carrier", "kind": "resonant_carrier", "variants": ["elite", "resonant"], "hull_mult": 2.4, "bounty": {"salvage": 190, "research": 26}, "desc": "Its drones sing in harmony. The harmony is a targeting system.", "region": 5},
	"pale_lantern": {"name": "The Pale Lantern", "kind": "ghost_runner", "variants": ["elite", "veteran"], "hull_mult": 2.6, "bounty": {"salvage": 170, "research": 22}, "desc": "Fishermen say it hangs a light under the water to lure ships in.", "region": 4},
	"static_saint": {"name": "The Static Saint", "kind": "jammer", "variants": ["elite", "commander"], "hull_mult": 3.0, "bounty": {"salvage": 160, "research": 22}, "desc": "Preaches through every speaker in range. Nobody has heard it say anything sane.", "region": 4},
	"hookjaw": {"name": "Hookjaw", "kind": "harpooner", "variants": ["elite", "stormbound"], "hull_mult": 2.4, "bounty": {"salvage": 150, "research": 18}, "desc": "Has never lost a ship off the end of its line.", "region": 3},
	"squall_choir": {"name": "The Squall Choir", "kind": "longbow_sloop", "variants": ["elite", "veteran", "stormbound"], "hull_mult": 2.2, "bounty": {"salvage": 150, "research": 20}, "desc": "A sniper sloop that only fires when the thunder covers the shot.", "region": 3},
	"the_ledger": {"name": "The Ledger", "kind": "mine_layer", "variants": ["elite", "veteran"], "hull_mult": 2.6, "bounty": {"salvage": 130, "research": 16}, "desc": "Keeps a ledger of every mine it has laid. The ledger is long.", "region": 2},
}

const ALLIES := {
	"barge": {"name": "Tidewright Barge", "hull": 260.0, "speed": 34.0, "radius": 26.0},
}

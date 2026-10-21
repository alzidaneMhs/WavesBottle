extends RefCounted

const START_UNLOCKS := {
	"weapons": ["roundshot:1", "chainshot:1", "canister:1"],
	"modules": ["repair_drone", "boost_jets"],
	"passives": ["reinforced_hull", "quick_load", "storm_canvas", "precision_rudder"],
}

const RESEARCH_ORDER := [
	"w_longbore", "w_harpoon", "w_torpedo", "w_mortar", "w_arc",
	"m_roundshot_2", "m_chainshot_2", "m_canister_2", "m_longbore_2", "m_harpoon_2", "m_torpedo_2", "m_mortar_2", "m_arc_2", "m_roundshot_3a", "m_roundshot_3b",
	"m_canister_3", "m_chainshot_3", "m_harpoon_3", "m_longbore_3", "m_arc_3", "m_torpedo_3", "m_mortar_3",
	"u_turret_ring",
	"a_flak_burst", "a_decoy_buoy", "a_smoke_screen", "a_mine_dispenser", "a_shock_pulse", "a_target_scanner", "a_sonar_pulse", "a_depth_charges", "a_overdrive",
	"p_shock_frame", "p_deep_keel", "p_crosswind_rigging", "p_wake_buffer", "p_slipstream_keel", "p_longbore_stabilizers", "p_salvage_magnet", "p_energy_capacitor", "p_bulkheads", "p_reinforced_mounts", "p_lightning_rod", "p_vane_rudder", "p_storm_rigging", "p_phase_anchor", "p_anomaly_insulation",
	"s_steady_wake", "s_predator_wake", "s_storm_wake", "s_resonant_wake",
]

const RESEARCH := {
	"w_longbore": {"cat": "Weapon Families", "grant": "weapons", "id": "longbore:1", "cost": {"research": 20}, "req": {"stage": "r1s3"}},
	"w_harpoon": {"cat": "Weapon Families", "grant": "weapons", "id": "harpoon:1", "cost": {"research": 25}, "req": {"stage": "r1s6"}},
	"w_torpedo": {"cat": "Weapon Families", "grant": "weapons", "id": "torpedo:1", "cost": {"research": 30}, "req": {"stage": "r1s8"}},
	"w_mortar": {"cat": "Weapon Families", "grant": "weapons", "id": "mortar:1", "cost": {"research": 40}, "req": {"stage": "r1s10"}},
	"w_arc": {"cat": "Weapon Families", "grant": "weapons", "id": "arc:1", "cost": {"research": 45}, "req": {"stage": "r1s10"}},
	"m_roundshot_2": {"cat": "Weapon Marks", "grant": "weapons", "id": "roundshot:2", "cost": {"research": 15}, "req": {"facility": "weapons_lab"}},
	"m_chainshot_2": {"cat": "Weapon Marks", "grant": "weapons", "id": "chainshot:2", "cost": {"research": 15}, "req": {"facility": "weapons_lab"}},
	"m_canister_2": {"cat": "Weapon Marks", "grant": "weapons", "id": "canister:2", "cost": {"research": 15}, "req": {"facility": "weapons_lab"}},
	"m_longbore_2": {"cat": "Weapon Marks", "grant": "weapons", "id": "longbore:2", "cost": {"research": 25}, "req": {"facility": "weapons_lab", "research": "w_longbore"}},
	"m_harpoon_2": {"cat": "Weapon Marks", "grant": "weapons", "id": "harpoon:2", "cost": {"research": 25}, "req": {"facility": "weapons_lab", "research": "w_harpoon"}},
	"m_torpedo_2": {"cat": "Weapon Marks", "grant": "weapons", "id": "torpedo:2", "cost": {"research": 30}, "req": {"facility": "weapons_lab", "research": "w_torpedo"}},
	"m_mortar_2": {"cat": "Weapon Marks", "grant": "weapons", "id": "mortar:2", "cost": {"research": 30}, "req": {"facility": "weapons_lab", "research": "w_mortar"}},
	"m_arc_2": {"cat": "Weapon Marks", "grant": "weapons", "id": "arc:2", "cost": {"research": 30}, "req": {"facility": "weapons_lab", "research": "w_arc"}},
	"m_roundshot_3a": {"cat": "Weapon Marks", "grant": "weapons", "id": "roundshot:3a", "cost": {"research": 35}, "req": {"facility": "weapons_lab", "research": "m_roundshot_2"}},
	"m_roundshot_3b": {"cat": "Weapon Marks", "grant": "weapons", "id": "roundshot:3b", "cost": {"research": 35}, "req": {"facility": "weapons_lab", "research": "m_roundshot_2"}},
	"m_canister_3": {"cat": "Weapon Marks", "grant": "weapons", "id": "canister:3", "cost": {"research": 35}, "req": {"facility": "weapons_lab", "research": "m_canister_2", "stage": "r2s1"}},
	"m_chainshot_3": {"cat": "Weapon Marks", "grant": "weapons", "id": "chainshot:3", "cost": {"research": 35}, "req": {"facility": "weapons_lab", "research": "m_chainshot_2", "stage": "r2s2"}},
	"m_harpoon_3": {"cat": "Weapon Marks", "grant": "weapons", "id": "harpoon:3", "cost": {"research": 40}, "req": {"facility": "weapons_lab", "research": "m_harpoon_2", "stage": "r2s4"}},
	"m_longbore_3": {"cat": "Weapon Marks", "grant": "weapons", "id": "longbore:3", "cost": {"research": 45}, "req": {"facility": "weapons_lab", "research": "m_longbore_2", "stage": "r2s6"}},
	"m_arc_3": {"cat": "Weapon Marks", "grant": "weapons", "id": "arc:3", "cost": {"research": 45}, "req": {"facility": "weapons_lab", "research": "m_arc_2", "stage": "r2s8"}},
	"m_torpedo_3": {"cat": "Weapon Marks", "grant": "weapons", "id": "torpedo:3", "cost": {"research": 50}, "req": {"facility": "weapons_lab", "research": "m_torpedo_2", "stage": "r2s10"}},
	"m_mortar_3": {"cat": "Weapon Marks", "grant": "weapons", "id": "mortar:3", "cost": {"research": 50}, "req": {"facility": "weapons_lab", "research": "m_mortar_2", "stage": "r2s10"}},
	"u_turret_ring": {"cat": "Advanced Fitting", "grant": "upgrades", "id": "turret_ring", "cost": {"research": 40, "intel": 1}, "req": {"facility": "weapons_lab", "stage": "r1s10"}},
	"a_flak_burst": {"cat": "Utility Modules", "grant": "modules", "id": "flak_burst", "cost": {"research": 12}, "req": {"stage": "r1s2"}},
	"a_decoy_buoy": {"cat": "Utility Modules", "grant": "modules", "id": "decoy_buoy", "cost": {"research": 18}, "req": {"stage": "r1s4"}},
	"a_smoke_screen": {"cat": "Utility Modules", "grant": "modules", "id": "smoke_screen", "cost": {"research": 18}, "req": {"stage": "r1s6"}},
	"a_mine_dispenser": {"cat": "Utility Modules", "grant": "modules", "id": "mine_dispenser", "cost": {"research": 22}, "req": {"stage": "r1s7"}},
	"a_shock_pulse": {"cat": "Utility Modules", "grant": "modules", "id": "shock_pulse", "cost": {"research": 25}, "req": {"stage": "r1s9"}},
	"a_target_scanner": {"cat": "Utility Modules", "grant": "modules", "id": "target_scanner", "cost": {"research": 30}, "req": {"stage": "r1s10"}},
	"a_sonar_pulse": {"cat": "Utility Modules", "grant": "modules", "id": "sonar_pulse", "cost": {"research": 35}, "req": {"stage": "r4s2"}},
	"a_depth_charges": {"cat": "Utility Modules", "grant": "modules", "id": "depth_charges", "cost": {"research": 45}, "req": {"stage": "r4s10"}},
	"a_overdrive": {"cat": "Utility Modules", "grant": "modules", "id": "overdrive", "cost": {"research": 45}, "req": {"stage": "r4s10"}},
	"p_shock_frame": {"cat": "Passive Systems", "grant": "passives", "id": "shock_frame", "cost": {"salvage": 60}, "req": {}},
	"p_deep_keel": {"cat": "Passive Systems", "grant": "passives", "id": "deep_keel", "cost": {"salvage": 60}, "req": {}},
	"p_crosswind_rigging": {"cat": "Passive Systems", "grant": "passives", "id": "crosswind_rigging", "cost": {"salvage": 60}, "req": {}},
	"p_wake_buffer": {"cat": "Passive Systems", "grant": "passives", "id": "wake_buffer", "cost": {"salvage": 70}, "req": {"stage": "r1s2"}},
	"p_slipstream_keel": {"cat": "Passive Systems", "grant": "passives", "id": "slipstream_keel", "cost": {"salvage": 80}, "req": {"stage": "r1s3"}},
	"p_longbore_stabilizers": {"cat": "Passive Systems", "grant": "passives", "id": "longbore_stabilizers", "cost": {"salvage": 90}, "req": {"stage": "r1s3"}},
	"p_salvage_magnet": {"cat": "Passive Systems", "grant": "passives", "id": "salvage_magnet", "cost": {"salvage": 80}, "req": {"stage": "r1s4"}},
	"p_energy_capacitor": {"cat": "Passive Systems", "grant": "passives", "id": "energy_capacitor", "cost": {"salvage": 100}, "req": {"stage": "r1s5"}},
	"p_bulkheads": {"cat": "Passive Systems", "grant": "passives", "id": "bulkheads", "cost": {"salvage": 120}, "req": {"stage": "r1s6"}},
	"p_reinforced_mounts": {"cat": "Passive Systems", "grant": "passives", "id": "reinforced_mounts", "cost": {"salvage": 100}, "req": {"stage": "r1s7"}},
	"p_lightning_rod": {"cat": "Passive Systems", "grant": "passives", "id": "lightning_rod", "cost": {"salvage": 160, "research": 10}, "req": {"stage": "r3s2"}},
	"p_vane_rudder": {"cat": "Passive Systems", "grant": "passives", "id": "vane_rudder", "cost": {"salvage": 200, "research": 20}, "req": {"stage": "r3s10"}},
	"p_storm_rigging": {"cat": "Passive Systems", "grant": "passives", "id": "storm_rigging", "cost": {"salvage": 200, "research": 20}, "req": {"stage": "r3s10"}},
	"p_phase_anchor": {"cat": "Passive Systems", "grant": "passives", "id": "phase_anchor", "cost": {"salvage": 220, "research": 25}, "req": {"stage": "r5s3"}},
	"p_anomaly_insulation": {"cat": "Passive Systems", "grant": "passives", "id": "anomaly_insulation", "cost": {"salvage": 150}, "req": {"region": 5}},
	"s_steady_wake": {"cat": "Wake Specializations", "grant": "passives", "id": "steady_wake", "cost": {"research": 20}, "req": {"stage": "r1s9"}},
	"s_predator_wake": {"cat": "Wake Specializations", "grant": "passives", "id": "predator_wake", "cost": {"research": 20}, "req": {"stage": "r1s9"}},
	"s_storm_wake": {"cat": "Wake Specializations", "grant": "passives", "id": "storm_wake", "cost": {"research": 20}, "req": {"stage": "r1s9"}},
	"s_resonant_wake": {"cat": "Wake Specializations", "grant": "passives", "id": "resonant_wake", "cost": {"research": 25}, "req": {"stage": "r1s10"}},
}

const FACILITY_ORDER := ["weapons_lab", "signal_archive", "training_basin", "navigation_room", "salvage_exchange", "fleet_registry"]

const FACILITIES := {
	"weapons_lab": {"name": "Weapons Lab", "desc": "Enables Mk II and Mk III weapon research.", "cost": {"salvage": 150, "intel": 2}},
	"signal_archive": {"name": "Signal Archive", "desc": "Decodes lore recovered from missions into Codex entries.", "cost": {"salvage": 80, "intel": 1}},
	"training_basin": {"name": "Training Basin", "desc": "Boss practice and enemy variant spawns in Sea Trials.", "cost": {"salvage": 100, "intel": 1}},
	"navigation_room": {"name": "Navigation Room", "desc": "A third contract slot and Navigation Trial operations.", "cost": {"salvage": 120, "intel": 2}},
	"salvage_exchange": {"name": "Salvage Exchange", "desc": "Trade Salvage and Research Data at fixed rates.", "cost": {"salvage": 100}},
	"fleet_registry": {"name": "Fleet Registry", "desc": "Fleet-wide records and mastery comparison in the Fleet office.", "cost": {"salvage": 60}},
}

const EXCHANGE := {"salvage_for_research": [60, 5], "research_for_salvage": [5, 30]}

const CONTRACTS := [
	{"id": "c_gunboats", "text": "Sink 20 Skiff Gunboats", "event": "kill", "key": "gunboat", "target": 20, "reward": {"salvage": 60}},
	{"id": "c_frigates", "text": "Sink 8 Broadside Frigates", "event": "kill", "key": "frigate", "target": 8, "reward": {"salvage": 70, "research": 5}},
	{"id": "c_wrecks", "text": "Salvage 5 wrecks", "event": "wreck", "key": "", "target": 5, "reward": {"salvage": 70}},
	{"id": "c_crossings", "text": "Cross the T 10 times", "event": "crossing", "key": "", "target": 10, "reward": {"research": 8}},
	{"id": "c_fireships", "text": "Sink 6 Fireships", "event": "kill", "key": "fireship", "target": 6, "reward": {"research": 8}},
	{"id": "c_dodges", "text": "Make 15 close dodges", "event": "dodge", "key": "", "target": 15, "reward": {"salvage": 60}},
	{"id": "c_rammers", "text": "Sink 5 Rammers", "event": "kill", "key": "rammer", "target": 5, "reward": {"salvage": 80}},
	{"id": "c_interrupts", "text": "Interrupt 6 enemy attacks", "event": "interrupt", "key": "", "target": 6, "reward": {"research": 10}},
	{"id": "c_needlefin", "text": "Complete a mission with the Needlefin", "event": "mission_ship", "key": "needlefin", "target": 1, "reward": {"research": 10}, "req": {"ship": "needlefin"}},
	{"id": "c_bulwark", "text": "Complete a mission with the Bulwark", "event": "mission_ship", "key": "bulwark", "target": 1, "reward": {"research": 10}, "req": {"ship": "bulwark"}},
	{"id": "c_grade", "text": "Earn an A grade or better twice", "event": "grade_a", "key": "", "target": 2, "reward": {"salvage": 90}},
	{"id": "c_wake", "text": "Reach Wake tier IV in a mission", "event": "wake_tier", "key": "", "target": 4, "reward": {"research": 8}, "max": true},
	{"id": "c_salvage", "text": "Earn 400 Salvage from missions", "event": "salvage", "key": "", "target": 400, "reward": {"research": 10}},
	{"id": "c_kills", "text": "Sink 40 enemies", "event": "kill", "key": "*", "target": 40, "reward": {"salvage": 100}},
	{"id": "c_layers", "text": "Sink 6 Mine Layers", "event": "kill", "key": "mine_layer", "target": 6, "reward": {"salvage": 90, "research": 6}, "req": {"region": 2}},
	{"id": "c_tenders", "text": "Sink 6 Shield Tenders", "event": "kill", "key": "shield_tender", "target": 6, "reward": {"research": 12}, "req": {"region": 2}},
	{"id": "c_weak", "text": "Land 30 weak-point hits", "event": "weak", "key": "", "target": 30, "reward": {"research": 10}},
	{"id": "c_monitors", "text": "Sink 5 Mortar Monitors", "event": "kill", "key": "mortar_monitor", "target": 5, "reward": {"salvage": 100}, "req": {"region": 2}},
	{"id": "c_corsair", "text": "Complete a mission with the Corsair", "event": "mission_ship", "key": "corsair", "target": 1, "reward": {"research": 12}, "req": {"ship": "corsair"}},
	{"id": "c_harpooners", "text": "Sink 6 Harpooners", "event": "kill", "key": "harpooner", "target": 6, "reward": {"salvage": 110}, "req": {"region": 3}},
	{"id": "c_sloops", "text": "Sink 6 Longbow Sloops", "event": "kill", "key": "longbow_sloop", "target": 6, "reward": {"research": 14}, "req": {"region": 3}},
	{"id": "c_stormbound", "text": "Sink 12 Stormbound enemies", "event": "stormbound", "key": "", "target": 12, "reward": {"salvage": 120, "research": 8}, "req": {"region": 3}},
	{"id": "c_manta", "text": "Complete a mission with the Manta", "event": "mission_ship", "key": "manta", "target": 1, "reward": {"research": 14}, "req": {"ship": "manta"}},
	{"id": "c_warden", "text": "Complete a mission with the Warden", "event": "mission_ship", "key": "warden", "target": 1, "reward": {"research": 14}, "req": {"ship": "warden"}},
	{"id": "c_ghosts", "text": "Sink 6 Ghost Runners", "event": "kill", "key": "ghost_runner", "target": 6, "reward": {"salvage": 130}, "req": {"region": 4}},
	{"id": "c_skaters", "text": "Sink 30 Swarm Skaters", "event": "kill", "key": "swarm_skater", "target": 30, "reward": {"research": 16}, "req": {"region": 4}},
	{"id": "c_jammers", "text": "Sink 5 Jammer Vessels", "event": "kill", "key": "jammer", "target": 5, "reward": {"salvage": 120, "research": 8}, "req": {"region": 4}},
	{"id": "c_riptide", "text": "Complete a mission with the Riptide", "event": "mission_ship", "key": "riptide", "target": 1, "reward": {"research": 16}, "req": {"ship": "riptide"}},
	{"id": "c_carriers", "text": "Sink 5 Resonant Drone Carriers", "event": "kill", "key": "resonant_carrier", "target": 5, "reward": {"salvage": 150, "research": 10}, "req": {"region": 5}},
	{"id": "c_drones", "text": "Destroy 30 Resonant Drones", "event": "kill", "key": "resonant_drone", "target": 30, "reward": {"research": 18}, "req": {"region": 5}},
	{"id": "c_echoforge", "text": "Complete a mission with the Echoforge", "event": "mission_ship", "key": "echoforge", "target": 1, "reward": {"research": 18}, "req": {"ship": "echoforge"}},
	{"id": "c_longshot", "text": "Complete a mission with the Longshot", "event": "mission_ship", "key": "longshot", "target": 1, "reward": {"research": 12}, "req": {"ship": "longshot"}},
]

const DIFFICULTY_ORDER := ["standard", "veteran", "elite", "abyssal"]

const DIFFICULTIES := {
	"standard": {"name": "Standard", "desc": "Baseline behavior and readable telegraphs.", "hull": 1.0, "cooldown": 1.0, "extra": 0, "reward": 1.0, "variants": 0.0, "unlock": {}},
	"veteran": {"name": "Veteran", "desc": "Coordinated compositions, modest stat increases, veteran variants.", "hull": 1.15, "cooldown": 0.88, "extra": 1, "reward": 1.3, "variants": 0.15, "unlock": {"stage": "r1s10", "tier": "standard"}},
	"elite": {"name": "Elite", "desc": "More variants, tighter attack windows, stronger objective pressure.", "hull": 1.3, "cooldown": 0.8, "extra": 1, "reward": 1.6, "variants": 0.3, "unlock": {"stage": "r1s10", "tier": "veteran"}},
	"abyssal": {"name": "Abyssal", "desc": "Endgame combinations and special boss modifiers.", "hull": 1.45, "cooldown": 0.72, "extra": 2, "reward": 2.0, "variants": 0.45, "unlock": {"stage": "r1s10", "tier": "elite"}},
}

const MODIFIERS := {
	"crosswind": {"name": "Heavy Crosswind", "desc": "Wind stays at full strength and pushes sideways twice as hard.", "reward": 1.15},
	"fog": {"name": "Fog Bank", "desc": "Visibility is reduced to a ring around your ship.", "reward": 1.2},
	"armored": {"name": "Reinforced Armor", "desc": "Many enemies are armored.", "reward": 1.2},
	"rich_salvage": {"name": "Rich Salvage", "desc": "+50% Salvage, but more elites.", "reward": 1.0},
	"rapid_reload": {"name": "Rapid Reload", "desc": "Enemies reload 20% faster. Telegraphs are unchanged.", "reward": 1.2},
	"limited_modules": {"name": "Limited Charges", "desc": "Each utility module can be used only twice.", "reward": 1.15},
	"anomaly": {"name": "Wake Anomaly", "desc": "Wake gains and decay are both 50% stronger.", "reward": 1.25},
	"no_repairs": {"name": "No Repairs", "desc": "No repair pickups drop.", "reward": 1.1},
}

const MASTERY_XP := [0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700]

const MASTERY_UNLOCKS := {
	2: "Hull marking: Stripe",
	3: "Wake trail: signature color",
	4: "+1 build slot",
	5: "Alternate perk",
	7: "Hull marking: Chevron",
	8: "+1 build slot",
	10: "Master badge",
}

const GRADE_ORDER := ["D", "C", "B", "A", "S"]
const GRADE_SALVAGE := {"S": 1.3, "A": 1.15, "B": 1.0, "C": 0.9, "D": 0.8}
const GRADE_XP := {"S": 60, "A": 40, "B": 20, "C": 10, "D": 0}

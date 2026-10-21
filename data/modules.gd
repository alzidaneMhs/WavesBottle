extends RefCounted

const ACTIVE_ORDER := ["repair_drone", "boost_jets", "flak_burst", "decoy_buoy", "smoke_screen", "mine_dispenser", "shock_pulse", "target_scanner", "sonar_pulse", "depth_charges", "overdrive"]

const ACTIVE := {
	"repair_drone": {"name": "Repair Drone", "short": "REPAIR", "desc": "Restores 30 Hull over 6 s.", "cooldown": 28.0, "power": 2.0, "mass": 0.8, "heal": 30.0, "duration": 6.0},
	"boost_jets": {"name": "Boost Jets", "short": "BOOST", "desc": "A short burst of forward acceleration.", "cooldown": 9.0, "power": 2.0, "mass": 0.4, "impulse": 280.0},
	"flak_burst": {"name": "Flak Burst", "short": "FLAK", "desc": "Destroys hostile projectiles within 170 px.", "cooldown": 14.0, "power": 2.0, "mass": 0.6, "radius": 170.0},
	"decoy_buoy": {"name": "Decoy Buoy", "short": "DECOY", "desc": "Drops a buoy that draws enemy fire for 8 s.", "cooldown": 20.0, "power": 1.0, "mass": 0.6, "duration": 8.0, "hull": 60.0},
	"smoke_screen": {"name": "Smoke Screen", "short": "SMOKE", "desc": "A 6 s smoke cloud. Enemies outside it lose track of ships inside.", "cooldown": 22.0, "power": 1.0, "mass": 0.5, "duration": 6.0, "radius": 170.0},
	"mine_dispenser": {"name": "Mine Dispenser", "short": "MINE", "desc": "Drops a mine behind the ship that only enemies trigger. Up to 3 at once.", "cooldown": 7.0, "power": 1.0, "mass": 0.8, "damage": 30.0, "max": 3},
	"shock_pulse": {"name": "Shock Pulse", "short": "PULSE", "desc": "A 190 px pulse: 14 damage, pushes and slows nearby enemies.", "cooldown": 16.0, "power": 3.0, "mass": 0.6, "radius": 190.0, "damage": 14.0},
	"sonar_pulse": {"name": "Sonar Pulse", "short": "SONAR", "desc": "Reveals cloaked ships and burns through jamming for 8 s.", "cooldown": 20.0, "power": 2.0, "mass": 0.4, "duration": 8.0},
	"depth_charges": {"name": "Depth Charges", "short": "DEPTH", "desc": "Rolls three charges off the stern that burst after 1.2 s for 30 damage each.", "cooldown": 12.0, "power": 1.0, "mass": 1.0, "damage": 30.0, "blast": 80.0},
	"overdrive": {"name": "Overdrive", "short": "DRIVE", "desc": "5 s of +30% speed and 30% faster reloads, then 3 s of sluggish engines.", "cooldown": 24.0, "power": 3.0, "mass": 0.7, "duration": 5.0, "slump": 3.0},
	"target_scanner": {"name": "Target Scanner", "short": "SCAN", "desc": "Marks weak points: enemies take 20% more damage for 7 s.", "cooldown": 24.0, "power": 2.0, "mass": 0.3, "duration": 7.0, "bonus": 0.2},
}

const PASSIVE_ORDER := ["reinforced_hull", "quick_load", "storm_canvas", "precision_rudder", "shock_frame", "deep_keel", "slipstream_keel", "crosswind_rigging", "longbore_stabilizers", "salvage_magnet", "wake_buffer", "bulkheads", "energy_capacitor", "reinforced_mounts", "anomaly_insulation", "lightning_rod", "vane_rudder", "storm_rigging", "phase_anchor", "steady_wake", "predator_wake", "storm_wake", "resonant_wake"]

const PASSIVES := {
	"reinforced_hull": {"name": "Reinforced Hull", "cat": "Hull", "desc": "+30 maximum Hull.", "mass": 1.5, "add": {"max_hull": 30.0}},
	"shock_frame": {"name": "Shock-Absorbing Frame", "cat": "Hull", "desc": "Collision damage and knockback halved.", "mass": 0.5, "mul": {"collision_mult": 0.5}},
	"bulkheads": {"name": "Emergency Bulkheads", "cat": "Hull", "desc": "Once per mission, survive a lethal hit with 1 Hull.", "mass": 1.0, "flags": ["bulkheads"]},
	"precision_rudder": {"name": "Precision Rudder", "cat": "Rudder", "desc": "+18% turn rate, better low-speed handling.", "mass": 0.3, "mul": {"turn": 1.18}, "add": {"low_turn": 0.12}},
	"deep_keel": {"name": "Deep Keel", "cat": "Keel", "desc": "+40% lateral grip. Less sliding, shorter drifts.", "mass": 0.8, "mul": {"lateral": 1.4}},
	"slipstream_keel": {"name": "Slipstream Keel", "cat": "Keel", "desc": "Drifts slide longer and drift passes give more Wake.", "mass": 0.5, "mul": {"drift_lateral": 0.6}, "flags": ["slipstream"]},
	"storm_canvas": {"name": "Storm Canvas", "cat": "Sails", "desc": "+20% acceleration, +8% top speed.", "mass": 0.4, "mul": {"accel": 1.2, "max_speed": 1.08}},
	"crosswind_rigging": {"name": "Crosswind Rigging", "cat": "Sails", "desc": "Headwind penalty and crosswind drift halved.", "mass": 0.3, "mul": {"wind_penalty": 0.5, "crosswind": 0.5}},
	"quick_load": {"name": "Quick-Load Crew", "cat": "Cannons", "desc": "All weapon reloads 12% faster.", "mass": 0.3, "mul": {"reload_mult": 0.88}},
	"longbore_stabilizers": {"name": "Long-Bore Stabilizers", "cat": "Cannons", "desc": "+15% weapon range and 40% tighter spread.", "mass": 0.6, "mul": {"range_mult": 1.15, "spread_mult": 0.6}},
	"reinforced_mounts": {"name": "Reinforced Weapon Mounts", "cat": "Cannons", "desc": "+3 mass rating and 40% less recoil.", "mass": 0.0, "add": {"mass_rating": 3.0}, "mul": {"recoil_mult": 0.6}},
	"energy_capacitor": {"name": "Energy Capacitor", "cat": "Power", "desc": "+3 power capacity.", "mass": 0.6, "add": {"power_cap": 3.0}},
	"salvage_magnet": {"name": "Salvage Magnet", "cat": "Utility", "desc": "+20% Salvage, double pickup radius, wrecks salvage 40% faster.", "mass": 0.4, "mul": {"salvage_mult": 1.2, "pickup_mult": 2.0, "wreck_time_mult": 0.6}},
	"wake_buffer": {"name": "Wake Buffer", "cat": "Wake", "desc": "+1.5 s grace before decay and decay 40% slower.", "mass": 0.2, "add": {"wake_grace": 1.5}, "mul": {"wake_decay": 0.6}},
	"lightning_rod": {"name": "Lightning Rod", "cat": "Hull", "desc": "Lightning strikes deal no damage to you; every strike it absorbs charges your ship ability by 25%.", "mass": 0.6, "flags": ["lightning_rod"]},
	"vane_rudder": {"name": "Vane Rudder", "cat": "Rudder", "desc": "+30% turn rate while drifting or below half speed.", "mass": 0.4, "flags": ["vane_rudder"]},
	"storm_rigging": {"name": "Storm Rigging", "cat": "Sails", "desc": "Currents, whirlpools and storm gusts push you 50% less; tailwind bonus +50%.", "mass": 0.5, "mul": {"flow_mult": 0.5, "wind_bonus": 1.5}},
	"phase_anchor": {"name": "Phase Anchor", "cat": "Wake", "desc": "Heavy hits drain Wake progress instead of dropping a whole tier.", "mass": 0.5, "flags": ["phase_anchor"]},
	"anomaly_insulation": {"name": "Anomaly Insulation", "cat": "Hull", "desc": "Hazard damage reduced by 40%.", "mass": 0.8, "mul": {"hazard_mult": 0.6}},
	"steady_wake": {"name": "Steady Wake", "cat": "Wake Specialization", "exclusive": "wake_spec", "desc": "Decay 50% slower and +1 s grace, but score multipliers are 15% lower.", "mass": 0.0, "mul": {"wake_decay": 0.5, "score_mult": 0.85}, "add": {"wake_grace": 1.0}},
	"predator_wake": {"name": "Predator Wake", "cat": "Wake Specialization", "exclusive": "wake_spec", "desc": "Crossing the T, weak-point hits and interrupts give double Wake.", "mass": 0.0, "flags": ["predator_wake"]},
	"storm_wake": {"name": "Storm Wake", "cat": "Wake Specialization", "exclusive": "wake_spec", "desc": "Gain Wake while riding currents, whirlpools and storms.", "mass": 0.0, "flags": ["storm_wake"]},
	"resonant_wake": {"name": "Resonant Wake", "cat": "Wake Specialization", "exclusive": "wake_spec", "desc": "+10% damage at Wake III or higher, but hits cost 60% more Wake.", "mass": 0.0, "flags": ["resonant_wake"]},
}

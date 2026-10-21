extends Node

const ShipsData = preload("res://data/ships.gd")
const WeaponsData = preload("res://data/weapons.gd")
const ModulesData = preload("res://data/modules.gd")
const EnemiesData = preload("res://data/enemies.gd")
const MissionsData = preload("res://data/missions.gd")
const ProgressionData = preload("res://data/progression.gd")
const WorldData = preload("res://data/world.gd")

const ARENA_SIZE := Vector2(3200, 2200)
const ARENA_MARGIN := 1200.0
const MAX_WAVE := 10

const COL_PORT := Color(0.30, 0.90, 1.00)
const COL_STBD := Color(1.00, 0.42, 0.78)
const COL_PLAYER := Color(0.55, 0.95, 1.00)
const COL_ENEMY := Color(1.00, 0.45, 0.25)
const COL_ENEMY_SHOT := Color(1.00, 0.35, 0.15)
const COL_WARN := Color(1.00, 0.20, 0.25)
const COL_TEXT := Color(0.86, 0.94, 1.00)
const COL_SALVAGE := Color(1.00, 0.85, 0.40)
const COL_RESEARCH := Color(0.55, 0.85, 1.00)
const COL_INTEL := Color(0.75, 1.00, 0.70)
const COL_ALLY := Color(0.45, 1.00, 0.70)

const SLOT_LABELS := {"port": "PORT", "starboard": "STARBOARD", "bow": "BOW", "stern": "STERN", "turret": "TURRET"}
const SLOT_ACTIONS := {"port": "fire_port", "starboard": "fire_starboard", "bow": "fire_bow", "stern": "fire_stern", "turret": "fire_turret"}
const SLOT_COLORS := {"port": Color(0.30, 0.90, 1.00), "starboard": Color(1.00, 0.42, 0.78), "bow": Color(0.55, 1.00, 0.70), "stern": Color(1.00, 0.85, 0.45), "turret": Color(0.78, 0.72, 1.00)}

const BASE_STATS := {
	"max_hull": 100.0, "accel": 230.0, "brake": 340.0, "max_speed": 320.0, "reverse_ratio": 0.3,
	"lateral": 3.4, "drift_lateral": 0.9, "turn": 2.4, "low_turn": 0.45, "turn_accel": 9.0, "radius": 18.0,
	"collision_mult": 1.0, "wind_bonus": 0.15, "wind_penalty": 0.15, "crosswind": 14.0,
	"wake_grace": 2.5, "wake_decay": 18.0, "power_cap": 10.0, "mass_rating": 10.0,
	"reload_mult": 1.0, "range_mult": 1.0, "spread_mult": 1.0, "damage_mult": 1.0, "recoil_mult": 1.0, "shot_speed_mult": 1.0,
	"extra_barrels": 0.0, "salvage_mult": 1.0, "pickup_mult": 1.0, "wreck_time_mult": 1.0, "hazard_mult": 1.0, "score_mult": 1.0,
	"ability_cd_mult": 1.0, "charge_mult": 1.0, "burst_immunity": 0.0, "brace_reduction": 0.0, "brace_drain_mult": 1.0,
	"wind_charge_mult": 1.0, "dodge_charge": 0.0, "mass_used": 0.0, "power_used": 0.0, "plunder_bonus": 0.0, "raid_time": 0.0, "mark_bonus": 0.0, "ward_radius": 0.0, "ward_charges": 0.0, "flow_mult": 1.0,
}

const STAT_LABELS := [
	["max_hull", "Max Hull", "int"],
	["accel", "Acceleration", "int"],
	["max_speed", "Top Speed", "int"],
	["turn", "Turn Rate", "f2"],
	["low_turn", "Low-Speed Turn", "pct"],
	["lateral", "Lateral Grip", "f1"],
	["drift_lateral", "Drift Slide", "f2"],
	["reload_mult", "Reload Time", "pct"],
	["range_mult", "Weapon Range", "pct"],
	["shot_speed_mult", "Shot Speed", "pct"],
	["extra_barrels", "Extra Barrels", "int"],
	["recoil_mult", "Recoil", "pct"],
	["collision_mult", "Collision Damage", "pct"],
	["wind_bonus", "Tailwind Bonus", "pct"],
	["wind_penalty", "Headwind Penalty", "pct"],
	["crosswind", "Crosswind Drift", "int"],
	["wake_grace", "Wake Grace (s)", "f1"],
	["wake_decay", "Wake Decay / s", "int"],
	["power_cap", "Power Capacity", "f1"],
	["mass_rating", "Mass Rating", "f1"],
]

const WAVES := [
	{"groups": [["gunboat", 3]], "elite": 0, "note": "Gunboats probe the line"},
	{"groups": [["gunboat", 5]], "elite": 0, "note": "A gunboat pack circles in"},
	{"groups": [["gunboat", 3], ["frigate", 1]], "elite": 0, "note": "A frigate joins the hunt"},
	{"groups": [["gunboat", 4], ["frigate", 2]], "elite": 0, "note": "Escorted frigates"},
	{"groups": [["gunboat", 3], ["fireship", 2]], "elite": 0, "note": "Fireships on the horizon"},
	{"groups": [["frigate", 2], ["gunboat", 3], ["fireship", 2]], "elite": 1, "note": "Mixed squadron"},
	{"groups": [["gunboat", 6], ["frigate", 2], ["fireship", 2]], "elite": 1, "note": "The swarm thickens"},
	{"groups": [["frigate", 3], ["gunboat", 4], ["fireship", 3]], "elite": 2, "note": "Battle line"},
	{"groups": [["frigate", 4], ["gunboat", 5], ["fireship", 3]], "elite": 3, "note": "Last escort before the flagship"},
	{"groups": [["galleon", 1]], "elite": 0, "note": "The Galleon approaches"},
]

const HAZARDS := {
	"mine": {"radius": 13.0, "trigger": 75.0, "fuse": 0.7, "blast": 95.0, "damage": 18.0, "field": 150.0},
	"current": {"length": 900.0, "width": 190.0, "speed": 110.0},
	"whirlpool": {"radius": 170.0, "pull": 90.0, "swirl": 140.0, "form": 3.0, "life": 26.0, "fade": 3.0},
	"storm": {"radius": 300.0, "push": 75.0, "gust": 35.0, "form": 4.0, "life": 40.0, "fade": 4.0, "drift": 28.0, "strike_damage": 12.0, "strike_radius": 55.0, "strike_delay": 1.2},
	"wreck": {"radius": 70.0, "time": 2.5, "max_speed": 140.0},
	"wreck_field": {"radius": 230.0, "pieces": 9},
	"lightning_field": {"radius": 200.0, "cycle": 6.0, "strikes": 5, "delay": 1.4, "strike_radius": 60.0, "damage": 12.0},
	"lane": {"width": 130.0, "span": 1300.0, "damage": 14.0},
	"vent": {"radius": 105.0, "warn": 2.0, "damage": 18.0, "push": 300.0, "idle_min": 5.0, "idle_max": 9.0},
	"bloom": {"radius": 210.0, "drift": 18.0},
	"buoy": {"radius": 100.0, "time": 3.0},
	"rift": {"radius": 175.0, "length": 240.0, "cycle": 6.5, "warn": 1.6, "damage": 12.0, "drain": 40.0},
}

const HAZARD_INTRO := {
	"wreck": ["SALVAGE WRECK", "Slow down inside the gold ring to salvage it for extra Salvage."],
	"current": ["NEW HAZARD: CURRENT", "Moving water pushes every ship along the arrows."],
	"mines": ["NEW HAZARD: MINEFIELD", "Mines arm when ships come close. Shoot them to detonate early."],
	"whirlpool": ["NEW HAZARD: WHIRLPOOL", "Pulls ships toward its center. Sail out along the edge."],
	"storm": ["NEW HAZARD: STORM FRONT", "Strong gusts push every ship, and lightning strikes inside."],
	"wreck_field": ["NEW HAZARD: WRECK FIELD", "Rusted hulks block ships and shots. A salvage wreck often sits in the middle."],
	"lightning_field": ["NEW HAZARD: LIGHTNING FIELD", "Strikes land in a steady rhythm. Cross while it recharges."],
	"rift": ["NEW HAZARD: RESONANCE RIFT", "Rifts flare in a steady rhythm. A pulse hurts and drains your Wake - cross while it is quiet."],
	"shift": ["CURRENTS SHIFTING", "The currents are about to change direction."],
	"vent": ["NEW HAZARD: PRESSURE VENT", "Vents rumble, ring, then erupt and throw ships aside. Leave the ring before it fills."],
	"bloom": ["GLOW BLOOM", "Glowing water. Nothing stays hidden inside a bloom."],
	"storm_lanes": ["LIGHTNING LANES", "Bands of lightning sweep the sea - one lane is always open. Steer into the gap."],
}

const WAKE_NAMES := ["Still", "Ripple", "Swell", "Surge", "Tempest", "Resonance"]
const WAKE_ROMAN := ["0", "I", "II", "III", "IV", "V"]
const WAKE_MULT := [1.0, 1.5, 2.0, 3.0, 4.0, 5.0]
const WAKE_NEED := [50.0, 70.0, 90.0, 110.0, 130.0, 150.0]

const PALETTES := {
	"classic": {"name": "Bioluminescent", "unlock": "", "colors": [Color(0.85, 0.92, 1.0), Color(0.62, 0.95, 1.0), Color(0.25, 0.90, 1.0), Color(0.30, 1.0, 0.85), Color(0.95, 0.45, 0.85), Color(1.0, 0.30, 0.70)]},
	"ember": {"name": "Ember Tide", "unlock": "Reach Wake tier V", "colors": [Color(0.95, 0.92, 0.88), Color(1.0, 0.85, 0.60), Color(1.0, 0.65, 0.30), Color(1.0, 0.48, 0.22), Color(1.0, 0.32, 0.35), Color(1.0, 0.22, 0.50)]},
	"aurora": {"name": "Aurora", "unlock": "Defeat the Ironwake", "colors": [Color(0.88, 0.95, 0.92), Color(0.70, 1.0, 0.75), Color(0.40, 1.0, 0.60), Color(0.40, 0.90, 1.0), Color(0.60, 0.50, 1.0), Color(0.85, 0.40, 1.0)]},
	"sovereign": {"name": "Sovereign", "unlock": "Defeat the Resonant Sovereign", "colors": [Color(0.95, 0.9, 1.0), Color(1.0, 0.75, 0.95), Color(1.0, 0.55, 0.9), Color(0.85, 0.5, 1.0), Color(0.55, 0.85, 1.0), Color(1.0, 0.95, 0.7)]},
	"prism": {"name": "Prism", "unlock": "Clear 10 stages in New Game+ Remix", "colors": [Color(1.0, 1.0, 1.0), Color(1.0, 0.6, 0.6), Color(1.0, 0.9, 0.5), Color(0.5, 1.0, 0.6), Color(0.5, 0.75, 1.0), Color(0.85, 0.55, 1.0)]},
	"abyssal": {"name": "Abyssal Glow", "unlock": "Defeat the Leviathan Engine", "colors": [Color(0.8, 0.95, 0.95), Color(0.5, 1.0, 0.85), Color(0.3, 0.95, 0.8), Color(0.25, 0.8, 1.0), Color(0.4, 0.6, 1.0), Color(0.75, 1.0, 0.95)]},
	"stormglass": {"name": "Stormglass", "unlock": "Defeat the Storm Matriarch", "colors": [Color(0.9, 0.93, 1.0), Color(0.75, 0.85, 1.0), Color(0.6, 0.75, 1.0), Color(0.95, 0.95, 0.6), Color(0.7, 0.6, 1.0), Color(1.0, 1.0, 0.85)]},
	"rustfire": {"name": "Rustfire", "unlock": "Defeat Dreadnought Kharon", "colors": [Color(0.92, 0.88, 0.84), Color(0.95, 0.75, 0.55), Color(1.0, 0.58, 0.32), Color(0.95, 0.42, 0.25), Color(0.75, 0.85, 0.95), Color(0.55, 0.95, 1.0)]},
}

const UPGRADES := [
	{"id": "plating", "name": "Reinforced Plating", "cat": "Hull", "desc": "+25 maximum Hull and restores 25 Hull.", "cost": 30, "max": 3, "add": {"max_hull": 25.0}, "heal": 25.0},
	{"id": "frame", "name": "Shock-Absorbing Frame", "cat": "Hull", "desc": "Collision damage and knockback halved.", "cost": 22, "max": 1, "mul": {"collision_mult": 0.5}},
	{"id": "bulkheads", "name": "Emergency Bulkheads", "cat": "Hull", "desc": "Once per run, survive a lethal hit with 1 Hull.", "cost": 55, "max": 1, "flags": ["bulkheads"]},
	{"id": "canvas", "name": "Storm Canvas", "cat": "Sails", "desc": "+20% acceleration and +8% top speed.", "cost": 24, "max": 3, "mul": {"accel": 1.2, "max_speed": 1.08}},
	{"id": "tailwind", "name": "Tailwind Catcher", "cat": "Sails", "desc": "Favorable wind bonus doubled.", "cost": 18, "max": 1, "mul": {"wind_bonus": 2.0}},
	{"id": "crosswind", "name": "Crosswind Rigging", "cat": "Sails", "desc": "Headwind penalty and crosswind drift halved.", "cost": 18, "max": 1, "mul": {"wind_penalty": 0.5, "crosswind": 0.5}},
	{"id": "rudder", "name": "Precision Rudder", "cat": "Rudder", "desc": "+18% turn rate and better low-speed handling.", "cost": 24, "max": 2, "mul": {"turn": 1.18}, "add": {"low_turn": 0.12}},
	{"id": "deep_keel", "name": "Deep Keel", "cat": "Keel", "desc": "+40% lateral grip. Less sliding, shorter drifts.", "cost": 20, "max": 1, "mul": {"lateral": 1.4}},
	{"id": "slip_keel", "name": "Slipstream Keel", "cat": "Keel", "desc": "Drifts slide longer and drift passes give more Wake.", "cost": 24, "max": 1, "mul": {"drift_lateral": 0.6}, "flags": ["slipstream"]},
	{"id": "quickload", "name": "Quick-Load Crew", "cat": "Cannons", "desc": "Reload time -15%.", "cost": 32, "max": 3, "mul": {"reload_mult": 0.85}},
	{"id": "longbore", "name": "Long-Bore Barrels", "cat": "Cannons", "desc": "+20% range and +10% shot speed.", "cost": 28, "max": 2, "mul": {"range_mult": 1.2, "shot_speed_mult": 1.1}},
	{"id": "volley", "name": "Dense Volley", "cat": "Cannons", "desc": "+1 barrel on every station. Reload time +12%.", "cost": 40, "max": 2, "add": {"extra_barrels": 1.0}, "mul": {"reload_mult": 1.12}},
	{"id": "carriages", "name": "Stabilized Carriages", "cat": "Cannons", "desc": "Firing recoil reduced by 65%.", "cost": 14, "max": 1, "mul": {"recoil_mult": 0.35}},
	{"id": "recoil_rig", "name": "Recoil Rigging", "cat": "Cannons", "desc": "Recoil +60%, and part of it becomes a forward surge.", "cost": 20, "max": 1, "mul": {"recoil_mult": 1.6}, "flags": ["recoil_rig"]},
	{"id": "resonant", "name": "Resonant Wake", "cat": "Wake", "desc": "+25% score and +1 Salvage per kill at Wake tier III or higher.", "cost": 28, "max": 1, "flags": ["resonant"]},
	{"id": "buffer", "name": "Wake Buffer", "cat": "Wake", "desc": "+1.5s grace before decay and decay 40% slower.", "cost": 24, "max": 1, "add": {"wake_grace": 1.5}, "mul": {"wake_decay": 0.6}},
	{"id": "repair_kit", "name": "Emergency Repair Kit", "cat": "Utility", "desc": "Restore 15 Hull after every cleared wave.", "cost": 30, "max": 1, "flags": ["repair_kit"]},
]

var SHIPS: Dictionary = ShipsData.SHIPS
var SHIP_ORDER: Array = ShipsData.ORDER
var ABILITIES: Dictionary = ShipsData.ABILITIES
var WEAPONS: Dictionary = WeaponsData.WEAPONS
var WEAPON_ORDER: Array = WeaponsData.ORDER
var MOUNT_FOR_SLOT: Dictionary = WeaponsData.MOUNT_FOR_SLOT
var ACTIVE_MODULES: Dictionary = ModulesData.ACTIVE
var ACTIVE_ORDER: Array = ModulesData.ACTIVE_ORDER
var PASSIVES: Dictionary = ModulesData.PASSIVES
var PASSIVE_ORDER: Array = ModulesData.PASSIVE_ORDER
var ENEMIES: Dictionary = EnemiesData.ENEMIES
var ENEMY_ORDER: Array = EnemiesData.ORDER
var BOSS_KINDS: Array = EnemiesData.BOSS_KINDS
var REGION_TWO: Array = EnemiesData.REGION_TWO
var REGION_THREE: Array = EnemiesData.REGION_THREE
var REGION_FOUR: Array = EnemiesData.REGION_FOUR
var REGION_FIVE: Array = EnemiesData.REGION_FIVE
var VARIANTS: Dictionary = EnemiesData.VARIANTS
var NAMED: Dictionary = EnemiesData.NAMED
var ALLIES: Dictionary = EnemiesData.ALLIES
var CAMPAIGN: Dictionary = MissionsData.CAMPAIGN
var OPERATIONS: Dictionary = MissionsData.OPERATIONS
var OPS_ORDER: Array = MissionsData.OPS_ORDER
var RESEARCH: Dictionary = ProgressionData.RESEARCH
var RESEARCH_ORDER: Array = ProgressionData.RESEARCH_ORDER
var FACILITIES: Dictionary = ProgressionData.FACILITIES
var FACILITY_ORDER: Array = ProgressionData.FACILITY_ORDER
var CONTRACTS: Array = ProgressionData.CONTRACTS
var DIFFICULTIES: Dictionary = ProgressionData.DIFFICULTIES
var DIFFICULTY_ORDER: Array = ProgressionData.DIFFICULTY_ORDER
var MODIFIERS: Dictionary = ProgressionData.MODIFIERS
var REGIONS: Array = WorldData.REGIONS
var REGION_STAGES: Dictionary = WorldData.REGION_STAGES
var LORE: Dictionary = WorldData.LORE
var LORE_ORDER: Array = WorldData.LORE_ORDER
var TACTICS: Array = WorldData.TACTICS
var FACTIONS: Array = WorldData.FACTIONS
var PREMISE: String = WorldData.PREMISE
var START_UNLOCKS: Dictionary = ProgressionData.START_UNLOCKS
var EXCHANGE: Dictionary = ProgressionData.EXCHANGE
var MASTERY_XP: Array = ProgressionData.MASTERY_XP
var MASTERY_UNLOCKS: Dictionary = ProgressionData.MASTERY_UNLOCKS
var GRADE_ORDER: Array = ProgressionData.GRADE_ORDER
var GRADE_SALVAGE: Dictionary = ProgressionData.GRADE_SALVAGE
var GRADE_XP: Dictionary = ProgressionData.GRADE_XP


func get_wave(n: int) -> Dictionary:
	var idx: int = clampi(n - 1, 0, WAVES.size() - 1)
	return WAVES[idx]


func hull_scale(wave: int) -> float:
	return 1.0 + maxf(0.0, float(wave - 5)) * 0.06


func upgrade_by_id(id: String) -> Dictionary:
	for u in UPGRADES:
		if u["id"] == id:
			return u
	return {}


func format_stat(kind: String, v: float) -> String:
	match kind:
		"int":
			return str(int(round(v)))
		"f1":
			return "%.1f" % v
		"f2":
			return "%.2f" % v
		"pct":
			return "%d%%" % int(round(v * 100.0))
	return str(v)


func wake_color(tier: int) -> Color:
	var pid: String = str(SaveData.data.get("palette", "classic"))
	if not PALETTES.has(pid):
		pid = "classic"
	var cols: Array = PALETTES[pid]["colors"]
	return cols[clampi(tier, 0, cols.size() - 1)]


func split_key(key: String) -> Array:
	var parts := key.split(":")
	if parts.size() < 2:
		return [key, "1"]
	return [parts[0], parts[1]]


func weapon_stats(id: String, mark: String) -> Dictionary:
	if not WEAPONS.has(id):
		return {}
	var base: Dictionary = (WEAPONS[id] as Dictionary).duplicate(true)
	base["id"] = id
	base["mark"] = mark
	base["mark_name"] = "Mk I"
	var marks: Dictionary = base.get("marks", {})
	if mark != "1" and marks.has(mark):
		var m: Dictionary = marks[mark]
		for k in m.keys():
			if k == "name":
				base["mark_name"] = m[k]
			elif k != "desc":
				base[k] = m[k]
	base.erase("marks")
	return base


func weapon_label(id: String, mark: String) -> String:
	var w := weapon_stats(id, mark)
	if w.is_empty():
		return "-"
	return "%s %s" % [w["name"], w["mark_name"]]


func mount_ok(id: String, slot: String) -> bool:
	if not WEAPONS.has(id):
		return false
	var mount: String = MOUNT_FOR_SLOT.get(slot, "")
	return (WEAPONS[id]["mounts"] as Array).has(mount)


func mission(id: String) -> Dictionary:
	return CAMPAIGN.get(id, {})


func stage_label(id: String) -> String:
	var m := mission(id)
	if m.is_empty():
		return id
	return "%d-%d" % [int(m["region"]), int(m["stage"])]


func next_stage(id: String) -> String:
	var m := mission(id)
	if m.is_empty():
		return ""
	var list: Array = REGION_STAGES.get(int(m["region"]), [])
	var idx := list.find(id)
	if idx >= 0 and idx + 1 < list.size():
		return list[idx + 1]
	var nxt: Array = REGION_STAGES.get(int(m["region"]) + 1, [])
	if idx == list.size() - 1 and not nxt.is_empty() and bool(region(int(m["region"]) + 1)["available"]):
		return nxt[0]
	return ""


func is_boss(kind: String) -> bool:
	return BOSS_KINDS.has(kind)


func global_stage(c: Dictionary) -> int:
	return (int(c.get("region", 1)) - 1) * 10 + int(c.get("stage", 1))


func all_stages() -> Array:
	var out: Array = []
	for r in REGIONS:
		out.append_array(REGION_STAGES.get(int(r["id"]), []))
	return out


func region(id: int) -> Dictionary:
	for r in REGIONS:
		if int(r["id"]) == id:
			return r
	return REGIONS[0]


func enemy_name(kind: String) -> String:
	if ENEMIES.has(kind):
		return str(ENEMIES[kind]["name"])
	return kind.capitalize()


func cost_text(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	if int(cost.get("salvage", 0)) > 0:
		parts.append("%d Salvage" % int(cost["salvage"]))
	if int(cost.get("research", 0)) > 0:
		parts.append("%d Research" % int(cost["research"]))
	if int(cost.get("intel", 0)) > 0:
		parts.append("%d Intel" % int(cost["intel"]))
	if parts.is_empty():
		return "Free"
	return " + ".join(parts)

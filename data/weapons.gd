extends RefCounted

const ORDER := ["roundshot", "chainshot", "canister", "longbore", "harpoon", "torpedo", "mortar", "arc"]

const WEAPONS := {
	"roundshot": {
		"name": "Roundshot Cannon", "short": "ROUND", "role": "Reliable general damage", "limit": "No special effect",
		"desc": "Balanced range and reload. The backbone of every fleet.",
		"mounts": ["broadside", "bow", "stern", "turret"], "pattern": "volley",
		"damage": 10.0, "range": 520.0, "speed": 660.0, "reload": 1.5, "spread": 0.05, "radius": 5.0,
		"mass": 1.0, "power": 0.0, "recoil": 18.0, "color": Color(0.85, 0.97, 1.0),
		"marks": {
			"2": {"name": "Mk II", "desc": "Heavier charge: +20% damage, slightly faster reload.", "damage": 12.0, "reload": 1.4, "mass": 1.1},
			"3a": {"name": "Mk III Penetrator", "desc": "Slow, armor-piercing heavy shot.", "damage": 17.0, "reload": 2.1, "speed": 760.0, "armor_pierce": true, "mass": 1.3, "radius": 6.0},
			"3b": {"name": "Mk III Rapid", "desc": "Light rapid-fire cannon with lower damage per hit.", "damage": 6.5, "reload": 0.8, "spread": 0.08, "mass": 1.0, "radius": 4.0},
		},
	},
	"chainshot": {
		"name": "Chainshot Launcher", "short": "CHAIN", "role": "Control / disabling", "limit": "Lower hull damage",
		"desc": "Spinning chains slow enemy speed and turning.",
		"mounts": ["broadside", "bow", "stern", "turret"], "pattern": "volley", "status": "slow", "slow": 0.25, "slow_time": 2.0,
		"damage": 4.0, "range": 440.0, "speed": 600.0, "reload": 1.6, "spread": 0.06, "radius": 6.0,
		"mass": 1.0, "power": 0.0, "recoil": 14.0, "color": Color(1.0, 0.78, 0.3),
		"marks": {
			"2": {"name": "Mk II", "desc": "Barbed chains: stronger and longer slow.", "slow": 0.33, "slow_time": 2.5, "mass": 1.1},
			"3": {"name": "Mk III Breaker Chain", "desc": "Tears rigging and plating instead of slowing: targets take 25% more damage and lose their armor for 4 s.", "status": "sunder", "slow": 0.0, "slow_time": 4.0, "damage": 5.0, "mass": 1.2},
		},
	},
	"canister": {
		"name": "Canister Broadside", "short": "CANISTER", "role": "Close-range burst", "limit": "Poor range, wide spread",
		"desc": "A wide cluster of pellets that shreds nearby targets.",
		"mounts": ["broadside", "bow", "stern", "turret"], "pattern": "pellets", "pellets": 3,
		"damage": 4.0, "range": 240.0, "speed": 690.0, "reload": 1.5, "spread": 0.34, "radius": 3.5,
		"mass": 1.2, "power": 0.0, "recoil": 20.0, "color": Color(1.0, 0.5, 0.8),
		"marks": {
			"2": {"name": "Mk II", "desc": "Packed charge: one extra pellet per barrel.", "pellets": 4, "mass": 1.35},
			"3": {"name": "Mk III Flechette", "desc": "A tight cloud of armor-piercing darts with longer reach but less spread.", "pellets": 3, "spread": 0.2, "range": 320.0, "damage": 3.6, "armor_pierce": true, "mass": 1.3},
		},
	},
	"longbore": {
		"name": "Long-Bore Cannon", "short": "LONGBORE", "role": "Precision / range", "limit": "Slow reload, demanding aim",
		"desc": "Fast, armor-piercing heavy rounds. Fires one shot per two barrels.",
		"mounts": ["broadside", "bow", "stern", "turret"], "pattern": "heavy", "armor_pierce": true,
		"damage": 22.0, "range": 780.0, "speed": 980.0, "reload": 2.6, "spread": 0.01, "radius": 6.0,
		"mass": 2.0, "power": 1.0, "recoil": 30.0, "color": Color(0.7, 0.9, 1.0),
		"marks": {
			"2": {"name": "Mk II", "desc": "Rifled bore: +18% damage.", "damage": 26.0, "mass": 2.2},
			"3": {"name": "Mk III Railbore", "desc": "Rounds punch through the first two targets and keep flying. Slower reload, more power.", "pierce": 2, "damage": 24.0, "reload": 3.0, "speed": 1150.0, "mass": 2.4, "power": 2.0},
		},
	},
	"harpoon": {
		"name": "Harpoon Battery", "short": "HARPOON", "role": "Tether / control", "limit": "Needs a hit, long cooldown",
		"desc": "A tethered harpoon that halves the target's speed and turning.",
		"mounts": ["broadside", "bow", "stern", "turret"], "pattern": "single", "status": "harpoon", "harpoon_time": 4.0,
		"damage": 6.0, "range": 420.0, "speed": 620.0, "reload": 4.0, "spread": 0.0, "radius": 5.0,
		"mass": 1.2, "power": 1.0, "recoil": 10.0, "color": Color(0.6, 1.0, 0.8),
		"marks": {
			"2": {"name": "Mk II", "desc": "Barbed line: longer tether, faster reload.", "harpoon_time": 5.5, "reload": 3.4, "mass": 1.3},
			"3": {"name": "Mk III Grapnel", "desc": "Reels light ships toward you for 3 s. Against heavy ships and bosses it hauls you in instead.", "status": "grapple", "harpoon_time": 3.0, "damage": 8.0, "reload": 4.2, "mass": 1.5},
		},
	},
	"torpedo": {
		"name": "Torpedo Tube", "short": "TORPEDO", "role": "Forward burst", "limit": "Long reload, can be outmaneuvered",
		"desc": "A slow, devastating armor-piercing torpedo that explodes on impact.",
		"mounts": ["bow", "stern"], "pattern": "torpedo", "armor_pierce": true, "blast": 60.0,
		"damage": 40.0, "range": 900.0, "speed": 300.0, "reload": 5.0, "spread": 0.0, "radius": 7.0,
		"mass": 1.8, "power": 1.0, "recoil": 8.0, "color": Color(0.5, 1.0, 0.9),
		"marks": {
			"2": {"name": "Mk II", "desc": "Shaped warhead: +20% damage.", "damage": 48.0, "mass": 2.0},
			"3": {"name": "Mk III Seeker", "desc": "A slower torpedo that curves toward the nearest enemy ahead of it.", "homing": 1.8, "speed": 260.0, "damage": 34.0, "reload": 5.4, "mass": 2.1},
		},
	},
	"mortar": {
		"name": "Mortar Rack", "short": "MORTAR", "role": "Area denial", "limit": "Delayed impact, poor against fast targets",
		"desc": "Lobs shells to a marked zone at long range. The blast hits every enemy inside.",
		"mounts": ["broadside", "bow", "stern"], "pattern": "mortar", "blast": 70.0, "delay": 1.0,
		"damage": 20.0, "range": 600.0, "speed": 0.0, "reload": 3.2, "spread": 0.0, "radius": 0.0,
		"mass": 2.5, "power": 1.0, "recoil": 22.0, "color": Color(1.0, 0.7, 0.4),
		"marks": {
			"2": {"name": "Mk II", "desc": "Heavier shells: wider blast.", "blast": 85.0, "mass": 2.7},
			"3": {"name": "Mk III Cluster Rack", "desc": "Each shell splits into three smaller blasts that blanket a much wider area.", "cluster": 3, "blast": 50.0, "damage": 11.0, "mass": 2.9},
		},
	},
	"arc": {
		"name": "Arc Projector", "short": "ARC", "role": "Chain / energy damage", "limit": "Low single-target damage, power hungry",
		"desc": "Instant lightning that jumps between clustered enemies inside its arc.",
		"mounts": ["broadside", "bow", "stern", "turret"], "pattern": "arc", "jumps": 2, "jump_range": 170.0, "arc": 0.75,
		"damage": 12.0, "range": 360.0, "speed": 0.0, "reload": 2.2, "spread": 0.0, "radius": 0.0,
		"mass": 0.6, "power": 3.0, "recoil": 0.0, "color": Color(0.6, 0.85, 1.0),
		"marks": {
			"2": {"name": "Mk II", "desc": "Capacitor bank: one more jump.", "jumps": 3, "mass": 0.7},
			"3": {"name": "Mk III Overload", "desc": "One heavy discharge with no jumps. Its damage counts double toward interrupting enemy attacks.", "jumps": 0, "damage": 28.0, "reload": 2.6, "overload": true, "power": 4.0, "mass": 0.8},
		},
	},
}

const MOUNT_FOR_SLOT := {"port": "broadside", "starboard": "broadside", "bow": "bow", "stern": "stern", "turret": "turret"}

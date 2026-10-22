extends RefCounted

const TOPICS := [
	{
		"id": "basics",
		"title": "Getting Started",
		"lines": [
			["The goal", "You captain one warship. Play Campaign stages, sink enemy fleets and finish each stage's objective."],
			["The loop", "Play a stage  >  earn Salvage and Research  >  upgrade your ship in the Harbor  >  take on harder stages."],
			["Where to start", "Press Play on the main menu. It always opens the next stage you have not cleared."],
			["Not sure about the controls?", "Play Training from this screen. It takes about three minutes and walks you through every key."],
			["You don't need everything at once", "New Harbor sections open as you clear stages, and each one explains itself the first time you open it."],
		],
	},
	{
		"id": "sailing",
		"title": "Sailing",
		"lines": [
			["Throttle", "[{throttle_up}] raises the throttle and [{throttle_down}] lowers it. The ship keeps that speed until you change it, so you don't have to hold the key."],
			["Steering", "[{turn_left}] / [{turn_right}] turn the ship. It is a heavy ship, so start your turns early."],
			["Braking", "Hold [{throttle_down}] while moving fast to brake hard."],
			["Drifting", "Hold [{drift}] while turning at speed to slide sideways. It is good for swinging your guns onto a target quickly."],
			["Wind", "The compass in the top right shows the wind. Sailing with the wind makes you faster; sailing into it makes you slower. The panel shows this as Tailwind or Headwind."],
			["Reefs and hazards", "Rocks block your ship and your shots. New hazards are always announced with a banner the first time they appear."],
		],
	},
	{
		"id": "shooting",
		"title": "Shooting",
		"lines": [
			["Your main guns point to the SIDES", "This is the most important rule. Your main cannons do not shoot forward. Turn the ship so the enemy is on your left or right, then fire."],
			["Left guns (Port)", "[{fire_port}] or the left mouse button fires the guns on the LEFT side of the ship."],
			["Right guns (Starboard)", "[{fire_starboard}] or the right mouse button fires the guns on the RIGHT side of the ship."],
			["Front and rear guns", "[{fire_bow}] fires the small Bow gun straight ahead. Some ships also have a Stern gun ([{fire_stern}]) that fires behind them."],
			["Turret", "Later you can research a Turret Ring. The turret ([{fire_turret}]) aims at the nearest enemy by itself."],
			["Firing arcs", "The coloured cones drawn around your ship show where each gun can hit. If an enemy is inside a cone, that gun will hit it."],
			["Reloading", "The cards at the bottom of the screen show each gun. A full bar means READY; after firing, it refills."],
		],
	},
	{
		"id": "wake",
		"title": "Wake (your combo meter)",
		"lines": [
			["What it is", "Wake is your combo meter, shown in the top right. It goes from 0 up to tier V."],
			["How to raise it", "Hit enemies, sink them, and dodge shots at close range. Each tier needs a bit more than the last."],
			["How you lose it", "Taking damage lowers it, and a heavy hit drops a whole tier. If you stop fighting for a few seconds, the bar starts to fade."],
			["Why it matters", "A higher Wake multiplies your score, improves your mission grade and powers some ship abilities. Higher grades pay more Salvage."],
			["Tip", "Stay aggressive but don't get hit. Circling an enemy and firing a broadside every time it lines up is the easiest way to build Wake."],
		],
	},
	{
		"id": "ability",
		"title": "Ability and Modules",
		"lines": [
			["Ship ability", "[{ability}] uses your ship's special ability. Each ship has its own; the Wayfarer's Quick Reload instantly reloads every gun."],
			["Utility modules", "[{module_1}] (and [{module_2}] on ships with two slots) uses a module, such as the Repair Drone, which heals your hull."],
			["Cooldowns", "The ability and module cards at the bottom of the screen show when they are ready again."],
		],
	},
	{
		"id": "screen",
		"title": "Reading the Screen",
		"lines": [
			["Top left", "Your Hull (health) and Salvage collected, then the stage's objective with its progress bar and any bonus goals."],
			["Top right", "Your Wake tier and the wind compass."],
			["Bottom", "One card per gun, plus your ability, modules and throttle."],
			["Edge arrows", "Red arrows at the screen edge point to enemies off screen. Gold arrows point to wrecks or special targets. A flashing red marker shows where enemies are about to arrive."],
			["Banners", "Big text in the middle of the screen introduces new enemies and hazards and explains how to beat them."],
			["Pause", "[{pause}] pauses the game. The pause screen repeats your objective and all your controls."],
		],
	},
	{
		"id": "missions",
		"title": "Stages and Grades",
		"lines": [
			["Objective", "Each stage has one main objective, such as sinking every wave, escorting a barge or salvaging wrecks. Complete it to clear the stage."],
			["Bonus goals", "Optional extra goals, such as finishing quickly or reaching a Wake tier. They are not required, but they raise your grade and give extra Research."],
			["Grade", "From D up to S. It depends on your remaining hull, bonus goals, highest Wake and time. A better grade pays more Salvage."],
			["Replays", "You can replay any cleared stage for more resources or to finish its bonus goals."],
			["Difficulty", "Choose it in the briefing. Higher difficulties pay more and unlock as you progress."],
			["Bosses", "Every region ends with a boss stage. Defeating it opens the next region."],
		],
	},
	{
		"id": "resources",
		"title": "Resources",
		"lines": [
			["Salvage (gold)", "The main currency. It builds new ships and Facilities and buys passive systems."],
			["Research (blue)", "Unlocks new weapons, weapon marks and utility modules in the Research tab."],
			["Intel (green)", "Rare. Earned from the first clear of some stages and from bosses. Used for advanced ships and Facilities."],
			["Mastery XP", "Every mission gives your ship mastery XP. Mastery levels add build slots, an alternate perk and cosmetics."],
		],
	},
	{
		"id": "harbor",
		"title": "The Harbor",
		"lines": [
			["Campaign", "Pick a region and a stage, then open its briefing and Launch."],
			["Fitting Dock", "Change your ship's loadout: which weapon goes on each side, plus modules and passive systems. Remember to press Save Build."],
			["Research", "Spend Research to unlock new weapons and modules. New items then appear in the Fitting Dock."],
			["Fleet", "See all ships, build new ones with Salvage, set your active ship and track mastery."],
			["Facilities", "One-time Harbor buildings that unlock extra features, such as the Weapons Lab for Mk II weapons."],
			["Contracts", "Small side tasks such as 'Sink 20 Gunboats' that pay out while you play any mode. Claim the reward when one is done."],
			["Operations", "Replayable side missions with random modifiers, good for farming resources."],
			["Sea Trials", "A free practice sea where you cannot sink. Use the number keys to spawn enemies and test your loadout."],
		],
	},
]

const TAB_HELP := {
	"campaign": ["Campaign", "Choose a stage and open its briefing. The highlighted card is your next stage.", [
		"Clear stages in order to open new ones.",
		"The last stage of each region is a boss. Beat it to open the next region.",
		"Replay cleared stages any time for more resources and better grades.",
	]],
	"fitting": ["Fitting Dock", "Choose which weapon goes on each side of your ship, plus modules and passives.", [
		"Each row is one gun position: Port = left side, Starboard = right side, Bow = front.",
		"Utility modules are active items with their own key. Passive systems are always on.",
		"Power and Mass are your limits. Stay under both bars.",
		"Press Save Build when you are happy. The preview on the left shows your firing arcs.",
	]],
	"research": ["Research", "Spend Research points to unlock new weapons and modules.", [
		"Research comes from clearing stages and finishing bonus goals.",
		"Unlocked weapons and modules appear in the Fitting Dock.",
		"Some items need a stage cleared or a Facility built first. The card tells you what is missing.",
	]],
	"fleet": ["Fleet", "Your ships. Build new hulls with Salvage and choose your active ship.", [
		"Every ship has its own ability, strengths and weaknesses.",
		"Blueprint ships can be built once you can afford them.",
		"Use Test Drive to try any ship in Sea Trials, even before you build it.",
	]],
	"facilities": ["Facilities", "One-time Harbor buildings that unlock extra features.", [
		"Each Facility is built once and helps you for the rest of the game.",
		"The Weapons Lab is the most important: it unlocks Mk II and Mk III weapons.",
	]],
	"contracts": ["Contracts", "Side tasks that complete while you play any mode.", [
		"Progress counts automatically. You don't need to pick anything.",
		"When a contract is done, press Claim to collect the reward. A new one replaces it.",
	]],
	"operations": ["Operations", "Replayable side missions with random modifiers.", [
		"Good for earning extra Salvage and Research between campaign stages.",
		"Each launch rolls a new layout and modifier. Modifiers can raise the rewards.",
		"Classic Run is a ten-wave score attack with a Shipyard between waves.",
	]],
}

const TAB_UNLOCK := {
	"campaign": "",
	"fitting": "r1s1",
	"research": "r1s2",
	"fleet": "r1s3",
	"operations": "r1s4",
	"facilities": "r1s5",
	"contracts": "r1s6",
}

extends RefCounted

const REGIONS := [
	{"id": 1, "name": "The Shattered Shoals", "stages": "1-10", "available": true, "theme": "Open water, reefs and wrecks. Where every captain learns the helm.", "pressure": "Movement and broadside positioning", "boss": "The Ironwake", "faction": "Shoal raiders", "deep": Color(0.010, 0.025, 0.060), "shallow": Color(0.028, 0.075, 0.140), "glint": Color(0.25, 0.70, 0.90)},
	{"id": 2, "name": "The Rusted Reach", "stages": "11-20", "available": true, "theme": "Industrial wreckage, mine lanes and armored patrols.", "pressure": "Armor, mines and defensive formations", "boss": "Dreadnought Kharon", "faction": "Rusted Reach Authority", "deep": Color(0.035, 0.025, 0.025), "shallow": Color(0.09, 0.06, 0.05), "glint": Color(0.9, 0.55, 0.3)},
	{"id": 3, "name": "The Tempest Belt", "stages": "21-30", "available": true, "theme": "Storm systems, currents, lightning and poor visibility.", "pressure": "Navigation and environmental control", "boss": "Storm Matriarch", "faction": "Tempest Cartographers", "deep": Color(0.02, 0.03, 0.05), "shallow": Color(0.06, 0.08, 0.12), "glint": Color(0.7, 0.8, 1.0)},
	{"id": 4, "name": "The Abyssal Trench", "stages": "31-40", "available": true, "theme": "Deep ocean, bioluminescent hazards and stealth hunters.", "pressure": "Ambushes, tracking and target identification", "boss": "The Leviathan Engine", "faction": "Abyssal Foundry", "deep": Color(0.0, 0.01, 0.03), "shallow": Color(0.01, 0.05, 0.08), "glint": Color(0.3, 1.0, 0.8)},
	{"id": 5, "name": "The Resonant Expanse", "stages": "41-50", "available": true, "theme": "Distorted water, Wake anomalies and elite mixed fleets.", "pressure": "Combined mechanics and build mastery", "boss": "The Resonant Sovereign", "faction": "Resonant Fleet", "deep": Color(0.03, 0.01, 0.05), "shallow": Color(0.08, 0.03, 0.12), "glint": Color(1.0, 0.4, 0.85)},
]

const REGION_STAGES := {
	1: ["r1s1", "r1s2", "r1s3", "r1s4", "r1s5", "r1s6", "r1s7", "r1s8", "r1s9", "r1s10"],
	2: ["r2s1", "r2s2", "r2s3", "r2s4", "r2s5", "r2s6", "r2s7", "r2s8", "r2s9", "r2s10"],
	3: ["r3s1", "r3s2", "r3s3", "r3s4", "r3s5", "r3s6", "r3s7", "r3s8", "r3s9", "r3s10"],
	4: ["r4s1", "r4s2", "r4s3", "r4s4", "r4s5", "r4s6", "r4s7", "r4s8", "r4s9", "r4s10"],
	5: ["r5s1", "r5s2", "r5s3", "r5s4", "r5s5", "r5s6", "r5s7", "r5s8", "r5s9", "r5s10"],
}

const PREMISE := "The ocean's Wake is more than the trail a ship leaves behind. Across five regions the water has begun to glow, ring and answer back - reacting to movement, cannon fire and the clash of fleets. You command a prototype warship from a remote Harbor of the Harbor Compact, investigating the cause while recovering lost technology and confronting the fleets that exploit the phenomenon."

const FACTIONS := [
	{"name": "Harbor Compact", "desc": "Your home network of free harbors. Repairs, research and contracts."},
	{"name": "Rusted Reach Authority", "desc": "Industrial fleets that value armor, artillery and territory."},
	{"name": "Tempest Cartographers", "desc": "Navigators who study storms - and have learned to weaponize them."},
	{"name": "Abyssal Foundry", "desc": "A hidden force behind the mechanical threats in the deep trench."},
	{"name": "Resonant Fleet", "desc": "A faction altered by, or aligned with, the Wake phenomenon."},
]

const LORE_ORDER := ["lore_wake", "lore_wreckers", "lore_compact", "lore_tidewrights", "lore_ironwake", "lore_reach", "lore_authority", "lore_platforms", "lore_kharon", "lore_belt", "lore_cartographers", "lore_lanes", "lore_matriarch", "lore_trench", "lore_archive", "lore_devourer", "lore_engine", "lore_expanse", "lore_mirror", "lore_long_hunt", "lore_sovereign"]

const LORE := {
	"lore_wake": {"title": "The Glowing Wake", "text": "Harbor logs from the last two years mention the same thing: wakes that keep glowing after a ship has passed, and grow brighter during battle. Old sailors call it 'the sea keeping score'."},
	"lore_wreckers": {"title": "Stripped Hulls", "text": "The wrecks in the Shoals were not lost to storms. Their iron plating was cut away with precision tools and loaded onto couriers. Someone is building something heavy."},
	"lore_compact": {"title": "The Harbor Compact", "text": "Seven free harbors that agreed to share repairs, charts and research. Your Harbor is the smallest and the farthest out - which is exactly why the Compact sent its prototype there."},
	"lore_tidewrights": {"title": "The Tidewrights", "text": "A family of shipwrights who sail their yard from place to place on barges. They designed the Bulwark for a war that never came. It came."},
	"lore_ironwake": {"title": "The Ironwake's Log", "text": "Recovered from the flagship: 'The plating hums when the wake is bright. The deeper we sail toward the Reach, the louder it sings. Kharon will pay for every ton.'"},
	"lore_reach": {"title": "The Rusted Reach", "text": "Once the busiest foundry coast in the world. When the Wake began to glow, the foundries found that iron cast near bright water came out harder - and stranger. Then they stopped selling it."},
	"lore_authority": {"title": "The Authority Ledgers", "text": "Convoy ledgers list every ton of stripped iron and one buyer: Dreadnought Kharon. Margin notes complain that the cargo 'hums at night' and that the crews refuse to sleep below decks."},
	"lore_platforms": {"title": "Gun Platforms", "text": "The siege platforms are cast in one piece from Reach iron. Salvage crews report that a sunk platform keeps ringing for hours, like a struck bell under water."},
	"lore_belt": {"title": "The Tempest Belt", "text": "A ring of permanent storms that sailors once crossed only in summer. Since the Wake began to glow, the storms no longer move with the seasons. They move with the fleets."},
	"lore_cartographers": {"title": "The Cartographers", "text": "The Tempest Cartographers chart storms the way other navies chart reefs. Their newest charts are not maps of where the weather is - they are orders for where it should go."},
	"lore_lanes": {"title": "Lightning Lanes", "text": "Cartographer logs describe 'lanes' of lightning laid across the sea like streets. Every lane plan leaves one route open. They call it the courtesy - nobody remembers who they are being courteous to."},
	"lore_matriarch": {"title": "The Matriarch's Log", "text": "'The Wake answers louder past the Belt. Below the storms the water is dark and something down there sings back. The Foundry has gone quiet. We will not sail deeper.'"},
	"lore_trench": {"title": "The Abyssal Trench", "text": "Below the storms the sea floor falls away into a trench no chart has a bottom for. The water glows here without any Wake at all - as if something below is lighting it from underneath."},
	"lore_archive": {"title": "The Drowned Archive", "text": "The archive wrecks carried Foundry records: hull numbers, engine schematics, and one word stamped on every page - LEVIATHAN. The engine was not built to sail. It was built to listen."},
	"lore_devourer": {"title": "The Devourer", "text": "The Devourer is not one ship. Foundry logs list four hulls with that name, each lost, each replaced. The crews never change. Nobody aboard has aged since the trench began to glow."},
	"lore_engine": {"title": "The Leviathan Engine", "text": "Its core was a resonator the size of a cathedral, tuned to the Wake. Its final log: 'Signal confirmed beyond the trench. Source: the Resonant Expanse. It is not answering us. It is calling.'"},
	"lore_expanse": {"title": "The Resonant Expanse", "text": "Here the sea does not glow - it rings. Every hull that crosses it hums a note, and the Expanse answers in harmony. Ships that have been here too long move like the water: all at once, all in time."},
	"lore_mirror": {"title": "The Mirror Fleet", "text": "The Resonant Fleet learns. Its captains copy the way you sail, the way you turn, the way you fire. They are not mocking you. They are listening to the Wake you leave behind and singing it back."},
	"lore_long_hunt": {"title": "The Long Shadow", "text": "The Long Shadow's log is one sentence, written thousands of times: 'It is calling the fleets home.' The handwriting changes every few pages. The ship never did."},
	"lore_sovereign": {"title": "The Sovereign's Answer", "text": "The Sovereign was the first ship ever to answer the Wake - and it never stopped. With it silenced, the sea still glows, but quietly, the way it did for sailors long ago: the sea keeping score, and nothing more."},
	"lore_kharon": {"title": "Kharon's Keel", "text": "Kharon's keel was not built - it was grown, layer by layer, in bright water. The Authority's last log entry: 'The Tempest Belt answers when Kharon sings. We are not the only ones listening.'"},
}

const TACTICS := [
	{"title": "Crossing the T", "text": "Hit a ship from its blind arc - bow or stern for broadside ships, stern for bow-gunned ships - for +25% damage and bonus Wake."},
	{"title": "Interrupts", "text": "Enough damage during an enemy's windup cancels the attack. Each interrupt builds Wake and buys time."},
	{"title": "Weak points", "text": "Armor-piercing weapons ignore armor. Target Scanner exposes weak points so every hit lands 20% harder."},
	{"title": "Fireship baiting", "text": "A fireship sunk inside an enemy formation burns its own fleet."},
	{"title": "Drift passes", "text": "Hold drift while turning past an enemy at speed to slide your broadside across it and build Wake."},
	{"title": "Breaking screens", "text": "Shield Tenders cut damage to nearby ships by 60%. Sink the tender, or drag its escorts out of its 230 px range."},
	{"title": "Reading mortars", "text": "Mortar rings land where you were heading. Turn hard once they lock, and close inside 260 range - monitors cannot fire up close."},
	{"title": "Using enemy mines", "text": "Layer mines ignore enemy ships, but their blasts do not. Shoot a mine when enemies drift past it."},
	{"title": "Lightning lanes", "text": "Lightning markers always leave one lane open. Read the gap before the strike and steer into it."},
	{"title": "Breaking tethers", "text": "A harpoon tether halves your turning. Open 560 px of distance, or use Flak Burst or Shock Pulse to cut the line."},
	{"title": "Sniper lines", "text": "A Longbow Sloop's red line tracks you, then locks. Turn the moment it locks - the shot flies straight down the line."},
	{"title": "Hunting ghosts", "text": "A Ghost Runner pings while hidden. Glow blooms, Target Scanner and Sonar Pulse reveal it; strike in the 3 s after it attacks."},
	{"title": "Sensor jamming", "text": "While a Jammer Vessel is close, edge markers lie and the turret cannot lock. Use your eyes, then sink the jammer."},
	{"title": "Pressure vents", "text": "Vents rumble, ring, then erupt. Leave the ring before it fills - the blast throws ships aside."},
	{"title": "Resonance rifts", "text": "Rifts flare in a steady rhythm. A pulse drains your Wake and hurts - cross while the rift is quiet."},
	{"title": "Resonant enemies", "text": "Resonant ships grow fiercer as your Wake rises, but each one you sink feeds your Wake. Strike them first when your tier is low."},
	{"title": "Turret ring", "text": "The turret tracks the nearest enemy in a wide forward arc. Fire it while your broadsides reload."},
]

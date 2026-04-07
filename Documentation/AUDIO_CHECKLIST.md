# 🎵 Fantasy World — Complete Audio Checklist

> A full production checklist of every sound effect, character audio, and music track needed for the final release of the game.
> Use this document to track sourcing, recording, and integration progress.
>
> **Legend**: `- [ ]` = Not yet sourced/done · `- [x]` = Completed

---

## Table of Contents

1. [🎼 Music Tracks](#-music-tracks)
2. [🖱️ UI/UX Sounds — Menu Navigation](#️-uiux-sounds--menu-navigation)
3. [🃏 UI/UX Sounds — Deck Selection](#-uiux-sounds--deck-selection)
4. [🎲 UI/UX Sounds — Dice Roll](#-uiux-sounds--dice-roll)
5. [🖥️ UI/UX Sounds — In-Game HUD](#️-uiux-sounds--in-game-hud)
6. [🗺️ UI/UX Sounds — Hex Board Interaction](#️-uiux-sounds--hex-board-interaction)
7. [⚔️ UI/UX Sounds — Combat Selection Phase](#️-uiux-sounds--combat-selection-phase)
8. [💥 UI/UX Sounds — Combat Resolution](#-uiux-sounds--combat-resolution)
9. [💰 UI/UX Sounds — Economy](#-uiux-sounds--economy)
10. [👺 UI/UX Sounds — NPC Encounters & Items](#-uiux-sounds--npc-encounters--items)
11. [🔔 UI/UX Sounds — Notifications & Toasts](#-uiux-sounds--notifications--toasts)
12. [🏆 UI/UX Sounds — End of Match](#-uiux-sounds--end-of-match)
13. [🌐 UI/UX Sounds — Multiplayer & Connection](#-uiux-sounds--multiplayer--connection)
14. [🌿 Ambient Sounds — Per Biome](#-ambient-sounds--per-biome)
15. [⚔️ Character Sounds — 12 Troops](#️-character-sounds--12-troops)
16. [👺 Character Sounds — 3 NPCs](#-character-sounds--3-npcs)

---

## 🎼 Music Tracks

> All tracks should be in OGG Vorbis format, 44.1 kHz. Looping tracks need seamless loop points.

- [ ] **Main Menu Theme** — Epic orchestral piece that builds tension slowly; conveys grandeur and fantasy world without being overwhelming. ~2–3 min, loops seamlessly.
- [ ] **Deck Selection Theme** — Mysterious and anticipatory; quieter than the main menu, with a sense of deliberation and strategy. ~1–2 min, loops.
- [ ] **Gameplay — Calm Variant** — Medieval ambiance with lute, strings, and light percussion; for turns without active combat. ~3–4 min, loops.
- [ ] **Gameplay — Tense Variant** — Layers drums and tension strings over the calm variant; triggers when combat is likely or timer is low. ~2–3 min, loops.
- [ ] **Combat Theme** — Fast-paced, intense orchestral burst; plays during the combat selection and resolution phase. ~1–2 min, loops.
- [ ] **Victory Fanfare** — Triumphant brass-led resolution; short and celebratory, not overbearing. ~30 sec, no loop.
- [ ] **Defeat Theme** — Slow descending strings with a muted horn; somber and dignified, not punishing. ~30 sec, no loop.
- [ ] **Tutorial Background Music** — Soft, instructional underscore; gentle and non-distracting to keep teaching moments clear. ~2 min, loops.

---

## 🖱️ UI/UX Sounds — Menu Navigation

> Shared across all menus (main menu, settings, archives, etc.)

- [ ] **Button Hover** — Faint dry paper-tap or soft wooden thud; like a finger brushing parchment. Fires on mouse-enter.
- [ ] **Button Click / Confirm** — Decisive single knock, like a chess piece placed down; satisfying but not heavy.

---

## 🃏 UI/UX Sounds — Deck Selection

> Fired during the 30-second simultaneous deck selection phase.

- [ ] **Card Hover** — Soft shimmer; a high-pitched single chime like a crystal tapped lightly.
- [ ] **Card Select** — Heavier, resonant chime with a quick magical tail; the card locking into place.
- [ ] **Card Deselect** — Reversed card-select sound; slightly hollow, like the card being pulled back.
- [ ] **Invalid Selection** — Brief descending two-tone buzz; medieval-flavored error, not digital.
- [ ] **Selection Timer Tick (last 10s)** — Quiet ticking like an antique pocket watch; escalates in volume only, no pitch shift.
- [ ] **Selection Complete (both players confirmed)** — Rising three-note ascending chime; done and anticipatory, like a tournament horn prep.

---

## 🎲 UI/UX Sounds — Dice Roll

> Fired during the first-move dice roll and all in-combat dice rolls.

- [ ] **Throw Button Pressed** — Hand-release whoosh; the dice leaving the grip with a quick air puff.
- [ ] **Dice Tumbling** — Rapid irregular clacking on a hard wood surface; like real dice rolling across a tavern table.
- [ ] **Dice Settle / Stop** — Final sharp clack followed by ~0.5s of wobble decay; comes to rest naturally.
- [ ] **Tie / Re-Roll** — Low, unresolved musical sting; then transitions back to the throw sound.
- [ ] **Winner Declared (first-move roll)** — Single triumphant low horn note; short and weighty, not yet celebratory.

---

## 🖥️ UI/UX Sounds — In-Game HUD

> General HUD feedback that plays during gameplay turns.

- [ ] **Troop Card Select (from hand)** — Leather and parchment crinkle; dry and tactile, like pulling a card from a leather pouch.
- [ ] **Turn Start** — Soft but clear bell toll; single mid-range note that signals ownership of the board.
- [ ] **Turn End** — Low descending chime; a closing tone, the opposite of turn start.
- [ ] **Timer Warning — 60s** — First subtle pulse beat; barely noticeable, just a gentle reminder.
- [ ] **Timer Warning — 30s** — Moderate ticking begins; slightly faster heartbeat rhythm.
- [ ] **Timer Warning — 10s** — Urgent fast ticking; tempo doubles with a slight pitch rise — urgency without panic.
- [ ] **Timer Expired** — Flat decisive buzzer-like drone; short, firm, no drama.
- [ ] **Invalid Action** — Muted hollow thud paired with the UI shake; like knocking on a locked wooden door.
- [ ] **Tooltip Appear** — Near-silent, very faint high tick; optional and nearly imperceptible.

---

## 🗺️ UI/UX Sounds — Hex Board Interaction

> Fired when interacting with hexagonal tiles on the game board.

- [ ] **Tile Hover** — Very soft stone-on-stone brush; subtle grit, a tile being touched but not stepped on.
- [ ] **Tile Confirm (Move)** — Clean stone step; a boots-on-flagstone footfall — grounded and satisfying.
- [ ] **Move Range Highlight On** — Soft wave of subtle chimes spreading outward; like ripples in still water.
- [ ] **Attack Range Highlight On** — Low tension chord, like a bowstring drawing back; held briefly then fades.
- [ ] **Hex Out of Range / Blocked** — Same as invalid action: muted hollow thud.

---

## ⚔️ UI/UX Sounds — Combat Selection Phase

> The 10-second simultaneous move/stance selection window.

- [ ] **Combat Phase Begins** — Dramatic sword-ring; like two blades meeting briefly, quick and sharp.
- [ ] **Move Button Hover** — Faint weapon-specific resonance; a hum or creak depending on the troop type.
- [ ] **Move Selected** — Firm decisive weapon-lock click; like a hilt snapping into a grip.
- [ ] **Move On Cooldown (blocked)** — Dull thud with a chain-rattle tail; unavailable, with the cost feeling real.
- [ ] **Stance Hover** — Quiet armor shift; a slight metallic whisper.
- [ ] **Stance Selected — Brace** — Shield-thud impact; solid and defensive.
- [ ] **Stance Selected — Dodge** — Light foot pivot; quick, airy, mobile.
- [ ] **Stance Selected — Counter** — Blade draw; crisp, deliberate, threatening.
- [ ] **Stance Selected — Endure** — Deep breath inhale; a steeling-oneself sound, heavy resolve.
- [ ] **Selection Timer Tick (last 5s)** — Tension-building heartbeat; slower than the turn timer but more dramatic.
- [ ] **Both Selections Locked In** — Quick dual-click; both sides confirmed, a brief beat of silence before the dice roll.

---

## 💥 UI/UX Sounds — Combat Resolution

> Fired during the reveal and calculation of combat outcomes.

- [ ] **Hit (Normal)** — Solid weapon-on-armor impact; meaty thud, defined by troop type at a generic level.
- [ ] **Miss / Dodge** — Quick air-cut whoosh with no impact; the weapon passing through empty space.
- [ ] **Critical Hit (Natural 18–20)** — Explosive crack; the kind of hit that shakes the table, paired with screen-flash.
- [ ] **Critical Miss (Natural 1)** — Stumble-clatter; weapon dropping or footing lost, almost comedic in weight.
- [ ] **Counter Attack Triggered** — Sharp reversal riposte; faster and tighter than a normal hit.
- [ ] **Endure Triggered** — Heavy impact almost breaking through; desperate crunch followed by a gasping hold.
- [ ] **Status Effect — Stunned Applied** — Electric zap; sharp and immediate.
- [ ] **Status Effect — Burned Applied** — Crackling hiss; ignition and heat.
- [ ] **Status Effect — Poisoned Applied** — Wet gurgle; thick and unpleasant.
- [ ] **Status Effect — Slowed Applied** — Deep thud; like sinking into mud.
- [ ] **Status Effect — Cursed Applied** — Hollow dark whisper; unsettling and ominous.
- [ ] **Status Effect — Terrified Applied** — Sharp shriek; sudden and frightening.
- [ ] **Status Effect — Rooted Applied** — Vines snapping shut; rapid organic crunch.
- [ ] **Status Effect — Stealth Applied** — Shadow whoosh; quiet and elusive.
- [ ] **Status Effect Tick (per turn)** — Shorter quieter version of the apply sound; a reminder, not a full re-trigger.
- [ ] **Status Effect Expires** — Light dissipating tone; a pop or fade, relief-coded.
- [ ] **Heal Number Appears** — Soft ascending chime with warm resonance; clearly distinct from damage numbers.
- [ ] **Type Super Effective** — Resonant swell under the hit sound; the impact rings longer like a tuned bell struck correctly.
- [ ] **Type Not Very Effective** — Duller, shorter hit; like striking stone, energy absorbed rather than transmitted.
- [ ] **Type Immune** — Complete deflection dome sound; the attack passing harmlessly with a hollow ring.

---

## 💰 UI/UX Sounds — Economy

> Fired for gold, XP, mine placement, and upgrade events.

- [ ] **Gold Received (Passive / Per Turn)** — Soft coins landing on a pile; two or three coins, not a cascade, understated.
- [ ] **Gold Received (Bounty / Loot Reward)** — Fuller coin cascade; more coins, a brief ringing jingle, more celebratory.
- [ ] **Not Enough Gold** — Single hollow clink on an empty pouch; the "well is dry" feeling.
- [ ] **Gold Mine Placed** — Construction hammer strike followed by a satisfying wood-thud settle.
- [ ] **Gold Mine Upgraded** — Rising mechanical clunk; gears engaging, something upgrading in place.
- [ ] **Gold Mine Destroyed** — Wooden crunch and structural collapse; followed by a brief dust-settle.
- [ ] **Troop Upgrade (Level Up)** — Ascending three-note chime with armor-clank punctuation; leveling up feels earned.
- [ ] **XP Gained** — Single soft crystalline ping; lighter than gold, high-register and brief.
- [ ] **Max Level Reached (Level 5)** — Full ascending chord that resolves; final and definitive, no more upgrades available.

---

## 👺 UI/UX Sounds — NPC Encounters & Items

> Fired during NPC spawn events, loot drops, and item usage.

- [ ] **NPC Spawn** — Sudden rustling appearance sound; like something stepping out of bushes, alert-coded.
- [ ] **Item Dropped (Loot)** — Object hitting the floor; a thud with a brief ring depending on item type.
- [ ] **Item Picked Up** — Quick collect chime; satisfying, fast, pocketable feeling.
- [ ] **Inventory Full (3/3 Items)** — Low firm rejection knock; space taken, no room but not harsh.
- [ ] **Item Used — Speed Potion** — Liquid gurgle followed by a rush whoosh; drinking and the speed effect kicking in.
- [ ] **Item Used — Whetstone** — Blade being scraped along a whetstone; sharp, purposeful.
- [ ] **Item Used — Phoenix Feather** — Fire crackling to life; ignition and warmth, resurrection energy.

---

## 🔔 UI/UX Sounds — Notifications & Toasts

> Short feedback sounds paired with the toast notification system.

- [ ] **Toast Appear (Neutral)** — Short clean pop; like a notification card being placed on a table.
- [ ] **First Blood Bounty** — Sharp horn burst; quick and triumphant, almost a miniature war-horn.
- [ ] **Kill Streak Bounty** — Escalating version of the horn; each new streak pitches the sound slightly higher.
- [ ] **Revenge Kill Bounty** — Dramatic resolution chord; the "justified" feeling, emotionally satisfying.
- [ ] **Mine Raider Bounty** — Coin burst + crash hybrid; the feeling of stealing and destroying simultaneously.
- [ ] **Enemy Troop Eliminated (Toast)** — No dedicated toast sound; the troop's own death SFX handles this moment.

---

## 🏆 UI/UX Sounds — End of Match

> Fired on the game-over overlay and post-match screen.

- [ ] **Victory Sting** — Full triumphant fanfare; brass-led, resolving upward, 5–8 seconds with a loopable tail.
- [ ] **Defeat Sting** — Slow descending strings with a muted horn; somber, dignified, not punishing.
- [ ] **Draw / Tie** — Unresolved chord that hangs; neither victory nor defeat, ambiguous and slowly fading.
- [ ] **Stat Card Appear** — Quiet paper-unfurl or scroll-unroll; each stat line appearing has a faint tick.
- [ ] **Rematch Confirm** — Same as Deck Selection Complete: rising three-note ascending chime, eager and ready.

---

## 🌐 UI/UX Sounds — Multiplayer & Connection

> Fired during lobby events, room codes, and disconnection handling.

- [ ] **Player Connected / Joined Lobby** — Warm two-note arrival chime; welcoming, a door-opening feeling.
- [ ] **Player Disconnected** — Low single note that drops off; like a candle extinguishing.
- [ ] **Reconnect Countdown Tick** — Slow heartbeat pulse; patient but present, counting the 3-minute window.
- [ ] **Reconnection Successful** — Short relief chime; same as connected but preceded by a brief tension beat.
- [ ] **Room Code Copied** — Quick wax-seal-press sound; stamping a document, old-world copy confirmation.

---

## 🌿 Ambient Sounds — Per Biome

> Looping ambient audio layers that play softly over gameplay music based on which biome the camera is low hover over.

- [ ] **Enchanted Forest** — Chirping birds, rustling canopy leaves, and an underlying magical hum; living and alive.
- [ ] **Frozen Peaks** — Howling mountain wind with intermittent ice cracking; cold, exposed, and isolating.
- [ ] **Desolate Wastes** — Dry gusting wind, distant distant rumble of thunder; vast and empty.
- [ ] **Golden Plains** — Gentle warm breeze and crickets at dusk; peaceful, pastoral, calm.
- [ ] **Ashlands** — Crackling embers, distant volcanic rumble, and falling ash; hostile and burning.
- [ ] **Highlands** — Strong wind gusts and occasional eagle cries in the distance; majestic and open.
- [ ] **Swamplands** — Frogs croaking, bubbling mud, and dense insect chorus; murky and thick.

---

## ⚔️ Character Sounds — 12 Troops

> Each troop needs 5 distinct sound sets: **Move**, **Attack**, **Damage Received**, **Death**, and **Special Ability**.

---

### 🛡️ Medieval Knight

- [ ] **Move** — Heavy metal armor clanking with each step; footfalls on stone, shield jostling.
- [ ] **Attack** — Sword slash through air followed by a shield bash impact; decisive and disciplined.
- [ ] **Damage Received** — Metal impact grunt; armor denting, a pained but controlled reaction.
- [ ] **Death** — Full armor collapse; sword clattering on stone, a final heavy thud.
- [ ] **Special (Shield Block)** — Resounding metallic clang; a powerful parry that rings through the air.

---

### 🪨 Stone Giant

- [ ] **Move** — Massive heavy thuds with each step; the ground shaking subtly underfoot.
- [ ] **Attack** — Boulder smash and earth rumble; massive blunt force impact with debris scatter.
- [ ] **Damage Received** — Rock crack; deep stress fracture sound, like stone splitting under pressure.
- [ ] **Death** — Full crumble and collapse; rocks and boulders cascading down in a long settling fall.
- [ ] **Special (Ground Slam)** — Earthquake-level shockwave impact; reverberating bass thud that echoes outward.

---

### 🐍 Four-Headed Hydra

- [ ] **Move** — Wet slithering across terrain with multiple simultaneous hisses; chaotic and unsettling.
- [ ] **Attack** — Multi-bite snaps from different heads, with an acidic spit sound; overlapping and relentless.
- [ ] **Damage Received** — High-pitched screech from one or more heads; pain multiplied and layered.
- [ ] **Death** — Writhing and thrashing collapse; all heads hissing, fading to a final long exhale.
- [ ] **Special (Multi-Strike / Regeneration)** — Wet growth sound; organic stretching and flesh reforming.

---

### 🐉 Dark Blood Dragon

- [ ] **Move** — Massive wing flaps with a deep bass growl; the air displacement is felt as much as heard.
- [ ] **Attack** — Fire breath roar; a building ignition followed by a sustained flame and claw swipe impact.
- [ ] **Damage Received** — Loud roar of pain; defiant, angry, not weakened-sounding.
- [ ] **Death** — Crash landing; massive body impact on the ground, followed by a long dying roar that fades.
- [ ] **Special (Inferno)** — Explosive fire burst; a contained explosion of flame with a massive pressure wave.

---

### 🌪️ Sky Serpent

- [ ] **Move** — Wind whoosh with an ethereal harmonic hum; moving like a current of air.
- [ ] **Attack** — Lightning crackle building to a discharge; followed by a whip-crack tail strike.
- [ ] **Damage Received** — High-pitched crystalline cry; sharp and clear, like breaking glass in the wind.
- [ ] **Death** — The body fading into the wind; a long dissolving exhale that becomes indistinguishable from wind.
- [ ] **Special (Storm Surge)** — Rolling thunder with a sharp lightning strike; pressure and electricity.

---

### ❄️ Frost Valkyrie

- [ ] **Move** — Rhythmic wingbeats with a faint chime of ice crystals catching in the air.
- [ ] **Attack** — Ice lance throw (a frozen shard cutting the air) followed by a sword swing impact.
- [ ] **Damage Received** — Ice shatter grunt; like a frozen shell partially breaking, cold and sharp.
- [ ] **Death** — Feathers scattering on the wind and a freeze-crack; the body crystallizing before falling.
- [ ] **Special (Blizzard)** — Howling blizzard wind; sustained, biting cold, frost and ice pellets.

---

### 🧙 Dark Magic Wizard

- [ ] **Move** — Robes rustling softly with the tap of a staff on stone; quiet, measured, deliberate.
- [ ] **Attack** — Dark energy blast charge-up followed by a muffled magical impact; spell chanting undertone.
- [ ] **Damage Received** — Magical disruption; a distorted, destabilized sound, like a spell being interrupted.
- [ ] **Death** — Dark implosion; the wizard collapsing inward in a void, followed by a faint echo of soul escaping.
- [ ] **Special (Curse Cast)** — Ominous whispering chant; low, hollow, and deeply unsettling.

---

### 😈 Demon of Darkness

- [ ] **Move** — Heavy hooves on stone with background crackling flames; an infernal presence announced.
- [ ] **Attack** — Dark flames igniting followed by a demonic roar; powerful and terrifying.
- [ ] **Damage Received** — An angry guttural growl; pain expressed as fury, not weakness.
- [ ] **Death** — Banishment scream followed by a void-pull; sucked back into darkness with swirling force.
- [ ] **Special (Hellfire)** — Infernal explosion; a deep demonic boom with fire rushing outward.

---

### 🏹 Elven Archer

- [ ] **Move** — Light footsteps, nearly silent, with the faint rustle of a quiver; agile and quiet.
- [ ] **Attack** — Deliberate bow draw with the creak of tension, then arrow whistle through the air on release.
- [ ] **Damage Received** — Light, surprised grunt; minimal vocalization, more a breath reaction.
- [ ] **Death** — Arrow clatter on the ground and a soft, graceful fall; dignified and quiet.
- [ ] **Special (Precision Shot)** — Slow-motion sound design; a super-tense draw and release with an impact echo.

---

### ✨ Celestial Cleric

- [ ] **Move** — Soft footsteps accompanied by a gentle holy chime; each step graced with divine warmth.
- [ ] **Attack** — Staff glow building to a pulse, followed by a divine beam strike; radiant and clean.
- [ ] **Damage Received** — Holy shield absorb; a deflection shimmer followed by a muted impact behind the barrier.
- [ ] **Death** — A peaceful exhale followed by a gentle ascending light; not tragic, almost serene.
- [ ] **Special (Mass Heal)** — A choir swell with a warm resonant pulse; healing energy radiating outward.

---

### 🗡️ Shadow Assassin

- [ ] **Move** — Near-silent; barely a whisper of cloth, perhaps a single soft step betraying presence.
- [ ] **Attack** — Rapid dagger slice through air followed by a close backstab plunge and soft exhale.
- [ ] **Damage Received** — Muffled grunt; contained and professional, the assassin barely reacting.
- [ ] **Death** — Shadow dissipating; a soft dark whoosh as the body becomes smoke and fades.
- [ ] **Special (Stealth Activation)** — Shadow whisper; a near-silent cloaking sound, the world going quiet.

---

### 🔥 Infernal Soul

- [ ] **Move** — Constant crackling embers and a rapid imp-like chittering; small but volatile.
- [ ] **Attack** — A fire bolt launching with an imp's loud shriek; chaotic and frenzied.
- [ ] **Damage Received** — High-pitched yelp; small and immediate, like a creature caught off guard.
- [ ] **Death** — Small explosion; the imp detonating in a burst of fire, then nothing remains.
- [ ] **Special (Soul Burn / Death Burst)** — Demonic laugh building into a short explosion; nihilistic and reckless.

---

## 👺 Character Sounds — 3 NPCs

> Each NPC needs 5 distinct sound sets: **Move**, **Attack**, **Damage Received**, **Death**, and **Loot Drop**.

---

### 🟢 Goblin

- [ ] **Move** — Scurrying feet and a continuous snickering; small, erratic, and cheeky.
- [ ] **Attack** — Club bonk on impact paired with a goblin battle yell; crude and unrefined.
- [ ] **Damage Received** — High-pitched squeal; disproportionate to the actual damage, dramatic.
- [ ] **Death** — A defeated whimper that trails off; pathetic and almost funny.
- [ ] **Loot Drop** — Gold coins scattering and bouncing; a brief jingle as the small reward hits the floor.

---

### 🪓 Orc

- [ ] **Move** — Heavy leather boots and a low grunt with each step; purposeful and menacing.
- [ ] **Attack** — Axe whoosh through the air followed by a war cry on impact; savage and loud.
- [ ] **Damage Received** — Angry roar; the orc responds to pain with aggression, not backing down.
- [ ] **Death** — A thunderous death bellow that echoes; a warrior's end, loud and unashamed.
- [ ] **Loot Drop** — Heavy armor pieces dropping; metallic clatter mixed with a coin drop.

---

### 🌲 Troll

- [ ] **Move** — Ground-shaking heavy lumber; the earth trembling slightly with each massive step.
- [ ] **Attack** — Tree trunk swing and deep bellow on strike; primitive and overwhelming in force.
- [ ] **Damage Received** — A stone crack and confused grunt; the troll registering damage slowly.
- [ ] **Death** — Massive collapse and an earthquake thud; the ground shaking as the troll falls.
- [ ] **Loot Drop** — A treasure reveal shimmer with heavy objects tumbling; the best loot reward sound.

---

*Last updated: 2026-04-05 — All entries pending sourcing unless marked complete.*

# 🎮 Combat System Guide

## Overview

Combat in Fantasy World uses a **D&D × Pokémon hybrid system** that combines dice-based attack rolls with type effectiveness and unique moves for each troop.

---

## ⚔️ How Combat Works

### 1. Initiating Combat
When you attack an enemy troop:
- **You (Attacker)** choose a **Move** from your 4 available moves
- **Opponent (Defender)** chooses a **Defensive Stance**
- Both choices are made simultaneously with a **10-second timer**
- Choices are revealed, dice are rolled, and damage is calculated

### 2. Attack Resolution
```
Your Attack Roll = d20 + ATK stat + Accuracy Modifier + Position Bonuses
Enemy Defense DC = 10 + DEF stat + Stance Bonus + Position Bonuses

If Attack Roll > Defense DC → HIT!
If Attack Roll ≤ Defense DC → MISS!
```

### 3. Critical Hits & Misses
- **Natural 18-20**: Critical Hit! Double damage!
- **Natural 1**: Critical Miss! Automatic miss!

---

## 🗡️ Move Types

Each troop has **4 unique moves**:

| Type | Power | Accuracy | Cooldown | Best For |
|------|-------|----------|----------|----------|
| **Standard** | 100% | +0 | None | Reliable damage every turn |
| **Power** | 150% | -3 | 3 turns | Big damage, risky accuracy |
| **Precision** | 80% | +5 | 2 turns | Guaranteed hits on tough targets |
| **Special** | 120% | +0 | 4 turns | Effects + good damage |

### Move Cooldowns
After using a move with a cooldown, you must wait that many turns before using it again. Standard moves have no cooldown!

---

## 🌈 Damage Types

Moves deal different types of damage:

| Type | Icon | Strong Against | Weak Against |
|------|------|----------------|--------------|
| **Physical** | ⚔️ | Varies | CONSTRUCT |
| **Fire** | 🔥 | UNDEAD, NATURE | ELEMENTAL |
| **Ice** | ❄️ | BEAST, NATURE | ELEMENTAL |
| **Dark** | 🌑 | SPIRIT | HOLY |
| **Holy** | ✨ | UNDEAD, DARK | None |
| **Nature** | 🌿 | BEAST | UNDEAD |

### Type Effectiveness
- **Super Effective**: Deal **1.5x** damage! 💥
- **Not Very Effective**: Deal **0.5x** damage... 
- **Immune**: Deal **0** damage! 🛡️

---

## 🛡️ Defensive Stances

When being attacked, choose how to defend:

### Brace 🛡️
- **+3 DEF bonus** to your Defense DC
- **Take 20% less damage** if hit
- *Best for*: Tanking hits when you expect to get hit

### Dodge ⚡
- **+5 Evasion** to your Defense DC  
- No damage reduction if hit
- *Best for*: Against low-accuracy Power moves

### Counter ↩️
- No defensive bonus
- If enemy **misses**, deal **50% of your ATK** back to them!
- *Best for*: Against precision attacks you think will miss

### Endure 💪
- No defensive bonus
- If damage would kill you, **survive at 1 HP**!
- **Once per combat** - use wisely!
- *Best for*: Clutch survival when you'd die otherwise

---

## 📍 Positioning Bonuses

Your position on the battlefield matters!

### Flanking (+3 Hit)
Have an **ally adjacent to the defender** when attacking.

### High Ground (+2 Hit, +10% Damage)
Attack from **Hills or Peaks** terrain.

### Cover (+3 DEF)
Defend from **Forest or Ruins** terrain.

### Surrounded (-2 DEF)
Defender has **3+ enemies adjacent** to them.

---

## ⚡ Status Effects

Some moves can apply status effects:

| Effect | Icon | Duration | Effect |
|--------|------|----------|--------|
| **Stunned** | ⚡ | 1 turn | Can't act! Auto-Brace if attacked |
| **Burned** | 🔥 | 3 turns | Take 10 damage per turn |
| **Poisoned** | ☠️ | 4 turns | Take 8 damage per turn |
| **Slowed** | 🐢 | 2 turns | -2 Speed |
| **Cursed** | 💀 | 3 turns | -25% ATK |
| **Terrified** | 😱 | 2 turns | -25% DEF |
| **Rooted** | 🌿 | 2 turns | Can't move |
| **Stealth** | 👻 | 3 turns | Next attack is guaranteed crit! |

### Immunities
Some troops are immune to certain effects:
- **Infernal Soul**: Immune to Burned
- **Frost Revenant**: Immune to Slowed
- **Celestial Cleric**: Immune to Cursed
- **Shadow Assassin**: Starts with Stealth

---

## 📊 Stat Stages

Buffs and debuffs can modify your stats:

| Stage | Multiplier |
|-------|------------|
| +6 | 4.00x |
| +3 | 2.50x |
| +2 | 2.00x |
| +1 | 1.50x |
| 0 | 1.00x |
| -1 | 0.67x |
| -2 | 0.50x |
| -6 | 0.25x |

Maximum stage is +6 or -6.

---

## 💡 Combat Tips

1. **Don't spam Power moves** - Their cooldown means you can't use them often
2. **Use Precision moves** against high-DEF tanks
3. **Counter stance** is high-risk, high-reward
4. **Save Endure** for when you really need it
5. **Watch type matchups** - 1.5x damage adds up fast!
6. **Position matters** - Fight from high ground when possible
7. **Focus fire** to trigger Surrounded debuff
8. **Cleanse debuffs** with Celestial Cleric's moves

---

## 🎯 Troop Combat Roles

### Ground Tanks
**Ironclad Golem**, **Thunder Behemoth**
- High DEF, use Brace stance often
- Deal consistent Physical damage

### Ranged DPS
**Sylvan Ranger**, **Crystal Mage**, **Frost Revenant**
- High ATK, lower DEF
- Stay at range, use Dodge stance

### Assassins
**Shadow Assassin**, **Void Walker**
- Stealth and high burst damage
- Use Counter to punish misses

### Support
**Celestial Cleric**
- Heals and cleanses allies
- Use Endure to survive and keep healing

### Hybrid
**Storm Wyvern**, **Tidal Serpent**, **Plague Herald**
- Mix of offense and utility
- Adapt stance to situation

---

*Good luck, Commander! May your dice roll high!* 🎲

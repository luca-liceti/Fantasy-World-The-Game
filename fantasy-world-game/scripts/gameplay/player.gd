## Player
## Represents a single player in the game with all their resources and state
class_name Player
extends RefCounted

# =============================================================================
# SIGNALS
# =============================================================================
signal gold_changed(new_amount: int)
signal xp_changed(new_amount: int)
signal troop_added(troop: Node)
signal troop_removed(troop: Node)
signal mine_added(mine: Node)
signal mine_removed(mine: Node)
signal inventory_changed(items: Array)

# =============================================================================
# PLAYER IDENTITY
# =============================================================================
var player_id: int = -1
var player_name: String = "Player"
var team_color: Color = Color.WHITE

# Team colors for visual distinction
const TEAM_COLORS: Array[Color] = [
	Color(0.2, 0.4, 0.9), # Player 1: Blue
	Color(0.9, 0.2, 0.2) # Player 2: Red
]

# =============================================================================
# RESOURCES
# =============================================================================
var gold: int = GameConfig.STARTING_GOLD:
	set(value):
		gold = max(0, value)
		gold_changed.emit(gold)

var xp: int = GameConfig.STARTING_XP:
	set(value):
		xp = max(0, value)
		xp_changed.emit(xp)

# =============================================================================
# DECK & TROOPS
# =============================================================================
## Selected card IDs for this player's deck (4 cards)
var deck: Array[String] = []

## Active troops on the board (Node references)
var troops: Array = []

## Destroyed troops (can be respawned with Phoenix Feather)
var destroyed_troops: Array[String] = []

# =============================================================================
# GOLD MINES
# =============================================================================
## Active gold mines owned by this player (Node references)
var gold_mines: Array = []

# =============================================================================
# INVENTORY
# =============================================================================
## Items held by the player (max 3)
var inventory: Array[String] = []

## Number of Phoenix Feathers (max 1)
var phoenix_feathers: int = 0

# =============================================================================
# GAME STATE TRACKING
# =============================================================================
## Troops that have performed an action this turn
var troops_acted_this_turn: Array = []

## Kill streak tracking for bounty system
var current_kill_streak: int = 0

## Has this player gotten the first blood?
var has_first_blood: bool = false

## Last player who killed one of our troops (for revenge tracking)
var last_killer_id: int = -1


# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(id: int = -1, p_name: String = "Player") -> void:
	player_id = id
	player_name = p_name
	
	# Assign team color based on player ID
	if id >= 0 and id < TEAM_COLORS.size():
		team_color = TEAM_COLORS[id]


## Initialize player for a new game
func initialize() -> void:
	gold = GameConfig.STARTING_GOLD
	xp = GameConfig.STARTING_XP
	
	troops.clear()
	destroyed_troops.clear()
	gold_mines.clear()
	inventory.clear()
	troops_acted_this_turn.clear()
	
	phoenix_feathers = 0
	current_kill_streak = 0
	has_first_blood = false
	last_killer_id = -1


# =============================================================================
# DECK MANAGEMENT
# =============================================================================

## Set the player's deck (4 card IDs)
## Returns: validation result
func set_deck(card_ids: Array[String]) -> Dictionary:
	var validation = CardData.validate_deck(card_ids)
	
	if validation["valid"]:
		deck = card_ids.duplicate()
	
	return validation


## Get the total mana cost of the current deck
func get_deck_mana_cost() -> int:
	var total: int = 0
	for card_id in deck:
		var card = CardData.get_troop(card_id)
		if not card.is_empty():
			total += card["mana"]
	return total


## Check if deck is valid
func is_deck_valid() -> bool:
	return CardData.validate_deck(deck)["valid"]


# =============================================================================
# RESOURCE MANAGEMENT
# =============================================================================

## Add gold to player
func add_gold(amount: int) -> void:
	gold += amount


## Spend gold (returns false if insufficient)
func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false


## Check if player can afford a gold cost
func can_afford_gold(amount: int) -> bool:
	return gold >= amount


## Add XP to player
func add_xp(amount: int) -> void:
	xp += amount


## Spend XP (returns false if insufficient)
func spend_xp(amount: int) -> bool:
	if xp >= amount:
		xp -= amount
		return true
	return false


## Check if player can afford an XP cost
func can_afford_xp(amount: int) -> bool:
	return xp >= amount


## Check if player can afford both gold and XP
func can_afford(gold_cost: int, xp_cost: int) -> bool:
	return can_afford_gold(gold_cost) and can_afford_xp(xp_cost)


## Spend both gold and XP (returns false if insufficient)
func spend_resources(gold_cost: int, xp_cost: int) -> bool:
	if can_afford(gold_cost, xp_cost):
		gold -= gold_cost
		xp -= xp_cost
		return true
	return false


# =============================================================================
# TROOP MANAGEMENT
# =============================================================================

## Add a troop to this player's control
func add_troop(troop: Node) -> void:
	if troop not in troops:
		troops.append(troop)
		troop_added.emit(troop)


## Remove a troop from this player's control
func remove_troop(troop: Node, add_to_destroyed: bool = true) -> void:
	if troop in troops:
		troops.erase(troop)
		
		# Track destroyed troops for potential respawn
		if add_to_destroyed and "troop_id" in troop:
			destroyed_troops.append(troop.troop_id)
		
		troop_removed.emit(troop)


## Get number of alive troops
func get_troop_count() -> int:
	return troops.size()


## Check if player has any troops left
func has_troops() -> bool:
	return not troops.is_empty()


## Check if a specific troop has acted this turn
func has_troop_acted(troop: Node) -> bool:
	return troop in troops_acted_this_turn


## Mark a troop as having acted this turn
func mark_troop_acted(troop: Node) -> void:
	if troop not in troops_acted_this_turn:
		troops_acted_this_turn.append(troop)


## Reset all troop actions for a new turn
func reset_troop_actions() -> void:
	troops_acted_this_turn.clear()


## Get troops that haven't acted yet this turn
func get_available_troops() -> Array:
	var available: Array = []
	for troop in troops:
		if troop not in troops_acted_this_turn:
			available.append(troop)
	return available


# =============================================================================
# GOLD MINE MANAGEMENT
# =============================================================================

## Add a gold mine to this player's ownership
func add_gold_mine(mine: Node) -> void:
	if mine not in gold_mines:
		gold_mines.append(mine)
		mine_added.emit(mine)


## Remove a gold mine from this player's ownership
func remove_gold_mine(mine: Node) -> void:
	if mine in gold_mines:
		gold_mines.erase(mine)
		mine_removed.emit(mine)


## Get number of gold mines owned
func get_mine_count() -> int:
	return gold_mines.size()


## Check if player can place more mines
func can_place_mine() -> bool:
	return gold_mines.size() < GameConfig.MAX_MINES_PER_PLAYER and can_afford_gold(GameConfig.MINE_PLACEMENT_COST)


## Calculate total gold generated per turn from all mines
func get_gold_per_turn() -> int:
	var total: int = 0
	for mine in gold_mines:
		if "level" in mine:
			var level = mine.level
			total += GameConfig.MINE_GENERATION_RATES.get(level, 0)
	return total


## Collect gold from all mines (called at start of turn)
func collect_mine_gold() -> int:
	var collected = get_gold_per_turn()
	if collected > 0:
		add_gold(collected)
		print("Player %d collected %d gold from %d mines (Total gold: %d)" % [player_id + 1, collected, gold_mines.size(), gold])
	return collected


# =============================================================================
# INVENTORY MANAGEMENT
# =============================================================================

## Add item to inventory (returns false if full)
func add_item(item_id: String) -> bool:
	# Special case for Phoenix Feather
	if item_id == "phoenix_feather":
		if phoenix_feathers < GameConfig.MAX_PHOENIX_FEATHERS:
			phoenix_feathers += 1
			inventory_changed.emit(inventory)
			return true
		return false
	
	# Regular items
	if inventory.size() < GameConfig.MAX_INVENTORY_SLOTS:
		inventory.append(item_id)
		inventory_changed.emit(inventory)
		return true
	
	return false


## Remove item from inventory
func remove_item(item_id: String) -> bool:
	# Special case for Phoenix Feather
	if item_id == "phoenix_feather":
		if phoenix_feathers > 0:
			phoenix_feathers -= 1
			inventory_changed.emit(inventory)
			return true
		return false
	
	# Regular items
	var index = inventory.find(item_id)
	if index != -1:
		inventory.remove_at(index)
		inventory_changed.emit(inventory)
		return true
	
	return false


## Check if player has an item
func has_item(item_id: String) -> bool:
	if item_id == "phoenix_feather":
		return phoenix_feathers > 0
	return item_id in inventory


## Check if inventory is full
func is_inventory_full() -> bool:
	return inventory.size() >= GameConfig.MAX_INVENTORY_SLOTS


## Get all items including phoenix feathers
func get_all_items() -> Array:
	var items = inventory.duplicate()
	for i in range(phoenix_feathers):
		items.append("phoenix_feather")
	return items


# =============================================================================
# RESPAWN MANAGEMENT
# =============================================================================

## Check if player can respawn a troop
func can_respawn_troop() -> bool:
	return phoenix_feathers > 0 and not destroyed_troops.is_empty()


## Get list of respawnable troop IDs
func get_respawnable_troops() -> Array[String]:
	return destroyed_troops.duplicate()


## Mark a troop as respawned (uses a phoenix feather)
func use_respawn(troop_id: String) -> bool:
	if not can_respawn_troop():
		return false
	
	var index = destroyed_troops.find(troop_id)
	if index == -1:
		return false
	
	destroyed_troops.remove_at(index)
	phoenix_feathers -= 1
	inventory_changed.emit(inventory)
	return true


# =============================================================================
# KILL STREAK & BOUNTY
# =============================================================================

## Register a kill (for streak tracking)
func register_kill() -> int:
	current_kill_streak += 1
	return current_kill_streak


## Reset kill streak (when one of our troops dies)
func reset_kill_streak() -> void:
	current_kill_streak = 0


## Get XP bonus multiplier based on kill streak
func get_kill_streak_bonus() -> float:
	if current_kill_streak >= 4:
		return GameConfig.KILL_STREAK_XP_BONUSES.get(4, 1.0)
	return GameConfig.KILL_STREAK_XP_BONUSES.get(current_kill_streak, 0.0)


# =============================================================================
# SERIALIZATION
# =============================================================================

## Convert player state to dictionary for saving
func to_dict() -> Dictionary:
	var troops_data: Array = []
	for troop in troops:
		if troop.has_method("to_dict"):
			troops_data.append(troop.to_dict())
	
	var mines_data: Array = []
	for mine in gold_mines:
		if mine.has_method("to_dict"):
			mines_data.append(mine.to_dict())
	
	return {
		"player_id": player_id,
		"player_name": player_name,
		"team_color": {
			"r": team_color.r,
			"g": team_color.g,
			"b": team_color.b
		},
		"gold": gold,
		"xp": xp,
		"deck": deck,
		"destroyed_troops": destroyed_troops,
		"inventory": inventory,
		"phoenix_feathers": phoenix_feathers,
		"current_kill_streak": current_kill_streak,
		"has_first_blood": has_first_blood,
		"last_killer_id": last_killer_id,
		"troops": troops_data,
		"gold_mines": mines_data
	}


## Load player state from dictionary
func from_dict(data: Dictionary) -> void:
	player_id = data.get("player_id", -1)
	player_name = data.get("player_name", "Player")
	
	var color_data = data.get("team_color", {})
	team_color = Color(
		color_data.get("r", 1.0),
		color_data.get("g", 1.0),
		color_data.get("b", 1.0)
	)
	
	gold = data.get("gold", GameConfig.STARTING_GOLD)
	xp = data.get("xp", GameConfig.STARTING_XP)
	deck = Array(data.get("deck", []), TYPE_STRING, "", null)
	destroyed_troops = Array(data.get("destroyed_troops", []), TYPE_STRING, "", null)
	inventory = Array(data.get("inventory", []), TYPE_STRING, "", null)
	phoenix_feathers = data.get("phoenix_feathers", 0)
	current_kill_streak = data.get("current_kill_streak", 0)
	has_first_blood = data.get("has_first_blood", false)
	last_killer_id = data.get("last_killer_id", -1)
	
	# Note: troops and gold_mines need to be reconstructed by the game manager
	# as they require scene instantiation

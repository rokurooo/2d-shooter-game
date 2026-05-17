extends Node2D

const PLAYER = preload("res://Character_Scene/player.tscn")
const RESPAWN_DELAY = 2.0  # Seconds before respawning

var spawned_players = []
var player_spawn_positions = {
	1: Vector2(300, 400),
	2: Vector2(700, 400)
}


func _ready() -> void:
	# Set up multiplayer
	if multiplayer.is_server():
		# Spawn both players on the server
		spawn_player(1)
		spawn_player(2)


func spawn_player(player_id: int) -> void:
	var player = PLAYER.instantiate()
	player.player_id = player_id
	
	# Set spawn position from dictionary
	player.position = player_spawn_positions[player_id]
	
	# Set the multiplayer authority
	player.set_multiplayer_authority(player_id)
	
	# Add to scene tree
	add_child(player)
	spawned_players.append(player)
	
	# Broadcast to all clients
	spawn_player_network.rpc(player_id, player.position)


@rpc("authority")
func spawn_player_network(player_id: int, pos: Vector2) -> void:
	# Only spawn if not already spawned by authority
	if is_multiplayer_authority():
		return
	
	var player = PLAYER.instantiate()
	player.player_id = player_id
	player.position = pos
	player.set_multiplayer_authority(player_id)
	add_child(player)
	spawned_players.append(player)


func _process(_delta: float) -> void:
	pass


func Death_area(area: Area2D) -> void:
	# Get the parent node (should be the player)
	var player = area.get_parent()
	
	# Check if it's actually a player with player_id
	if player and player.get("player_id"):
		if multiplayer.is_server():
			kill_player.rpc(player.player_id)


@rpc("authority")
func kill_player(player_id: int) -> void:
	# Find and remove the player from scene
	for player in get_children():
		if player.get("player_id") == player_id:
			player.queue_free()
			break
	
	# Respawn after delay
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	spawn_player(player_id)

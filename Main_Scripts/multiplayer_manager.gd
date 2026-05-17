extends Node

# Multiplayer networking configuration
const PORT = 9999
const ADDRESS = "127.0.0.1"
const MAX_PLAYERS = 2


func _ready() -> void:
	# Set up multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


func host_game() -> void:
	"""Start game as server/host"""
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	print("Hosting game on port %d" % PORT)


func join_game(server_address: String = ADDRESS) -> void:
	"""Connect to a game server"""
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(server_address, PORT)
	multiplayer.multiplayer_peer = peer
	print("Connecting to %s:%d" % [server_address, PORT])


func _on_peer_connected(peer_id: int) -> void:
	print("Player %d connected" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Player %d disconnected" % peer_id)


func _on_connected_to_server() -> void:
	print("Successfully connected to server")


func _on_connection_failed() -> void:
	print("Failed to connect to server")
	get_tree().quit()

class_name NetworkSession
extends Node

signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal connected_to_host
signal connection_failed
signal host_disconnected
signal session_closed

const OFFLINE_PEER_ID := 1
const HOST_PEER_ID := 1

var is_host := false
var host_peer_id := HOST_PEER_ID
var local_peer_id := OFFLINE_PEER_ID
var connected_peers: Array[int] = []

var _peer: ENetMultiplayerPeer


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func start_host(port: int, max_players: int) -> Error:
	close_session()

	var max_clients : int = max(1, max_players - 1)
	_peer = ENetMultiplayerPeer.new()
	var error := _peer.create_server(port, max_clients)
	if error != OK:
		_peer = null
		push_error("NetworkSession: Failed to start host on port %d. Error: %d" % [port, error])
		return error

	multiplayer.multiplayer_peer = _peer
	is_host = true
	local_peer_id = multiplayer.get_unique_id()
	connected_peers = [local_peer_id]
	print("NetworkSession: Hosting on port %d for %d player(s)" % [port, max_players])
	return OK


func join_host(address: String, port: int) -> Error:
	close_session()

	_peer = ENetMultiplayerPeer.new()
	var error := _peer.create_client(address, port)
	if error != OK:
		_peer = null
		push_error("NetworkSession: Failed to join %s:%d. Error: %d" % [address, port, error])
		return error

	multiplayer.multiplayer_peer = _peer
	is_host = false
	local_peer_id = multiplayer.get_unique_id()
	connected_peers.clear()
	print("NetworkSession: Joining %s:%d" % [address, port])
	return OK


func close_session() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	_peer = null
	is_host = false
	local_peer_id = OFFLINE_PEER_ID
	connected_peers.clear()
	session_closed.emit()


func has_active_peer() -> bool:
	return multiplayer.multiplayer_peer != null


func is_client() -> bool:
	return has_active_peer() and not is_host


func is_online_session() -> bool:
	return has_active_peer()


func is_connected_to_host() -> bool:
	return is_client() and connected_peers.has(host_peer_id)


func _on_peer_connected(peer_id: int) -> void:
	if not connected_peers.has(peer_id):
		connected_peers.append(peer_id)
	peer_joined.emit(peer_id)
	print("NetworkSession: Peer joined: %d" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	connected_peers.erase(peer_id)
	peer_left.emit(peer_id)
	print("NetworkSession: Peer left: %d" % peer_id)


func _on_connected_to_server() -> void:
	local_peer_id = multiplayer.get_unique_id()
	if not connected_peers.has(host_peer_id):
		connected_peers.append(host_peer_id)
	if not connected_peers.has(local_peer_id):
		connected_peers.append(local_peer_id)
	connected_to_host.emit()
	print("NetworkSession: Connected to host as peer %d" % local_peer_id)


func _on_connection_failed() -> void:
	connection_failed.emit()
	push_error("NetworkSession: Connection failed.")


func _on_server_disconnected() -> void:
	host_disconnected.emit()
	print("NetworkSession: Host disconnected.")

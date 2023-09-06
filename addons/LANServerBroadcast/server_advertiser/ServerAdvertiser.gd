@icon('res://addons/LANServerBroadcast/server_advertiser/server_advertiser.png')
extends Node
class_name ServerAdvertiser

const DEFAULT_PORT := 3111

# How often to broadcast out to the network that this host is active
@export var broadcast_interval: float = 1.0
var serverInfo := {"nama": "Unknown Room", "max_pemain" : 4, "jumlah_pemain" : 0}

var socketUDP: PacketPeerUDP
var broadcastTimer := Timer.new()
var broadcastPort := DEFAULT_PORT

func _enter_tree():
	broadcastTimer.wait_time = broadcast_interval
	broadcastTimer.one_shot = false
	broadcastTimer.autostart = true
	
	if multiplayer.is_server():
		add_child(broadcastTimer)
		broadcastTimer.timeout.connect(broadcast) 
		
		socketUDP = PacketPeerUDP.new()
		socketUDP.set_broadcast_enabled(true)
		socketUDP.set_dest_address('255.255.255.255', broadcastPort)
		print("Sukses Broadcast peladen.")
	else:
		print("Broadcast error: Mode peer koneksi bukan mode server.")

func broadcast():
	#print('Broadcasting game...')
	var packetMessage := JSON.stringify(serverInfo)
	var packet := packetMessage.to_ascii_buffer()
	socketUDP.put_packet(packet)

func _exit_tree():
	broadcastTimer.stop()
	if socketUDP != null:
		socketUDP.close()

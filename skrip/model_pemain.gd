extends Node3D

@export var rotasi : Vector3 :
	set(arah):
		for node in %GeneralSkeleton.get_children():
			if node is MeshInstance3D:
				node.rotation_degrees = arah
		rotasi = arah

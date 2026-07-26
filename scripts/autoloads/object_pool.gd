extends Node
## Gestor de Object Pooling nativo en GDScript.
## Sustituye a queue_free() e instantiate() para mejorar los FPS.

var _pools: Dictionary = {}

func acquire(scene: PackedScene, parent: Node, spawn_pos: Vector2) -> Node:
	if not _pools.has(scene):
		_pools[scene] = []
		
	var pool: Array = _pools[scene]
	var instance: Node = null
	
	while not pool.is_empty():
		var popped = pool.pop_back()
		if is_instance_valid(popped) and not popped.is_queued_for_deletion():
			instance = popped
			break
			
	if instance == null:
		instance = scene.instantiate()
		instance.set_meta("pool_scene", scene)
		instance.set_meta("is_pooled", false)
		parent.call_deferred("add_child", instance)
	else:
		instance.set_meta("is_pooled", false)
		if instance.get_parent() == null:
			parent.call_deferred("add_child", instance)
		elif instance.get_parent() != parent:
			instance.call_deferred("reparent", parent)
			
	# As it might not be in the tree yet, we set position directly
	instance.position = spawn_pos
	
	# Reactivar diferidamente para evitar errores de físicas
	instance.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
	if instance is CanvasItem:
		instance.call_deferred("show")
	
	if instance.has_method("_on_acquire"):
		instance._on_acquire()
		
	return instance


func release(instance: Node) -> void:
	if instance.get_meta("is_pooled", false):
		return
	instance.set_meta("is_pooled", true)
	
	if instance.has_meta("kb_tween"):
		var tw = instance.get_meta("kb_tween")
		if tw and tw.is_valid():
			tw.kill()
		instance.remove_meta("kb_tween")
	
	var scene: PackedScene = instance.get_meta("pool_scene", null)
	if scene == null:
		# Si no fue creado por el pool, lo destruimos normalmente.
		instance.queue_free()
		return
		
	if instance.has_method("_on_release"):
		instance._on_release()
		
	# Desactivar
	instance.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	if instance is CanvasItem:
		instance.call_deferred("hide")
		
	if not _pools.has(scene):
		_pools[scene] = []
		
	_pools[scene].append(instance)

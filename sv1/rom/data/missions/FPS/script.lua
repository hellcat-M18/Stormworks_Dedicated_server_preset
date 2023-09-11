function onCreate(is_world_create)

		deletedObjects = 0
		
		if min_id == nil then
			min_id = 0
		end		
		if max_id == nil then
			max_id = 10000
		end
		
		for idCounter = min_id, max_id do
			success = server.despawnObject(idCounter, true)
			if success then
				deletedObjects = deletedObjects + 1
		
			end
		end
		playerCount = #server.getPlayers()
		server.announce("[Performance Optimizer]", string.format("Deleted %d objects", deletedObjects-playerCount))

end
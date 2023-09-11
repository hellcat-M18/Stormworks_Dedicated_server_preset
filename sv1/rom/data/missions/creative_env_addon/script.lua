-- g_savedata table that persists between game sessions

function Reset()

g_savedata = {}

g_savedata.own_vehicles = {}

g_savedata.npc_id = {}

end

Reset()

-- Tick function that will be executed every logic tick
function onTick(game_ticks)

end



function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, one, two, three, four, five)
	if command == "?clean" or command == "?c" then
	
		name, is_success = server.getPlayerName(user_peer_id)
	
		V_id = g_savedata.own_vehicles[name]
		
		if V_id ~= nil then
			
			total = #V_id
			fail = 0
			
			for i = 1, #V_id do
				is_success = server.despawnVehicle(V_id[i], true)
				
			end
		
			if total > fail then
			
				server.notify(user_peer_id,"?clean","Command executed.",4)
				
			else 
			
				server.notify(user_peer_id,"ERROR","Something went wrong.",2)
				
			end
		
		else
		
			server.notify(user_peer_id,"ERROR","Vehicle not found.",2)
			
		end
	elseif command == "?vtp" then
	
		if one and two and three then
		
			name, is_success = server.getPlayerName(user_peer_id)
	
			object_id, is_success = server.getPlayerCharacterID(user_peer_id)
		
			vehicle_id, is_success = server.getCharacterVehicle(object_id)
			
			if is_success then
		
				tp_target = matrix.translation(one,two,three)
				tp_target_pl = matrix.translation(one+3,two,three)
		
				is_success = server.setVehiclePos(vehicle_id, tp_target)
		
				is_success = server.setPlayerPos(user_peer_id, tp_target_pl)
				
				if is_success then
				
					server.notify(user_peer_id,"?vtp","Successfully teleported vehicle.",4)
				
				else server.notify(user_peer_id,"ERROR","Something went wrong.",2)
				
				end
			
			else server.notify(user_peer_id,"ERROR","Please sit on the vehicle.",2)
			
			end
		
		else server.notify(user_peer_id,"ERROR","Too few args for this command.",2)
		
		end
		
	
	elseif command == "?repair" then

		object_id, is_success = server.getPlayerCharacterID(user_peer_id)
		
		vehicle_id, is_success = server.getCharacterVehicle(object_id)

		if is_success then
		
			transform_matrix, is_success = server.getVehiclePos(vehicle_id)
		
			x,y,z = matrix.position(transform_matrix)
			
			pl_matrix = matrix.translation(x+5,y+1,z)
			
			is_success = server.resetVehicleState(vehicle_id)
			
			if is_success then
				
				is_success = server.setPlayerPos(user_peer_id, pl_matrix)
				
				server.notify(user_peer_id,"repair","Successfully repaird vehicle.",4)
			
			else server.notify(user_peer_id,"ERROR","something went wrong.",2)
			
			end
		
		else server.notify(user_peer_id,"ERROR","Please sit on the vehicle.",2)
		
		end
		
	
	elseif command == "?stand" then
		
		object_id, is_success = server.getPlayerCharacterID(user_peer_id)
		
		vehicle_id, is_success = server.getCharacterVehicle(object_id)
		
		if is_success then
		
			transform_matrix, is_success = server.getVehiclePos(vehicle_id)
		
			x,y,z = matrix.position(transform_matrix)
			
			pl_matrix = matrix.translation(x+5,y+1,z)
	
			out_matrix = matrix.translation(x,y,z)
		
			is_success = server.setVehiclePos(vehicle_id, out_matrix)
		
			if is_success then
				
				is_success = server.setPlayerPos(user_peer_id, pl_matrix)
				
				server.notify(user_peer_id,"stand","command executed.",4)
			
			else server.notify(user_peer_id,"ERROR","something went wrong.",2)
			
			end
		
		else server.notify(user_peer_id,"ERROR","please sit on the vehicle.",2)
		
		end
		
		
	elseif command == "?tp" then
	
		if one ~= nil then
			
			pl_pos, is_success = server.getPlayerPos(one)
			
			if is_success then
				
				name, is_success = server.getPlayerName(peer_id)
				
				is_success = server.setPlayerPos(user_peer_id, pl_pos)
				
				if is_success then
				
					is_success = server.setPlayerPos(user_peer_id, pl_matrix)
					
					server.notify(user_peer_id, "tp", "teleported to "..name..".", 4)
				
				else server.norify(user_peer_id, "ERROR", "something went wrong.",2)
				
				end
				
			else server.notify(user_peer_id,"ERROR", "player not found.",2)
			
			end
		
		else server.notify(user_peer_id,"ERROR", "too few args for this command.",2)
		
		end

	elseif command == "?kill" and is_admin then
		
		if one ~= nil then
		
			name, is_success = server.getPlayerName(one)

			object_id, is_success = server.getPlayerCharacterID(one)
			
			server.killCharacter(object_id)
			
			server.notify(user_peer_id,"kill","killed "..name,4)
		
		else server.notify(user_peer_id,"ERROR","too few args for this command.",2)
		
		end
	
	
	elseif command == "?no_damage" and is_admin then
		
		if one == "true" then
			
			object_id, is_success = server.getPlayerCharacterID(user_peer_id)

			vehicle_id, is_success = server.getCharacterVehicle(object_id)
			
			if is_success then
			
				no_damage = server.setVehicleInvulnerable(vehicle_id, true)
				
				if not no_damage then 
					
					server.notify(user_peer_id,"no_damage","set vehicle undamageable.",4)
				
				else server.notify(user_peer_id,"ERROR","something went wrong.",2)
				
				end
			
			else server.notify(user_peer_id,"ERROR","please sit on the vehicle.",2)
			
			end
			
			
			
		elseif one == "false" then
			
			object_id, is_success = server.getPlayerCharacterID(user_peer_id)

			vehicle_id, is_success = server.getCharacterVehicle(object_id)
			
			if is_success then
			
				no_damage = server.setVehicleInvulnerable(vehicle_id, false)
				
				if not no_damage then
					
					server.notify(user_peer_id,"no_damage","set vehicle damageable.",4)
				
				else server.notify(user_peer_id,"ERROR","something went wrong.",2)
				
				end
			
			else server.notify(user_peer_id,"ERROR","please sit on the vehicle.",2)
			
			end
		
		else server.notify(user_peer_id,"ERROR","too few args for this command.",2)
		
		end
	
	
	elseif command == "?npc" then
		
		if one == "spawn" then
			
			if two ~= nil then
			
				total = tonumber(two)
				
				transform_matrix, is_success = server.getPlayerPos(peer_id)
				
				x,y,z = matrix.position(transform_matrix)
				
				X = math.floor(math.sqrt(two))+1
				
				Y = math.floor(math.sqrt(two))
				
				spawnX = x
				
				spawnY = y+1
				
				spawnZ = z
				
				for i = 1, Y do
					
					for i = 1, X do
					
						if total > 0 then
					
							out_matrix = matrix.translation(spawnX,spawnY,spawnZ)
						
							object_id, is_success = server.spawnObject(out_matrix, 1)
							
							table.insert(g_savedata.npc_id,object_id)
						
							total = total-1
							
							spawnX = spawnX+1
						
						else break
						
						end
						
					end
					
					spawnX = x
					
					spawnZ = spawnZ+1
				
				end
				
				server.notify(user_peer_id,"npc","spawned "..two.." npc.",4)
			
			else 			
							
			server.notify(user_peer_id,"ERROR","too few args for this command.",2)				
			
			end
			
		elseif one == "clean" then
		
			if #g_savedata.npc_id > 0 then
		
				for i = 1, #g_savedata.npc_id do
			
					is_success = server.despawnObject(tonumber(g_savedata.npc_id[i]), true)
				
		
				end
			
				server.notify(user_peer_id,"npc","despawned npc from this addon",4)
			
			else
			
			server.notify(user_peer_id,"ERROR","no npc found from this addon",2)
			
			end
			
		else server.notify(user_peer_id,"ERROR","no such option found",2)
		
		end
		
	elseif command == "?reset" then
		
		Reset()
	
		
	end
	
	
end


function onVehicleSpawn(vehicle_id, peer_id, x, y, z, cost)
	name, is_success = server.getPlayerName(peer_id)
	
	if g_savedata.own_vehicles[name]  == nil then
	
		g_savedata.own_vehicles[name] = {}
		
		table.insert(g_savedata.own_vehicles[name],vehicle_id)
	
	else
	
		table.insert(g_savedata.own_vehicles[name],vehicle_id)
	
	end
	
end
	
function onVehicleDespawn(vehicle_id, peer_id)
	name, is_success = server.getPlayerName(peer_id)
	
	if g_savedata.own_vehicles[name] ~= nil then
	
		for i = 1, #g_savedata.own_vehicles[name] do
		
			if g_savedata.own_vehicles[name][i] == vehicle_id then
			
				g_savedata.own_vehicles[name][i] = nil
			end
		end
	end
end



function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)

	if not is_auth then
		server.addAuth(peer_id)
	end
end

function onCreate(is_world_create)

	if is_world_create then
	
		server.setGameSetting("clear_fow", true)
		
		server.setGameSetting("unlock_all_islands",true)
		
		server.setGameSetting("override_weather",true)
		
		server.setGameSetting("despawn_when_leave",true)
		
		server.setWeather(0, 0, 0)
		
	end
end


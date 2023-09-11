-- g_savedata table that persists between game sessions

function reset()
	g_savedata = {}

	g_savedata.own_vehicles = {}

	g_savedata.ready_player = {}

	g_savedata.in_game = false

	ready_count = 0

	g_savedata.targ_time = nil

	g_savedata.set_min = nil

end



function find(array,element)
	for i = 1 , #array do	
		if array[i] == element then	
			index = i
			break			
		else	
			index = nil
		end
	end
	return index
	
end
	
reset()





-- Tick function that will be executed every logic tick
function onTick(game_ticks)
	player_list = server.getPlayers()

	ready_count = 0
	
	for i = 1, #player_list do
	
		name = player_list[i]["name"]

		if g_savedata.ready_player[name] == true then
		
			ready_count = ready_count + 1
		
		end
	
	end
	
	if g_savedata.in_game then 

		system_time = server.getTimeMillisec()
		
		leave_time = math.floor((g_savedata.targ_time - system_time) / 1000)
		
		leave_min = math.floor(leave_time/60)
		
		leave_sec = leave_time - leave_min*60
		
		if leave_sec < 10 then
			leave_sec = "0"..leave_sec
		end
		
		if leave_time < 0 then
			g_savedata.in_game = false
			
			server.notify(-1,"end","game set. "..g_savedata.set_min.." minutes passed.",4)
		end
	
		text = leave_min..":"..leave_sec
	
	else 
		
		text = ready_count.."/"..#player_list.." ready"
		
	end
	
	server.setPopupScreen(-1, 127, "ready_indicator", true, text, 0.85, 0.75)

	
	

		
	
	
end



function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, one, two, three, four, five)
	if command == "?clean" or command == "?c" then
	
		name, is_success = server.getPlayerName(user_peer_id)
		
		if g_savedata.own_vehicles[name] ~= nil then
		v_id = g_savedata.own_vehicles[name]
		
			success = 0
			
			for i = 1, #v_id do
			
				is_success = server.despawnVehicle(v_id[i], true)
				
				if is_success then
					
					v_id[i] = nil
					
					success = success+1
					
				end		
			end
			
			g_savedata.own_vehicles[name] = v_id
		
			if success > 0 then
			
				server.notify(user_peer_id,"?clean","Command executed. Despawned "..success.." vehicles.",4)
				
			else 
			
				server.notify(user_peer_id,"ERROR","Something went wrong.",2)
				
			end
		
		else
		
			server.notify(user_peer_id,"ERROR","Vehicle not found",2)
			
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
					server.notify(-1,"notice",name.." used ?vtp",7)
				
				else server.notify(user_peer_id,"ERROR","Something went wrong.",2)
				
				end
			
			else server.notify(user_peer_id,"ERROR","Please sit on the vehicle.",2)
			
			end
		
		else server.notify(user_peer_id,"ERROR","Too few args for this command",2)
		
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
		
		
		
		
	elseif command == "?ready" then
	
	if g_savedata.in_game == false then
	
		name, is_success = server.getPlayerName(user_peer_id)
	
		g_savedata.ready_player[name] = true
		
		server.notify(-1,"Ready",name.." is ready.", 4)

	else server.notify(user_peer_id,"ERROR","this command is not available now",2)
	end
			
		
		
	
	elseif command == "?cancel" then
	
	if g_savedata.in_game == false then
	
		name, is_success = server.getPlayerName(user_peer_id)
	
		g_savedata.ready_player[name] = false
		
		server.notify(-1,"Cancel",name.." canceled preparation.", 2)

	else server.notify(user_peer_id,"ERROR","this command is not available now",2)
	end
		
		
	
	elseif command == "?start" and is_admin then

		if one ~= nil and type(tonumber(one)) == "number" then

			player_list = server.getPlayers()
		
			if g_savedata.in_game == false then
			
				g_savedata.in_game = true

				system_time = server.getTimeMillisec()
			
				g_savedata.set_min = one
			
				millisec = one*60*1000
			
				g_savedata.targ_time = system_time + millisec
			
				server.notify(-1,"START!","game started. Time limit is "..one.." minutes!",4)

				for i = 1 ,#player_list do
					player = player_list[i]["name"]

					g_savedata.ready_player[player] = false
				end
		
			else server.notify(user_peer_id,"ERROR","now it's already in game",2)
			end
		
		else server.notify(user_peer_id,"ERROR","syntax error.",2)

		end
		
		
		
	elseif command == "?end" and is_admin then
	
		if g_savedata.in_game == true then
	
			g_savedata.in_game = false
			
			if one == "1" then 
			
				msg = "attacker side win!"
			
			elseif one == "2" then 
				msg = "defender side win!"
			
			else msg = "game set"
			
			end
		
			server.notify(-1,"End",msg,4)
	
		else server.notify(user_peer_id,"ERROR","game does not started",2)
		end
	
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

	g_savedata.ready_player[name] = false
	
end


function onPlayerLeave(steam_id, name, peer_id, is_admin, is_auth)
	
	g_savedata.ready_player[name] = nil

end



function onCreate(is_world_create)

	if is_world_create then
	
		server.setGameSetting("clear_fow", true)
		
		server.setGameSetting("unlock_all_islands",true)
		
		server.setGameSetting("override_weather",true)
		
		server.setWeather(0, 0, 0)
		
	end
end


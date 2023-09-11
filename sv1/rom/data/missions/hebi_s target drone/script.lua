--Tags
--hebis_target	 - declare range target
--name			 - Override vehicle name. (default vehicle display name on editor)
--type			 - plane,drone,reflector,ship,float,torpedo,missile,random_ocean,missile_random
--spawn_type	 - plane,drone,reflector,ship,float,torpedo,missile,random_ocean,missile_random (default same as type)
--replace_target - replace vanilla target by name (Target_Plane|Target_Drone|Target_Reflector|Float_Target|Target_Ship|Target_SEPTAR|Target_Torpedo)

--Vehicle Format
--Create vehicle in functional condition.  This script will do nothing.(Dont forget fuel and battery.
--Some type of spawned target vehicles can recieve target GPS coordinate by keypads named "Nav_X" and "Nav_Y" (You can only use small keypad.
--Random spawn will spawn out of keep active anchors area. Dont forget keep active setting.


debug = false


static_weapon_position_x = 0
static_weapon_position_z = 0
static_weapon_position = nil
static_weapon_position_noRot = nil
static_player_position = nil
drone_target_position = nil
dock_pos = nil
dock_ai_pos = nil
hanger_pos = nil
hanger_ai_pos = nil

hanger_target_pos = nil
dock_target_pos = nil

float_target_area = nil

ship_waypoint_1 = nil
ship_waypoint_2 = nil

torpedo_spawn_position = nil

anchor_location_index = -1

targets = {}
addon_targets = {}
addon_names_str = ""

distance_offset = 0
this_addon = -1

function LoadTargetobject(addon_index,location_index,component_index,is_addon_target)
	local COMPONENT_DATA, is_success = server.getLocationComponentData(addon_index, location_index, component_index)
	if (COMPONENT_DATA.type=="vehicle") and (hasTag(COMPONENT_DATA.tags,"hebis_target")) then
		--server.announce("Hebis Targets", COMPONENT_DATA.display_name.."\n"..COMPONENT_DATA.tags_full)
		local parameters = {
			name = COMPONENT_DATA.display_name,
			type = "float",
			spawn_type = "",
			replace_target = "",
			local_matrix = COMPONENT_DATA.transform
		}
		parameters = getParameters(parameters,COMPONENT_DATA.tags)
		
		parameters.addon_index = addon_index
		parameters.location_index = location_index
		parameters.component_index = component_index
		
		if (parameters.spawn_type == "") then
			parameters.spawn_type = parameters.type
		end
		
		if parameters.name ~= "" then
			if is_addon_target then
				if parameters.replace_target ~= "" then
					if targets[parameters.replace_target] ~= nil then
						targets[parameters.replace_target] = parameters
						Debuglog("Replace Loaded...\nname:"..parameters.name.."\ntype:"..parameters.type)
					else
						Debuglog("!!Failed Load...\nname:"..parameters.name.."\nNot found replace target:"..parameters.replace_target)
					end
				else
					table.insert(addon_targets, parameters)
					Debuglog("addon["..#addon_targets.."]Loaded...\nname:"..parameters.name.."\ntype:"..parameters.type)
				end
			else
				if targets[parameters.name] == nil then
					targets[parameters.name] = parameters
					Debuglog("Loaded...\nname:"..parameters.name.."\ntype:"..parameters.type)
				else
					Debuglog("!!Failed Load...\nname:"..parameters.name)
				end
			end
		end
	end
end

function onCreate(is_world_create)

	math.randomseed(server.getTimeMillisec())
	if g_savedata.targets == nil then
		g_savedata.targets = {}
	end
	if g_savedata.auto_teleport == nil then
		g_savedata.auto_teleport = true
	end
	if g_savedata.ship_auto_teleport == nil then
		g_savedata.ship_auto_teleport = false
	end
	if g_savedata.target_teleport == nil then
		g_savedata.target_teleport = false
	end
	if g_savedata.ship_target_teleport == nil then
		g_savedata.ship_target_teleport = false
	end
	if g_savedata.first_load == nil then
		g_savedata.first_load = false
	end
	
	local t , is_success = server.getAddonIndex()
	if is_success then
		this_addon = t
		anchor_location_index, is_success = server.getLocationIndex(this_addon, "KeepActiveAnchor")
		
		for j in iterLocations(t) do
			for k in iterObjects(t,j) do
				LoadTargetobject(t,j,k)
			end
		end
		
		for i in iterPlaylists() do
			if (i ~= this_addon ) then
				for j in iterLocations(i) do
					for k in iterObjects(i,j) do
						LoadTargetobject(i,j,k,true)
					end
				end
			end
		end
	end
	
	local addon_names = {"Addon Targets"}
	for i=9,0,-1 do
		if ( addon_targets[i+1] == nil ) then
			table.insert(addon_names, "["..i.."] ".."-not installed-")
		else
			table.insert(addon_names, "["..i.."] "..addon_targets[i+1].name)
		end
	end
	
	addon_names_str = table.concat(addon_names,"\n")
	
	
	if is_world_create then
		is_success = server.spawnThisAddonLocation("Spawn_On_Load")
		g_savedata.spawn_anchors = property.checkbox("Spawn keep active anchors (for extra long range shooting)", true)
		g_savedata.anchors_count = property.slider("Anchor counts(1500m each)", 2, 10, 1, 5)
	end
	
	ZONE_LIST = server.getZones()
	for i,zone in ipairs(ZONE_LIST) do
		if zone.name == "Static_Weapon_Position" then
			static_weapon_position = zone.transform
			static_weapon_position_x,_,static_weapon_position_z = matrix.position(zone.transform)
			
			static_weapon_position_noRot = matrix.translation(static_weapon_position_x,_,static_weapon_position_z)
		elseif zone.name == "Dock_AI_pos" then
			dock_ai_pos = zone.transform
		elseif zone.name == "Hanger_AI_pos" then
			hanger_ai_pos = zone.transform
		elseif zone.name == "Static_Weapon_Player_Pos" then
			static_player_position = zone.transform
		elseif zone.name == "Creative_hanger_Spawn" then
			hanger_pos = zone.transform
		elseif zone.name == "Drone_Target" then
			drone_target_position = zone.transform
		elseif zone.name == "Float_Target_Area" then
			float_target_area = zone
		elseif zone.name == "Ship_WP1" then
			ship_waypoint_1 = zone.transform
		elseif zone.name == "Ship_WP2" then
			ship_waypoint_2 = zone.transform
		elseif zone.name == "hanger_Target_Spawn" then
			hanger_target_pos = zone.transform
		elseif zone.name == "Creative_Dock_Spawn" then
			dock_pos = zone.transform
		elseif zone.name == "dock_Target_Spawn" then
			dock_target_pos = zone.transform
		end
	end
	
	if ship_waypoint_1 ~= nil and ship_waypoint_2 ~= nil then
		local f_x,f_y,f_z = matrix.position(ship_waypoint_1)
		local t_x,t_y,t_z = matrix.position(ship_waypoint_2)
		local faceRot = matrix.rotationToFaceXZ(t_x-f_x, t_z-f_z)
		
		ship_waypoint_1 = matrix.multiply(ship_waypoint_1, faceRot)
		
		local center_pos = matrix.translation((f_x+t_x)/2,0,(f_z+t_z)/2)
		local offset = matrix.translation(0,-5,-1000)
		
		offset = matrix.multiply(faceRot, offset)
		offset = matrix.multiply(center_pos, offset)
		
		torpedo_spawn_position = offset
	end
	
	if is_world_create then
		if (g_savedata.spawn_anchors) and (g_savedata.anchors_count > 0) then
			for i = 0, g_savedata.anchors_count do
				local anchor_pos = matrix.translation(static_weapon_position_x,0,static_weapon_position_z-1500*i)
				server.spawnAddonLocation(anchor_pos, this_addon, anchor_location_index)
			end
		end
	end
end
function jumpToSeat(peer_id,target_id) 
	local player_id, _ = server.getPlayerCharacterID(peer_id)
	local VEHICLE_DATA, is_success = server.getVehicleData(target_id)
	
	if #VEHICLE_DATA.components.seats > 0 then
		server.setCharacterSeated(player_id, target_id, VEHICLE_DATA.components.seats[1].pos.x, VEHICLE_DATA.components.seats[1].pos.y, VEHICLE_DATA.components.seats[1].pos.z)
		return target_id
	end
	return -1
end
function resetAllTargets()
	for i = #g_savedata.targets, 1, -1 do
		server.resetVehicleState(g_savedata.targets[i].id)
	end
end
function despawnAllTargets()
	PLAYER_LIST = server.getPlayers()
	for i = #g_savedata.targets, 1, -1 do
		despawnTarget(g_savedata.targets[i].id)
	end
end

function despawnTarget(v_id)
	PLAYER_LIST = server.getPlayers()
	for i = #g_savedata.targets, 1, -1 do
		if (g_savedata.targets[i].id == v_id) then
			
			for j,player in ipairs(PLAYER_LIST) do
				server.removeMapObject(player.id, g_savedata.targets[i].ui_id)
			end
			is_success = server.despawnVehicle(g_savedata.targets[i].id, true)
			
			table.remove(g_savedata.targets, i)
		end
	end
end
first_count = 0
function onTick(game_ticks)
	PLAYER_LIST = server.getPlayers()
	
	if not g_savedata.first_load then
		first_count = first_count + 1
		if first_count > 10 then
			g_savedata.first_load = true
			updateAutoTeleportSwitcher(g_savedata.autoTeleportSwitcher)
		end
	end
	
	for i = 1, #g_savedata.targets do
		local tgt_pos, is_success = server.getVehiclePos(g_savedata.targets[i].id)
		local _,vehicle_Y,_ = matrix.position(tgt_pos)
		local tgt_spd = matrix.distance(tgt_pos, g_savedata.targets[i].last_pos)
		tgt_spd = tgt_spd * 60
		
		local dist = matrix.distance(tgt_pos, static_weapon_position)
		
		if g_savedata.targets[i].type == "reflector" then
			g_savedata.targets[i].time = g_savedata.targets[i].time - 1
			if (vehicle_Y < 5) then
				g_savedata.targets[i].time = g_savedata.targets[i].time - 10
			end
		elseif (g_savedata.targets[i].type == "drone") or (g_savedata.targets[i].type == "missile") or (g_savedata.targets[i].type == "missile_random") then
			
			if (g_savedata.targets[i].type == "missile") or (g_savedata.targets[i].type == "missile_random") then
				local wp_x,_,wp_z = matrix.position(static_player_position)
			
				server.setVehicleKeypad(g_savedata.targets[i].id, "Nav_X", static_weapon_position_x)
				server.setVehicleKeypad(g_savedata.targets[i].id, "Nav_Y", static_weapon_position_z)
			end
			
			if(tgt_spd < 10)then
				g_savedata.targets[i].time = g_savedata.targets[i].time - 1
			else
				g_savedata.targets[i].time = 360
			end
			
			if (vehicle_Y < 3) then
				g_savedata.targets[i].time = g_savedata.targets[i].time - 10
			end
		elseif g_savedata.targets[i].type == "plane" then
		
			if(tgt_spd < 10)then
				g_savedata.targets[i].time = g_savedata.targets[i].time - 1
			else
				g_savedata.targets[i].time = 360
			end
			local wp_x,_,wp_z = matrix.position(drone_target_position)
			
			local dist = Distance2D(drone_target_position, tgt_pos)
			
			if dist < 200 then
				server.setVehicleKeypad(g_savedata.targets[i].id, "Nav_X", wp_x)
				server.setVehicleKeypad(g_savedata.targets[i].id, "Nav_Y", wp_z-500-g_savedata.targets[i].offset)
			else
				server.setVehicleKeypad(g_savedata.targets[i].id, "Nav_X", wp_x)
				server.setVehicleKeypad(g_savedata.targets[i].id, "Nav_Y", wp_z-g_savedata.targets[i].offset)
			end
		elseif g_savedata.targets[i].type == "float" then
			if (vehicle_Y < -5) then
				g_savedata.targets[i].time = g_savedata.targets[i].time - 1
			else
				g_savedata.targets[i].time = 30*60
			end
		elseif g_savedata.targets[i].type == "ship" or g_savedata.targets[i].type == "torpedo" then
			if (g_savedata.targets[i].offset ==nil ) then
				g_savedata.targets[i].offset = 0
			end
			
			local offset = matrix.translation(0,0,-g_savedata.targets[i].offset)
			local wp1_offset = matrix.multiply(offset , ship_waypoint_1)
			local wp2_offset = matrix.multiply(offset , ship_waypoint_2)
			
			local dist_wp_1 = Distance2D(wp1_offset, tgt_pos)
			local dist_wp_2 = Distance2D(wp2_offset, tgt_pos)
			
			if ( g_savedata.targets[i].wp == nil ) then
				g_savedata.targets[i].wp = wp2_offset
			end
			
			if dist_wp_1 < 50 then
				g_savedata.targets[i].wp = wp2_offset
			end
			if dist_wp_2 < 50 then
				g_savedata.targets[i].wp = wp1_offset
			end
			
			local wp_x,_,wp_z = matrix.position(g_savedata.targets[i].wp)
		
			server.setVehicleKeypad(g_savedata.targets[i].id, "Nav_X", wp_x)
			server.setVehicleKeypad(g_savedata.targets[i].id, "Nav_Y", wp_z)
			
			if g_savedata.targets[i].type == "ship" then
				if (vehicle_Y < -5) then
					g_savedata.targets[i].time = g_savedata.targets[i].time - 1
				else
					g_savedata.targets[i].time = 30*60
				end
			elseif g_savedata.targets[i].type == "torpedo" then
				if (vehicle_Y < -15) then
					g_savedata.targets[i].time = g_savedata.targets[i].time - 1
				else
					g_savedata.targets[i].time = 30*60
				end
			end
		elseif (g_savedata.targets[i].type == "random_ocean") then
			
			local dist_wp = Distance2D(g_savedata.targets[i].wp, tgt_pos)
			
			if dist_wp < 50 then
				g_savedata.targets[i].wp = RandomCirclePos(g_savedata.targets[i].start_pos,500)
			end
			local wp_x,_,wp_z = matrix.position(g_savedata.targets[i].wp)
		
			server.setVehicleKeypad(g_savedata.targets[i].id, "Nav_X", wp_x)
			server.setVehicleKeypad(g_savedata.targets[i].id, "Nav_Y", wp_z)
			
			if (vehicle_Y < -5) then
				g_savedata.targets[i].time = g_savedata.targets[i].time - 1
			else
				g_savedata.targets[i].time = 30*60
			end
		else
			g_savedata.targets[i].time = g_savedata.targets[i].time - 1
		end
		
		
		for j,player in ipairs(PLAYER_LIST) do
			server.removeMapObject(player.id, g_savedata.targets[i].ui_id)
			server.addMapObject(player.id, g_savedata.targets[i].ui_id, 1, 18, 0, 0, 0, 0, g_savedata.targets[i].id, -1, "Target", 0, "Type:".. g_savedata.targets[i].name.."  [".. math.ceil(g_savedata.targets[i].id) .."]" .."\nSPEED:".. (math.ceil(tgt_spd*100)/100) .."m/s  ALTITUDE :" .. (math.ceil(vehicle_Y*100)/100).."m\n\nRange:"..(math.ceil(dist*100)/100).."m")
		end
		
		g_savedata.targets[i].last_pos = tgt_pos
		
	end
	for i = #g_savedata.targets, 1, -1 do
		if (g_savedata.targets[i].time <= 0) then
			despawnTarget(g_savedata.targets[i].id)
		end
	end
	
	if (g_savedata.weapon_tester ~= nil ) then
		server.setCharacterData(g_savedata.weapon_tester, 100, true, true)
		if ( #g_savedata.targets > 0 ) then
			server.setAIState(g_savedata.weapon_tester, 1)
			server.setAITargetVehicle(g_savedata.weapon_tester, g_savedata.targets[1].id)
		else
			server.setAIState(g_savedata.weapon_tester, 0)
		end
	end
	
	if (g_savedata.drone_spawner ~= nil) then
		local DATA, is_success = server.getVehicleDial(g_savedata.drone_spawner, "Target_Range_Offset")
		if is_success then
			distance_offset = DATA.value
		end
		if ( #g_savedata.targets > 0 ) then
			local t_pos, t_suc = server.getVehiclePos(g_savedata.targets[1].id)
			if t_suc then
				local t_x,t_y,t_z = matrix.position(t_pos)
				server.setVehicleKeypad(g_savedata.drone_spawner, "TGT_X", t_x)
				server.setVehicleKeypad(g_savedata.drone_spawner, "TGT_Y", t_z)
				server.setVehicleKeypad(g_savedata.drone_spawner, "TGT_ALT", t_y)
			end
		else
			server.setVehicleKeypad(g_savedata.drone_spawner, "TGT_X", 0)
			server.setVehicleKeypad(g_savedata.drone_spawner, "TGT_Y", 0)
			server.setVehicleKeypad(g_savedata.drone_spawner, "TGT_ALT", 0)
		end
		server.setVehicleTooltip(g_savedata.drone_spawner, addon_names_str)
	end
	
	for i = 1,#g_output_log do
		server.announce("[Hebis Targets]" .. i,g_output_log[i])
	end
	g_output_log = {}
end

function onVehicleLoad(vehicle_id)
	updateAutoTeleportSwitcher(vehicle_id)
end

function onVehicleUnload(vehicle_id)
	despawnTarget(vehicle_id)
end

function onButtonPress(vehicle_id, peer_id, button_name, is_pressed)
	local DATA, is_success = server.getVehicleButton(vehicle_id, button_name)
	if (is_success and DATA.on) then
		if (vehicle_id == g_savedata.autoTeleportSwitcher) and (g_savedata.autoTeleportSwitcher ~= nil) then
			if (button_name == "Switch Range Teleport") then
				g_savedata.auto_teleport = not g_savedata.auto_teleport
				if g_savedata.auto_teleport then
					g_savedata.target_teleport = false
				end
			end
			if (button_name == "Switch Target Teleport") then
				g_savedata.target_teleport = not g_savedata.target_teleport
				if g_savedata.target_teleport then
					g_savedata.auto_teleport = false
				end
			end
			updateAutoTeleportSwitcher(vehicle_id)
		elseif (vehicle_id == g_savedata.shipAutoTeleportSwitcher) and (g_savedata.shipAutoTeleportSwitcher ~= nil) then
			if (button_name == "Switch Target Teleport") then
				g_savedata.ship_target_teleport = not g_savedata.ship_target_teleport
			end
			
			updateAutoTeleportSwitcher(vehicle_id)
		elseif (g_savedata.drone_spawner == nil) or (g_savedata.drone_spawner == vehicle_id) then
			if (button_name == "Despawn Targets") then
				despawnAllTargets(peer_id)
			elseif (button_name == "Spawn Reflector") then
				SpawnTarget(targets["Target_Reflector"],peer_id)
			elseif (button_name == "Spawn Float Target") then
				SpawnTarget(targets["Float_Target"],peer_id)
			elseif (button_name == "Spawn SEPTAR") then
				SpawnTarget(targets["Target_SEPTAR"],peer_id)
			elseif (button_name == "Spawn Drone") then
				SpawnTarget(targets["Target_Drone"],peer_id)
			elseif (button_name == "Spawn Plane") then
				SpawnTarget(targets["Target_Plane"],peer_id)
			elseif (button_name == "Spawn Target Ship") then
				SpawnTarget(targets["Target_Ship"],peer_id)
			elseif (button_name == "Spawn Target Torpedo") then
				SpawnTarget(targets["Target_Torpedo"],peer_id)
			elseif (button_name == "Spawn Addon Target") then
				local DATA, i_s = server.getVehicleDial(vehicle_id, "Choosed_Addon_Target_Index")
				if i_s then
					Debuglog("pressed "..button_name.." ".. DATA.value)
					SpawnTarget(addon_targets[DATA.value+1],peer_id)
				end
			end
		end
	end
end

function updateAutoTeleportSwitcher(vehicle_id)
	if (g_savedata.autoTeleportSwitcher ~= nil) and (g_savedata.autoTeleportSwitcher == vehicle_id) then
		if g_savedata.auto_teleport then
			server.pressVehicleButton(vehicle_id, "Activate_Teleportort_To_Range")
		else
			server.pressVehicleButton(vehicle_id, "Disable_Teleport_To_Range")
		end
		if g_savedata.target_teleport then
			server.pressVehicleButton(vehicle_id, "Activate_Teleportort_To_Target")
		else
			server.pressVehicleButton(vehicle_id, "Disable_Teleport_To_Target")
		end
	end
	if (g_savedata.autoTeleportSwitcher ~= nil) and (g_savedata.shipAutoTeleportSwitcher == vehicle_id) then
		if g_savedata.ship_target_teleport then
			server.pressVehicleButton(vehicle_id, "Activate_Teleportort_To_Target")
		else
			server.pressVehicleButton(vehicle_id, "Disable_Teleport_To_Target")
		end
	end
end

function onSpawnAddonComponent(vehicle_id, component_name, TYPE_STRING, addon_index)
	if addon_index == this_addon and this_addon >= 0 then
		if TYPE_STRING == "character" then
			if component_name == "Weapon Tester" then
				g_savedata.weapon_tester = vehicle_id
			end
		elseif (TYPE_STRING == "vehicle") then
			
			if component_name == "AutoTeleportSwitchButtons" then
				g_savedata.autoTeleportSwitcher = vehicle_id
			elseif component_name == "ShipAutoTeleportSwitchButtons" then
				g_savedata.shipAutoTeleportSwitcher = vehicle_id
			elseif component_name == "Drone_Spawner" then
				g_savedata.drone_spawner = vehicle_id
			end
		end
	end
end

autoSeatList = {}

function onVehicleSpawn(vehicle_id, peer_id, x, y, z, cost)
	if (peer_id >= 0) then
		vehicle_pos = matrix.translation(x,y,z)
		is_hanger_in_zone, hanger_success = server.isInZone(vehicle_pos, "Creative_hanger_Spawn")
		is_dock_in_zone, dock_success = server.isInZone(vehicle_pos, "Creative_Dock_Spawn")
		
		
		if (is_hanger_in_zone and hanger_success ) then
			if (g_savedata.auto_teleport) then
				local spawn_pos = matrix.multiply(matrix.invert(hanger_pos),vehicle_pos)
				spawn_pos = matrix.multiply(static_weapon_position,spawn_pos)
				local x,y,z = matrix.position(spawn_pos)
				spawn_pos = matrix.translation(x,y,z)
				spawn_pos = matrix.multiply(spawn_pos,matrix.rotationToFaceXZ(0, -1))
				
				--is_success = server.setVehiclePosSafe(vehicle_id, spawn_pos)
				is_success = server.setVehiclePos(vehicle_id, spawn_pos)
				
				if static_player_position ~= nil then
					is_success = server.setPlayerPos(peer_id, static_player_position)
				end
				
				if (g_savedata.weapon_tester ~= nil and dock_ai_pos ~= nil ) then
					server.setObjectPos(g_savedata.weapon_tester, dock_ai_pos)
				end
			elseif (g_savedata.target_teleport) then
				local spawn_pos = matrix.multiply(matrix.invert(hanger_pos),vehicle_pos)
				spawn_pos = matrix.multiply(hanger_target_pos,spawn_pos)
				local x,y,z = matrix.position(spawn_pos)
				spawn_pos = matrix.translation(x,y,z)
				spawn_pos = matrix.multiply(spawn_pos,matrix.rotationToFaceXZ(-1, 0))
				
				--is_success = server.setVehiclePosSafe(vehicle_id, spawn_pos)
				is_success = server.setVehiclePos(vehicle_id, spawn_pos)
				
				if (g_savedata.weapon_tester ~= nil and hanger_ai_pos ~= nil ) then
					server.setObjectPos(g_savedata.weapon_tester, hanger_ai_pos)
				end
			else
				if (g_savedata.weapon_tester ~= nil and hanger_ai_pos ~= nil ) then
					server.setObjectPos(g_savedata.weapon_tester, hanger_ai_pos)
				end
			end
			
			autoSeatList[ tostring(vehicle_id) ] = peer_id
			
		elseif (is_dock_in_zone and dock_success ) then
			if (g_savedata.ship_target_teleport) then
				local spawn_pos = matrix.multiply(matrix.invert(dock_pos),vehicle_pos)
				spawn_pos = matrix.multiply(dock_target_pos,spawn_pos)
				local x,y,z = matrix.position(spawn_pos)
				spawn_pos = matrix.translation(x,y,z-distance_offset)
				spawn_pos = matrix.multiply(spawn_pos,matrix.rotationToFaceXZ(1, 0))
				
				is_success = server.setVehiclePosSafe(vehicle_id, spawn_pos)
			end
			
			if (g_savedata.weapon_tester ~= nil and dock_ai_pos ~= nil ) then
				server.setObjectPos(g_savedata.weapon_tester, dock_ai_pos)
			end
			
			autoSeatList[ tostring(vehicle_id) ] = peer_id
		end
	end
end

function onVehicleLoad(vehicle_id)
	local t = autoSeatList[ tostring(vehicle_id) ]
	if ( t ~= nil ) then
		local object_id, is_success = server.getPlayerCharacterID(t)
		if (is_success) then
			server.setCharacterSeated(object_id, vehicle_id, "hebis_auto_seat")
		end
		
		server.setCharacterSeated(g_savedata.weapon_tester, vehicle_id, "hebis_ai_auto_seat")
	end
	
	autoSeatList[ tostring(vehicle_id) ] = nil
end

function onCustomCommand(full_message, peer_id, is_admin, is_auth, command, one, two, three, four, five)
	if (is_auth) then
		if (command == "?spawn_tgt") then
			local v_nam = one
			local v_type = two
			local v_stype = three
			
			if (v_nam == "") or (v_nam == nil) then
				v_nam = ""
			end
			
			if (v_type == "") or (v_type == nil) then
				v_type = "ship"
			end
			if (v_stype == "") or (v_stype == nil) then
				v_stype = v_type
			end
			v_type = string.lower(v_type)
			v_stype = string.lower(v_stype)
			
			--server.spawnVehicle(float_target_area, v_nam)
			SpawnTargetFromSaveData(v_nam,v_type,v_stype)
		end
		if (command == "?jumpTo") then
			local ret = jumpToSeat(peer_id,tonumber(one))
			
			if ret >= 0 then
				server.announce("[Hebis] Target drones", "jump to target")
			else
				server.announce("[Hebis] Target drones", "failed : "..ret)
			end
		end
		if (command == "?reset_targets") then
			resetAllTargets()
			server.announce("[Hebis] Target drones", "reset all targets")
		end
		if (command == "?despawn_targets") then
			despawnAllTargets()
			server.announce("[Hebis] Target drones", "Despawned all targets")
		end
	end
end

function addSpawnedTargetData(target_parameter,COMPONENT_DATA,start_mat,first_wp)
	target_data = {
		id = COMPONENT_DATA.id,
		name = target_parameter.name,
		type = target_parameter.type,
		time = 60*60,
		ui_id = server.getMapID(),
		offset = distance_offset,
		wp = first_wp,
		start_pos = start_mat,
		last_pos = start_mat,
		set_safed = false
	}
	
	if target_data.type == "torpedo" then
		target_data.time = 180*60
	end
	
	table.insert(g_savedata.targets, target_data)
end

function spawnTargetObject(target_data,spawn_matrix)
	local data,suc = server.spawnAddonComponent(matrix.multiply(spawn_matrix,target_data.local_matrix), target_data.addon_index, target_data.location_index, target_data.component_index)
	server.setVehiclePosSafe(data.id, data.transform)
	data.transform = server.getVehiclePos(data.id)
	return data,suc
end
set_invisible = {}
function SpawnTargetFromSaveData(vehicle_name,vehicle_type,spawn_type,peer_id)
	server.announce("[Hebis Targets]", "spawnning "..vehicle_name.."\ntype :"..vehicle_type.."\nspawn:"..spawn_type, peer_id)
	if vehicle_name ~= "" then
		local target_data = {
				name = vehicle_name,
				type = vehicle_type,
				spawn_type = spawn_type,
				replace_target = "",
				local_matrix = matrix.identity()
			}
		
		local spawn_mat,first_wp = GetSpawnMatrix(target_data)
		
		if spawn_mat ~= nil then
			local tgt_id, spawn_success = server.spawnVehicle(spawn_mat, vehicle_name)
			
			if spawn_success then
				spawned_target_data = {
					id = tgt_id,
					name = target_data.name,
					type = target_data.type,
					time = 60*60,
					ui_id = server.getMapID(),
					offset = distance_offset,
					wp = first_wp,
					start_pos = spawn_mat,
					last_pos = spawn_mat,
					set_safed = false
				}
				
				if spawned_target_data.type == "torpedo" then
					spawned_target_data.time = 180*60
				end
				
				table.insert(g_savedata.targets, spawned_target_data)
				server.announce("[Hebis Targets]", "spawned "..spawned_target_data.name, peer_id)
				return true
			end
		end
	end
	
	server.notify(peer_id,"[Hebis Targets]", "failed spawn",2)
	return false
end
function SpawnTarget(target_data,peer_id)
	
	local spawn_mat,first_wp = GetSpawnMatrix(target_data)
	
	if spawn_mat ~= nil then
		local tgt, spawn_success = spawnTargetObject(target_data,spawn_mat)
		addSpawnedTargetData(target_data,tgt,spawn_mat,first_wp)
		Debuglog("spawned "..target_data.name)
		return true
	else
		server.notify(peer_id,"[Hebis Targets]", "failed spawn",2)
		return false
	end
end

function GetSpawnMatrix(target_data)
	local spawn_mat = nil
	local first_wp = matrix.identity()
	
	if ( target_data ~= nil ) then
		if (target_data.spawn_type == "float") then
			if (float_target_area ~= nil) then
				local x = float_target_area.size.x*math.random (-1000,1000)/1000/2
				local z = float_target_area.size.z*math.random (-1000,1000)/1000/2
				local offset = matrix.translation(x,0,z-distance_offset)
				spawn_mat = matrix.multiply(float_target_area.transform, offset)
			end
		elseif (target_data.spawn_type == "reflector") then
			if (drone_target_position ~= nil) then
				local dir = math.rad(math.random (-180,180))
				local dis = math.random (0,100)
				local x = math.sin(dir)*dis
				local z = -math.cos(dir)*dis
				local offset = matrix.translation(x,800,z-distance_offset)
				spawn_mat = matrix.multiply(drone_target_position, offset)
			end
		elseif (target_data.spawn_type == "drone") then
			if (drone_target_position ~= nil) then
				local dir = math.rad(math.random (-90,90))
				local x = math.sin(dir)*800
				local z = -math.cos(dir)*800
				local offset = matrix.translation(x,10,z)
				local rot_mat = matrix.rotationY(-dir)
				offset = matrix.multiply(offset, rot_mat)
				local d_offset = matrix.translation(0,0,z-distance_offset)
				offset = matrix.multiply(d_offset, offset)
				spawn_mat = matrix.multiply(drone_target_position, offset)
			end
		elseif (target_data.spawn_type == "plane") then
			if (drone_target_position ~= nil) then
				local dir = math.rad(math.random (-90,90))
				local x = math.sin(dir)*500
				local z = -math.cos(dir)*500
				local offset = matrix.translation(x,10,z)
				local rot_mat = matrix.rotationY(-dir)
				offset = matrix.multiply(offset, rot_mat)
				local d_offset = matrix.translation(0,0,z-distance_offset)
				offset = matrix.multiply(d_offset, offset)
				spawn_mat = matrix.multiply(drone_target_position, offset)
			end
		elseif (target_data.spawn_type == "ship") or (target_data.spawn_type == "torpedo") then
			if (ship_waypoint_1 ~= nil) and (ship_waypoint_2 ~= nil) then
				local offset = matrix.translation(0,0,-distance_offset)
				spawn_mat = matrix.multiply(offset , ship_waypoint_1)
				first_wp = ship_waypoint_2
			end
		elseif (target_data.spawn_type == "random_ocean")then
			local spawn_distance = math.max(1000,distance_offset)
			spawn_mat, is_success = server.getOceanTransform(static_weapon_position_noRot, spawn_distance, spawn_distance+500)
			if (not is_success) then
				spawn_mat = nil
			else
				first_wp = RandomCirclePos(spawn_mat,500)
				local s_x,s_y,s_z = matrix.position(spawn_mat)
				local w_x,w_y,w_z = matrix.position(first_wp)
				
				local spawn_rotation = matrix.rotationToFaceXZ(w_x-s_x, w_z-s_z)
				
				spawn_mat = matrix.multiply(spawn_mat, spawn_rotation)
			end
		elseif (target_data.spawn_type == "missile_random") then
			local spawn_distance = math.max(1000,distance_offset)
			spawn_mat, is_success = server.getOceanTransform(static_weapon_position_noRot, spawn_distance, spawn_distance+500)
			if (not is_success) then
				spawn_mat = nil
			else
				first_wp = static_weapon_position_noRot
				local s_x,s_y,s_z = matrix.position(spawn_mat)
				local w_x,w_y,w_z = matrix.position(first_wp)
				
				local spawn_rotation = matrix.rotationToFaceXZ(w_x-s_x, w_z-s_z)
				
				spawn_mat = matrix.multiply(spawn_mat, spawn_rotation)
			end
		elseif (target_data.spawn_type == "missile") then
				local dir = math.rad(math.random (-45,45))
				local x = math.sin(dir)*(distance_offset+1000)
				local z = -math.cos(dir)*(distance_offset+1000)
				local offset = matrix.translation(x,10,z)
				spawn_mat = matrix.multiply(static_weapon_position_noRot, offset)
				
				local s_x,s_y,s_z = matrix.position(spawn_mat)
				local w_x,w_y,w_z = matrix.position(static_weapon_position_noRot)
				
				local spawn_rotation = matrix.rotationToFaceXZ(w_x-s_x, w_z-s_z)
				spawn_mat = matrix.multiply(spawn_mat, spawn_rotation)
		else
			if (float_target_area ~= nil) then
				local offset = matrix.translation(0,0,-distance_offset)
				spawn_mat = matrix.multiply(float_target_area.transform, offset)
			end
		end
	end
	
	return spawn_mat,first_wp
end

function RandomCirclePos (pos_mat,distance)
	local x,y,z = matrix.position(pos_mat)
	local dir = math.rad(math.random (-180,180))
	local a = math.sin(dir)*distance
	local b = math.cos(dir)*distance
	
	return matrix.translation(x+a,y,z+b)
end

function Distance2D(matrix1,matrix2)
	if matrix1 == nil or matrix2 == nil then
		return math.huge
	end
	local x1,y1,z1 = matrix.position(matrix1)
	local x2,y2,z2 = matrix.position(matrix2)

	return math.sqrt((x1-x2)*(x1-x2)+(z1-z2)*(z1-z2))
end

function hasTag(tags,tag)
	if tags ~= nil and type(tags)=="table" then
		for k,v in pairs(tags) do
			if v == tag then
				return true
			end
		end
	elseif type(tags)=="string" then
		return tags == tag
	end

	return false
end


function getParameters(d,tags)
	if tags ~= nil then
		for _,tag in pairs(tags) do
			local l = split(tag,"=")
			if (#l==2) then
				if l[1]=="name" then
					d[l[1]] = l[2]
				elseif l[1]=="replace_target" then
					d[l[1]] = l[2]
				else
					d[l[1]] = string.lower(l[2])
				end
			end
		end
	end
	return d
end
function split(str, ts)
	if ts == nil then return {} end

	local t = {}
	i=1
	for s in string.gmatch(str, "([^"..ts.."]+)") do
		t[i] = s
		i = i + 1
	end

	return t
end

function iterPlaylists()
	local playlist_count = server.getPlaylistCount()
	local playlist_index = 0

	return function()
		local playlist_data = nil
		local index = playlist_count

		while playlist_data == nil and playlist_index < playlist_count do
			playlist_data = server.getPlaylistData(playlist_index)
			index = playlist_index
			playlist_index = playlist_index + 1
		end

		if playlist_data ~= nil then
			return index,playlist_data
		else
			return nil
		end
	end
end

function iterLocations(playlist_index)
	local playlist_data = server.getPlaylistData(playlist_index)
	local location_count = 0
	if playlist_data ~= nil then location_count = playlist_data.location_count end
	local location_index = 0

	return function()
		local location_data = nil
		local index = location_count

		while location_data == nil and location_index < location_count do
			location_data = server.getLocationData(playlist_index,location_index)
			index = location_index
			location_index = location_index + 1
		end

		if location_data ~= nil then
			return index,location_data
		else
			return nil
		end
	end
end

function iterObjects(playlist_index,location_index)
	local location_data = server.getLocationData(playlist_index,location_index)
	local object_count = 0
	if location_data ~= nil then object_count = location_data.component_count end
	local object_index = 0

	return function()
		local object_data = nil
		local index = object_count

		while object_data == nil and object_index < object_count do
			object_data = server.getLocationComponentData(playlist_index,location_index,object_index)
			object_data.index = object_index
			index = object_index
			object_index = object_index + 1
		end

		if object_data ~= nil then
			return index,object_data
		else
			return nil
		end
	end
end

g_output_log = {}
function Debuglog(text)
	if debug then
		table.insert(g_output_log,text)
	end
end





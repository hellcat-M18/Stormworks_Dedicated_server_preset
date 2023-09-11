-- g_savedata table that persists between game sessions
g_savedata = {}

g_savedata.auto_tp = false



function GetZoneTransform(zone_name)

	ZONE_LIST = server.getZones()
	
	zone_transform = matrix.translation(0,0,0)
	
	for key,value in pairs(ZONE_LIST) do
		
		if value.name == zone_name then
			
			zone_transform = value.transform
		end
	
	end
	
	return zone_transform

end




-- Tick function that will be executed every logic tick
function onTick(game_ticks)

end

function onButtonPress(vehicle_id, peer_id, button_name, is_pressed)
	
	if is_pressed then
	
		if button_name == "tp switch" then
		
			g_savedata.auto_tp = not g_savedata.auto_tp
			
			
			if g_savedata.auto_tp then
				
				server.pressVehicleButton(vehicle_id, "reset")
			
			else server.pressVehicleButton(vehicle_id, "set")

			end
		
		end
		
	end
	
end


function onVehicleSpawn(vehicle_id, peer_id, x, y, z, cost)
	
	if g_savedata.auto_tp == true then
		
		vehicle_pos, is_success = server.getVehiclePos(vehicle_id)
		
		is_in_zone, is_success = server.isInZone(vehicle_pos, "hanger")

		 if is_in_zone then

			hanger_transform = GetZoneTransform("hanger")
			
			x1,y1,z1 = matrix.position(zone_transform)
			
			spawn_transform = GetZoneTransform("spawn")
			
			x2,y2,z2 = matrix.position(spawn_transform)
			
			x3,y3,z3 = matrix.position(vehicle_pos)
			
			
			spawn_pos = matrix.translation(z3-z1+x2,y3-y1+y2,(x3-x1)*-1+z2)

			pl_pos = matrix.translation(z3-z1+x2-10,y3-y1+y2,(x3-x1)*-1+z2)
			
			Rotation = matrix.rotationToFaceXZ(0, -1)
			
			spawn_pos = matrix.multiply(spawn_pos,Rotation)

	
			is_success = server.setVehiclePos(vehicle_id, spawn_pos)

			server.setPlayerPos(peer_id, pl_pos)
		
		end
	
	end

end


			
			
			
			
		
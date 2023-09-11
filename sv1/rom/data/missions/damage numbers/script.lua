sv = server

damageNumbers={}
idStorage={}
playerNumberExclusion={}

NUMBER_LIFESPAN = 60

zVel = 30
zGravity = 30

low_performance_mode = true


function onTick(game_ticks)
	local plys = sv.getPlayers()
	for k,v in pairs(damageNumbers) do
		v[5] = v[5] - 1
		if not low_performance_mode then
			if v[5] <= NUMBER_LIFESPAN - 5 and v[5] > 0 then
				for pk,pv in pairs(plys) do
					if not playerNumberExclusion[pv.id] then
						sv.setPopup(pv.id, v[1], "Pop!", true, math.floor(v[6]), v[2],v[3],v[4],2500)
					end
				end
				v[3] = v[3] + v[7]/60
				v[7] = v[7] - zGravity/60
			end
		else
			if v[5] == NUMBER_LIFESPAN - 5 then
				for pk,pv in pairs(plys) do
					if not playerNumberExclusion[pv.id] then
						sv.setPopup(pv.id, v[1], "Pop!", true, math.floor(v[6]), v[2],v[3],v[4],2500)
					end
				end
			end
		end
		if v[5] <= 0 then
			--sv.removePopup(-1,v[1])
			sv.setPopup(-1, v[1], "Pop!", true, ".", 0,0,0,1)
			idStorage[#idStorage+1] = v[1]
			damageNumbers[k] = nil
		end
	end
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)

end

function onPlayerLeave(steam_id, name, peer_id, is_admin, is_auth)
	playerNumberExclusion[peer_id] = nil
end

function onCustomCommand(f_msg, peer_id, is_admin, is_auth, command, arg1, arg2, arg3, arg4)
	
	
	if command == "?damagenumbers_pop" and is_admin then
		low_performance_mode = not low_performance_mode
		if low_performance_mode then
			sv.announce("[Damage Numbers]", "Damage Number animations turned off.")
		else
			sv.announce("[Damage Numbers]", "Damage Number animations turned on.")
		end
	end
	
	if command == "?damagenumbers_toggle" then
		local excl = playerNumberExclusion[peer_id]
		if excl then
			playerNumberExclusion[peer_id] = nil
			sv.announce("[Damage Numbers]", "Damage Numbers turned on", peer_id)
		else
			playerNumberExclusion[peer_id] = 1
			sv.announce("[Damage Numbers]", "Damage Numbers turned off", peer_id)
		end
	end
end

function onVehicleDamaged(vehicle_id, damage_amount, vx, vy, vz)
	local vpos, suc = server.getVehiclePos(vehicle_id, vx, vy, vz)
	local existingNum = nil
	local numKey = nil
	local existingNum = damageNumbers[vehicle_id]
	if suc then
		local x,y,z = matrix.position(vpos)
		local UiId = sv.getMapID()
		if #idStorage > 0 then
			UiId = table.remove(idStorage)
		end
		if not existingNum then
			damageNumbers[vehicle_id] = {UiId, x, y, z, NUMBER_LIFESPAN, damage_amount, zVel}
		else
			local combinedDamage = damage_amount+existingNum[6]
			damageNumbers[vehicle_id][5] = NUMBER_LIFESPAN
			damageNumbers[vehicle_id][6] = combinedDamage
			damageNumbers[vehicle_id][2] = x
			damageNumbers[vehicle_id][3] = y
			damageNumbers[vehicle_id][4] = z
			damageNumbers[vehicle_id][7] = zVel
		end
	end
end
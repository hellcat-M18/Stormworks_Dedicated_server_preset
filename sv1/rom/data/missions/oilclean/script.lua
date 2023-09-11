g_savedata = {}
--OilSpill_Pos_list_x = {}
--OilSpill_Pos_list_y = {}
--OilSpill_data_total = {}

--world_oil_max = 0
--world_oil_total = 0
-------------------------------------------------------------------------------------------------------------------------------------
function onTick(game_ticks)end
function onVehicleDespawn(vehicle_id, peer_id)
	for i = -30, 30 do
		for j = -40, 100 do
			local transform_matrix = matrix.translation(i*1000,0,j*1000)
			server.setOilSpill(transform_matrix, 0)
		end
	end
end

-------------------------------------------------------------------------------------------------------------------------------------
--[[function onOilSpill(tile_x, tile_y, delta, total, vehicle_id)
	
	tile_x = tile_x *1000
	tile_y = tile_y *1000
	
	
	for i, value in ipairs(OilSpill_Pos_list_x) do
		if (OilSpill_Pos_list_x[i] == tile_x) and (OilSpill_Pos_list_y[i] == tile_y) then
			table.remove(OilSpill_Pos_list_x,i)
			table.remove(OilSpill_Pos_list_y, i)
			
			table.remove(OilSpill_data_total, i)
		end
	end
	
	
	table.insert(OilSpill_Pos_list_x, tile_x)
	table.insert(OilSpill_Pos_list_y, tile_y)
	
	--table.insert(OilSpill_data_delta, delta)
	table.insert(OilSpill_data_total, total)
	--table.insert(OilSpill_data_vehicle_id, vehicle_id)
	
	--oil_amount = server.getOilSpill(transform_matrix)
	
	world_oil_max   = math.max(delta, 0) + world_oil_max
	world_oil_total = delta + world_oil_total
	
	--server.announce("[Clean Oil]", "Called2")
	--server.announce("[Clean Oil]", tile_x.." , "..tile_y)
	--server.announce("[Clean Oil]", OilSpill_Pos_list_x[#OilSpill_Pos_list_x])
	--server.announce("[Clean Oil]", #OilSpill_Pos_list_x)
	--server.announce("[Clean Oil]", world_oil_max)
	--server.announce("[Clean Oil]", world_oil_total)
end]]
-------------------------------------------------------------------------------------------------------------------------------------
function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, one, two, three, four, five)
--[[if (is_auth == true) and (command == "?oil") and (one == "clean" or one == "c") then
	
		for i, value in ipairs(OilSpill_Pos_list_x) do
		
			local x, z = OilSpill_Pos_list_x[i], OilSpill_Pos_list_y[i]
			local transform_matrix = matrix.translation(x*1000,0,z*1000)
			server.setOilSpill(transform_matrix, 0)
			
		end
		
		server.announce("[Clean Oil]", "Cleaned")
		
	end
	---------------------------------------------------------------------------------------------------------------------------------
	if (is_auth == true) and (command == "?oil") and (one == "currentamount" or one == "a") then
		
		local oil_amount, recordtotal = 0, 0
		for i, value in ipairs(OilSpill_Pos_list_x) do
			
			local x, z = OilSpill_Pos_list_x[i], OilSpill_Pos_list_y[i]
			local transform_matrix = matrix.translation(x*1000,0,z*1000)
			oil_amount = server.getOilSpill(transform_matrix) + oil_amount
			recordtotal = OilSpill_data_total[i] + recordtotal
			
		end
		
		server.announce("[Clean Oil]", "record total oil level : "..world_oil_total)
		server.announce("[Clean Oil]", "table total oil : "..recordtotal)
		server.announce("[Clean Oil]", "oil_amount:"..oil_amount)
		
	end]]
	---------------------------------------------------------------------------------------------------------------------------------
	if (is_auth == true) and (command == "?oil") and (one == "clean" or one == "c") then
	
		server.announce("[Clean Oil]", "Oil Cleaned")
		
	end
	---------------------------------------------------------------------------------------------------------------------------------
	if (is_auth == true) and (command == "?oil") and (one == "Allclean" or one == "AC") then
		
		--server.announce("[Clean Oil]", "Now All Tiles Cleaning...")
		--local oil_amount, cleaned_oil_amount, tiles = 0, 0, 0
		for i = -128, 128 do
			for j = -128, 128 do
				
				local transform_matrix = matrix.translation(i*1000,0,j*1000)
				--oil_amount = server.getOilSpill(transform_matrix) + oil_amount
				server.setOilSpill(transform_matrix, 0)
				--cleaned_oil_amount = server.getOilSpill(transform_matrix) + cleaned_oil_amount
				--tiles = tiles + 1
				
			end
		end
		
		--server.announce("[Clean Oil]", "clean tiles :"..tiles)
		--server.announce("[Clean Oil]", "oil amount:"..oil_amount)
		--server.announce("[Clean Oil]", "cleaned oil amount : "..cleaned_oil_amount)
		server.announce("[Clean Oil]", "All Tiles Cleaned")
		
	end
	---------------------------------------------------------------------------------------------------------------------------------
	if (is_auth == true) and (command == "?oil") and (one == "set" or one == "s") then
		
		if (type(two) ~= "string") or (tonumber(two) < 0) then
			server.announce("[Clean Oil]", "Specify a set amount.")
			return
		end
		if (type(three) ~= "number") or (tonumber(three) < 0) then
			three = 0
		end
		if (type(four) ~= "number") or (tonumber(four) < 0) then
			four = 0
		end
		
		if (tonumber(three) == 0) and (tonumber(four) == 0) then
			transform_matrix, is_success = server.getPlayerPos(user_peer_id)
			if (is_success == false) then
				server.announce("[Clean Oil]", "Is not success : getPlayerPos")
				return
			else
				server.announce("[Clean Oil]", "Is success : getPlayerPos")
			end
		else
			transform_matrix = matrix.translation(three,0,four)
		end
		
		server.setOilSpill(transform_matrix, two / 10)
		
		if (is_success == true) then
			server.announce("[Clean Oil]", "Oil Pos Set : Player")
		end
		server.announce("[Clean Oil]", "Oil Amount Set : "..two)
	end
	---------------------------------------------------------------------------------------------------------------------------------
	if (is_auth == true) and (command == "?oil") and (one == "currentamount" or one == "a") then
		
		local oil_amount = 0
		for i = -30, 30 do
			for j = -40, 100 do
				
				local transform_matrix = matrix.translation(i*1000,0,j*1000)
				oil_amount = server.getOilSpill(transform_matrix) + oil_amount
				
			end
		end
		
		server.announce("[Clean Oil]", "oil amount:"..oil_amount * 10)
		
	end
	---------------------------------------------------------------------------------------------------------------------------------
	if (is_auth == true) and (command == "?oil") and (one == "Allcurrentamount" or one == "aa") then
		
		local all_oil_amount = 0
		for i = -128, 128 do
			for j = -128, 128 do
				
				local transform_matrix = matrix.translation(i*1000,0,j*1000)
				all_oil_amount = server.getOilSpill(transform_matrix) + all_oil_amount
				
			end
		end
		
		server.announce("[Clean Oil]", "all tiles oil amount:"..all_oil_amount)
		
	end
end
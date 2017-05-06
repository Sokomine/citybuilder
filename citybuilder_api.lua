

-- register the building in the citybuilder.cities data structure;
-- there can only be one building at a given position
citybuilder.city_add_building = function( city_id, data)
	local building_id = minetest.pos_to_string( data.pos );
	local building_data = build_chest.building[ data.building_name ];
	-- add some information
	data.building_name = building_data.scm;
	data.placed = os.time();
	citybuilder.cities[ city_id ].buildings[ building_id ] = data;
	citybuilder.save_data();
end


-- unregister a building
citybuilder.city_delete_building = function( building_id )
	for city_id,v in pairs( citybuilder.cities ) do
		if( v.buildings[ building_id ] ) then
			citybuilder.cities[ city_id ].buildings[ building_id ] = nil;
		end
	end
	citybuilder.save_data();
end


-- count buildings inside a city
citybuilder.city_get_anz_buildings = function( city_id )
	if( not( city_id ) or not( citybuilder.cities[ city_id ])) then
		return 0;
	end
	local anz_buildings = 0;
	for k,v in pairs( citybuilder.cities[ city_id ].buildings) do
		anz_buildings = anz_buildings + 1;
	end
	return anz_buildings;
end


-- search for a building at a given position and return data from the city data structure
citybuilder.city_get_building_at = function( pos )
	local building_id = minetest.pos_to_string( pos );
	for city_id,v in pairs( citybuilder.cities ) do
		if( v.buildings[ building_id ] ) then
			-- provide a current city_id
			citybuilder.cities[ city_id ].buildings[ building_id ].city_id = city_id;
			return citybuilder.cities[ city_id ].buildings[ building_id ];
		end
	end
end


-- can the building at position pos be upgraded?
citybuilder.city_can_upgrade_building = function( pos )
	local building_id = minetest.pos_to_string( pos );
	local stored_building = citybuilder.city_get_building_at( pos );
	-- is there a building at that position?
	if( not( stored_building )) then
		return;
	end
	-- is an upgrade defined?
	local building_data = build_chest.building[ citybuilder.mts_path..stored_building.building_name ];
	if( not(building_data) or not(building_data.upgrade_to)) then
		return;
	end
	-- get the data about the new building
	local upgrade_data = build_chest.building[ citybuilder.mts_path..building_data.upgrade_to ];
	-- get the city data
	local city_data = citybuilder.cities[ stored_building.city_id ];
	-- city and upgrade building both need to exist
	if( not(upgrade_data) or not(city_data)) then
		return;
	end

	-- upgrade is allowed if all requirements are fullfilled
	if( not(citybuilder.city_requirements_missing( city_data, upgrade_data.requires, ""))) then
		return building_data.upgrade_to;
	end
end


-- lists all requirements the current buildings in the city may fullfill
-- that is: get the maximum level of whatever the buildings provide
citybuilder.city_requirements_met = function( city_data, except_building_id )
	local req_met = {};
	if( not( city_data )) then
		return req_met;
	end
	-- get the maximum level of whatever the buildings provide
	for k,v in pairs( city_data.buildings ) do
		-- one building can be excluded from this comparison
		if( k ~= except_building_id ) then
			local building_data = build_chest.building[ citybuilder.mts_path..v.building_name ];
			if( building_data and building_data.provides and building_data.citybuilder
			  and (not( req_met[ building_data.provides ] ) or req_met[ building_data.provides ]<building_data.level )) then
				req_met[ building_data.provides ] = building_data.level;
			end
		end
	end
	return req_met;
end


-- checks if the city described in city_data fullfills the requiremens given; the building
-- given in except_building_id is excluded from this check (this we can check if it can be
-- removed/downgraded)
citybuilder.city_requirements_missing = function( city_data, requirements, except_building_id )
	if( not( requirements )) then
		return;
	end
	local req_met = citybuilder.city_requirements_met( city_data, except_building_id );
	local missing = {};
	local found = 0;
	-- now compare that to the actual requirements
	for k,v in pairs( requirements ) do
		-- return nil as soon as one requirement is not fullfilled
		if( not( req_met[ k ]) or req_met[ k ]<v ) then
			missing[ k ] = v;
			found = found+1;
		end
	end
	if( found>0 ) then
		return missing;
	end
end


-- helper function; returns true if pos is located inside the volume spanned by p1 and p2
citybuilder.pos_is_inside = function( pos, p1, p2 )
	return (pos.x >= math.min(p1.x,p2.x) and pos.x <= math.max(p1.x,p2.x)
	    and pos.y >= math.min(p1.y,p2.y) and pos.y <= math.max(p1.y,p2.y)
	    and pos.z >= math.min(p1.z,p2.z) and pos.z <= math.max(p1.z,p2.z));
end


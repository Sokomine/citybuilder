

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


-- from which building has this one been upgraded?
-- returns nil if nothing found
citybuilder.city_get_downgrade = function( pos )
	local stored_building = citybuilder.city_get_building_at( pos );
	-- is there a building at that position?
	if( not( stored_building )) then
		return;
	end
	-- return the first suitable building found
	for k,v in pairs( build_chest.building ) do
		if( v and v.upgrade_to and v.upgrade_to == stored_building.building_name ) then
			return k;
		end
	end
end


-- is a downgrade possible without violating requirements?
citybuilder.city_can_downgrade_building = function( pos )
	local stored_building = citybuilder.city_get_building_at( pos );
	-- is there a building at that position?
	if( not( stored_building ) or not( stored_building.city_id) or not( citybuilder.cities[ stored_building.city_id ])) then
		return false;
	end
	-- get information about the building type
	local building_data = build_chest.building[ citybuilder.mts_path..stored_building.building_name ];
	if( not(building_data) or not(building_data.provides)) then
		return false;
	end
	-- check if what this building provides is needed in the city at this level
	local building_id = minetest.pos_to_string( pos );
	local city_data = citybuilder.cities[ stored_building.city_id ];
	local min_req = -1;
	local min_provided = -1;
	for k,v in pairs( city_data.buildings ) do
		if( k ~= building_id ) then
			local b = build_chest.building[ citybuilder.mts_path..v.building_name ];
			-- if there is another building which provides the same at this or a higher level we are done
			if( b and b.provides and b.provides == building_data.provides ) then
				if(b.level >= building_data.level ) then
					-- all ok; that building here provides the same at the same or higher level
					return true;
				elseif( b.level >= min_provided ) then
					min_provided = b.level;
				end
			end
			if( b.requires ) then
				for typ, level in pairs( b.requires ) do
					if( typ==building_data.provides ) then
						if( level > min_req) then
							min_req = level;
						end
					end
				end
			end
		end
	end
	-- another building provides it at a sufficiently high level
	if( min_provided >= min_req ) then
		return true;
	end
	-- the new buidling will provide the same at one level less
	if( min_req <= building_data.level - 1 ) then
		return true;
	end
	return false;
end


-- helper function; returns true if pos is located inside the volume spanned by p1 and p2
citybuilder.pos_is_inside = function( pos, p1, p2 )
	return (pos.x >= math.min(p1.x,p2.x) and pos.x <= math.max(p1.x,p2.x)
	    and pos.y >= math.min(p1.y,p2.y) and pos.y <= math.max(p1.y,p2.y)
	    and pos.z >= math.min(p1.z,p2.z) and pos.z <= math.max(p1.z,p2.z));
end


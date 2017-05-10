

-- check blueprint data and add it to the build_chest.buildings data structure from handle_schematics;
-- includes some checks regarding up/downgrade and required fields
citybuilder.add_blueprint = function( path, data, modname )
	-- required fields
	if(  not( data )
	  or not( data.scm )
	  or not( data.provides)
	  or not( data.level)
	  or not( data.title )
	  or not( data.descr )) then
		print("[citybuilder] Error: Not adding "..minetest.serialize( data ).." due to missing fields (scm, provides, level, title and/or descr).");
		return;
	end

	-- there can only be one file per filename...even if it is using a diffrent path
	if( citybuilder.full_filename[ data.scm ]) then
		print("[citybuilder] Error: "..tostring( data.scm ).." - duplicate filename.");
		return;
	end

	-- necessary in order to determine the full filename (without extension)
	if( not(path )) then
		data.path = citybuilder.mts_path;
	else
		data.path = path;
	end

	local downgrade_building = nil;
	-- find out if any other building can be upgraded to this one and set downgrade_to
	for k,v in pairs( build_chest.building ) do
		if( v and v.scm and v.citybuilder and v.upgrade_to == data.scm ) then
			data.downgrade_to = v.scm;
			downgrade_building = v;
			if( v.provides ~= data.provides ) then
				print("[citybuilder] Error: " ..tostring( data.scm ).." provides something else than "..tostring( v.data.scm ).." from which it can be upgraded.");
				return;
			end
			if( v.level+1 ~= data.level ) then
				print("[citybuilder] Error: " ..tostring( data.scm ).." has not level+1 of "..tostring( v.data.scm ).." from which it can be upgraded.");
				return;
			end
		end
	end

	local upgrade_building = nil;
	-- make sure that the level of the building we upgrade to also fits
	if( data.upgrade_to ) then
		upgrade_building = citybuilder.city_get_building_data( data.upgrade_to );
		if( upgrade_building and upgrade_building.level-1 ~= data.level) then
			print("[citybuilder] Error: " ..tostring( data.scm ).." has not level-1 of "..tostring( upgrade_building.scm ).." to which it can be upgraded.");
			return;
		end
	end

	if( upgrade_building ) then
		upgrade_building.downgrade_to = data.scm;
	end

	-- the upgrade building has to provide the same
	if( upgrade_building
	  and upgrade_building.provides ~= data.provides ) then
		print("[citybuilder] Error: " ..tostring( data.scm ).." provides something else than "..tostring( v.data.scm ).." to which it can be upgraded.");
		return;
	end

	-- register the building so that handle_schematics can analyze the blueprint and keep it ready
	build_chest.add_building(  data.path..data.scm, data );
	-- create preview images, statistics etc
	build_chest.read_building( data.path..data.scm, data );

	-- check size
	if( downgrade_building and downgrade_building.size
	  and( (downgrade_building.size.x ~= data.size.x)
	    or (downgrade_building.size.y ~= data.size.y)
	    or (downgrade_building.size.z ~= data.size.z))) then
		print("[citybuilder] Error: " ..tostring( data.scm ).." and "..tostring( downgrade_building.scm ).." (from which it is upgraded) are not the same size.");
		-- citybuilder will not cover this building
		data.citybuilder = nil;
		return;
	end
	if( upgrade_building   and upgrade_building.size
	  and( (upgrade_building.size.x ~= data.size.x)
	    or (upgrade_building.size.y ~= data.size.y)
	    or (upgrade_building.size.z ~= data.size.z))) then
		print("[citybuilder] Error: " ..tostring( data.scm ).." and "..tostring( upgrade_building.scm ).." (to which this one could be upgraded) are not the same size.");
		-- citybuilder will not cover this building
		data.citybuilder = nil;
		return;
	end

	-- add the building to the build chest
	if( not( modname ) or modname == "" ) then
		modname = "citybuilder";
	end
	build_chest.add_entry( {'main','mods', modname, data.provides, data.scm, data.path..data.scm});
	-- there has to be a first building in each series which does not require any predecessors;
	-- it will be offered as something the player can build
	-- (upgrades are then available at the particular building)
	if( not( data.requires ) and data.level==0) then
		table.insert( citybuilder.starter_buildings, data.scm );
	end

	-- downgrade_to, upgrade_to and building_name are filenames without the path
	citybuilder.full_filename[ data.scm ] = data.path..data.scm;

	-- this is a building that belongs to the citybuilder mod
	data.citybuilder = 1;
end


citybuilder.city_get_building_data = function( filename )
	if( not( filename ) or not( citybuilder.full_filename )) then
		return;
	end
	return build_chest.building[ citybuilder.full_filename[ filename ]];
end


-- register the building in the citybuilder.cities data structure;
-- there can only be one building at a given position
citybuilder.city_add_building = function( city_id, data)
	local building_id = minetest.pos_to_string( data.pos );
	local building_data = citybuilder.city_get_building_data( data.building_name );
	-- add some information
	if( not( building_data )) then
		return false;
	end
	data.building_name = building_data.scm;
	data.placed = os.time();
	citybuilder.cities[ city_id ].buildings[ building_id ] = data;
	citybuilder.save_data();
	return true;
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
	local building_data = citybuilder.city_get_building_data( stored_building.building_name );
	if( not(building_data) or not(building_data.upgrade_to)) then
		return;
	end
	-- get the data about the new building
	local upgrade_data = citybuilder.city_get_building_data( building_data.upgrade_to );
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
			local building_data = citybuilder.city_get_building_data( v.building_name );
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
-- returns nil if nothing found; returns building data on success
citybuilder.city_get_downgrade_data = function( pos )
	local stored_building = citybuilder.city_get_building_at( pos );
	local building_data = citybuilder.city_get_building_data( stored_building.building_name );
	-- is there a building at that position?
	if( not( building_data ) or not( building_data.downgrade_to)) then
		return;
	end
	return citybuilder.city_get_building_data( building_data.downgrade_to );
end


-- is a downgrade possible without violating requirements?
citybuilder.city_can_downgrade_building = function( pos )
	local stored_building = citybuilder.city_get_building_at( pos );
	-- is there a building at that position?
	if( not( stored_building ) or not( stored_building.city_id) or not( citybuilder.cities[ stored_building.city_id ])) then
		return false;
	end
	-- get information about the building type
	local building_data = citybuilder.city_get_building_data( stored_building.building_name );
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
			local b = citybuilder.city_get_building_data( v.building_name );
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


-- interface for mobs to perform updates; players ought to use the formspecs provided (players
-- will want to read the formspec returned, but mobs can't read and can ignore it)
citybuilder.update_building_at = function( pos, clicker )
	-- the update function will return a formspec
	local formspec = citybuilder.constructor_update( pos, clicker, minetest.get_meta( pos ), nil, nil, nil );
	if( formspec and formspec ~= "" ) then
		return true;
	else
		return false;
	end
end

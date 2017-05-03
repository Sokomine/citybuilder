

-- register the building in the citybuilder.cities data structure;
-- there can only be one building at a given position
citybuilder.city_add_building = function( city_id, data)
	local building_id = minetest.pos_to_string( data.pos );
	local building_data = build_chest.building[ data.building_name ];
	citybuilder.cities[ city_id ].buildings[ building_id ] = {
			pos = data.pos,
			start_pos = data.start_pos,
			end_pos = data.end_pos,
			-- store here without path
			building_name = building_data.scm,
			rotate = data.rotate,
			mirror = data.mirror,
			placed = os.time() };
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


citybuilder.city_get_building_at = function( pos )
	local building_id = minetest.pos_to_string( pos );
	for city_id,v in pairs( citybuilder.cities ) do
		if( v.buildings[ building_id ] ) then
			return citybuilder.cities[ city_id ].buildings[ building_id ];
		end
	end
end

-- helper function; returns true if pos is located inside the volume spanned by p1 and p2
citybuilder.pos_is_inside = function( pos, p1, p2 )
	return (pos.x >= math.min(p1.x,p2.x) and pos.x <= math.max(p1.x,p2.x)
	    and pos.y >= math.min(p1.y,p2.y) and pos.y <= math.max(p1.y,p2.y)
	    and pos.z >= math.min(p1.z,p2.z) and pos.z <= math.max(p1.z,p2.z));
end


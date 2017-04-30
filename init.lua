
citybuilder = {};

-- path to the current mod
citybuilder.modpath = minetest.get_modpath( minetest.get_current_modname());

-- folder where the buildings can be found
citybuilder.mts_path = citybuilder.modpath..'/schems/';

-- configure some parameters
dofile(citybuilder.modpath.."/config.lua")

-- load information about available buildings
dofile(citybuilder.modpath.."/citybuilder_buildings.lua")

-- helper functions and input handling
dofile(citybuilder.modpath.."/citybuilder_misc.lua")

-- the tool used to place, construct, repair and upgrade said buildings
dofile(citybuilder.modpath.."/citybuilder_constructor.lua")

-- tool found in the townhall; hands out the construction tool from above
dofile(citybuilder.modpath.."/citybuilder_townadmin.lua")



-- only level 0 buildings are available at the beginning; all other buildings
-- can only be obtained through upgrades of said level 0 buildings
citybuilder.starter_buildings = {};

for i,v in ipairs( citybuilder.buildings ) do
	-- this is a building that belongs to the citybuilder mod
	v.citybuilder = 1;
	-- register the building so that handle_schematics can analyze the blueprint and keep it ready
	build_chest.add_building( citybuilder.mts_path..v.scm, v );
	-- create preview images, statistics etc
	build_chest.read_building( citybuilder.mts_path..v.scm, v );
	-- add the building to the build chest
	build_chest.add_entry( {'main','mods', 'citybuilder', v.provides, v.scm, citybuilder.mts_path..v.scm});
	-- there has to be a first building in each series which does not require any predecessors;
	-- it will be offered as something the player can build
	-- (upgrades are then available at the particular building)
	if( not( v.requires )) then
		table.insert( citybuilder.starter_buildings, v.scm );
	end
end

-- print("[citybuilder] Available starter buildings: "..minetest.serialize( citybuilder.starter_buildings ));


-- this table will contain information about all existing cities
citybuilder.cities = {};

-- restore saved data (makes use of save_restore from the mod handle_schematics
citybuilder.cities = save_restore.restore_data( citybuilder.savefilename );

-- save the datastructure
citybuilder.save_data = function()
	-- save datastructure
	save_restore.save_data( citybuilder.savefilename, citybuilder.cities );
end

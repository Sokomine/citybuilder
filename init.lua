
citybuilder = {};

-- path to the current mod
citybuilder.modpath = minetest.get_modpath( minetest.get_current_modname());

-- folder where the buildings can be found
citybuilder.mts_path = citybuilder.modpath..'/schems/';

-- load information about available buildings
dofile(citybuilder.modpath.."/citybuilder_buildings.lua")

-- the tool used to place, construct, repair and upgrade said buildings
dofile(citybuilder.modpath.."/citybuilder_constructor.lua")

-- tool found in the townhall; hands out the construction tool from above
dofile(citybuilder.modpath.."/citybuilder_townadmin.lua")


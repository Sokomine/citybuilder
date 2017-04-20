
citybuilder = {};

citybuilder.buildings = {
	{scm="npc_house_level_0_1_180", title="Provisory shed",    descr="Just arrived",             upgrade_to="npc_house_level_1_1_180",
		-- we need to get started somehow
		requires=nil,
		-- other workers (apart from the basic lumberjack and bartender) may
		-- not be willing to work without beeing offered a better house
		provides="housing", level=0, inh=1, worker=1, children=0},

	{scm="npc_house_level_1_1_180", title="Worker's hut",      descr="Getting settled",          upgrade_to="npc_house_level_2_1_180",
		-- the lumberjack provides the wood for this and further houses
		-- a pub attracts more workers
		requires={"lumber","pub"},
		provides="housing", level=1, inh=1, worker=1, children=0},

	{scm="npc_house_level_2_1_180", title="Tiny house",        descr="Getting married",          upgrade_to="npc_house_level_3_1_180",
		-- the miner is needed for the cobble in the building;
		-- the church is needed in order to get married :-)
		requires={"lumber","pub","mine","church"},  -- TODO: also require a ring forged from gold?
		provides="housing", level=2, inh=2, worker=2, children=0},

	{scm="npc_house_level_3_1_180", title="Small house",       descr="Founding a family",        upgrade_to="npc_house_level_4_1_180",
		-- the farmer provides straw for the roof and wheat; may also provide loam
		-- wheat + mill provide enough food for a child
		requires={"lumber","pub","mine","church","farm","mill"},
		provides="housing", level=3, inh=3, worker=2, children=1},

	{scm="npc_house_level_4_1_180", title="Family home",       descr="Room for a second child",  upgrade_to="npc_house_level_5_1_180",
		-- there are enough children for a school now;
		-- the bakery helps to feed more children more easily
		requires={"lumber","pub","mine","church","farmer","mill","bakery","school"},
		provides="housing", level=4, inh=4, worker=2, children=2},

	{scm="npc_house_level_5_1_180", title="Large family home", descr="Third child on the way",   upgrade_to="npc_house_level_6_1_180",
		-- the house uses glass; needs to come from somewhere
		-- a market might be useful for trading (more mouths to feed)
		requires={"lumber","pub","mine","church","farmer","mill","bakery","school","glassmaker","market"},
		provides="housing", level=5, inh=5, worker=2, children=3},

	{scm="npc_house_level_6_1_180", title="Family estate",     descr="Grandparents move in",     upgrade_to=nil,
		-- the grandparents will expect some level of education; thus, the library;
		-- a doctor also comes in very handy...
		requires={"lumber","pub","mine","church","farmer","mill","bakery","school","glassmaker","market","library","doctor"},
		provides="housing", level=6, inh=7, worker=3, children=0}
	};

citybuilder.starter_buildings = {};


local mts_path = minetest.get_modpath( minetest.get_current_modname())..'/schems/';

for i,v in ipairs( citybuilder.buildings ) do
	-- register the building so that handle_schematics can analyze the blueprint and keep it ready
	build_chest.add_building( mts_path..v.scm..'.mts', v );
	-- there has to be a first building in each series which does not require any predecessors;
	-- it will be offered as something the player can build
	-- (upgrades are then available at the particular building)
	if( not( v.requires )) then
		table.insert( citybuilder.starter_buildings, i );
	end	
end


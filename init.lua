
citybuilder = {};

citybuilder.buildings = {
	-- very tiny wooden cabin
	{scm="npc_house_level_0_1_180", title="Provisory shed",    descr="Just arrived",             upgrade_to="npc_house_level_1_1_180",
		-- we need to get started somehow
		requires=nil,
		-- other workers (apart from the basic lumberjack and bartender) may
		-- not be willing to work without beeing offered a better house
		provides="housing", level=0, inh=1, worker=1, children=0},

	-- wooden shed
	{scm="npc_house_level_1_1_180", title="Worker's hut",      descr="Getting settled",          upgrade_to="npc_house_level_2_1_180",
		-- the lumberjack provides the wood for this and further houses
		-- a pub attracts more workers
		requires={"lumber","pub"},
		provides="housing", level=1, inh=1, worker=1, children=0},

	-- wooden house with furnace and first farming attempts
	{scm="npc_house_level_2_1_180", title="Tiny house",        descr="Getting married",          upgrade_to="npc_house_level_3_1_180",
		-- the miner is needed for the cobble in the building;
		-- the church is needed in order to get married :-)
		requires={"lumber","pub","mine","church"},  -- TODO: also require a ring forged from gold?
		provides="housing", level=2, inh=2, worker=2, children=0},

	-- loam + wood + some farming
	{scm="npc_house_level_3_1_180", title="Small house",       descr="Founding a family",        upgrade_to="npc_house_level_4_1_180",
		-- the farmer provides straw for the roof and wheat; may also provide loam
		-- wheat + mill provide enough food for a child
		requires={"lumber","pub","mine","church","farm","mill"},
		provides="housing", level=3, inh=3, worker=2, children=1},

	-- clay + wood
	{scm="npc_house_level_4_1_180", title="Family home",       descr="Room for a second child",  upgrade_to="npc_house_level_5_1_180",
		-- there are enough children for a school now;
		-- the bakery helps to feed more children more easily
		requires={"lumber","pub","mine","church","farmer","mill","bakery","school"},
		provides="housing", level=4, inh=4, worker=2, children=2},

	-- full caly + simple glass pane windows
	{scm="npc_house_level_5_1_180", title="Large family home", descr="Third child on the way",   upgrade_to="npc_house_level_6_1_180",
		-- the house uses glass; needs to come from somewhere
		-- a market might be useful for trading (more mouths to feed)
		requires={"lumber","pub","mine","church","farmer","mill","bakery","school","glassmaker","market"},
		provides="housing", level=5, inh=5, worker=2, children=3},

	-- full brick, bookshelves, obsidian glass, ...
	{scm="npc_house_level_6_1_180", title="Family estate",     descr="Grandparents move in",     upgrade_to=nil,
		-- the grandparents will expect some level of education; thus, the library;
		-- a doctor also comes in very handy...
		requires={"lumber","pub","mine","church","farmer","mill","bakery","school","glassmaker","market","library","doctor"},
		provides="housing", level=6, inh=7, worker=3, children=3},



	{scm="npc_mine_level_0_6_270", title="Prospektors Dig", descr="Is this a good place for a mine?", upgrade_to="npc_mine_level_1_6_270",
		-- we need to get started somehow
		requires=nil,
		provides="mine", level=0, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_1_6_270", title="Cobble mine", descr="Beginner's mine - Collecting cobble", upgrade_to="npc_mine_level_2_6_270",
		-- the mine will need a lot of wood;
		-- the pub is needed for recovery after all that mining;
		-- TODO: there has to be at least one house
		requires={"lumber","pub", "housing"},
		provides="mine", level=1, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_2_6_270", title="Coal mine",   descr="Digging for coal",  upgrade_to="npc_mine_level_3_6_270",
		-- the miner is needed for the cobble in the building;
		-- the church is needed in order to get married :-)
		requires={"lumber","pub","mine","church"},
		provides="mine", level=2, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_3_6_270", title="Ore mine", descr="Searching for iron and copper",   upgrade_to="npc_mine_level_4_6_270",
		-- the farmer provides straw for the roof and wheat; may also provide loam
		-- wheat + mill provide enough food for a child
		requires={"lumber","pub","mine","church","farm","mill"},
		provides="mine", level=3, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_4_6_270", title="Gold mine", descr="Searching for gold and other ores",  upgrade_to="npc_mine_level_5_6_270",
		-- there are enough children for a school now;
		-- the bakery helps to feed more children more easily
		requires={"lumber","pub","mine","church","farmer","mill","bakery","school"},
		provides="mine", level=4, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_5_6_270", title="Mese mine", descr="Advanced mine",   upgrade_to="npc_mine_level_6_6_270",
		-- the house uses glass; needs to come from somewhere
		-- a market might be useful for trading (more mouths to feed)
		requires={"lumber","pub","mine","church","farmer","mill","bakery","school","glassmaker","market"},
		provides="mine", level=5, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_6_6_270", title="Diamond mine", descr="Extreme mining operation", upgrade_to=nil,
		-- the grandparents will expect some level of education; thus, the library;
		-- a doctor also comes in very handy...
		requires={"lumber","pub","mine","church","farmer","mill","bakery","school","glassmaker","market","library","doctor"},
		provides="mine", level=6, inh=0, worker=0, children=0, needs_worker=1, job="miner"},



	-- very tiny wooden chapel
	{scm="npc_church_level_0_1_0", title="Small chapel",         descr="Getting started",          upgrade_to="npc_church_level_1_1_0",
		-- we need to get started somehow
		requires=nil,
		-- too small to require a worker of its own; can be done by a part-time worker
		provides="church", level=0, inh=0, worker=0, children=0, needs_worker=0, job="priest"},

	-- small wooden church
	{scm="npc_church_level_1_1_0", title="Small wooden church",  descr="Marriages can take place", upgrade_to="npc_church_level_2_1_0",
		-- we need to get started somehow
		requires={"lumber","housing"},
		provides="church", level=1, inh=0, worker=0, children=0, needs_worker=1, job="priest"},

	};

citybuilder.starter_buildings = {};


local mts_path = minetest.get_modpath( minetest.get_current_modname())..'/schems/';

for i,v in ipairs( citybuilder.buildings ) do
	-- this is a building that belongs to the citybuilder mod
	v.citybuilder = 1;
	-- register the building so that handle_schematics can analyze the blueprint and keep it ready
	build_chest.add_building( mts_path..v.scm, v );
	-- add the building to the build chest
	build_chest.add_entry( {'main','mods', 'citybuilder', v.provides, v.scm, mts_path..v.scm});
	-- there has to be a first building in each series which does not require any predecessors;
	-- it will be offered as something the player can build
	-- (upgrades are then available at the particular building)
	if( not( v.requires )) then
		table.insert( citybuilder.starter_buildings, v.scm );
	end	
end

print("[citybuilder] Available starter buildings: "..minetest.serialize( citybuilder.starter_buildings )); -- TODO: just for debugging


-- called in after_place_node
citybuilder.blueprint_placed = function( pos, placer, itemstack )
 -- TODO: check if placement is allowed
	local meta = minetest.get_meta( pos );
	meta:set_string( 'owner',        placer:get_player_name());

	-- TODO: encode the filename somewhere (in the itemstacks metadata)
	local building_name = mts_path.."npc_house_level_0_1_180";
	meta:set_string( 'building_name', building_name );

	-- this takes param2 of the node at the position pos into account (=rotation
	-- of the chest/plot marker/...) and sets metadata accordingly: start_pos,
	-- end_pos, rotate, mirror and replacements
	local start_pos = build_chest.get_start_pos( pos );
	if( not( start_pos ) or not( start_pos.x )) then
		minetest.chat_send_player( placer:get_player_name(), "Error: "..tostring( start_pos ));
		return;
	end
minetest.chat_send_player( placer:get_player_name(), "start_pos is: "..tostring( start_pos ));
if( true) then end;


	local formspec = ""; -- TODO

	local error_msg = handle_schematics.place_building_from_file(
			minetest.deserialize(meta:get_string( "start_pos")),
			minetest.deserialize(meta:get_string( "end_pos")),
			building_name,
			{}, -- no replacements
		        meta:get_string("rotate"),
			build_chest.building[ building_name ].axis,
			meta:get_string("mirror"),
			-- no_plotmarker, keep_ground, scaffolding_only, plotmarker_pos
			1, false, true, pos );
	formspec = formspec.."label[3,3;The building has been reset.]";
	if( error_msg ) then
		formspec = formspec..'label[4,3;Error: '..tostring( fields.error_msg ).."]";
	end
	minetest.chat_send_player( placer:get_player_name(), "INFO: "..tostring( formspec ));
end


citybuilder.on_receive_fields = function(pos, formname, fields, player)
   minetest.chat_send_player("You entered: "..minetest.serialize(fields));
end

minetest.register_node("citybuilder:blueprint", {
	description = "Blueprint for a house", -- TODO: there are diffrent types
	tiles = {"default_chest_side.png", "default_chest_top.png", "default_chest_side.png", -- TODO: a universal texture would be better
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png"},
	paramtype2 = "facedir",
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	legacy_facedir_simple = true,

        after_place_node = function(pos, placer, itemstack)
		citybuilder.blueprint_placed( pos, placer, itemstack );
        end,
        on_receive_fields = function( pos, formname, fields, player )
           return citybuilder.on_receive_fields(pos, formname, fields, player);
        end,
        allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
                if from_list=="needed" or to_list=="needed" then return 0 end
                return count
        end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
                if listname=="needed" then return 0 end
                return stack:get_count()
        end,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
                if listname=="needed" then return 0 end
                return stack:get_count()
        end,

        can_dig = function(pos,player)
            local meta          = minetest.get_meta( pos );
            local inv           = meta:get_inventory();
            local owner_name    = meta:get_string( 'owner' );
            local building_name = meta:get_string( 'building_name' );
            local name          = player:get_player_name();

            if( not( meta ) or not( owner_name )) then
               return true;
            end
            if( owner_name ~= name ) then
               minetest.chat_send_player(name, "This building chest belongs to "..tostring( owner_name )..". You can't take it.");
               return false;
            end
            if( building_name ~= nil and building_name ~= "" ) then
               minetest.chat_send_player(name, "This building chest has been assigned to a building project. You can't take it away now.");
               return false;
            end
            return true;
        end,
})


-- a player clicked on something in a formspec he was shown
citybuilder.form_input_handler = function( player, formname, fields)
	if(formname == "citybuilder:build" and fields and fields.pos2str) then
		local pos = minetest.string_to_pos( fields.pos2str );
		citybuilder.on_receive_fields(pos, formname, fields, player);
	end
end

-- make sure we receive player input; needed for showing formspecs directly (which is in turn faster than just updating the node)
minetest.register_on_player_receive_fields( citybuilder.form_input_handler );

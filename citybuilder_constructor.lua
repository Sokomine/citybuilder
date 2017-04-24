
-- citybuilder:blueprint is used to construct the houses at the location
-- which the player selected


-- called in after_place_node
citybuilder.blueprint_placed = function( pos, placer, itemstack )
 -- TODO: check if placement is allowed
	local meta = minetest.get_meta( pos );
	meta:set_string( 'owner',        placer:get_player_name());

	-- TODO: encode the filename somewhere (in the itemstacks metadata)
	local building_name = citybuilder.mts_path.."npc_house_level_0_1_180";
	meta:set_string( 'building_name', building_name );

	-- this takes param2 of the node at the position pos into account (=rotation
	-- of the chest/plot marker/...) and sets metadata accordingly: start_pos,
	-- end_pos, rotate, mirror and replacements
	local start_pos = build_chest.get_start_pos( pos );
	if( not( start_pos ) or not( start_pos.x )) then
		minetest.chat_send_player( placer:get_player_name(), "Error: "..tostring( start_pos ));
		return;
	end

	citybuilder.update( pos, placer, meta );
end


citybuilder.update = function( pos, player, meta )
	if( not( meta ) or not( pos ) or not( player )) then
		return;
	end
	local building_name = meta:get_string( 'building_name' );
	local error_msg = nil;
	if( not( building_name ) or building_name == "" or not( build_chest.building[ building_name ] )) then
		error_msg = "Unkown building \""..tostring( building_name ).."\".";
	else
		-- the place_building_from_file function will set these values
		meta:set_int( "nodes_to_dig", -1 );
		meta:set_int( "nodes_to_place", -1 );
		-- actually place dig_here-indicators and special scaffolding
		error_msg = handle_schematics.place_building_from_file(
			minetest.deserialize(meta:get_string( "start_pos")),
			minetest.deserialize(meta:get_string( "end_pos")),
			building_name,
			{}, -- no replacements
		        meta:get_string("rotate"),
			build_chest.building[ building_name ].axis,
			meta:get_string("mirror"),
			-- no_plotmarker, keep_ground, scaffolding_only, plotmarker_pos
			1, false, true, pos );
	end
	if( error_msg ) then
		minetest.show_formspec( placer:get_player_name(), "citybuilder:build",
			"size[8,1]"..
			"label[0,0.1;Error: "..tostring( error_msg ).."]"..
			"button_exit[3.5,0.7;1,0.5;OK;OK]");
		return;
	end

	local need_to_dig   = meta:get_int( "nodes_to_dig" );
	local need_to_place = meta:get_int( "nodes_to_place" );
--[[
	local inv = meta:get_inventory();
	local need_to_place = 0;
	if( not( inv:is_empty("needed"))) then
		for i in 1,inv:get_size("needed") do
			need_to_place = need_to_place + inv:get_stack("needed", i):get_count();
		end
	end
--]]
minetest.chat_send_player( player:get_player_name(), "Need to dig "..tostring( need_to_dig ).." and place "..tostring( need_to_place ).." nodes.");
	local formspec = ""; -- TODO
	formspec = formspec.."label[3,3;The building has been updated.]"; -- TODO
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
		-- TODO: only allow aborting a project if level 0 has not been completed yet
		-- TODO: unregister the building with the townhall
		handle_schematics.abort_project_remove_indicators( meta );
--            if( building_name ~= nil and building_name ~= "" ) then
--               minetest.chat_send_player(name, "This building chest has been assigned to a building project. You can't take it away now.");
--               return false;
--            end
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

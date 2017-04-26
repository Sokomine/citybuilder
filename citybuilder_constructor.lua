
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

	local formspec = citybuilder.update( pos, placer, meta, nil, nil );
	minetest.show_formspec( placer:get_player_name(), "citybuilder:build", formspec );
end


-- returns the new formspec
citybuilder.update = function( pos, player, meta, do_upgrade, no_update )
	if( not( meta ) or not( pos ) or not( player )) then
		return;
	end
	local building_name = meta:get_string( 'building_name' );
	local error_msg = nil;
	if( not( building_name ) or building_name == "" or not( build_chest.building[ building_name ] )) then
		error_msg = "Unkown building \""..tostring( building_name ).."\".";
	elseif( no_update ) then
		-- do nothing here
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
			nil, -- no mirror; meta:get_int("mirror"),
			-- no_plotmarker, keep_ground, scaffolding_only, plotmarker_pos
			1, false, true, pos );
	end

	local formspec = "size[9,7]"..
			"list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";needed;0,2;8,5;]"..
			"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..
			"button_exit[3.0,0.7;2.5,0.5;remove_indicators;Remove scaffolding]"..
			"button_exit[6.0,0.7;1.2,0.5;preview;Preview]"..
			"button_exit[7.5,0.7;1,0.5;OK;Exit]";
	if( error_msg ) then
		return formspec..
			"label[0,0.1;Error: "..tostring( error_msg ).."]";
	end

	local need_to_dig   = meta:get_int( "nodes_to_dig" );
	local need_to_place = meta:get_int( "nodes_to_place" );

	-- if the building is not yet finished
	if( need_to_dig ~= 0 or need_to_place ~= 0 or not( build_chest.building[ building_name ].citybuilder)) then
		return formspec..
			"label[0,0.1;Status: Need to dig "..tostring( need_to_dig ).." and place "..tostring( need_to_place ).." nodes.]"..
			"button_exit[0.5,0.7;2,0.5;update;Update status]";
	end

	-- set the level of the (completed) building
	meta:set_int( "citybuilder_level", build_chest.building[ building_name ].level+1 );
	meta:set_int( "complete", 1 );

	if( build_chest.building[ building_name ].upgrade_to ) then
		-- TODO
		local upgrade_possible_to = build_chest.building[ building_name ].upgrade_to;
		local descr = upgrade_possible_to;
		if( upgrade_possible_to
		  and build_chest.building[ citybuilder.mts_path..upgrade_possible_to ]
		  and build_chest.building[ citybuilder.mts_path..upgrade_possible_to ].descr ) then
			descr = build_chest.building[ citybuilder.mts_path..upgrade_possible_to ].descr;
		end

		if( not( do_upgrade )) then
			return formspec..
				"label[0,0.1;Info: Upgrade \""..descr.."\" (level "..
					tostring( build_chest.building[ citybuilder.mts_path..upgrade_possible_to ].level )..") available.]"..
				"button_exit[0.5,0.7;2,0.5;upgrade;Upgrade now]";
		end

		meta:set_string( 'building_name', citybuilder.mts_path..upgrade_possible_to );
		-- call the function recursively once in order to update
		return citybuilder.update( pos, player, meta, nil, nil );
	end
	return formspec..
		"label[0,0.1;Congratulations! The highest upgrade has been reached.]";
end




citybuilder.on_receive_fields = function(pos, formname, fields, player)
	if( not( pos ) or fields.OK) then
		return;
	end
	local meta = minetest.get_meta( pos );

	if( fields.remove_indicators ) then
		handle_schematics.abort_project_remove_indicators( meta );
		return;
	end

	local formspec = "";
	if( fields.preview and not( fields.end_preview )) then
		if( fields.preview == "Preview" ) then
			fields.preview = "front";
		end
		local building_name = meta:get_string( 'building_name' );
		formspec = "size[10,10]"..
			"label[3,1;Preview]"..
			"button[7,1;2.5,0.5;end_preview;Back to main menu]"..
			"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..
			build_chest.preview_image_formspec( building_name, {}, fields.preview);
	else
		formspec = citybuilder.update( pos, player, meta, fields.upgrade, not(fields.update) );
	end
	minetest.show_formspec( player:get_player_name(), "citybuilder:build", formspec );
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

		local level = meta:get_int( "citybuilder_level" );
		if( level and level > 0 ) then
			minetest.chat_send_player(name, "This chest has spawned a building and cannot be digged.");
			return false;
		end
		-- TODO: only allow aborting a project if level 0 has not been completed yet
		-- TODO: unregister the building with the townhall
		handle_schematics.abort_project_remove_indicators( meta );
		return true;
        end,

	-- handle formspec manually - not via meta:set_string("formspec") as it is very dynamic
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		citybuilder.on_receive_fields(pos, "citybuilder:build", {}, clicker );
		return itemstack;
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
